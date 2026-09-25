from rest_framework import serializers
from .models import InpatientAdmission


class InpatientAdmissionSerializer(serializers.ModelSerializer):
    patient_id = serializers.SerializerMethodField()
    patient_email = serializers.SerializerMethodField()

    class Meta:
        model = InpatientAdmission
        fields = [
            'id',
            'admission_id',
            'patient',
            'patient_id',
            'patient_email',
            'patient_name',
            'age',
            'gender',
            'ward',
            'bed_no',
            'attending_doctor',
            'diagnosis',
            'status',
            'admission_date',
            'discharge_date',
            'discharge_notes',
            'created_at',
        ]
        read_only_fields = ['id', 'admission_id', 'created_at']

    def get_patient_id(self, obj):
        if obj.patient:
            return f"PAT-{str(obj.patient.id)[:6].upper()}"
        return 'PAT-UNLINKED'

    def get_patient_email(self, obj):
        return obj.patient.email if obj.patient else ''
