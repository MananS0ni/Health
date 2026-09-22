from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import LabTestOrder
from .serializers import LabTestOrderSerializer
from apps.reports.models import LabReport, TestParameter


class LabPendingOrdersView(APIView):
    """
    GET /api/lab/orders/ — List all pending lab orders. Filter by category or status.
    POST /api/lab/orders/ — Queue a new test order.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        orders = LabTestOrder.objects.filter(lab=request.user)
        cat = request.query_params.get('category')
        if cat and cat.lower() != 'all':
            orders = orders.filter(category__iexact=cat)
        serializer = LabTestOrderSerializer(orders, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = LabTestOrderSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(lab=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LabPublishReportView(APIView):
    """
    POST /api/lab/orders/<str:order_id>/publish/
    Submits verified test parameters and marks order complete.
    Automatically generates and attaches the official LabReport to the patient's personal locker!
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, order_id):
        order = LabTestOrder.objects.filter(lab=request.user, order_id=order_id).first()
        if not order:
            return Response({'error': 'Test order not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not order.patient:
            return Response({'error': 'Order has no linked patient account.'}, status=status.HTTP_400_BAD_REQUEST)

        parameters_data = request.data.get('parameters', [])
        summary = request.data.get('summary', 'Diagnostic test results finalized.')
        test_status = request.data.get('status', 'Normal')

        # Create verified LabReport in patient's locker
        lab_name = getattr(request.user.lab_profile, 'lab_name', 'Diagnostic Hub') if hasattr(request.user, 'lab_profile') else 'Diagnostic Hub'
        report = LabReport.objects.create(
            patient=order.patient,
            report_name=order.test_name,
            category=order.category,
            facility_name=lab_name,
            doctor_name=order.doctor_name,
            status=test_status,
            summary=summary,
        )

        for p in parameters_data:
            TestParameter.objects.create(
                report=report,
                parameter_name=p.get('parameter_name', 'Parameter'),
                value=str(p.get('value', '')),
                unit=p.get('unit', ''),
                reference_range=p.get('reference_range', ''),
                is_abnormal=p.get('is_abnormal', False),
            )

        order.status = 'Completed'
        order.save(update_fields=['status'])

        return Response({
            'success': True,
            'message': 'Report published directly to patient health locker.',
            'report_id': report.report_id,
        }, status=status.HTTP_201_CREATED)


class LabBatchUploadView(APIView):
    """
    POST /api/lab/batch-upload/
    Accepts CSV file upload or 'csv_text' payload.
    Batch-processes diagnostic test results and automatically attaches verified reports
    to each patient's digital health locker.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        import csv
        import io
        from apps.accounts.models import User, Role

        csv_content = None
        if 'file' in request.FILES:
            uploaded_file = request.FILES['file']
            try:
                csv_content = uploaded_file.read().decode('utf-8-sig')
            except UnicodeDecodeError:
                return Response({'error': 'Could not decode CSV file. Please ensure UTF-8 encoding.'}, status=status.HTTP_400_BAD_REQUEST)
        elif 'csv_text' in request.data:
            csv_content = request.data['csv_text']
        else:
            return Response({'error': 'Please provide a CSV file in "file" or CSV string in "csv_text".'}, status=status.HTTP_400_BAD_REQUEST)

        if not csv_content or not csv_content.strip():
            return Response({'error': 'The provided CSV content is empty.'}, status=status.HTTP_400_BAD_REQUEST)

        f = io.StringIO(csv_content.strip())
        reader = csv.DictReader(f)
        
        # Clean column headers
        if not reader.fieldnames:
            return Response({'error': 'CSV missing header row.'}, status=status.HTTP_400_BAD_REQUEST)

        required_cols = {'patient_email', 'test_name', 'parameter_name', 'value'}
        normalized_headers = {col.strip().lower(): col for col in reader.fieldnames if col}
        
        missing = [req for req in required_cols if req not in normalized_headers]
        if missing:
            return Response({
                'error': f'Missing required CSV columns: {", ".join(missing)}',
                'expected_columns': ['patient_email', 'patient_name', 'test_name', 'category', 'parameter_name', 'value', 'unit', 'reference_range', 'is_abnormal', 'doctor_name', 'summary']
            }, status=status.HTTP_400_BAD_REQUEST)

        lab_name = 'Diagnostic Hub'
        if hasattr(request.user, 'lab_profile') and request.user.lab_profile.lab_name:
            lab_name = request.user.lab_profile.lab_name
        elif request.user.full_name:
            lab_name = request.user.full_name

        processed_rows = 0
        reports_map = {}  # key: (patient_id, test_name) -> LabReport
        patients_seen = set()

        for row_idx, raw_row in enumerate(reader, start=2):
            # Normalize row keys
            row = {k.strip().lower(): v.strip() for k, v in raw_row.items() if k and v is not None}
            email = row.get('patient_email', '').lower().strip()
            if not email or '@' not in email:
                continue

            patient_name = row.get('patient_name', '')
            test_name = row.get('test_name', 'Diagnostic Test')
            category = row.get('category', 'Biochemistry')
            param_name = row.get('parameter_name', 'Parameter')
            param_val = row.get('value', '')
            unit = row.get('unit', '')
            ref_range = row.get('reference_range', '')
            is_abnormal_str = row.get('is_abnormal', 'false').lower()
            is_abnormal = is_abnormal_str in ('true', '1', 'yes', 'y', 'abnormal')
            doctor_name = row.get('doctor_name', 'Prescribing Physician')
            summary = row.get('summary', f"Batch-imported results from {lab_name}.")

            # Find or auto-provision patient account
            patient, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'full_name': patient_name or email.split('@')[0].capitalize(),
                    'role': Role.PATIENT,
                    'roles': ['patient'],
                    'is_verified': True,
                }
            )
            if patient_name and not patient.full_name:
                patient.full_name = patient_name
                patient.save(update_fields=['full_name'])

            patients_seen.add(email)

            report_key = (patient.id, test_name.lower())
            if report_key not in reports_map:
                report = LabReport.objects.create(
                    patient=patient,
                    report_name=test_name,
                    category=category,
                    facility_name=lab_name,
                    doctor_name=doctor_name,
                    status='Abnormal' if is_abnormal else 'Normal',
                    summary=summary,
                )
                reports_map[report_key] = report
            else:
                report = reports_map[report_key]
                if is_abnormal and report.status != 'Abnormal':
                    report.status = 'Abnormal'
                    report.save(update_fields=['status'])

            TestParameter.objects.create(
                report=report,
                parameter_name=param_name,
                value=param_val,
                unit=unit,
                reference_range=ref_range,
                is_abnormal=is_abnormal,
            )
            processed_rows += 1

        return Response({
            'success': True,
            'message': f'Successfully batch-processed {processed_rows} test parameters across {len(reports_map)} reports.',
            'processed_rows': processed_rows,
            'reports_created': len(reports_map),
            'patients_notified': list(patients_seen),
        }, status=status.HTTP_201_CREATED)

