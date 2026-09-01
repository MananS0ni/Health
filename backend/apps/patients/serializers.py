from rest_framework import serializers
from .models import PatientProfile
from apps.accounts.serializers import UserSerializer

class PatientProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = PatientProfile
        fields = [
            'id', 'user', 'blood_group', 'known_allergies',
            'chronic_conditions', 'emergency_contact_name',
            'emergency_contact_phone', 'emergency_contact_relation'
        ]
