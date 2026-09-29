from apps.care.services import notify, audit
import csv
import io
import json
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.accounts.models import User
from apps.accounts.permissions import IsLab, VerifiedProfessional, resolve_patient, require_patient_access
from apps.reports.models import LabReport, TestParameter
from apps.reports.serializers import TestParameterSerializer, LabReportSerializer
from apps.reports.files import validate_document
from .models import LabTestOrder
from .serializers import LabTestOrderSerializer


def parsed_parameters(raw):
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except ValueError:
            raise serializers.ValidationError({'parameters':'Invalid JSON.'})
    serializer = TestParameterSerializer(data=raw or [], many=True)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


def publish(patient, lab, name, category, parameters, file=None, summary='', date=None):
    require_patient_access(lab, patient)
    validate_document(file)
    profile = getattr(lab, 'lab_profile', None)
    report = LabReport.objects.create(source='professional', created_by=lab, patient=patient, report_name=name, category=category,
        facility_name=profile.lab_name if profile else lab.full_name, report_date=date or timezone.localdate(),
        summary=summary, status=('Abnormal' if any(p.get('is_abnormal') for p in parameters) else 'Normal') if parameters else 'Pending review', file_url=file)
    for parameter in parameters:
        TestParameter.objects.create(report=report, **parameter)
    notify(patient, 'A new laboratory report is available.', 'lab_report', report.report_id)
    audit(lab, 'report.published', report.report_id)
    return report


class LabPendingOrdersView(APIView):
    permission_classes = [IsLab]
    def get(self, request):
        orders = LabTestOrder.objects.filter(lab=request.user).exclude(status='Completed')
        category = request.query_params.get('category')
        if category and category.lower() != 'all':
            orders = orders.filter(category__iexact=category)
        return Response(LabTestOrderSerializer(orders[:200], many=True).data)
    def post(self, request):
        patient = resolve_patient(request.data.get('patient') or request.data.get('patient_identifier'))
        require_patient_access(request.user, patient)
        data = request.data.copy()
        data['patient'] = str(patient.pk)
        data['patient_name'] = patient.full_name
        serializer = LabTestOrderSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        serializer.save(lab=request.user)
        return Response(serializer.data, status=201)


class LabPublishReportView(APIView):
    permission_classes = [IsLab]
    @transaction.atomic
    def post(self, request, order_id):
        order = get_object_or_404(LabTestOrder.objects.select_for_update(), lab=request.user, order_id=order_id)
        if order.status == 'Completed':
            return Response({'error':'Order already published.'}, status=409)
        if not order.patient:
            raise serializers.ValidationError('Link an exact patient before publishing.')
        params = parsed_parameters(request.data.get('parameters'))
        file = request.FILES.get('file')
        if not params and not file:
            raise serializers.ValidationError('Supply measured results or the original document.')
        report = publish(order.patient, request.user, order.test_name, order.category, params, file, request.data.get('summary',''))
        order.status = 'Completed'
        order.save(update_fields=['status'])
        return Response({'success':True, 'report_id':report.report_id}, status=201)


def process_lab_csv_data(reader, lab, target_patient=None):
    """Validate the complete batch before writing; original multi-patient CSV is never attached."""
    grouped = {}
    count = 0
    for row_number, original in enumerate(reader, 2):
        if row_number > 1002:
            raise serializers.ValidationError('Maximum 1000 CSV rows per import.')
        row = {str(k).strip().lower():str(v).strip() for k,v in original.items() if k is not None and v is not None}
        identifier = row.get('patient_email') or row.get('email') or row.get('patient_id') or row.get('patient')
        patient = resolve_patient(identifier) if identifier else target_patient
        if not patient:
            raise serializers.ValidationError(f'Row {row_number}: patient identifier is required.')
        if target_patient and patient.pk != target_patient.pk:
            raise serializers.ValidationError(f'Row {row_number}: this row belongs to a different patient. Use batch import.')
        require_patient_access(lab, patient)
        name = row.get('test_name') or row.get('test') or row.get('panel')
        parameter = row.get('parameter_name') or row.get('parameter')
        value = row.get('result_value') or row.get('value') or row.get('result')
        if not name or not parameter or value is None or value == '':
            raise serializers.ValidationError(f'Row {row_number}: test name, parameter and measured value are required.')
        flag = (row.get('result_status') or row.get('is_abnormal') or row.get('flag') or row.get('status') or '').lower()
        if flag not in ('','normal','false','0','no','true','1','yes','abnormal','high','low','critical','positive','negative'):
            raise serializers.ValidationError(f'Row {row_number}: unsupported result flag.')
        date = serializers.DateField().run_validation(row.get('report_date') or row.get('collection_date') or str(timezone.localdate()))
        params = parsed_parameters([{'parameter_name':parameter,'value':value,'unit':row.get('unit',''),'reference_range':row.get('reference_range',''), 'is_abnormal':flag in ('true','1','yes','abnormal','high','low','critical','positive')}])
        key = (patient.pk, name, date, row.get('specimen_id',''))
        if key not in grouped:
            grouped[key] = {'patient':patient,'name':name,'date':date,'category':row.get('category') or row.get('test_category') or 'Pathology','parameters':[]}
        grouped[key]['parameters'].extend(params)
        count += 1
    if not count:
        raise serializers.ValidationError('CSV contains no valid results.')
    for group in grouped.values():
        publish(lab=lab, **group)
    return {'processed_rows':count,'reports_created':len(grouped)}


class LabBatchUploadView(APIView):
    permission_classes = [IsLab]
    @transaction.atomic
    def post(self, request):
        file = request.FILES.get('file')
        if file:
            validate_document(file, allow_csv=True)
            try:
                content = file.read().decode('utf-8-sig')
            except UnicodeDecodeError:
                raise serializers.ValidationError('CSV must use UTF-8 encoding.')
        else:
            content = request.data.get('csv_text','')
        if not isinstance(content, str) or len(content) > 10*1024*1024:
            raise serializers.ValidationError('Invalid or oversized CSV.')
        result = process_lab_csv_data(csv.DictReader(io.StringIO(content)), request.user)
        return Response({'success':True, **result}, status=201)


class LabPatientListView(APIView):
    permission_classes = [VerifiedProfessional]
    def get(self, request):
        q = request.query_params.get('q','').strip()
        if not q:
            return Response([])
        try:
            patient = resolve_patient(q)
        except serializers.ValidationError:
            return Response([])
        return Response([{'id':str(patient.pk),'patient_id':f'PAT-{patient.pk}','full_name':patient.full_name,'email':patient.email}])


class LabDirectUploadView(APIView):
    permission_classes = [IsLab]
    @transaction.atomic
    def post(self, request):
        patient = resolve_patient(request.data.get('patient_identifier'))
        require_patient_access(request.user, patient)
        file = request.FILES.get('file')
        if file and file.name.lower().endswith('.csv'):
            validate_document(file, allow_csv=True)
            result = process_lab_csv_data(csv.DictReader(io.StringIO(file.read().decode('utf-8-sig'))), request.user, target_patient=patient)
            return Response({'success':True, **result, 'patient_id':str(patient.pk), 'patient_name':patient.full_name, 'status':'Imported'}, status=201)
        parameters = parsed_parameters(request.data.get('parameters'))
        if not file and not parameters:
            raise serializers.ValidationError('Attach a real report or enter actual measured results.')
        name = serializers.CharField(max_length=200).run_validation(request.data.get('test_name'))
        category = serializers.CharField(max_length=100).run_validation(request.data.get('category','Pathology'))
        date = serializers.DateField().run_validation(request.data.get('report_date', str(timezone.localdate())))
        report = publish(patient, request.user, name, category, parameters, file, request.data.get('summary',''), date)
        return Response({'success':True,'report_id':report.report_id,'patient_id':str(patient.pk),'patient_name':patient.full_name,'parameters_count':len(parameters),'status':report.status,'file_url':LabReportSerializer(report).data['file_url']}, status=201)
