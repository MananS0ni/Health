from rest_framework.test import APITestCase
from rest_framework import status
from apps.accounts.models import User, Role, EmailOTP


class FullSystemAPITests(APITestCase):
    def setUp(self):
        # Create Patient User
        self.patient = User.objects.create_user(
            email='patient@test.com',
            full_name='Rajesh Kumar',
            role=Role.PATIENT,
            is_verified=True
        )

        # Create Doctor User
        self.doctor = User.objects.create_user(
            email='doctor@test.com',
            full_name='Dr. Max Patel',
            role=Role.DOCTOR,
            is_verified=True
        )

        # Create Lab User
        self.lab = User.objects.create_user(
            email='lab@test.com',
            full_name='Metropolis Lab',
            role=Role.LAB,
            is_verified=True
        )

        # Create Hospital User
        self.hospital = User.objects.create_user(
            email='hospital@test.com',
            full_name='Apollo Hospital',
            role=Role.HOSPITAL,
            is_verified=True
        )

    def test_auth_otp_flow(self):
        # Request OTP
        resp = self.client.post('/api/auth/request-otp/', {'email': 'newuser@test.com'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        otp_obj = EmailOTP.objects.get(email='newuser@test.com')
        # Verify OTP
        resp_verify = self.client.post('/api/auth/verify-otp/', {'email': 'newuser@test.com', 'otp': otp_obj.otp}, format='json')
        self.assertEqual(resp_verify.status_code, status.HTTP_200_OK)
        self.assertIn('tokens', resp_verify.json())

    def test_patient_and_family_endpoints(self):
        self.client.force_authenticate(user=self.patient)

        # 1. Update Profile (Emergency Info)
        resp_patch = self.client.patch('/api/patients/me/', {
            'blood_group': 'O +ve',
            'allergies': ['Penicillin', 'Sulfa Drugs'],
            'medical_conditions': ['Hypertension'],
            'emergency_contact_name': 'Anita Kumar',
            'emergency_contact_phone': '+91 9876543210',
        }, format='json')
        self.assertEqual(resp_patch.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_patch.json()['blood_group'], 'O +ve')

        # 2. Add Family Member
        resp_fam = self.client.post('/api/patients/family/', {
            'full_name': 'Rohan Kumar',
            'relationship': 'Son',
            'gender': 'Male',
            'blood_group': 'O +ve',
        }, format='json')
        self.assertEqual(resp_fam.status_code, status.HTTP_201_CREATED)

        # 3. Add Vital
        resp_vital = self.client.post('/api/patients/vitals/', {
            'vital_type': 'blood_pressure',
            'value': '120/80',
            'unit': 'mmHg',
            'status': 'Normal',
        }, format='json')
        self.assertEqual(resp_vital.status_code, status.HTTP_201_CREATED)

    def test_records_and_timeline(self):
        self.client.force_authenticate(user=self.patient)

        # 1. Add Record
        resp_rec = self.client.post('/api/reports/records/', {
            'title': 'General Health Checkup Note',
            'record_type': 'Doctor Note',
            'facility_name': 'City Clinic',
            'doctor_name': 'Dr. Max Patel',
            'description': 'Patient is healthy and vitals stable.',
        }, format='json')
        self.assertEqual(resp_rec.status_code, status.HTTP_201_CREATED)

        # 2. Check Timeline
        resp_timeline = self.client.get('/api/reports/timeline/')
        self.assertEqual(resp_timeline.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_timeline.json()['total_events'], 1)

    def test_doctor_prescribes_to_patient(self):
        self.client.force_authenticate(user=self.doctor)

        # Issue Prescription
        resp_rx = self.client.post('/api/doctor/prescriptions/', {
            'patient': str(self.patient.id),
            'diagnosis': 'Stage 1 Hypertension',
            'clinical_notes': 'Reduce sodium intake and regular walks.',
            'medicines': [
                {'medicine_name': 'Telmisartan 40mg', 'dosage': '1-0-0', 'duration': '30 Days'}
            ]
        }, format='json')
        self.assertEqual(resp_rx.status_code, status.HTTP_201_CREATED)

        # Switch context to Patient and verify that the prescription appeared in their health locker!
        self.client.force_authenticate(user=self.patient)
        resp_records = self.client.get('/api/reports/records/')
        self.assertEqual(resp_records.status_code, status.HTTP_200_OK)
        self.assertTrue(any('Prescription: Stage 1 Hypertension' in r['title'] for r in resp_records.json()))

    def test_hospital_admit_and_discharge(self):
        self.client.force_authenticate(user=self.hospital)

        # 1. Admit Patient
        resp_adm = self.client.post('/api/hospital/admissions/', {
            'patient': str(self.patient.id),
            'patient_name': self.patient.full_name,
            'age': 42,
            'gender': 'Male',
            'ward': 'ICU Ward 2',
            'bed_no': 'ICU-04',
            'attending_doctor': 'Dr. Max Patel',
            'diagnosis': 'Severe Chest Pain - Under Observation',
        }, format='json')
        self.assertEqual(resp_adm.status_code, status.HTTP_201_CREATED)
        admission_id = resp_adm.json()['admission_id']

        # 2. Discharge Patient
        resp_dis = self.client.post(f'/api/hospital/admissions/{admission_id}/discharge/', {
            'discharge_notes': 'Cardiac enzymes negative. Stable for home recovery.'
        }, format='json')
        self.assertEqual(resp_dis.status_code, status.HTTP_200_OK)

        # 3. Verify Patient has the Discharge Summary in their locker!
        self.client.force_authenticate(user=self.patient)
        resp_records = self.client.get('/api/reports/records/')
        self.assertEqual(resp_records.status_code, status.HTTP_200_OK)
        self.assertTrue(any('Discharge Summary' in r['title'] for r in resp_records.json()))
