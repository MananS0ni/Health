from rest_framework import serializers
from .models import LabReport

class LabReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabReport
        fields = '__all__'
