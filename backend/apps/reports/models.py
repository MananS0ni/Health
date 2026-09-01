from django.db import models
from django.conf import settings

class LabReport(models.Model):
    report_id = models.CharField(max_length=50, unique=True)
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reports')
    title = models.CharField(max_length=255)
    report_type = models.CharField(max_length=100, default='Blood Test')
    category = models.CharField(max_length=100, default='Blood Tests')
    provider = models.CharField(max_length=200, default='Dr. Lal PathLabs')
    facility_type = models.CharField(max_length=100, default='Diagnostic Lab')
    date = models.DateField(auto_now_add=True)
    doctor_name = models.CharField(max_length=150, default='Dr. A. K. Sharma')
    status = models.CharField(max_length=50, default='Verified & Synced')
    source = models.CharField(max_length=150, default='Auto-Pulled via LIS API')
    summary = models.TextField()
    ai_explanation = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.report_id} - {self.title} ({self.provider})"
