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
    date_of_birth = serializers.CharField(required=False, allow_blank=True, default='')
    gender = serializers.CharField(required=False, allow_blank=True, default='')
    blood_group = serializers.CharField(required=False, allow_blank=True, default='')
    allergies = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    medical_conditions = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    current_medications = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    emergency_contact_name = serializers.CharField(required=False, allow_blank=True, default='')
    emergency_contact_phone = serializers.CharField(required=False, allow_blank=True, default='')
    doctor_profile = serializers.DictField(required=False, allow_null=True)
    org_profile = serializers.DictField(required=False, allow_null=True)
    lab_profile = serializers.DictField(required=False, allow_null=True)
    hospital_profile = serializers.DictField(required=False, allow_null=True)

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
    patient_id = serializers.SerializerMethodField()
    blood_group = serializers.SerializerMethodField()
    gender = serializers.SerializerMethodField()
    date_of_birth = serializers.SerializerMethodField()
    allergies = serializers.SerializerMethodField()
    medical_conditions = serializers.SerializerMethodField()
    current_medications = serializers.SerializerMethodField()
    emergency_contact_name = serializers.SerializerMethodField()
    emergency_contact_phone = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'patient_id',
            'email',
            'full_name',
            'phone_number',
            'role',
            'roles',
            'is_verified',
            'blood_group',
            'gender',
            'date_of_birth',
            'allergies',
            'medical_conditions',
            'current_medications',
            'emergency_contact_name',
            'emergency_contact_phone',
            'doctor_profile',
            'lab_profile',
            'hospital_profile',
            'created_at',
        ]
        read_only_fields = ['id', 'patient_id', 'email', 'is_verified', 'created_at']

    def get_blood_group(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.blood_group if prof and prof.blood_group else ''

    def get_gender(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.gender if prof and prof.gender else ''

    def get_date_of_birth(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.date_of_birth if prof and prof.date_of_birth else ''

    def get_allergies(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.allergies if prof and prof.allergies else []

    def get_medical_conditions(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.medical_conditions if prof and prof.medical_conditions else []

    def get_current_medications(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.current_medications if prof and prof.current_medications else []

    def get_emergency_contact_name(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.emergency_contact_name if prof and prof.emergency_contact_name else ''

    def get_emergency_contact_phone(self, obj):
        prof = getattr(obj, 'patient_profile', None)
        return prof.emergency_contact_phone if prof and prof.emergency_contact_phone else ''

    def get_patient_id(self, obj):
        return f"PAT-{str(obj.id)[:6].upper()}"

    def get_roles(self, obj):
        roles = list(obj.roles or [])
        if obj.role and obj.role not in roles:
            roles.append(obj.role)
        if 'lab' in roles and 'lab_staff' not in roles:
            roles.append('lab_staff')
        if 'lab_staff' in roles and 'lab' not in roles:
            roles.append('lab')
        if 'hospital' in roles and 'hospital_staff' not in roles:
            roles.append('hospital_staff')
        if 'hospital_staff' in roles and 'hospital' not in roles:
            roles.append('hospital')
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
