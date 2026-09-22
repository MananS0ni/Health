import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone

User = settings.AUTH_USER_MODEL


class LabTestOrder(models.Model):
    lab = models.ForeignKey(User, on_delete=models.CASCADE, related_name='lab_orders')
    order_id = models.CharField(max_length=64, unique=True, default=uuid.uuid4)
    patient = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='ordered_tests')
    patient_name = models.CharField(max_length=150)
    doctor_name = models.CharField(max_length=150, blank=True, null=True)
    test_name = models.CharField(max_length=200)
    category = models.CharField(max_length=100, default='Biochemistry')
    order_date = models.DateField(default=timezone.localdate)
    status = models.CharField(max_length=50, default='Pending')  # Pending, Sample Collected, Completed
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.test_name} for {self.patient_name} [{self.status}]"
