from rest_framework import serializers
from .models import User, Role, DoctorProfile, LabProfile, HospitalProfile


class RequestOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        return value.lower().strip()


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(min_length=6, max_length=6)
    full_name = serializers.CharField(required=False, allow_blank=True, default='')
    phone_number = serializers.CharField(required=False, allow_blank=True, default='')
    roles = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    role = serializers.CharField(required=False, allow_blank=True, default='patient')
    doctor_profile = serializers.DictField(required=False, allow_null=True)
    org_profile = serializers.DictField(required=False, allow_null=True)

    def validate_email(self, value):
        return value.lower().strip()

    def validate_otp(self, value):
        return value.strip()


class DoctorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorProfile
        fields = ['registration_number', 'specialization', 'clinic_name']


class LabProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabProfile
        fields = ['lab_name', 'license_number', 'address']


class HospitalProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = HospitalProfile
        fields = ['hospital_name', 'registration_id', 'departments']


class UserSerializer(serializers.ModelSerializer):
    doctor_profile = DoctorProfileSerializer(read_only=True)
    lab_profile = LabProfileSerializer(read_only=True)
    hospital_profile = HospitalProfileSerializer(read_only=True)
    roles = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'full_name',
            'phone_number',
            'role',
            'roles',
            'is_verified',
            'doctor_profile',
            'lab_profile',
            'hospital_profile',
            'created_at',
        ]
        read_only_fields = ['id', 'email', 'is_verified', 'created_at']

    def get_roles(self, obj):
        roles = list(obj.roles or [])
        if obj.role and obj.role not in roles:
            roles.append(obj.role)
        if 'patient' not in roles:
            roles.insert(0, 'patient')
        return roles


class RegisterProfileSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=Role.choices, default=Role.PATIENT)

    # Doctor specific fields
    specialization = serializers.CharField(max_length=150, required=False, allow_blank=True)
    registration_number = serializers.CharField(max_length=100, required=False, allow_blank=True)
    clinic_name = serializers.CharField(max_length=200, required=False, allow_blank=True)

    # Lab specific fields
    lab_name = serializers.CharField(max_length=200, required=False, allow_blank=True)
    lab_license = serializers.CharField(max_length=100, required=False, allow_blank=True)
    lab_address = serializers.CharField(required=False, allow_blank=True)

    # Hospital specific fields
    hospital_name = serializers.CharField(max_length=200, required=False, allow_blank=True)
    hospital_reg_id = serializers.CharField(max_length=100, required=False, allow_blank=True)
    departments = serializers.CharField(required=False, allow_blank=True)
