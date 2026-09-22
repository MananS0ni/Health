from rest_framework import serializers
from .models import MedicalRecord, LabReport, TestParameter


class TestParameterSerializer(serializers.ModelSerializer):
    class Meta:
        model = TestParameter
        fields = ['id', 'parameter_name', 'value', 'unit', 'reference_range', 'is_abnormal']


class LabReportSerializer(serializers.ModelSerializer):
    parameters = TestParameterSerializer(many=True, required=False)

    class Meta:
        model = LabReport
        fields = [
            'id',
            'report_id',
            'report_name',
            'category',
            'report_date',
            'facility_name',
            'doctor_name',
            'status',
            'summary',
            'file_url',
            'parameters',
            'created_at',
        ]
        read_only_fields = ['id', 'report_id', 'created_at']

    def create(self, validated_data):
        parameters_data = validated_data.pop('parameters', [])
        report = LabReport.objects.create(**validated_data)
        for param in parameters_data:
            TestParameter.objects.create(report=report, **param)
        return report


class MedicalRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicalRecord
        fields = [
            'id',
            'record_id',
            'title',
            'record_type',
            'record_date',
            'facility_name',
            'doctor_name',
            'description',
            'file_url',
            'created_at',
        ]
        read_only_fields = ['id', 'record_id', 'created_at']
