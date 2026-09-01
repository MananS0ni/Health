from rest_framework import serializers
from .models import ConsentPermission

class ConsentPermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ConsentPermission
        fields = '__all__'
