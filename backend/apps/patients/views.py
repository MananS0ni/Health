from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import PatientProfile
from .serializers import PatientProfileSerializer
from apps.accounts.models import CustomUser

class PatientProfileDetailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = CustomUser.objects.first()
        if not user:
            user = CustomUser.objects.create(phone='+91 9876543210', full_name='Manan Soni')
        profile, created = PatientProfile.objects.get_or_create(user=user)
        return Response(PatientProfileSerializer(profile).data)

    def patch(self, request):
        user = CustomUser.objects.first()
        profile, created = PatientProfile.objects.get_or_create(user=user)
        serializer = PatientProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class EmergencyCardView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = CustomUser.objects.first()
        if not user:
            user = CustomUser.objects.create(phone='+91 9876543210', full_name='Manan Soni')
        profile, created = PatientProfile.objects.get_or_create(user=user)
        return Response({
            "blood_group": profile.blood_group,
            "patient_phone": user.phone,
            "patient_name": user.full_name,
            "known_allergies": profile.known_allergies.split(','),
            "emergency_contact": {
                "name": profile.emergency_contact_name,
                "phone": profile.emergency_contact_phone,
                "relation": profile.emergency_contact_relation
            },
            "qr_verification_status": "VERIFIED_PATIENT_CARD"
        })
