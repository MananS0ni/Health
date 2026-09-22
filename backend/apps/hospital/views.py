from django.utils import timezone
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import InpatientAdmission
from .serializers import InpatientAdmissionSerializer
from apps.reports.models import MedicalRecord


class InpatientAdmissionListCreateView(APIView):
    """
    GET /api/hospital/admissions/ — List active ward admissions. Filter by ward.
    POST /api/hospital/admissions/ — Admit a patient to a ward and bed.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        admissions = InpatientAdmission.objects.filter(hospital=request.user)
        ward = request.query_params.get('ward')
        if ward and ward.lower() != 'all wards':
            admissions = admissions.filter(ward__iexact=ward)
        serializer = InpatientAdmissionSerializer(admissions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = InpatientAdmissionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(hospital=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class InpatientDischargeView(APIView):
    """
    POST /api/hospital/admissions/<str:admission_id>/discharge/
    Discharges a patient, marks bed available, and automatically logs a Discharge Summary in the patient's personal health locker.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, admission_id):
        admission = InpatientAdmission.objects.filter(hospital=request.user, admission_id=admission_id).first()
        if not admission:
            return Response({'error': 'Admission record not found.'}, status=status.HTTP_404_NOT_FOUND)

        discharge_notes = request.data.get('discharge_notes', 'Patient discharged in stable condition.')
        admission.status = 'Discharged'
        admission.discharge_date = timezone.now().date()
        admission.discharge_notes = discharge_notes
        admission.save(update_fields=['status', 'discharge_date', 'discharge_notes'])

        # If patient has a registered user account, auto-sync the discharge summary to their locker!
        if admission.patient:
            hosp_name = getattr(request.user.hospital_profile, 'hospital_name', 'Hospital Care Facility') if hasattr(request.user, 'hospital_profile') else 'Hospital Care Facility'
            MedicalRecord.objects.create(
                patient=admission.patient,
                title=f"Discharge Summary: {admission.diagnosis}",
                record_type="Discharge Summary",
                record_date=admission.discharge_date,
                doctor_name=admission.attending_doctor,
                facility_name=hosp_name,
                description=f"Ward: {admission.ward} (Bed: {admission.bed_no})\nDiagnosis: {admission.diagnosis}\nSummary: {discharge_notes}",
            )

        return Response({
            'success': True,
            'message': f"Patient {admission.patient_name} successfully discharged.",
            'admission_id': admission.admission_id,
        }, status=status.HTTP_200_OK)
