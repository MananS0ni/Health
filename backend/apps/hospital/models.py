import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone

User = settings.AUTH_USER_MODEL


class InpatientAdmission(models.Model):
    hospital = models.ForeignKey(User, on_delete=models.CASCADE, related_name='hospital_admissions')
    admission_id = models.CharField(max_length=64, unique=True, default=uuid.uuid4)
    patient = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='hospital_stays')
    patient_name = models.CharField(max_length=150)
    age = models.IntegerField(default=35)
    gender = models.CharField(max_length=20, default='Male')
    ward = models.CharField(max_length=100, default='General Male Ward')
    bed_no = models.CharField(max_length=50)
    attending_doctor = models.CharField(max_length=150, default='Consulting Physician')
    diagnosis = models.CharField(max_length=255)
    status = models.CharField(max_length=50, default='Admitted')  # Admitted, Critical Care, Discharged
    admission_date = models.DateField(default=timezone.localdate)
    discharge_date = models.DateField(null=True, blank=True)
    discharge_notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-admission_date', '-created_at']

    def __str__(self):
        return f"{self.patient_name} in {self.ward} (Bed: {self.bed_no})"
