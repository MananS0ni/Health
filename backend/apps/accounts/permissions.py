"""Server-owned authorization. Client role context never grants privileges."""
import uuid
from django.db.models import Q
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.permissions import BasePermission
from .models import User

ALIASES = {'lab_staff': 'lab', 'hospital_staff': 'hospital'}
PROFESSIONAL_ROLES = {'doctor', 'lab', 'hospital'}

def roles_for(user):
    return {ALIASES.get(r, r) for r in [user.role, *(user.roles or [])]}

class IsPlatformAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user.is_authenticated and request.user.is_active and request.user.is_superuser)

class VerifiedProfessional(BasePermission):
    role = None
    def has_permission(self, request, view):
        u = request.user
        return bool(u.is_authenticated and u.is_active and u.professional_verified
                    and (self.role in roles_for(u) if self.role else roles_for(u) & PROFESSIONAL_ROLES))

class IsDoctor(VerifiedProfessional):
    role = 'doctor'

class IsLab(VerifiedProfessional):
    role = 'lab'

class IsHospital(VerifiedProfessional):
    role = 'hospital'

def resolve_patient(value):
    """Exact IDs/email only. Legacy six-character display codes must be unique."""
    value = str(value or '').strip()
    if not value:
        raise ValidationError({'patient': 'An exact patient ID or email is required.'})
    qs = User.objects.filter(is_active=True)
    if '@' in value:
        matches = list(qs.filter(email__iexact=value)[:2])
    else:
        identifier = value[4:] if value.upper().startswith('PAT-') else value
        try:
            matches = list(qs.filter(id=uuid.UUID(identifier)))
        except ValueError:
            if len(identifier) != 6 or any(c not in '0123456789abcdefABCDEF' for c in identifier):
                raise ValidationError({'patient': 'Invalid patient ID.'})
            matches = list(qs.filter(id__startswith=identifier.lower())[:2])
    if len(matches) != 1:
        raise ValidationError({'patient': 'Patient not found or identifier is ambiguous. Use full ID or email.'})
    return matches[0]

def can_access_patient(actor, patient):
    if actor.pk == patient.pk:
        return True
    if not actor.professional_verified or not roles_for(actor) & PROFESSIONAL_ROLES:
        return False
    from apps.doctor.models import ConsentRequest
    return ConsentRequest.objects.filter(doctor=actor, patient=patient, status='approved', valid_until__gt=timezone.now()).exists()

def require_patient_access(actor, patient):
    if not can_access_patient(actor, patient):
        raise PermissionDenied('Active patient consent is required.')

def scoped_patients(actor):
    from apps.doctor.models import ConsentRequest
    ids = [actor.pk]
    if actor.professional_verified and roles_for(actor) & PROFESSIONAL_ROLES:
        ids += list(ConsentRequest.objects.filter(doctor=actor, status='approved', valid_until__gt=timezone.now()).values_list('patient_id', flat=True))
    return ids
