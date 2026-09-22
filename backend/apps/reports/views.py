from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import MedicalRecord, LabReport
from .serializers import MedicalRecordSerializer, LabReportSerializer


from apps.accounts.models import User


def get_patient_user(request):
    if request.user and request.user.is_authenticated:
        return request.user
    email = request.query_params.get('email')
    if not email and hasattr(request, 'data') and isinstance(request.data, dict):
        email = request.data.get('patient_email')
    if email:
        u = User.objects.filter(email__iexact=email).first()
        if u:
            return u
    return User.objects.filter(email='manansoni2905@gmail.com').first() or User.objects.first()


class MedicalRecordListCreateView(APIView):
    """
    GET /api/reports/records/ — List all patient medical records and prescriptions.
    POST /api/reports/records/ — Add a new medical record.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        patient = get_patient_user(request)
        records = MedicalRecord.objects.filter(patient=patient) if patient else MedicalRecord.objects.none()
        # Optional record_type filtering
        rtype = request.query_params.get('type')
        if rtype:
            records = records.filter(record_type__iexact=rtype)
        serializer = MedicalRecordSerializer(records, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        patient = get_patient_user(request)
        serializer = MedicalRecordSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=patient)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LabReportListCreateView(APIView):
    """
    GET /api/reports/lab/ — List all diagnostic lab reports.
    POST /api/reports/lab/ — Upload or record a diagnostic lab report.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        patient = get_patient_user(request)
        reports = LabReport.objects.filter(patient=patient) if patient else LabReport.objects.none()
        category = request.query_params.get('category')
        if category and category.lower() != 'all':
            reports = reports.filter(category__iexact=category)
        serializer = LabReportSerializer(reports, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        patient = get_patient_user(request)
        serializer = LabReportSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=patient)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TimelineView(APIView):
    """
    GET /api/reports/timeline/ — Unified chronological health feed.
    Combines prescriptions, lab tests, doctor visits, and hospital notes into one seamless stream.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        patient = get_patient_user(request)
        records = MedicalRecord.objects.filter(patient=patient) if patient else MedicalRecord.objects.none()
        reports = LabReport.objects.filter(patient=patient) if patient else LabReport.objects.none()

        events = []
        for r in records:
            events.append({
                'id': str(r.id),
                'type': 'record',
                'category': r.record_type,
                'title': r.title,
                'date': str(r.record_date),
                'facility': r.facility_name or 'Clinic / Hospital',
                'doctor': r.doctor_name or 'Consulting Doctor',
                'description': r.description or '',
            })

        for rep in reports:
            events.append({
                'id': str(rep.id),
                'type': 'lab_report',
                'category': rep.category,
                'title': rep.report_name,
                'date': str(rep.report_date),
                'facility': rep.facility_name,
                'doctor': rep.doctor_name or 'Referring Doctor',
                'description': rep.summary or f"Status: {rep.status}",
            })

        # Sort descending by date
        events.sort(key=lambda x: x['date'], reverse=True)

        return Response({
            'success': True,
            'total_events': len(events),
            'timeline': events,
        }, status=status.HTTP_200_OK)


class GlobalSearchView(APIView):
    """
    GET /api/search/?q=<query>
    Instant global search across prescriptions, lab reports, test parameters, and doctors.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        from django.db.models import Q
        from apps.accounts.models import User, Role
        from .models import TestParameter

        q = request.query_params.get('q', '').strip()
        if not q or len(q) < 2:
            return Response({
                'query': q,
                'total_results': 0,
                'prescriptions': [],
                'lab_reports': [],
                'doctors': [],
            }, status=status.HTTP_200_OK)

        records_qs = MedicalRecord.objects.filter(
            Q(title__icontains=q) |
            Q(description__icontains=q) |
            Q(doctor_name__icontains=q) |
            Q(facility_name__icontains=q)
        )
        if request.user and request.user.is_authenticated:
            user_roles = getattr(request.user, 'roles', []) or []
            if getattr(request.user, 'role', None) == Role.PATIENT or 'patient' in user_roles:
                records_qs = records_qs.filter(patient=request.user)

        prescriptions = []
        for r in records_qs[:10]:
            prescriptions.append({
                'id': str(r.record_id),
                'title': r.title,
                'record_type': r.record_type,
                'date': str(r.record_date),
                'doctor_name': r.doctor_name or '',
                'facility_name': r.facility_name or '',
                'snippet': (r.description[:120] + '...') if r.description and len(r.description) > 120 else (r.description or ''),
            })

        reports_qs = LabReport.objects.filter(
            Q(report_name__icontains=q) |
            Q(category__icontains=q) |
            Q(facility_name__icontains=q) |
            Q(summary__icontains=q) |
            Q(parameters__parameter_name__icontains=q)
        ).distinct()

        if request.user and request.user.is_authenticated:
            user_roles = getattr(request.user, 'roles', []) or []
            if getattr(request.user, 'role', None) == Role.PATIENT or 'patient' in user_roles:
                reports_qs = reports_qs.filter(patient=request.user)

        lab_reports = []
        for rep in reports_qs[:10]:
            matched_params = [p.parameter_name for p in rep.parameters.filter(parameter_name__icontains=q)[:3]]
            lab_reports.append({
                'id': str(rep.report_id),
                'report_name': rep.report_name,
                'category': rep.category,
                'date': str(rep.report_date),
                'facility_name': rep.facility_name,
                'status': rep.status,
                'matched_parameters': matched_params,
                'summary': rep.summary or '',
            })

        matched_users = User.objects.filter(
            Q(full_name__icontains=q) | Q(email__icontains=q)
        )
        doctor_users = [
            u for u in matched_users
            if u.role == Role.DOCTOR or 'doctor' in (u.roles or [])
        ][:5]

        doctors = []
        for d in doctor_users:
            spec = getattr(d, 'doctor_profile', None).specialization if hasattr(d, 'doctor_profile') else 'General Medicine'
            clinic = getattr(d, 'doctor_profile', None).clinic_name if hasattr(d, 'doctor_profile') else 'Clinic'
            doctors.append({
                'id': str(d.id),
                'name': d.full_name or d.email,
                'specialization': spec,
                'clinic': clinic,
                'email': d.email,
            })

        total = len(prescriptions) + len(lab_reports) + len(doctors)

        return Response({
            'query': q,
            'total_results': total,
            'prescriptions': prescriptions,
            'lab_reports': lab_reports,
            'doctors': doctors,
        }, status=status.HTTP_200_OK)

