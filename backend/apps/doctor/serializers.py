from rest_framework import serializers
from .models import Appointment, Prescription, PrescriptionItem, ConsentRequest
from apps.accounts.models import User
from apps.patients.models import PatientProfile


class PrescriptionItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrescriptionItem
        fields = ['id', 'medicine_name', 'dosage', 'duration', 'instructions']


class PrescriptionSerializer(serializers.ModelSerializer):
    medicines = PrescriptionItemSerializer(many=True, required=False)
    doctor_name = serializers.CharField(source='doctor.full_name', read_only=True)
    patient_email = serializers.CharField(source='patient.email', read_only=True)

    class Meta:
        model = Prescription
        fields = [
            'id',
            'patient',
            'patient_email',
            'doctor_name',
            'diagnosis',
            'clinical_notes',
            'prescribed_date',
            'medicines',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        medicines_data = validated_data.pop('medicines', [])
        prescription = Prescription.objects.create(**validated_data)
        for med in medicines_data:
            PrescriptionItem.objects.create(prescription=prescription, **med)
        return prescription


class AppointmentSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='doctor.full_name', read_only=True)
    specialization = serializers.SerializerMethodField()
    clinic_name = serializers.SerializerMethodField()
    patient_id = serializers.SerializerMethodField()
    patient_email = serializers.CharField(source='patient.email', read_only=True)
    time = serializers.CharField(source='time_slot', read_only=True)
    appointment_time = serializers.CharField(source='time_slot', read_only=True)
    doctor = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Appointment
        fields = [
            'id',
            'doctor',
            'doctor_name',
            'specialization',
            'clinic_name',
            'patient',
            'patient_id',
            'patient_name',
            'patient_email',
            'appointment_date',
            'time_slot',
            'time',
            'appointment_time',
            'consultation_type',
            'status',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']

    def get_specialization(self, obj):
        profile = getattr(obj.doctor, 'doctor_profile', None)
        return profile.specialization if profile and profile.specialization else 'Specialist Consultation'

    def get_clinic_name(self, obj):
        profile = getattr(obj.doctor, 'doctor_profile', None)
        return profile.clinic_name if profile and profile.clinic_name else 'Medical Center'

    def get_patient_id(self, obj):
        return f"PAT-{str(obj.patient.id)[:6].upper()}"


class ConsentRequestSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='doctor.full_name', read_only=True)
    doctor_email = serializers.CharField(source='doctor.email', read_only=True)
    patient_name = serializers.CharField(source='patient.full_name', read_only=True)
    patient_email = serializers.CharField(source='patient.email', read_only=True)
    patient_phone = serializers.CharField(source='patient.phone_number', read_only=True)
    patient_code = serializers.SerializerMethodField()
    is_active = serializers.BooleanField(read_only=True)

    def get_patient_code(self, obj):
        if obj.patient:
            return f"PAT-{str(obj.patient.id)[:6].upper()}"
        return "PAT-UNKNOWN"

    class Meta:
        model = ConsentRequest
        fields = [
            'id',
            'doctor',
            'doctor_name',
            'doctor_email',
            'patient',
            'patient_name',
            'patient_email',
            'patient_phone',
            'patient_code',
            'purpose',
            'status',
            'valid_until',
            'is_active',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at', 'valid_until']

