from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import ConsentPermission
from .serializers import ConsentPermissionSerializer
from apps.accounts.models import CustomUser

class ConsentListCreateView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = CustomUser.objects.first()
        if not user:
            user = CustomUser.objects.create(phone='+91 9876543210', full_name='Manan Soni', abha_id='manan.soni@abha')

        if ConsentPermission.objects.count() == 0:
            ConsentPermission.objects.create(
                consent_id='CNS-8812',
                patient=user,
                doctor_name='Dr. Ritu Verma',
                specialty='Cardiologist',
                hospital_name='Max Healthcare Hospital',
                purpose='Follow-up Heart Review',
                scope='All Heart & ECG Reports',
                expires_in='Valid for 23 hours',
                status='ACTIVE'
            )
            ConsentPermission.objects.create(
                consent_id='CNS-7401',
                patient=user,
                doctor_name='Dr. A. K. Sharma',
                specialty='General Physician',
                hospital_name='Dr. Lal PathLabs Portal',
                purpose='Diagnostic Consultation',
                scope='Blood Report Only',
                expires_in='Access Expired',
                status='EXPIRED'
            )

        consents = ConsentPermission.objects.filter(patient=user).order_by('-id')
        return Response({
            "count": consents.count(),
            "results": ConsentPermissionSerializer(consents, many=True).data
        })

    def post(self, request):
        user = CustomUser.objects.first()
        serializer = ConsentPermissionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=user, status='ACTIVE')
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ConsentRevokeView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, consent_id):
        try:
            consent = ConsentPermission.objects.get(consent_id=consent_id)
            consent.status = 'REVOKED'
            consent.expires_in = 'Access Revoked'
            consent.save()
            return Response({
                "status": "REVOKED",
                "message": f"Doctor access revoked immediately for {consent.doctor_name}. Access blocked."
            }, status=status.HTTP_200_OK)
        except ConsentPermission.DoesNotExist:
            return Response({"error": "Consent record not found"}, status=status.HTTP_404_NOT_FOUND)
