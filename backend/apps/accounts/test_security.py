import re
from django.core import mail
from django.core.cache import cache
from django.utils import timezone
from rest_framework.test import APITestCase
from .models import User, EmailOTP
from apps.doctor.models import ConsentRequest, Appointment
from apps.patients.models import PatientProfile
from apps.reports.models import MedicalRecord, LabReport
from apps.lab.models import LabTestOrder


class SecurityRegressionTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.patient = User.objects.create_user(email='patient@example.com', full_name='Patient', roles=['patient'])
        self.other = User.objects.create_user(email='other@example.com', full_name='Other', roles=['patient'])
        self.doctor = User.objects.create_user(email='doctor@example.com', role='doctor', roles=['doctor','patient'], professional_verified=True)
        self.lab = User.objects.create_user(email='lab@example.com', role='lab', roles=['lab'], professional_verified=True)
        PatientProfile.objects.create(user=self.patient, allergies=['Private allergy'])
        MedicalRecord.objects.create(patient=self.patient, title='Private clinical record', record_type='Doctor Note')

    def grant(self, provider):
        return ConsentRequest.objects.create(doctor=provider, patient=self.patient, status='approved', valid_until=timezone.now()+timezone.timedelta(hours=1))

    def test_anonymous_cannot_read_or_write(self):
        for path in ['/api/patients/me/','/api/reports/records/','/api/search/?q=Private','/api/admin-portal/users/']:
            with self.subTest(path=path):
                self.assertEqual(self.client.get(path, HTTP_X_USER_EMAIL=self.patient.email).status_code, 401)
        self.assertEqual(self.client.patch('/api/patients/me/', {'blood_group':'AB+'}, format='json', HTTP_X_USER_EMAIL=self.patient.email).status_code,401)

    def test_authenticated_header_does_not_change_owner(self):
        self.client.force_authenticate(self.other)
        response = self.client.get('/api/patients/me/', HTTP_X_USER_EMAIL=self.patient.email)
        self.assertEqual(response.data['email'], self.other.email)
        self.assertEqual(self.client.get('/api/search/?q=Private').data['total_results'],0)

    def test_admin_is_not_self_assignable(self):
        self.client.force_authenticate(self.patient)
        self.assertEqual(self.client.post('/api/auth/register-profile/',{'full_name':'Patient','role':'admin'},format='json').status_code,403)
        self.assertEqual(self.client.get('/api/admin-portal/users/').status_code,403)

    def test_provider_roles_need_review(self):
        self.client.force_authenticate(self.patient)
        r=self.client.post('/api/auth/register-profile/',{'full_name':'Patient','role':'doctor'},format='json')
        self.assertEqual(r.status_code,200)
        self.patient.refresh_from_db()
        self.assertEqual(self.patient.role,'patient')
        self.assertEqual(self.patient.pending_roles,['doctor'])
        self.assertFalse(self.patient.professional_verified)

    def test_patient_cannot_publish_or_admit(self):
        self.client.force_authenticate(self.patient)
        for path in ['/api/lab/upload-report/','/api/hospital/admissions/']:
            self.assertEqual(self.client.post(path,{},format='json').status_code,403)

    def test_only_patient_can_approve(self):
        consent=ConsentRequest.objects.create(doctor=self.doctor,patient=self.patient)
        self.client.force_authenticate(self.doctor)
        self.assertEqual(self.client.post(f'/api/doctor/incoming-requests/{consent.pk}/action/',{'action':'approve'},format='json').status_code,403)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.post(f'/api/patients/consents/{consent.pk}/action/',{'action':'approve'},format='json').status_code,404)
        self.client.force_authenticate(self.patient)
        self.assertEqual(self.client.post(f'/api/patients/consents/{consent.pk}/action/',{'action':'approve'},format='json').status_code,200)

    def test_locked_chart_hides_clinical_fields(self):
        self.client.force_authenticate(self.doctor)
        r=self.client.get(f'/api/doctor/patients/{self.patient.pk}/chart/')
        self.assertFalse(r.data['has_consent'])
        self.assertNotIn('allergies',r.data)
        self.grant(self.doctor)
        r=self.client.get(f'/api/doctor/patients/{self.patient.pk}/chart/')
        self.assertEqual(r.data['allergies'],['Private allergy'])
        self.assertEqual(len(r.data['records']),1)

    def test_existing_registration_cannot_grant_consent(self):
        self.client.force_authenticate(self.doctor)
        self.assertEqual(self.client.post('/api/doctor/patients/',{'email':self.patient.email,'full_name':'Changed'},format='json').status_code,409)
        self.assertFalse(ConsentRequest.objects.exists())

    def test_no_fabricated_lab_parameters(self):
        self.grant(self.lab)
        self.client.force_authenticate(self.lab)
        r=self.client.post('/api/lab/upload-report/',{'patient_identifier':self.patient.email,'test_name':'CBC'},format='json')
        self.assertEqual(r.status_code,400)
        self.assertFalse(LabReport.objects.exists())

    def test_low_csv_and_batch_validation(self):
        self.grant(self.lab)
        self.client.force_authenticate(self.lab)
        text=f'patient_email,test_name,parameter,value,status\n{self.patient.email},CBC,Hemoglobin,1,low\n'
        r=self.client.post('/api/lab/batch-upload/',{'csv_text':text},format='json')
        self.assertEqual(r.status_code,201,r.data)
        report=LabReport.objects.get()
        self.assertEqual(report.status,'Abnormal')
        self.assertFalse(report.file_url)
        self.assertTrue(report.parameters.get().is_abnormal)

    def test_publish_does_not_duplicate(self):
        self.grant(self.lab)
        self.client.force_authenticate(self.lab)
        order=LabTestOrder.objects.create(lab=self.lab,patient=self.patient,patient_name='Patient',test_name='Measured')
        payload={'parameters':[{'parameter_name':'Metric','value':'2','is_abnormal':False}]}
        url=f'/api/lab/orders/{order.order_id}/publish/'
        self.assertEqual(self.client.post(url,payload,format='json').status_code,201)
        self.assertEqual(self.client.post(url,payload,format='json').status_code,409)
        self.assertEqual(LabReport.objects.count(),1)

    def test_doctor_context_and_invalid_patient(self):
        Appointment.objects.create(doctor=self.doctor,patient=self.patient)
        self.client.force_authenticate(self.doctor)
        self.assertEqual(len(self.client.get('/api/doctor/appointments/?context=doctor').data),1)
        self.assertEqual(len(self.client.get('/api/doctor/appointments/?context=patient').data),0)
        self.assertEqual(self.client.post('/api/doctor/appointments/',{'patient':'PAT-'},format='json').status_code,400)

    def test_medications_round_trip(self):
        self.client.force_authenticate(self.patient)
        r=self.client.patch('/api/patients/me/',{'current_medications':['Recorded medicine']},format='json')
        self.assertEqual(r.data['current_medications'],['Recorded medicine'])

    def test_otp_hash_expiry_attempt_limit_and_no_privilege_merge(self):
        r=self.client.post('/api/auth/request-otp/',{'email':self.patient.email},format='json')
        self.assertEqual(r.status_code,200)
        self.assertNotIn('dev_otp',r.data)
        code=re.search(r'\b\d{6}\b',mail.outbox[-1].body).group()
        self.assertNotEqual(EmailOTP.objects.get().otp,code)
        r=self.client.post('/api/auth/verify-otp/',{'email':self.patient.email,'otp':code,'roles':['admin']},format='json')
        self.assertEqual(r.status_code,400)
        r=self.client.post('/api/auth/verify-otp/',{'email':self.patient.email,'otp':code,'roles':['doctor']},format='json')
        self.assertEqual(r.status_code,200)
        self.patient.refresh_from_db()
        self.assertEqual(self.patient.roles,['patient'])
        self.assertEqual(self.client.post('/api/auth/verify-otp/',{'email':self.patient.email,'otp':code},format='json').status_code,400)

    def test_raw_media_is_not_public(self):
        self.assertEqual(self.client.get('/media/reports/anything.pdf').status_code,404)
