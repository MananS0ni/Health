from django.utils import timezone
from rest_framework import serializers
from .models import PatientProfile, HealthVital, FamilyMember


class PatientProfileSerializer(serializers.ModelSerializer):
    allergies = serializers.ListField(child=serializers.CharField(max_length=200), max_length=100, required=False)
    medical_conditions = serializers.ListField(child=serializers.CharField(max_length=200), max_length=100, required=False)
    current_medications = serializers.ListField(child=serializers.CharField(max_length=300), max_length=100, required=False)
    def validate_date_of_birth(self, value):
        if not value: return value
        parsed = serializers.DateField().run_validation(value)
        if parsed > timezone.localdate():
            raise serializers.ValidationError('Date of birth cannot be in the future.')
        return parsed

    email = serializers.EmailField(source='user.email', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)

    class Meta:
        model = PatientProfile
        fields = [
            'id',
            'email',
            'full_name',
            'phone_number',
            'blood_group',
            'gender',
            'date_of_birth',
            'address',
            'allergies',
            'medical_conditions',
            'current_medications',
            'emergency_contact_name',
            'emergency_contact_phone',
            'emergency_contact_relation',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class HealthVitalSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthVital
        fields = ['id', 'vital_type', 'value', 'unit', 'status', 'recorded_at']
        read_only_fields = ['id', 'recorded_at']


class FamilyMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = FamilyMember
        fields = [
            'id',
            'member_id',
            'full_name',
            'relationship',
            'date_of_birth',
            'gender',
            'blood_group',
            'total_records',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']
