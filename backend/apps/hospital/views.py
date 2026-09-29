from apps.care.services import notify, audit
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.accounts.models import User
from apps.accounts.permissions import IsHospital, resolve_patient, require_patient_access
from apps.reports.models import MedicalRecord
from apps.reports.files import validate_document
from .models import InpatientAdmission
from .serializers import InpatientAdmissionSerializer

class InpatientAdmissionListCreateView(APIView):
    permission_classes = [IsHospital]
    def get(self, request):
        admissions = InpatientAdmission.objects.filter(hospital=request.user)
        if request.query_params.get('include_discharged') != 'true':
            admissions = admissions.exclude(status='Discharged')
        ward = request.query_params.get('ward')
        if ward and ward.lower() != 'all wards':
            admissions = admissions.filter(ward__iexact=ward)
        return Response(InpatientAdmissionSerializer(admissions[:200], many=True).data)

    @transaction.atomic
    def post(self, request):
        patient = resolve_patient(request.data.get('patient') or request.data.get('patient_identifier') or request.data.get('patient_email') or request.data.get('patient_id'))
        require_patient_access(request.user, patient)
        data = request.data.copy()
        data['patient'], data['patient_name'] = str(patient.pk), patient.full_name
        data['ward'] = str(data.get('ward') or 'General Ward').strip()
        data['bed_no'] = str(data.get('bed_no') or '').strip()
        if data.get('status', 'Admitted') not in ('Admitted','Critical Care'):
            raise serializers.ValidationError('An admission must begin in Admitted or Critical Care status.')
        serializer = InpatientAdmissionSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        User.objects.select_for_update().get(pk=request.user.pk)
        if InpatientAdmission.objects.filter(hospital=request.user, ward__iexact=data['ward'], bed_no__iexact=data['bed_no']).exclude(status='Discharged').exists():
            return Response({'error':'This bed is occupied.'}, status=409)
        admission = serializer.save(hospital=request.user, patient=patient)
        notify(patient, 'Your hospital admission has been recorded.', 'admission', admission.admission_id)
        audit(request.user, 'admission.created', admission.admission_id)
        MedicalRecord.objects.create(source='professional', created_by=request.user, patient=patient,title=f'Inpatient Admission: {admission.diagnosis}',record_type='Inpatient Admission',record_date=admission.admission_date,facility_name=request.user.full_name,doctor_name=admission.attending_doctor,description=f'Ward: {admission.ward}; Bed: {admission.bed_no}. {admission.diagnosis}')
        return Response(serializer.data, status=201)

class InpatientDischargeView(APIView):
    permission_classes = [IsHospital]
    @transaction.atomic
    def post(self, request, admission_id):
        admission = get_object_or_404(InpatientAdmission.objects.select_for_update(), hospital=request.user, admission_id=admission_id)
        if admission.status == 'Discharged':
            return Response({'success':True,'message':'Already discharged.','admission_id':admission.admission_id})
        if not admission.patient:
            raise serializers.ValidationError('Link this admission to the exact patient before discharge.')
        require_patient_access(request.user, admission.patient)
        notes = serializers.CharField(max_length=20000).run_validation(request.data.get('discharge_notes'))
        file = validate_document(request.FILES.get('file'))
        date = serializers.DateField().run_validation(request.data.get('discharge_date', str(timezone.localdate())))
        if date < admission.admission_date or date > timezone.localdate():
            raise serializers.ValidationError('Discharge date must be between admission and today.')
        admission.status, admission.discharge_date, admission.discharge_notes = 'Discharged', date, notes
        admission.save(update_fields=['status','discharge_date','discharge_notes'])
        notify(admission.patient, 'Your discharge summary is available in your records.', 'discharge', admission.admission_id)
        audit(request.user, 'admission.discharged', admission.admission_id)
        MedicalRecord.objects.create(source='professional', created_by=request.user, patient=admission.patient,title=f'Discharge Summary: {admission.diagnosis}',record_type='Discharge Summary',record_date=date,doctor_name=admission.attending_doctor,facility_name=request.user.full_name,description=notes,file_url=file)
        return Response({'success':True,'message':'Patient discharged and summary saved.','admission_id':admission.admission_id})
