from django.utils import timezone
from rest_framework import serializers
from .models import Service, Slot, Campaign, Booking, Notification, Review

class ServiceSerializer(serializers.ModelSerializer):
    provider_name = serializers.CharField(source='provider.full_name', read_only=True)
    class Meta:
        model = Service
        fields = ['id','provider','provider_name','name','kind','specialty','location','description','price','active']
        read_only_fields = ['provider']
    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError('Price cannot be negative.')
        return value

class SlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Slot
        fields = ['id','service','starts_at','capacity','reserved']
        read_only_fields = ['reserved']
    def validate(self, data):
        if data['starts_at'] <= timezone.now() or data.get('capacity',1) < 1:
            raise serializers.ValidationError('Choose a future slot with positive capacity.')
        return data

class CampaignSerializer(serializers.ModelSerializer):
    class Meta:
        model = Campaign
        fields = '__all__'
        read_only_fields = ['reserved']
    def validate_code(self, code):
        code = code.strip().upper()
        if not code.isalnum():
            raise serializers.ValidationError('Use letters and numbers only.')
        if Campaign.objects.filter(code=code).exists():
            raise serializers.ValidationError('Code already exists.')
        return code
    def validate(self, data):
        if data['ends_at'] <= data['starts_at']:
            raise serializers.ValidationError('End date must follow start date.')
        if data.get('value',0) < 0 or (data['kind']=='percent' and data.get('value',0)>100):
            raise serializers.ValidationError('Invalid discount amount.')
        if data.get('max_discount') is not None and data['max_discount'] < 0:
            raise serializers.ValidationError('Discount cap cannot be negative.')
        if data['total_limit'] < 1 or data.get('per_patient_limit',1)<1:
            raise serializers.ValidationError('Campaign limits must be positive.')
        if data.get('active') and not data.get('partner_approved'):
            raise serializers.ValidationError('Partner approval is required before activation.')
        return data

class BookingSerializer(serializers.ModelSerializer):
    service = ServiceSerializer(source='slot.service', read_only=True)
    starts_at = serializers.DateTimeField(source='slot.starts_at', read_only=True)
    patient_name = serializers.CharField(source='patient.full_name', read_only=True)
    class Meta:
        model = Booking
        fields = ['id','patient_name','slot','service','starts_at','original_price','discount','payable','campaign','status','created_at']

class NotificationSerializer(serializers.ModelSerializer):
    type = serializers.CharField(source='kind', read_only=True)
    ref_id = serializers.CharField(source='reference', read_only=True)
    class Meta:
        model = Notification
        fields = ['id','message','type','ref_id','read','created_at']
