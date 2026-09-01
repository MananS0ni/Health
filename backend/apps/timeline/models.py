from django.db import models
from django.conf import settings

class TimelineEvent(models.Model):
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='timeline_events')
    title = models.CharField(max_length=255)
    provider = models.CharField(max_length=200)
    event_type = models.CharField(max_length=100, default='Diagnostic Test')
    event_date = models.CharField(max_length=50)
    event_time = models.CharField(max_length=50)
    status = models.CharField(max_length=100, default='Report Issued & Auto-Imported')
    details = models.TextField()

    def __str__(self):
        return f"{self.event_date} - {self.title} ({self.provider})"
