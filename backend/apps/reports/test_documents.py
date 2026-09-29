from pathlib import Path
from django.conf import settings
import tempfile
from datetime import timedelta
from urllib.parse import urlsplit
from django.test import override_settings
from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from rest_framework.test import APITestCase
from apps.accounts.models import User
from apps.doctor.models import ConsentRequest
from apps.care.models import Notification
from apps.care.services import notify
from .models import MedicalRecord

class DocumentSecurityTests(APITestCase):
    def setUp(self):
        self.override=override_settings(STORAGES={'default':{'BACKEND':'django.core.files.storage.InMemoryStorage'}})
        self.override.enable()
        self.addCleanup(self.override.disable)
        self.patient=User.objects.create_user(email='files@example.com')
        self.other=User.objects.create_user(email='otherfiles@example.com')
        self.doctor=User.objects.create_user(email='doctorfiles@example.com',role='doctor',professional_verified=True)
        self.client.force_authenticate(self.patient)
    def upload(self):
        return self.client.post('/api/reports/records/',{'title':'Historical document','record_type':'Lab Report','record_date':'2020-01-01','file_url':SimpleUploadedFile('history.pdf',b'%PDF-1.4\nTest fixture'),'source':'professional','created_by':str(self.doctor.pk)},format='multipart')
    def test_source_date_bytes_and_private_download(self):
        response=self.upload()
        self.assertEqual(response.status_code,201,response.data)
        self.assertEqual(response.data['source'],'patient')
        self.assertEqual(str(response.data['created_by']),str(self.patient.pk))
        self.assertEqual(response.data['record_date'],'2020-01-01')
        link=self.client.get(response.data['file_url'])
        self.assertEqual(link.status_code,200)
        url=urlsplit(link.data['url'])
        self.client.force_authenticate(None)
        download=self.client.get(url.path+'?'+url.query)
        self.assertEqual(download.status_code,200)
        self.assertEqual(b''.join(download.streaming_content),b'%PDF-1.4\nTest fixture')
        self.assertEqual(download['Cache-Control'],'no-store')
        self.assertEqual(self.client.get(response.data['file_url']).status_code,401)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get(response.data['file_url']).status_code,403)
    def test_revocation_invalidates_issued_download(self):
        response=self.upload()
        consent=ConsentRequest.objects.create(doctor=self.doctor,patient=self.patient,status='approved',valid_until=timezone.now()+timedelta(hours=1))
        self.client.force_authenticate(self.doctor)
        link=self.client.get(response.data['file_url'])
        self.assertEqual(link.status_code,200)
        consent.status='revoked';consent.save()
        url=urlsplit(link.data['url'])
        self.assertEqual(self.client.get(url.path+'?'+url.query).status_code,403)
    def test_spoofed_file_rejected(self):
        result=self.client.post('/api/reports/records/',{'title':'x','record_type':'Report','file_url':SimpleUploadedFile('fake.pdf',b'<script>bad</script>')},format='multipart')
        self.assertEqual(result.status_code,400)
        self.assertEqual(MedicalRecord.objects.count(),0)
    def test_only_own_patient_documents_can_be_deleted(self):
        result=self.upload()
        path=f"/api/reports/records/{result.data['record_id']}/"
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.delete(path).status_code,404)
        self.client.force_authenticate(self.patient)
        self.assertEqual(self.client.delete(path).status_code,204)
        record=MedicalRecord.objects.create(patient=self.patient,source='professional',title='Prescription',record_type='Prescription')
        self.assertEqual(self.client.delete(f'/api/reports/records/{record.record_id}/').status_code,403)
    def test_preferences_persist_and_do_not_suppress_consent(self):
        result=self.client.patch('/api/auth/me/',{'notification_preferences':{'lab_report':False}},format='json')
        self.assertEqual(result.status_code,200)
        self.patient.refresh_from_db()
        notify(self.patient,'Report ready','lab_report')
        notify(self.patient,'Access requested','consent')
        self.assertEqual(list(Notification.objects.values_list('kind',flat=True)),['consent'])
    def test_invalid_profile_types_and_future_birth_rejected(self):
        self.assertEqual(self.client.patch('/api/patients/me/',{'medical_conditions':{'hidden':'data'}},format='json').status_code,400)
        self.assertEqual(self.client.patch('/api/patients/me/',{'date_of_birth':str(timezone.localdate()+timedelta(days=1))},format='json').status_code,400)
