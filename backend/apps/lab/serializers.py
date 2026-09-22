from rest_framework import serializers
from .models import LabTestOrder


class LabTestOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabTestOrder
        fields = [
            'id',
            'order_id',
            'patient',
            'patient_name',
            'doctor_name',
            'test_name',
            'category',
            'order_date',
            'status',
            'created_at',
        ]
        read_only_fields = ['id', 'order_id', 'created_at']
