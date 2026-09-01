from django.db import models
from django.conf import settings

class ConsentPermission(models.Model):
    STATUS_CHOICES = (
        ('ACTIVE', 'Active Access Allowed'),
        ('REVOKED', 'Access Revoked by Patient'),
        ('EXPIRED', 'Access Expired'),
    )

    consent_id = models.CharField(max_length=50, unique=True)
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='consents')
    doctor_name = models.CharField(max_length=150)
    specialty = models.CharField(max_length=100, default='Cardiologist')
    hospital_name = models.CharField(max_length=200, default='Max Healthcare Hospital')
    purpose = models.CharField(max_length=200, default='Follow-up Heart Review')
    scope = models.CharField(max_length=200, default='All Heart & ECG Reports')
    expires_in = models.CharField(max_length=100, default='Valid for 23 hours')
    granted_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')

    def __str__(self):
        return f"{self.consent_id} - {self.doctor_name} ({self.status})"
