import uuid
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Q

from .models import Appointment, Prescription, ConsentRequest
from .serializers import AppointmentSerializer, PrescriptionSerializer, ConsentRequestSerializer
from apps.accounts.models import User, Role
from apps.patients.models import PatientProfile, HealthVital
from apps.reports.models import MedicalRecord, LabReport
from apps.patients.serializers import HealthVitalSerializer
from apps.reports.serializers import MedicalRecordSerializer, LabReportSerializer


def resolve_patient_user(val):
    """
    Robustly resolves a patient User object by:
    - UUID string
    - Email address
    - Phone number
    - Formatted patient code (e.g. PAT-4726A2)
    - Full name
    """
    if not val:
        return None
    s = str(val).strip()

    # 1. Try UUID
    try:
        uid = uuid.UUID(s)
        u = User.objects.filter(id=uid).first()
        if u:
            return u
    except (ValueError, AttributeError):
        pass

    # 2. Try Email
    u = User.objects.filter(email__iexact=s).first()
    if u:
        return u

    # 3. Try Phone
    u = User.objects.filter(phone_number__iexact=s).first()
    if u:
        return u

    # 4. Try PAT- code prefix or match
    if s.upper().startswith('PAT-'):
        prefix = s[4:].strip().upper()
        for p in User.objects.all():
            if str(p.id).upper().startswith(prefix) or f"PAT-{str(p.id)[:6].upper()}" == s.upper():
                return p

    # 5. Try Full Name
    u = User.objects.filter(full_name__iexact=s).first()
    if u:
        return u

    return None


def resolve_current_doctor(request):
    """
    Robustly identifies the current doctor User object from:
    1. 'X-User-Email' request header
    2. Authenticated request.user
    3. Query parameter or request body doctor_email / doctor_id
    4. Fallback doctor account (Dr. Rana Parthil or any doctor role user)
    """
    user_header = request.headers.get('X-User-Email')
    if user_header:
        u = resolve_patient_user(user_header)
        if u:
            return u

    if request.user and request.user.is_authenticated:
        return request.user

    param_email = request.query_params.get('doctor_email') or request.query_params.get('email')
    if param_email:
        u = resolve_patient_user(param_email)
        if u:
            return u

    if hasattr(request, 'data') and isinstance(request.data, dict):
        body_val = request.data.get('doctor_email') or request.data.get('doctor_id') or request.data.get('doctor')
        if body_val:
            u = resolve_patient_user(body_val)
            if u:
                return u

    return (
        User.objects.filter(email='23ci2020115@gmail.com').first() or
        User.objects.filter(roles__icontains='doctor').first() or
        User.objects.filter(email='sonimanan2905@gmail.com').first() or
        User.objects.first()
    )


class DoctorAppointmentListCreateView(APIView):
    """
    GET /api/doctor/appointments/ — List all appointments for the logged-in doctor.
    POST /api/doctor/appointments/ — Schedule an appointment.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        patient_email = request.query_params.get('patient_email')
        doc = resolve_current_doctor(request)
        if patient_email:
            patient_user = resolve_patient_user(patient_email)
            appointments = Appointment.objects.filter(patient=patient_user) if patient_user else Appointment.objects.none()
        elif request.user.is_authenticated and ('patient' in (request.user.roles or []) or request.user.role == Role.PATIENT):
            appointments = Appointment.objects.filter(patient=request.user)
        else:
            appointments = Appointment.objects.filter(doctor=doc) if doc else Appointment.objects.none()
        serializer = AppointmentSerializer(appointments, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        doc = resolve_current_doctor(request)
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        patient_val = data.get('patient') or data.get('patient_id')
        if patient_val:
            patient_obj = resolve_patient_user(patient_val)
            if patient_obj:
                data['patient'] = patient_obj.id
            else:
                data['patient'] = doc.id
        else:
            data['patient'] = doc.id
        serializer = AppointmentSerializer(data=data)
        if serializer.is_valid():
            serializer.save(doctor=doc)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DoctorPatientSearchView(APIView):
    """
    GET /api/doctor/patients/?q=rajesh
    Search patient directory by name, email, or phone.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        all_users = User.objects.all()
        patients = [
            u for u in all_users
            if u.role == Role.PATIENT or 'patient' in (u.roles or [])
        ]
        if query:
            q_lower = query.lower()
            patients = [
                p for p in patients
                if q_lower in (p.full_name or '').lower() or
                   q_lower in (p.email or '').lower() or
                   q_lower in (p.phone_number or '').lower()
            ]

        results = []
        from django.utils import timezone
        for p in patients[:25]:
            profile = getattr(p, 'patient_profile', None)
            latest_consultation = Appointment.objects.filter(patient=p).order_by('-appointment_date').first()
            last_visit_str = latest_consultation.appointment_date.strftime('%Y-%m-%d') if latest_consultation else 'First Consultation (New Patient)'
            results.append({
                'id': str(p.id),
                'patient_id': f"PAT-{str(p.id)[:6].upper()}",
                'full_name': p.full_name or 'Anonymous Patient',
                'email': p.email,
                'phone_number': p.phone_number or '--',
                'gender': (profile.gender if profile and profile.gender else 'Not specified'),
                'blood_group': (profile.blood_group if profile and profile.blood_group else '--'),
                'age': profile.date_of_birth if profile and profile.date_of_birth else 'Not specified',
                'last_visit': last_visit_str,
                'last_diagnosis': (latest_consultation.consultation_type if latest_consultation else 'Routine Checkup'),
                'allergies': profile.allergies if profile else [],
                'chronic_conditions': profile.medical_conditions if profile else [],
            })

        return Response(results, status=status.HTTP_200_OK)

    def post(self, request):
        """
        POST /api/doctor/patients/
        Register a new patient from the Doctor Portal with email, phone, age, and blood group.
        """
        data = request.data
        email = data.get('email', '').strip().lower()
        full_name = data.get('full_name', '').strip()
        phone_number = data.get('phone_number', '').strip()
        age = data.get('age')
        gender = data.get('gender', 'Not specified')
        blood_group = data.get('blood_group', '--')

        if not email:
            import time
            email = f"patient_{int(time.time())}@health.local"

        patient, created = User.objects.get_or_create(
            email=email,
            defaults={
                'full_name': full_name or 'New Patient',
                'phone_number': phone_number,
                'role': Role.PATIENT,
                'roles': ['patient'],
                'is_verified': True,
            }
        )
        if not created:
            if full_name:
                patient.full_name = full_name
            if phone_number:
                patient.phone_number = phone_number
            patient.save()

        profile, _ = PatientProfile.objects.get_or_create(user=patient)
        if gender:
            profile.gender = gender
        if blood_group and blood_group != '--':
            profile.blood_group = blood_group
        if age:
            profile.date_of_birth = f"{age} yrs"
        profile.save()

        # Pre-authorize this doctor for 24 hours so clinical chart is immediately unlocked!
        doc = request.user if request.user.is_authenticated else (
            User.objects.filter(email='sonimanan2905@gmail.com').first() or
            User.objects.filter(roles__icontains='doctor').first() or
            User.objects.first()
        )
        from datetime import timedelta
        from django.utils import timezone
        ConsentRequest.objects.update_or_create(
            doctor=doc,
            patient=patient,
            defaults={
                'purpose': 'Initial Clinical Registration & Consultation',
                'status': 'approved',
                'valid_until': timezone.now() + timedelta(hours=24),
            }
        )

        patient_code = f"PAT-{str(patient.id)[:6].upper()}"
        return Response({
            'id': str(patient.id),
            'patient_id': patient_code,
            'full_name': patient.full_name,
            'email': patient.email,
            'phone_number': patient.phone_number,
            'gender': profile.gender,
            'blood_group': profile.blood_group,
            'age': profile.date_of_birth,
            'last_visit': 'First Consultation (New Patient)',
            'last_diagnosis': 'General Registration',
        }, status=status.HTTP_201_CREATED)


class DoctorPrescriptionCreateView(APIView):
    """
    POST /api/doctor/prescriptions/
    Saves a clinical diagnosis and electronic prescription.
    Automatically adds a corresponding record to the patient's personal health locker!
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        patient_val = data.get('patient') or data.get('patient_id')
        patient_obj = None
        if patient_val:
            patient_obj = resolve_patient_user(patient_val)

        if not patient_obj:
            if request.user.is_authenticated:
                patient_obj = request.user
            else:
                patient_obj = User.objects.filter(email='manansoni2905@gmail.com').first() or User.objects.first()

        data['patient'] = str(patient_obj.id)

        # Resolve doctor
        doctor_user = request.user if request.user.is_authenticated else None
        if not doctor_user:
            doc_email = data.get('doctor_email')
            if doc_email:
                doctor_user = resolve_patient_user(doc_email)
            if not doctor_user:
                doctor_user = User.objects.filter(email='sonimanan2905@gmail.com').first() or User.objects.filter(roles__icontains='doctor').first()

        serializer = PrescriptionSerializer(data=data)
        if serializer.is_valid():
            rx = serializer.save(doctor=doctor_user)

            # Auto-sync to the Patient's personal Medical Records locker
            med_list = ", ".join([m.medicine_name for m in rx.medicines.all()])
            facility = 'Patel Clinic'
            if hasattr(doctor_user, 'doctor_profile') and doctor_user.doctor_profile.clinic_name:
                facility = doctor_user.doctor_profile.clinic_name

            MedicalRecord.objects.create(
                patient=rx.patient,
                title=f"Prescription: {rx.diagnosis}",
                record_type="Prescription",
                record_date=rx.prescribed_date,
                doctor_name=doctor_user.full_name or "Dr. Dhruv Patel",
                facility_name=facility,
                description=f"Diagnosis: {rx.diagnosis}\nMedicines: {med_list}\nNotes: {rx.clinical_notes or 'None'}",
            )

            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DoctorPatientDetailChartView(APIView):
    """
    GET /api/doctor/patients/<str:patient_id>/chart/
    Retrieves full clinical chart: vitals, allergies, conditions, and previous records.
    Enforces patient consent: if no active consent is granted, sensitive clinical records remain locked.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, patient_id):
        patient = resolve_patient_user(patient_id)
        if not patient:
            return Response({'error': f'Patient "{patient_id}" not found.'}, status=status.HTTP_404_NOT_FOUND)

        profile, _ = PatientProfile.objects.get_or_create(user=patient)
        vitals = HealthVital.objects.filter(patient=patient)[:6]
        prescriptions = Prescription.objects.filter(patient=patient)
        reports = LabReport.objects.filter(patient=patient)

        doc = resolve_current_doctor(request)

        # Check active consent
        active_consent = ConsentRequest.objects.filter(
            doctor=doc,
            patient=patient,
            status='approved'
        ).order_by('-valid_until').first()

        has_active_consent = active_consent is not None and active_consent.is_active()

        # Check pending consent
        pending_consent = ConsentRequest.objects.filter(
            doctor=doc,
            patient=patient,
            status='pending'
        ).first()

        consent_status = 'approved' if has_active_consent else ('pending' if pending_consent else 'none')

        base_data = {
            'patient_id': str(patient.id),
            'full_name': patient.full_name or 'Patient',
            'email': patient.email,
            'phone_number': patient.phone_number or '--',
            'gender': profile.gender or '--',
            'blood_group': profile.blood_group or '--',
            'allergies': profile.allergies,
            'chronic_conditions': profile.medical_conditions,
            'has_consent': has_active_consent or (request.user == patient),
            'consent_status': consent_status,
            'consent_id': str(active_consent.id) if active_consent else (str(pending_consent.id) if pending_consent else None),
            'consent_valid_until': active_consent.valid_until if active_consent else None,
        }

        if has_active_consent or request.user == patient:
            base_data['vitals'] = HealthVitalSerializer(vitals, many=True).data
            base_data['prescriptions'] = PrescriptionSerializer(prescriptions, many=True).data
            base_data['reports'] = LabReportSerializer(reports, many=True).data
        else:
            base_data['vitals'] = []
            base_data['prescriptions'] = []
            base_data['reports'] = []

        return Response(base_data, status=status.HTTP_200_OK)


class DoctorRequestConsentView(APIView):
    """
    POST /api/doctor/consent/request/
    Doctor submits an access request to view a patient's historical records.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        patient_id = request.data.get('patient_id') or request.data.get('patient')
        patient_email = request.data.get('patient_email') or request.data.get('email')
        purpose = request.data.get('purpose', 'Clinical Consultation & Medical History Review')

        patient = resolve_patient_user(patient_id or patient_email)

        if not patient:
            return Response({'error': f'Patient account "{patient_id or patient_email}" not found.'}, status=status.HTTP_404_NOT_FOUND)

        doc = resolve_current_doctor(request)

        # Check existing active consent
        existing_active = ConsentRequest.objects.filter(
            doctor=doc,
            patient=patient,
            status='approved'
        ).first()

        if existing_active and existing_active.is_active():
            return Response({
                'success': True,
                'message': 'Active consent is already granted for this patient.',
                'consent': ConsentRequestSerializer(existing_active).data
            }, status=status.HTTP_200_OK)

        # Create or refresh pending request
        consent_obj, _ = ConsentRequest.objects.update_or_create(
            doctor=doc,
            patient=patient,
            defaults={
                'purpose': purpose,
                'status': 'pending',
                'valid_until': None,
            }
        )

        return Response({
            'success': True,
            'message': f'Consent request sent to {patient.full_name or patient.email}.',
            'consent': ConsentRequestSerializer(consent_obj).data
        }, status=status.HTTP_201_CREATED)


class PatientConsentListView(APIView):
    """
    GET /api/patients/consents/
    Returns all incoming doctor access requests for the logged-in patient.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        patient = request.user if request.user.is_authenticated else (User.objects.filter(email='manansoni2905@gmail.com').first() or User.objects.first())
        consents = ConsentRequest.objects.filter(patient=patient).order_by('-created_at')
        return Response(ConsentRequestSerializer(consents, many=True).data, status=status.HTTP_200_OK)

    def post(self, request):
        from datetime import timedelta
        from django.utils import timezone
        patient = request.user if request.user.is_authenticated else (User.objects.filter(email='manansoni2905@gmail.com').first() or User.objects.first())
        doc_val = request.data.get('doctor_id') or request.data.get('doctor_email') or request.data.get('doctor')
        doctor = resolve_patient_user(doc_val)
        if not doctor:
            # Fallback to any doctor user if specific email not found
            doctor = User.objects.filter(roles__icontains='doctor').first() or User.objects.filter(email='dr.patel@health.com').first()

        if not doctor:
            return Response({'error': 'Doctor account not found.'}, status=status.HTTP_404_NOT_FOUND)

        consent_obj, _ = ConsentRequest.objects.update_or_create(
            doctor=doctor,
            patient=patient,
            defaults={
                'purpose': 'Patient Connection & Medical Records Access Request',
                'status': 'pending',
                'valid_until': None,
            }
        )
        return Response({
            'success': True,
            'message': f'Connection request sent to Dr. {doctor.full_name or doctor.email}. Awaiting doctor acceptance.',
            'consent': ConsentRequestSerializer(consent_obj).data
        }, status=status.HTTP_200_OK)


class PatientConsentActionView(APIView):
    """
    POST /api/patients/consents/<str:consent_id>/action/
    Patient approves, rejects, or revokes a doctor's access request.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, consent_id):
        from datetime import timedelta
        from django.utils import timezone

        action = request.data.get('action', '').lower()
        if action not in ('approve', 'reject', 'deny', 'revoke'):
            return Response({'error': 'Invalid action. Must be "approve", "reject", or "revoke".'}, status=status.HTTP_400_BAD_REQUEST)

        patient = request.user if request.user.is_authenticated else (User.objects.filter(email='manansoni2905@gmail.com').first() or User.objects.first())
        consent = ConsentRequest.objects.filter(id=consent_id, patient=patient).first()
        if not consent:
            return Response({'error': 'Consent request not found.'}, status=status.HTTP_404_NOT_FOUND)

        if action == 'approve':
            consent.status = 'approved'
            consent.valid_until = timezone.now() + timedelta(hours=24)
            msg = 'Access granted to doctor for 24 hours.'
        else:
            consent.status = 'revoked'
            consent.valid_until = None
            msg = 'Doctor access request rejected / revoked.'

        consent.save(update_fields=['status', 'valid_until', 'updated_at'])

        return Response({
            'success': True,
            'message': msg,
            'consent': ConsentRequestSerializer(consent).data
        }, status=status.HTTP_200_OK)


class DoctorIncomingConsentListView(APIView):
    """
    GET /api/doctor/incoming-requests/
    Returns all patient connection and access requests sent to the active doctor.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        doc = resolve_current_doctor(request)
        if not doc:
            return Response([], status=status.HTTP_200_OK)

        consents = ConsentRequest.objects.filter(doctor=doc).order_by('-created_at')
        return Response(ConsentRequestSerializer(consents, many=True).data, status=status.HTTP_200_OK)


class DoctorIncomingConsentActionView(APIView):
    """
    POST /api/doctor/incoming-requests/<str:consent_id>/action/
    Doctor accepts or declines patient connection and record sharing request.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, consent_id):
        from datetime import timedelta
        from django.utils import timezone

        action = request.data.get('action', '').lower()
        if action not in ('accept', 'approve', 'decline', 'reject'):
            return Response({'error': 'Invalid action. Must be "accept" or "decline".'}, status=status.HTTP_400_BAD_REQUEST)

        consent = ConsentRequest.objects.filter(id=consent_id).first()
        if not consent:
            return Response({'error': 'Request not found.'}, status=status.HTTP_404_NOT_FOUND)

        if action in ('accept', 'approve'):
            consent.status = 'approved'
            consent.valid_until = timezone.now() + timedelta(hours=24)
            msg = f"Request accepted. You now have 24-hour access to {consent.patient.full_name or 'patient'}'s medical chart."
        else:
            consent.status = 'rejected'
            consent.valid_until = None
            msg = f"Request from {consent.patient.full_name or 'patient'} was declined."

        consent.save(update_fields=['status', 'valid_until', 'updated_at'])

        return Response({
            'success': True,
            'message': msg,
            'consent': ConsentRequestSerializer(consent).data
        }, status=status.HTTP_200_OK)


class DoctorDirectoryView(APIView):
    """
    GET /api/doctor/directory/
    Returns all registered doctors and clinics for patient discovery and linking.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        query = request.query_params.get('q', '').strip().lower()
        all_users = User.objects.all()
        doctors = [
            u for u in all_users
            if u.role == Role.DOCTOR or 'doctor' in (u.roles or [])
        ]
        if query:
            doctors = [
                d for d in doctors
                if query in (d.full_name or '').lower() or
                   query in (d.email or '').lower() or
                   query in (getattr(d, 'doctor_profile', None).specialty if (hasattr(d, 'doctor_profile') and hasattr(getattr(d, 'doctor_profile'), 'specialty')) else '').lower() or
                   query in (getattr(d, 'doctor_profile', None).hospital_affiliation if (hasattr(d, 'doctor_profile') and hasattr(getattr(d, 'doctor_profile'), 'hospital_affiliation')) else '').lower()
            ]

        results = []
        for d in doctors:
            profile = getattr(d, 'doctor_profile', None)
            spec = getattr(profile, 'specialty', None) or 'General Medicine'
            clinic = getattr(profile, 'hospital_affiliation', None) or getattr(profile, 'clinic_name', None) or 'Metro Health Clinic'
            license_no = getattr(profile, 'license_number', None) or 'MCI-REG'
            
            results.append({
                'id': str(d.id),
                'name': d.full_name or d.email,
                'email': d.email,
                'specialty': spec,
                'clinic': clinic,
                'subtext': f"Reg: {license_no} • {clinic}",
                'type': 'doctor',
            })
        return Response(results, status=status.HTTP_200_OK)

