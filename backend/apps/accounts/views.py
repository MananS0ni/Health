import logging
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, Role, EmailOTP, DoctorProfile, LabProfile, HospitalProfile
from .serializers import (
    RequestOTPSerializer,
    VerifyOTPSerializer,
    UserSerializer,
    RegisterProfileSerializer
)

logger = logging.getLogger(__name__)


class RequestOTPView(APIView):
    """
    POST /api/auth/request-otp/
    Accepts an email address, generates a 6-digit OTP, and sends it via SMTP.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        otp_obj = EmailOTP.generate_otp(email)

        # Compose email
        subject = f"Your Health Platform Verification Code: {otp_obj.otp}"
        message = (
            f"Hello,\n\n"
            f"Your verification code for the Digital Health Record Platform is: {otp_obj.otp}\n\n"
            f"This code will expire in 5 minutes. If you did not request this, please disregard.\n\n"
            f"— The Health Platform Team"
        )
        
        print(f"\n" + "="*50)
        print(f"  [HEALTH PLATFORM OTP]")
        print(f"  To:   {email}")
        print(f"  OTP:  {otp_obj.otp}")
        print(f"="*50 + "\n")

        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
            email_sent = True
        except Exception as e:
            logger.error(f"Failed to send OTP email to {email}: {e}")
            email_sent = False

        if email_sent or settings.DEBUG:
            response_payload = {
                'success': True,
                'message': 'OTP sent successfully to your email.' if email_sent else 'OTP generated (Email delivery failed or delayed. Check console in DEBUG mode).',
                'email': email,
            }
            if settings.DEBUG:
                response_payload['dev_otp'] = otp_obj.otp
            return Response(response_payload, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'error': 'Failed to send OTP email. Please check your SMTP configuration or email address.',
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class VerifyOTPView(APIView):
    """
    POST /api/auth/verify-otp/
    Verifies the submitted 6-digit OTP. On success, returns JWT access and refresh tokens.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        otp_code = serializer.validated_data['otp']

        otp_record = EmailOTP.objects.filter(
            email=email,
            otp=otp_code,
            is_used=False
        ).first()

        if not otp_record or not otp_record.is_valid():
            return Response({
                'success': False,
                'error': 'Invalid or expired OTP code. Please request a new code.'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Mark OTP as consumed
        otp_record.is_used = True
        otp_record.save(update_fields=['is_used'])

        full_name = serializer.validated_data.get('full_name', '')
        phone_number = serializer.validated_data.get('phone_number', '')
        roles = serializer.validated_data.get('roles', [])
        doctor_profile_data = serializer.validated_data.get('doctor_profile')
        org_profile_data = serializer.validated_data.get('org_profile')

        primary_role = Role.PATIENT
        if 'doctor' in roles:
            primary_role = Role.DOCTOR
        elif 'lab_staff' in roles:
            primary_role = Role.LAB
        elif 'hospital_staff' in roles:
            primary_role = Role.HOSPITAL
        elif serializer.validated_data.get('role'):
            primary_role = serializer.validated_data['role']

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'is_verified': True,
                'role': primary_role,
                'full_name': full_name,
                'phone_number': phone_number,
                'roles': roles,
            }
        )

        user.is_verified = True
        if full_name:
            user.full_name = full_name
        if phone_number:
            user.phone_number = phone_number
        if roles:
            user.roles = roles
        if primary_role != Role.PATIENT or not user.role:
            user.role = primary_role
        user.save()

        # Create/Update sub-profiles if provided
        if ('doctor' in user.roles or user.role == Role.DOCTOR) and doctor_profile_data:
            DoctorProfile.objects.update_or_create(
                user=user,
                defaults={
                    'registration_number': doctor_profile_data.get('registration_number', ''),
                    'specialization': doctor_profile_data.get('specialization', 'General Medicine'),
                    'clinic_name': doctor_profile_data.get('clinic_name', ''),
                }
            )

        if ('lab_staff' in user.roles or user.role == Role.LAB) and org_profile_data:
            LabProfile.objects.update_or_create(
                user=user,
                defaults={
                    'lab_name': org_profile_data.get('organization_name', user.full_name or 'Diagnostic Lab'),
                    'license_number': org_profile_data.get('employee_id', ''),
                    'address': '',
                }
            )

        if ('hospital_staff' in user.roles or user.role == Role.HOSPITAL) and org_profile_data:
            HospitalProfile.objects.update_or_create(
                user=user,
                defaults={
                    'hospital_name': org_profile_data.get('organization_name', user.full_name or 'Hospital Care'),
                    'registration_id': org_profile_data.get('employee_id', ''),
                    'departments': 'General, ICU, Emergency',
                }
            )

        # Refresh from db to ensure related objects are loaded
        user.refresh_from_db()

        is_profile_complete = bool(user.full_name and user.full_name.strip())

        # Generate JWT Tokens
        refresh = RefreshToken.for_user(user)

        return Response({
            'success': True,
            'message': 'Verification successful.',
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            },
            'user': UserSerializer(user).data,
            'is_new_user': created or not is_profile_complete,
            'role': user.role,
        }, status=status.HTTP_200_OK)


class RegisterProfileView(APIView):
    """
    POST /api/auth/register-profile/
    Submits role-specific profile details (Doctor license, Lab reg, Hospital ID).
    Requires Bearer token authentication.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = RegisterProfileSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user = request.user

        user.full_name = data['full_name']
        if data.get('phone_number'):
            user.phone_number = data['phone_number']
        user.role = data.get('role', Role.PATIENT)
        user.save()

        # Handle role-specific sub-profiles
        if user.role == Role.DOCTOR:
            DoctorProfile.objects.update_or_create(
                user=user,
                defaults={
                    'registration_number': data.get('registration_number', ''),
                    'specialization': data.get('specialization', 'General Medicine'),
                    'clinic_name': data.get('clinic_name', ''),
                }
            )
        elif user.role == Role.LAB:
            LabProfile.objects.update_or_create(
                user=user,
                defaults={
                    'lab_name': data.get('lab_name', data['full_name']),
                    'license_number': data.get('lab_license', ''),
                    'address': data.get('lab_address', ''),
                }
            )
        elif user.role == Role.HOSPITAL:
            HospitalProfile.objects.update_or_create(
                user=user,
                defaults={
                    'hospital_name': data.get('hospital_name', data['full_name']),
                    'registration_id': data.get('hospital_reg_id', ''),
                    'departments': data.get('departments', ''),
                }
            )

        return Response({
            'success': True,
            'message': 'Profile registered successfully.',
            'user': UserSerializer(user).data,
        }, status=status.HTTP_200_OK)


class MeView(APIView):
    """
    GET /api/auth/me/
    Retrieves the currently authenticated user's profile and active role details.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({
            'success': True,
            'user': UserSerializer(request.user).data,
        }, status=status.HTTP_200_OK)
