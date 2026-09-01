from rest_framework import serializers
from .models import CustomUser

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'phone', 'abha_id', 'full_name', 'role', 'is_verified', 'created_at']

class RequestOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

class VerifyOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    otp = serializers.CharField(max_length=6)

class LinkABHASerializer(serializers.Serializer):
    abha_id = serializers.CharField(max_length=100)
