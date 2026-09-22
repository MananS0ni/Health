from rest_framework import serializers
from .models import InpatientAdmission


class InpatientAdmissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = InpatientAdmission
        fields = [
            'id',
            'admission_id',
            'patient',
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
