from apps.care.services import notify, audit
from apps.care.services import notify, audit
from datetime import timedelta
from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import permissions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Appointment, Prescription, ConsentRequest
from .serializers import AppointmentSerializer, PrescriptionSerializer, ConsentRequestSerializer
from apps.accounts.models import User
from apps.accounts.permissions import IsDoctor, VerifiedProfessional, resolve_patient, require_patient_access, can_access_patient
from apps.patients.models import PatientProfile, HealthVital
from apps.patients.serializers import PatientProfileSerializer, HealthVitalSerializer
from apps.reports.models import MedicalRecord, LabReport
from apps.reports.serializers import MedicalRecordSerializer, LabReportSerializer


def resolve_patient_user(value):
    return resolve_patient(value)


def resolve_current_doctor(request):
    return request.user


class DoctorAppointmentListCreateView(APIView):
    def get(self, request):
        context = request.query_params.get('context', 'patient')
        if context == 'doctor':
            if not IsDoctor().has_permission(request, self):
                return Response({'error': 'Verified doctor access required.'}, status=403)
            appointments = Appointment.objects.filter(doctor=request.user)
        else:
            appointments = Appointment.objects.filter(patient=request.user)
        return Response(AppointmentSerializer(appointments[:200], many=True).data)

    @transaction.atomic
    def post(self, request):
        if not IsDoctor().has_permission(request, self):
            return Response({'error': 'Use patient booking to reserve a provider slot.'}, status=403)
        patient = resolve_patient(request.data.get('patient') or request.data.get('patient_id'))
        require_patient_access(request.user, patient)
        data = request.data.copy()
        data['patient'] = str(patient.pk)
        data['patient_name'] = patient.full_name
        serializer = AppointmentSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        date = serializer.validated_data.get('appointment_date', timezone.localdate())
        slot = serializer.validated_data.get('time_slot', '10:00 AM')
        # Serialize schedule mutations on the provider account.
        User.objects.select_for_update().get(pk=request.user.pk)
        if Appointment.objects.filter(doctor=request.user, appointment_date=date, time_slot=slot).exclude(status='Cancelled').exists():
            return Response({'error': 'This appointment slot is already reserved.'}, status=409)
        appointment = serializer.save(doctor=request.user)
        notify(patient, 'An appointment has been booked for you.', 'appointment', appointment.pk)
        audit(request.user, 'appointment.created', appointment.pk)
        return Response(serializer.data, status=201)


class AppointmentActionView(APIView):
    @transaction.atomic
    def post(self, request, appointment_id):
        appt = get_object_or_404(Appointment.objects.select_for_update().filter(Q(patient=request.user)|Q(doctor=request.user)), pk=appointment_id)
        if request.data.get('action') != 'cancel':
            return Response({'error': 'Supported action: cancel.'}, status=400)
        if appt.status == 'Cancelled': return Response({'success': True})
        if appt.status == 'Completed': return Response({'error': 'Completed appointment cannot be cancelled.'}, status=400)
        appt.status = 'Cancelled'
        appt.save(update_fields=['status'])
        notify(appt.patient, 'Your appointment was cancelled.', 'appointment', appt.pk)
        audit(request.user, 'appointment.cancelled', appt.pk)
        return Response({'success': True})


class DoctorPatientSearchView(APIView):
    permission_classes = [IsDoctor]
    def get(self, request):
        q = (request.query_params.get('q') or request.query_params.get('email') or '').strip()
        if len(q) < 3:
            return Response([])
        qs = User.objects.filter(is_active=True, is_staff=False).filter(Q(email__iexact=q)|Q(full_name__icontains=q))[:25]
        return Response([{'id':str(u.pk), 'patient_id':f'PAT-{u.pk}', 'full_name':u.full_name, 'email':u.email} for u in qs])

    def post(self, request):
        email = serializers.EmailField().run_validation(request.data.get('email')) .lower()
        if User.objects.filter(email__iexact=email).exists():
            return Response({'error': 'Patient already registered. Request their consent instead.'}, status=409)
        name = serializers.CharField(max_length=255).run_validation(request.data.get('full_name'))
        patient = User.objects.create_user(email=email, full_name=name, roles=['patient'], is_verified=False)
        PatientProfile.objects.create(user=patient)
        return Response({'id':str(patient.pk), 'patient_id':f'PAT-{patient.pk}', 'full_name':name, 'email':email}, status=201)


class DoctorPrescriptionCreateView(APIView):
    permission_classes = [IsDoctor]
    @transaction.atomic
    def post(self, request):
        patient = resolve_patient(request.data.get('patient') or request.data.get('patient_id'))
        require_patient_access(request.user, patient)
        data = request.data.copy()
        data['patient'] = str(patient.pk)
        serializer = PrescriptionSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        rx = serializer.save(doctor=request.user)
        notify(patient, 'A new prescription is available in your records.', 'prescription', rx.pk)
        audit(request.user, 'prescription.created', rx.pk)
        instructions = '\n'.join(f'{m.medicine_name}: {m.dosage}, {m.duration}. {m.instructions or ""}' for m in rx.medicines.all())
        profile = getattr(request.user, 'doctor_profile', None)
        MedicalRecord.objects.create(source='professional', created_by=request.user, patient=patient, title=f'Prescription: {rx.diagnosis}', record_type='Prescription', record_date=rx.prescribed_date, doctor_name=request.user.full_name, facility_name=profile.clinic_name if profile else '', description=f'Diagnosis: {rx.diagnosis}\n{instructions}\nNotes: {rx.clinical_notes or ""}')
        return Response(serializer.data, status=201)


class DoctorPatientDetailChartView(APIView):
    def get(self, request, patient_id):
        patient = resolve_patient(patient_id)
        if request.user != patient and not VerifiedProfessional().has_permission(request, self):
            return Response({'error': 'Professional access required.'}, status=403)
        consent = ConsentRequest.objects.filter(doctor=request.user, patient=patient).order_by('-created_at').first()
        permitted = can_access_patient(request.user, patient)
        if permitted and request.user.pk != patient.pk: audit(request.user, 'clinical_chart.viewed', patient.pk)
        data = {'patient_id':str(patient.pk), 'full_name':patient.full_name, 'has_consent':permitted, 'consent_status':'approved' if permitted else ('pending' if consent and consent.status == 'pending' else 'none'), 'consent_id':str(consent.pk) if consent else None, 'vitals':[], 'prescriptions':[], 'reports':[], 'records':[]}
        if permitted:
            profile, _ = PatientProfile.objects.get_or_create(user=patient)
            data.update(PatientProfileSerializer(profile).data)
            data['chronic_conditions'] = profile.medical_conditions
            data['vitals'] = HealthVitalSerializer(HealthVital.objects.filter(patient=patient)[:20], many=True).data
            data['prescriptions'] = PrescriptionSerializer(Prescription.objects.filter(patient=patient).prefetch_related('medicines')[:100], many=True).data
            data['reports'] = LabReportSerializer(LabReport.objects.filter(patient=patient).prefetch_related('parameters')[:100], many=True).data
            data['records'] = MedicalRecordSerializer(MedicalRecord.objects.filter(patient=patient)[:100], many=True).data
        return Response(data)


class DoctorRequestConsentView(APIView):
    permission_classes = [VerifiedProfessional]
    @transaction.atomic
    def post(self, request):
        patient = resolve_patient(request.data.get('patient_id') or request.data.get('patient') or request.data.get('patient_email'))
        if patient == request.user:
            return Response({'error': 'Self-consent is unnecessary.'}, status=400)
        User.objects.select_for_update().get(pk=request.user.pk)
        existing = ConsentRequest.objects.filter(doctor=request.user, patient=patient).filter(Q(status='pending')|Q(status='approved', valid_until__gt=timezone.now())).first()
        if existing:
            return Response({'success':True, 'consent':ConsentRequestSerializer(existing).data})
        purpose = serializers.CharField(max_length=200).run_validation(request.data.get('purpose', 'Clinical consultation'))
        consent = ConsentRequest.objects.create(doctor=request.user, patient=patient, purpose=purpose)
        notify(patient, 'A professional requested access to your medical records. Review it in your consent inbox.', 'consent', consent.pk)
        audit(request.user, 'consent.requested', consent.pk)
        return Response({'success':True, 'message':'Consent request sent.', 'consent':ConsentRequestSerializer(consent).data}, status=201)


class PatientConsentListView(APIView):
    def get(self, request):
        return Response(ConsentRequestSerializer(ConsentRequest.objects.filter(patient=request.user).select_related('doctor','patient')[:200], many=True).data)
    def post(self, request):
        return Response({'error':'Approve a provider request from your consent inbox.'}, status=403)


class PatientConsentActionView(APIView):
    @transaction.atomic
    def post(self, request, consent_id):
        consent = get_object_or_404(ConsentRequest.objects.select_for_update(), pk=consent_id, patient=request.user)
        action = request.data.get('action')
        if action not in ('approve','reject','deny','revoke'):
            return Response({'error':'Invalid action.'}, status=400)
        if action == 'approve' and consent.status != 'pending':
            return Response({'error':'Only a pending request can be approved. Request new consent to renew.'}, status=409)
        consent.status = 'approved' if action == 'approve' else ('revoked' if action == 'revoke' else 'rejected')
        consent.valid_until = timezone.now()+timedelta(hours=24) if action == 'approve' else None
        consent.save()
        notify(consent.doctor, f'Patient access request {consent.status}.', 'consent', consent.pk)
        audit(request.user, 'consent.'+consent.status, consent.pk)
        return Response({'success':True, 'consent':ConsentRequestSerializer(consent).data})


class DoctorIncomingConsentListView(APIView):
    permission_classes = [VerifiedProfessional]
    def get(self, request):
        return Response(ConsentRequestSerializer(ConsentRequest.objects.filter(doctor=request.user).select_related('doctor','patient')[:200], many=True).data)


class DoctorIncomingConsentActionView(APIView):
    permission_classes = [VerifiedProfessional]
    def post(self, request, consent_id):
        return Response({'error':'Only the patient can approve or reject clinical access.'}, status=403)


class DoctorDirectoryView(APIView):
    def get(self, request):
        q = (request.query_params.get('q') or request.query_params.get('email') or '').strip()
        if len(q) < 2:
            return Response([])
        doctors = User.objects.filter(is_active=True, professional_verified=True, doctor_profile__isnull=False).filter(Q(full_name__icontains=q)|Q(email__iexact=q)|Q(doctor_profile__specialization__icontains=q)).select_related('doctor_profile')[:25]
        return Response([{'id':str(d.pk), 'name':d.full_name, 'specialty':d.doctor_profile.specialization, 'clinic':d.doctor_profile.clinic_name, 'type':'doctor'} for d in doctors])
