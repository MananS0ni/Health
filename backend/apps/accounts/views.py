import logging
from django.conf import settings
from django.contrib.auth.hashers import check_password
from django.core.mail import send_mail
from django.db import transaction, IntegrityError
from django.db.models import F
from django.utils import timezone
from rest_framework import permissions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from .models import User, EmailOTP, DoctorProfile, LabProfile, HospitalProfile
from .serializers import RequestOTPSerializer, VerifyOTPSerializer, UserSerializer, RegisterProfileSerializer
from .permissions import ALIASES, PROFESSIONAL_ROLES

logger = logging.getLogger(__name__)

class RequestOTPView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'otp_send'

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email, mode = serializer.validated_data['email'], serializer.validated_data['mode']
        user = User.objects.filter(email__iexact=email).first()
        if mode == 'login' and (not user or not user.is_active):
            return Response({'error': 'Account unavailable. Please register or contact support.'}, status=400)
        if mode == 'signup' and user:
            return Response({'error': 'An account with this email already exists. Please sign in.'}, status=400)
        if EmailOTP.objects.filter(email=email, created_at__gt=timezone.now()-timezone.timedelta(seconds=60)).exists():
            return Response({'error': 'Please wait one minute before requesting another code.'}, status=429)
        otp = EmailOTP.generate_otp(email, purpose=mode)
        try:
            send_mail('Health Platform verification code', f'Your verification code is {otp.code}. It expires in 5 minutes.', settings.DEFAULT_FROM_EMAIL, [email], fail_silently=False)
        except Exception:
            otp.is_used = True
            otp.save(update_fields=['is_used'])
            logger.warning('OTP delivery failed')
            return Response({'error': 'Email delivery failed. Please try again later.'}, status=503)
        return Response({'success': True, 'message': 'Verification code sent.', 'email': email})

class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'otp_verify'

    @transaction.atomic
    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        email = data['email']
        otp = EmailOTP.objects.filter(email=email, is_used=False).first()
        if not otp or not otp.is_valid():
            return Response({'error': 'Invalid or expired code.'}, status=400)
        if not check_password(data['otp'], otp.otp):
            EmailOTP.objects.filter(pk=otp.pk, is_used=False).update(attempts=F('attempts')+1)
            return Response({'error': 'Invalid or expired code.'}, status=400)
        user = User.objects.filter(email__iexact=email).first()
        if user and not user.is_active:
            return Response({'error': 'Account unavailable.'}, status=403)
        if not user and (otp.purpose != 'signup' or not data.get('full_name')):
            return Response({'error': 'Please complete signup first.'}, status=400)
        if not EmailOTP.objects.filter(pk=otp.pk, is_used=False, attempts__lt=5, expires_at__gt=timezone.now()).update(is_used=True):
            return Response({'error': 'Code already used or expired.'}, status=400)
        created = user is None
        if created:
            requested = {ALIASES.get(r, r) for r in data.get('roles', []) + [data.get('role', 'patient')]}
            try:
                with transaction.atomic():
                    user = User.objects.create_user(email=email, full_name=data['full_name'], phone_number=data.get('phone_number', ''), role='patient', roles=['patient'], pending_roles=sorted(requested & PROFESSIONAL_ROLES), is_verified=True)
            except IntegrityError:
                return Response({'error': 'An account with this email already exists.'}, status=409)
            from apps.patients.serializers import PatientProfileSerializer
            from apps.patients.models import PatientProfile
            profile = PatientProfile.objects.create(user=user)
            fields = {'date_of_birth','gender','blood_group','allergies','medical_conditions','current_medications','emergency_contact_name','emergency_contact_phone'}
            ps = PatientProfileSerializer(profile, data={k:v for k,v in data.items() if k in fields}, partial=True)
            ps.is_valid(raise_exception=True)
            ps.save()
            for key, model, allowed in (
                ('doctor_profile', DoctorProfile, {'registration_number','specialization','clinic_name'}),
                ('lab_profile', LabProfile, {'lab_name','license_number','address'}),
                ('hospital_profile', HospitalProfile, {'hospital_name','registration_id','departments'}),
            ):
                if data.get(key):
                    model.objects.create(user=user, **{k:v for k,v in data[key].items() if k in allowed})
        else:
            user.is_verified = True
            user.save(update_fields=['is_verified'])
        refresh = RefreshToken.for_user(user)
        return Response({'success': True, 'tokens': {'access': str(refresh.access_token), 'refresh': str(refresh)}, 'user': UserSerializer(user).data, 'is_new_user': created, 'role': user.role})

class RegisterProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = RegisterProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data, user = serializer.validated_data, request.user
        role = ALIASES.get(data.get('role', 'patient'), data.get('role', 'patient'))
        if role == 'admin':
            return Response({'error': 'Administrative privileges cannot be requested here.'}, status=403)
        user.full_name = data['full_name']
        if 'phone_number' in data:
            user.phone_number = data['phone_number']
        if role in PROFESSIONAL_ROLES:
            user.pending_roles = sorted(set(user.pending_roles or []) | {role})
            user.professional_verified = False
            mapping = {
                'doctor': (DoctorProfile, {'registration_number':'registration_number','specialization':'specialization','clinic_name':'clinic_name'}),
                'lab': (LabProfile, {'lab_name':'lab_name','lab_license':'license_number','lab_address':'address'}),
                'hospital': (HospitalProfile, {'hospital_name':'hospital_name','hospital_reg_id':'registration_id','departments':'departments'}),
            }
            model, fields = mapping[role]
            model.objects.update_or_create(user=user, defaults={dest:data[src] for src,dest in fields.items() if src in data})
        user.save()
        return Response({'success': True, 'message': 'Profile saved. Professional credentials require administrator review.', 'user': UserSerializer(user).data})

class MeView(APIView):
    def get(self, request):
        return Response({'success': True, 'user': UserSerializer(request.user).data})

    def patch(self, request):
        if any(k in request.data for k in ('role','roles','email','is_verified','professional_verified','pending_roles')):
            raise serializers.ValidationError('Identity and role grants cannot be changed through profile editing.')
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'success': True, 'user': serializer.data})

class LogoutView(APIView):
    def post(self, request):
        try:
            token = RefreshToken(request.data.get('refresh', ''))
            if str(token['user_id']) != str(request.user.pk):
                return Response({'error': 'Token belongs to another session owner.'}, status=403)
            token.blacklist()
        except (TokenError, KeyError):
            return Response({'error': 'Invalid refresh token.'}, status=400)
        return Response({'success': True})
