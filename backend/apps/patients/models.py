from django.db import models
from django.conf import settings

class PatientProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='patient_profile')
    blood_group = models.CharField(max_length=10, default='O +ve')
    known_allergies = models.TextField(default='Penicillin, Sulfa Antibiotics')
    chronic_conditions = models.TextField(default='Mild Asthma')
    emergency_contact_name = models.CharField(max_length=150, default='Pooja Soni')
    emergency_contact_phone = models.CharField(max_length=20, default='+91 98765 43210')
    emergency_contact_relation = models.CharField(max_length=50, default='Kin / Spouse')

    def __str__(self):
        return f"Patient Profile - {self.user.full_name}"
