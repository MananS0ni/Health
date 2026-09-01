from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import LabReport
from .serializers import LabReportSerializer
from apps.accounts.models import CustomUser
import datetime

class LabReportListCreateView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = CustomUser.objects.first()
        if not user:
            user = CustomUser.objects.create(phone='+91 9876543210', full_name='Manan Soni', abha_id='manan.soni@abha')

        # Ensure demo reports exist if DB is fresh
        if LabReport.objects.count() == 0:
            LabReport.objects.create(
                report_id='REP-881',
                patient=user,
                title='Complete Blood Count (CBC) & Lipid Profile',
                report_type='Blood Test',
                category='Blood Tests',
                provider='Dr. Lal PathLabs',
                facility_type='Diagnostic Lab',
                doctor_name='Dr. A. K. Sharma',
                status='Verified & Synced',
                source='Auto-Pulled via LIS API',
                summary='Hemoglobin (14.2 g/dL) & Cholesterol (185 mg/dL) are in healthy normal ranges.'
            )
            LabReport.objects.create(
                report_id='REP-742',
                patient=user,
                title='Annual Heart & ECG Checkup',
                report_type='Heart & ECG',
                category='Prescriptions',
                provider='Max Healthcare Hospital',
                facility_type='Hospital',
                doctor_name='Dr. Ritu Verma (Cardiologist)',
                status='Verified',
                source='Hospital HIS Auto-Push',
                summary='Heart rhythm is normal (72 bpm) and blood pressure is healthy (118/78 mmHg).'
            )

        reports = LabReport.objects.filter(patient=user).order_by('-id')
        return Response({
            "count": reports.count(),
            "results": LabReportSerializer(reports, many=True).data
        })

    def post(self, request):
        user = CustomUser.objects.first()
        serializer = LabReportSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LabReportDetailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, report_id):
        try:
            report = LabReport.objects.get(report_id=report_id)
            return Response(LabReportSerializer(report).data)
        except LabReport.DoesNotExist:
            return Response({"error": "Report not found"}, status=status.HTTP_404_NOT_FOUND)

class AISummarizeReportView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        report_id = request.data.get('report_id', 'REP-881')
        return Response({
            "status": "SUCCESS",
            "report_id": report_id,
            "overall_verdict": "Healthy & Normal",
            "plain_english_summary": "Your blood oxygen capacity and cholesterol levels are in safe, ideal zones. No urgent concerns found.",
            "metrics": [
                { "name": "Hemoglobin", "value": "14.2 g/dL", "status": "Healthy Normal", "ref_range": "13.0 - 17.0 g/dL" },
                { "name": "Total Cholesterol", "value": "185 mg/dL", "status": "Healthy Normal", "ref_range": "< 200 mg/dL" },
                { "name": "HDL (Good Cholesterol)", "value": "48 mg/dL", "status": "Optimal", "ref_range": "> 40 mg/dL" }
            ],
            "lifestyle_tips": [
                "Drink 8 to 10 glasses of water daily.",
                "Enjoy 30 minutes of walking or light exercise.",
                "Schedule your next routine checkup in 1 year."
            ]
        }, status=status.HTTP_200_OK)
