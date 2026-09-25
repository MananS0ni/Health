import uuid
from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL


class PatientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='patient_profile')
    blood_group = models.CharField(max_length=10, blank=True, null=True)
    gender = models.CharField(max_length=20, blank=True, null=True)
    date_of_birth = models.CharField(max_length=50, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    
    # Emergency medical info
    allergies = models.JSONField(default=list, blank=True)
    medical_conditions = models.JSONField(default=list, blank=True)
    current_medications = models.JSONField(default=list, blank=True)
    emergency_contact_name = models.CharField(max_length=150, blank=True, null=True)
    emergency_contact_phone = models.CharField(max_length=30, blank=True, null=True)
    emergency_contact_relation = models.CharField(max_length=50, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"PatientProfile: {self.user.email}"


class HealthVital(models.Model):
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vitals')
    vital_type = models.CharField(max_length=50)  # 'blood_pressure', 'heart_rate', 'blood_sugar', 'bmi', 'spo2'
    value = models.CharField(max_length=50)
    unit = models.CharField(max_length=20, blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)  # 'Normal', 'Elevated', etc.
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-recorded_at']

    def __str__(self):
        return f"{self.vital_type}: {self.value} ({self.patient.email})"


class FamilyMember(models.Model):
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='family_members')
    member_id = models.CharField(max_length=64, unique=True, default=uuid.uuid4)
    full_name = models.CharField(max_length=150)
    relationship = models.CharField(max_length=50)
    date_of_birth = models.CharField(max_length=50, blank=True, null=True)
    gender = models.CharField(max_length=20, blank=True, null=True)
    blood_group = models.CharField(max_length=10, blank=True, null=True)
    total_records = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.full_name} ({self.relationship}) - {self.patient.email}"
