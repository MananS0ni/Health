import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone

User = settings.AUTH_USER_MODEL


class Appointment(models.Model):
    doctor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='doctor_appointments')
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='patient_appointments')
    patient_name = models.CharField(max_length=150, blank=True, null=True)
    appointment_date = models.DateField(default=timezone.localdate)
    time_slot = models.CharField(max_length=50, default='10:00 AM')
    consultation_type = models.CharField(max_length=50, default='OPD Consultation')
    status = models.CharField(max_length=50, default='Confirmed')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['appointment_date', 'time_slot']

    def __str__(self):
        return f"{self.patient_name or self.patient.email} with Dr. {self.doctor.full_name} on {self.appointment_date}"


class Prescription(models.Model):
    doctor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='issued_prescriptions')
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prescriptions')
    diagnosis = models.CharField(max_length=255)
    clinical_notes = models.TextField(blank=True, null=True)
    prescribed_date = models.DateField(default=timezone.localdate)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-prescribed_date', '-created_at']

    def __str__(self):
        return f"{self.diagnosis} for {self.patient.email} by Dr. {self.doctor.full_name}"


class PrescriptionItem(models.Model):
    prescription = models.ForeignKey(Prescription, on_delete=models.CASCADE, related_name='medicines')
    medicine_name = models.CharField(max_length=150)
    dosage = models.CharField(max_length=50, default='1-0-1')
    duration = models.CharField(max_length=50, default='14 Days')
    instructions = models.CharField(max_length=200, blank=True, null=True)

    def __str__(self):
        return f"{self.medicine_name} ({self.dosage}) - {self.duration}"


class ConsentRequest(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    doctor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='doctor_consent_requests')
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='patient_consent_requests')
    purpose = models.CharField(max_length=200, default='Clinical Consultation & Medical History Review')
    status = models.CharField(max_length=20, default='pending')  # 'pending', 'approved', 'rejected', 'revoked'
    valid_until = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def is_active(self):
        if self.status != 'approved':
            return False
        if self.valid_until and timezone.now() > self.valid_until:
            return False
        return True

    def __str__(self):
        return f"Consent from {self.patient.email} to Dr. {self.doctor.full_name or self.doctor.email} ({self.status})"

