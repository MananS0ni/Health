import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone

User = settings.AUTH_USER_MODEL


class MedicalRecord(models.Model):
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='medical_records')
    record_id = models.CharField(max_length=64, unique=True, default=uuid.uuid4)
    title = models.CharField(max_length=200)
    record_type = models.CharField(max_length=50)  # Prescription, Discharge Summary, Doctor Note, Lab Report
    record_date = models.DateField(default=timezone.localdate)
    facility_name = models.CharField(max_length=200, blank=True, null=True)
    doctor_name = models.CharField(max_length=150, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    file_url = models.FileField(upload_to='records/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-record_date', '-created_at']

    def __str__(self):
        return f"{self.title} ({self.record_type}) - {self.patient.email}"


class LabReport(models.Model):
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='lab_reports')
    report_id = models.CharField(max_length=64, unique=True, default=uuid.uuid4)
    report_name = models.CharField(max_length=200)
    category = models.CharField(max_length=100, default='Biochemistry')
    report_date = models.DateField(default=timezone.localdate)
    facility_name = models.CharField(max_length=200, default='Diagnostic Lab')
    doctor_name = models.CharField(max_length=150, blank=True, null=True)
    status = models.CharField(max_length=50, default='Normal')  # Normal, Abnormal, Critical, Pending
    summary = models.TextField(blank=True, null=True)
    file_url = models.FileField(upload_to='reports/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-report_date', '-created_at']

    def __str__(self):
        return f"{self.report_name} - {self.patient.email}"


class TestParameter(models.Model):
    report = models.ForeignKey(LabReport, on_delete=models.CASCADE, related_name='parameters')
    parameter_name = models.CharField(max_length=100)
    value = models.CharField(max_length=50)
    unit = models.CharField(max_length=50, blank=True, null=True)
    reference_range = models.CharField(max_length=100, blank=True, null=True)
    is_abnormal = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.parameter_name}: {self.value} {self.unit or ''}"
