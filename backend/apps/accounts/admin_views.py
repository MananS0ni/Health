from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.db.models import Q

from .models import User, Role
from apps.reports.models import MedicalRecord, LabReport
from apps.hospital.models import InpatientAdmission
from apps.lab.models import LabTestOrder


class AdminPortalOverviewView(APIView):
    """
    GET /api/admin-portal/overview/
    Returns high-level system metrics and health parameters for the Admin Portal.
    """
    permission_classes = [permissions.AllowAny]  # For local/demo administration

    def get(self, request):
        total_patients = User.objects.filter(role=Role.PATIENT).count()
        total_doctors = User.objects.filter(role=Role.DOCTOR).count()
        total_labs = User.objects.filter(role=Role.LAB).count()
        total_hospitals = User.objects.filter(role=Role.HOSPITAL).count()
        total_admins = User.objects.filter(role=Role.ADMIN).count()

        total_records = MedicalRecord.objects.count()
        total_lab_reports = LabReport.objects.count()
        total_orders = LabTestOrder.objects.count()

        active_admissions = InpatientAdmission.objects.filter(status='Admitted').count()
        total_admissions = InpatientAdmission.objects.count()
        pending_verifications = User.objects.filter(is_verified=False).exclude(role=Role.PATIENT).count()

        # Recent system activity
        recent_records = MedicalRecord.objects.select_related('patient').order_by('-created_at')[:8]
        activity_stream = []
        for r in recent_records:
            pid = f"PAT-{str(r.patient.id)[:6].upper()}" if r.patient else "PAT-UNKNOWN"
            activity_stream.append({
                'title': r.title,
                'type': r.record_type,
                'patient_name': r.patient.full_name or r.patient.email if r.patient else 'Unknown',
                'patient_id': pid,
                'facility': r.facility_name or 'Healthcare Center',
                'date': r.record_date.strftime('%Y-%m-%d') if r.record_date else '',
            })

        return Response({
            'success': True,
            'stats': {
                'total_patients': total_patients,
                'total_doctors': total_doctors,
                'total_labs': total_labs,
                'total_hospitals': total_hospitals,
                'total_admins': total_admins,
                'total_records': total_records,
                'total_lab_reports': total_lab_reports,
                'total_orders': total_orders,
                'active_admissions': active_admissions,
                'total_admissions': total_admissions,
                'pending_verifications': pending_verifications,
            },
            'engine_status': {
                'backend': 'ONLINE',
                'database': 'POSTGRESQL_READY',
                'ingestion_pipeline': 'OPERATIONAL',
                'consent_engine': 'ACTIVE',
            },
            'recent_activity': activity_stream,
        }, status=status.HTTP_200_OK)


class AdminPortalUsersView(APIView):
    """
    GET /api/admin-portal/users/?role=&q=
    Returns all registered platform users with search and role filtering.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        role_filter = request.query_params.get('role', '').strip().lower()
        q = request.query_params.get('q', '').strip()

        qs = User.objects.all().order_by('-created_at')

        if role_filter and role_filter != 'all':
            qs = qs.filter(role__iexact=role_filter)

        if q:
            qs = qs.filter(
                Q(full_name__icontains=q) |
                Q(email__icontains=q) |
                Q(phone_number__icontains=q)
            )

        results = []
        for u in qs[:100]:
            pid = f"PAT-{str(u.id)[:6].upper()}"
            results.append({
                'id': str(u.id),
                'patient_id': pid,
                'full_name': u.full_name or 'Unnamed User',
                'email': u.email,
                'phone_number': u.phone_number or '',
                'role': u.role,
                'is_verified': u.is_verified,
                'created_at': u.created_at.strftime('%Y-%m-%d %H:%M') if u.created_at else '',
            })

        return Response({
            'success': True,
            'count': len(results),
            'users': results,
        }, status=status.HTTP_200_OK)


class AdminPortalToggleVerifyView(APIView):
    """
    POST /api/admin-portal/users/<str:user_id>/toggle-verify/
    Toggles the is_verified credential status of any healthcare user or facility.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, user_id):
        user = User.objects.filter(id=user_id).first()
        if not user:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        user.is_verified = not user.is_verified
        user.save(update_fields=['is_verified'])

        return Response({
            'success': True,
            'user_id': str(user.id),
            'is_verified': user.is_verified,
            'message': f"Provider {user.full_name or user.email} verification updated to {user.is_verified}.",
        }, status=status.HTTP_200_OK)
