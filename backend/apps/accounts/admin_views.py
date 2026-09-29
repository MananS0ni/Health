from django.db import connection
from .permissions import IsPlatformAdmin, PROFESSIONAL_ROLES
from django.shortcuts import get_object_or_404
from django.db import transaction
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
    permission_classes = [IsPlatformAdmin]  # For local/demo administration

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
        pending_verifications = User.objects.filter(professional_verified=False).exclude(pending_roles=[]).count()

        # Recent system activity
        recent_records = MedicalRecord.objects.select_related('patient').order_by('-created_at')[:8]
        activity_stream = []
        for r in recent_records:
            pid = f"PAT-{str(r.patient.id).upper()}" if r.patient else "PAT-UNKNOWN"
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
                'database': connection.vendor.upper(),
                'ingestion_pipeline': 'MANUAL_UPLOAD_ONLY',
                'consent_engine': 'ACTIVE',
            },
            'recent_activity': activity_stream,
        }, status=status.HTTP_200_OK)


class AdminPortalUsersView(APIView):
    """
    GET /api/admin-portal/users/?role=&q=
    Returns all registered platform users with search and role filtering.
    """
    permission_classes = [IsPlatformAdmin]

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
                'is_verified': u.professional_verified,
                'email_verified': u.is_verified,
                'pending_roles': u.pending_roles,
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
    permission_classes = [IsPlatformAdmin]

    def post(self, request, user_id):
        if not isinstance(request.data.get('verified'), bool):
            return Response({'error': 'Supply verified: true or false and a review reason.'}, status=400)
        reason = str(request.data.get('reason', '')).strip()
        if not reason:
            return Response({'error': 'Review reason is required.'}, status=400)
        with transaction.atomic():
            user = get_object_or_404(User.objects.select_for_update(), pk=user_id)
            if not request.data['verified']:
                user.professional_verified = False
            else:
                user.professional_verified = True
            if user.professional_verified:
                approved = set(user.pending_roles or []) & PROFESSIONAL_ROLES
                if not approved:
                    approved = ({user.role} | set(user.roles or [])) & PROFESSIONAL_ROLES
                if not approved:
                    return Response({'error': 'No professional role to approve.'}, status=400)
                required = {'doctor':('registration_number','specialization'),'lab':('license_number',),'hospital':('registration_id',)}
                for role in approved:
                    profile = getattr(user, {'doctor':'doctor_profile','lab':'lab_profile','hospital':'hospital_profile'}[role], None)
                    if profile is None or any(not str(getattr(profile, field, '') or '').strip() for field in required[role]):
                        return Response({'error': f'Complete the required {role} credentials before approval.'}, status=400)
                user.roles = sorted({'patient'} | approved)
                user.role = sorted(approved)[0]
                user.pending_roles = []
            user.save()
            from django.contrib.admin.models import LogEntry, CHANGE
            from django.contrib.contenttypes.models import ContentType
            LogEntry.objects.log_actions(user_id=request.user.pk, queryset=User.objects.filter(pk=user.pk), action_flag=CHANGE, change_message='Credential review: '+reason)
        return Response({'success': True, 'user_id': str(user.pk), 'is_verified': user.professional_verified, 'message': 'Credential review saved.'})
