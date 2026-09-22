from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.reports.models import MedicalRecord, LabReport
from apps.doctor.models import Prescription
from apps.lab.models import LabTestOrder
from apps.patients.models import FamilyMember

User = get_user_model()


class FullPortalIntegrationTests(APITestCase):
    def setUp(self):
        # Patient
        self.patient = User.objects.create_user(
            email='patient.test@dhealth.com',
            full_name='Test Patient',
            role='patient',
            roles=['patient']
        )

        # Doctor
        self.doctor = User.objects.create_user(
            email='doctor.test@dhealth.com',
            full_name='Dr. Sharma',
            role='doctor',
            roles=['doctor']
        )

        # Lab Staff
        self.lab_staff = User.objects.create_user(
            email='lab.test@dhealth.com',
            full_name='City Diagnostics Lab',
            role='lab_staff',
            roles=['lab_staff']
        )

    def test_patient_medical_record_crud(self):
        """Test patient can add and list personal medical records."""
        self.client.force_authenticate(user=self.patient)

        create_resp = self.client.post('/api/reports/records/', {
            'title': 'Chest X-Ray Digital Copy',
            'record_type': 'Radiology Report',
            'record_date': '2026-09-01',
            'facility_name': 'Apollo Imaging',
            'doctor_name': 'Dr. Raman',
            'description': 'Lungs clear, no active consolidation.'
        }, format='json')
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('record_id', create_resp.data)

        list_resp = self.client.get('/api/reports/records/')
        self.assertEqual(list_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_resp.data), 1)
        self.assertEqual(list_resp.data[0]['title'], 'Chest X-Ray Digital Copy')

    def test_patient_lab_report_crud(self):
        """Test patient can record and retrieve diagnostic lab reports."""
        self.client.force_authenticate(user=self.patient)

        create_resp = self.client.post('/api/reports/lab-reports/', {
            'report_name': 'Complete Blood Count (CBC)',
            'category': 'Hematology',
            'report_date': '2026-09-02',
            'facility_name': 'City Diagnostics Hub',
            'status': 'Normal',
            'summary': 'All counts within normal healthy range.',
            'parameters': [
                {
                    'parameter_name': 'Hemoglobin',
                    'value': '14.5',
                    'unit': 'g/dL',
                    'reference_range': '13.0 - 17.0',
                    'is_abnormal': False
                },
                {
                    'parameter_name': 'Total Leukocyte Count',
                    'value': '7200',
                    'unit': '/cumm',
                    'reference_range': '4000 - 11000',
                    'is_abnormal': False
                }
            ]
        }, format='json')
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('report_id', create_resp.data)

        list_resp = self.client.get('/api/reports/lab-reports/')
        self.assertEqual(list_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_resp.data), 1)
        self.assertEqual(len(list_resp.data[0]['parameters']), 2)

    def test_doctor_prescription_cross_syncs_to_patient_locker(self):
        """When a doctor issues a prescription, it automatically enters patient's locker."""
        self.client.force_authenticate(user=self.doctor)

        rx_resp = self.client.post('/api/doctor/prescriptions/', {
            'patient_id': str(self.patient.id),
            'diagnosis': 'Acute Pharyngitis & Mild Fever',
            'clinical_notes': 'Advised rest and warm hydration.',
            'medicines': [
                {'medicine_name': 'Amoxicillin 500mg', 'dosage': '1-0-1', 'duration': '5 Days'},
                {'medicine_name': 'Paracetamol 650mg', 'dosage': '1-0-1', 'duration': '3 Days'}
            ]
        }, format='json')
        self.assertEqual(rx_resp.status_code, status.HTTP_201_CREATED)

        # Now authenticate as patient and check medical records
        self.client.force_authenticate(user=self.patient)
        records_resp = self.client.get('/api/reports/records/')
        self.assertEqual(records_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(records_resp.data), 1)
        self.assertEqual(records_resp.data[0]['record_type'], 'Prescription')
        self.assertIn('Acute Pharyngitis', records_resp.data[0]['title'])

    def test_lab_order_publish_cross_syncs_to_patient_locker(self):
        """When a lab technician publishes results, it automatically enters patient's locker."""
        order = LabTestOrder.objects.create(
            lab=self.lab_staff,
            patient=self.patient,
            patient_name='Test Patient',
            test_name='Lipid Profile',
            category='Biochemistry',
            doctor_name='Dr. Sharma',
            status='Sample Collected'
        )

        self.client.force_authenticate(user=self.lab_staff)
        publish_resp = self.client.post(f'/api/lab/orders/{order.order_id}/publish/', {
            'status': 'Normal',
            'summary': 'Lipid levels are well controlled.',
            'parameters': [
                {'parameter_name': 'Total Cholesterol', 'value': '185', 'unit': 'mg/dL', 'reference_range': '< 200', 'is_abnormal': False},
                {'parameter_name': 'HDL Cholesterol', 'value': '52', 'unit': 'mg/dL', 'reference_range': '> 40', 'is_abnormal': False},
            ]
        }, format='json')
        self.assertEqual(publish_resp.status_code, status.HTTP_201_CREATED)

        # Now authenticate as patient and verify lab report is present
        self.client.force_authenticate(user=self.patient)
        reports_resp = self.client.get('/api/reports/lab-reports/')
        self.assertEqual(reports_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(reports_resp.data), 1)
        self.assertEqual(reports_resp.data[0]['report_name'], 'Lipid Profile')

    def test_health_timeline_chronological_aggregation(self):
        """Verify timeline combines records and reports sorted by date descending."""
        self.client.force_authenticate(user=self.patient)

        # Create record
        self.client.post('/api/reports/records/', {
            'title': 'Consultation Note',
            'record_type': 'Doctor Note',
            'record_date': '2026-09-05',
        }, format='json')

        # Create report
        self.client.post('/api/reports/lab-reports/', {
            'report_name': 'Blood Glucose Fasting',
            'category': 'Biochemistry',
            'report_date': '2026-09-08',
        }, format='json')

        timeline_resp = self.client.get('/api/reports/timeline/')
        self.assertEqual(timeline_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(timeline_resp.data['total_events'], 2)
        # Most recent first
        self.assertEqual(timeline_resp.data['timeline'][0]['title'], 'Blood Glucose Fasting')
        self.assertEqual(timeline_resp.data['timeline'][1]['title'], 'Consultation Note')

    def test_family_member_creation_and_removal(self):
        """Verify patient can manage family members."""
        self.client.force_authenticate(user=self.patient)

        create_resp = self.client.post('/api/patients/family/', {
            'full_name': 'Pooja Soni',
            'relationship': 'Spouse',
            'date_of_birth': '1995-04-12',
            'gender': 'Female',
            'blood_group': 'A+'
        }, format='json')
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        member_id = create_resp.data['member_id']

        list_resp = self.client.get('/api/patients/family/')
        self.assertEqual(len(list_resp.data), 1)

        del_resp = self.client.delete(f'/api/patients/family/{member_id}/')
        self.assertEqual(del_resp.status_code, status.HTTP_204_NO_CONTENT)

        list_resp2 = self.client.get('/api/patients/family/')
        self.assertEqual(len(list_resp2.data), 0)
