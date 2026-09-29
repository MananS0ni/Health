"""Read-only-to-project audit: reproductions use an in-memory DB and synthetic users.
Run: backend\\venv\\Scripts\\python.exe audit\\reproduce_findings.py
No SMTP, live HTTP server, or existing database is used.
"""
import contextlib
import io
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backend'))
os.environ['DJANGO_SETTINGS_MODULE'] = 'config.settings'
from django.conf import settings
settings.DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}}
settings.EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'
settings.DEBUG = True
settings.ALLOWED_HOSTS = ['testserver']
import django
django.setup()
from django.core.management import call_command
from rest_framework.test import APIClient
from apps.accounts.models import User, EmailOTP
from apps.patients.models import PatientProfile
from apps.doctor.models import Appointment, ConsentRequest
from apps.reports.models import MedicalRecord, LabReport
from apps.lab.models import LabTestOrder
from apps.hospital.models import InpatientAdmission
from apps.lab.views import process_lab_csv_data
import csv

results = []
def record(name, reproduced, **observed):
    results.append({'finding': name, 'reproduced': bool(reproduced), 'observed': observed})

with contextlib.nullcontext(str(ROOT / 'audit' / 'synthetic_media')) as media:
    settings.MEDIA_ROOT = media
    call_command('migrate', verbosity=0, interactive=False)
    patient = User.objects.create_user(email='patient@example.invalid', full_name='Audit Patient', roles=['patient'])
    other = User.objects.create_user(email='other@example.invalid', full_name='Other Patient', roles=['patient'])
    doctor = User.objects.create_user(email='doctor@example.invalid', full_name='Audit Doctor', role='doctor', roles=['doctor','patient'])
    PatientProfile.objects.create(user=patient, allergies=['Synthetic allergy'], current_medications=['Synthetic medicine'])
    MedicalRecord.objects.create(patient=patient, title='AuditPrivateRecord', record_type='Doctor Note')
    anon = APIClient()
    r = anon.get('/api/patients/me/', HTTP_X_USER_EMAIL=patient.email)
    record('Anonymous header impersonation reads profile', r.status_code == 200 and r.data.get('email') == patient.email, status=r.status_code)
    r = anon.patch('/api/patients/me/', {'blood_group':'AB+'}, format='json', HTTP_X_USER_EMAIL=patient.email)
    record('Anonymous header impersonation changes profile', r.status_code == 200 and r.data.get('blood_group') == 'AB+', status=r.status_code)
    r = anon.get('/api/search/', {'q':'AuditPrivateRecord'})
    record('Anonymous global search reads private records', r.status_code == 200 and r.data['total_results'] > 0, status=r.status_code)
    r = anon.get('/api/admin-portal/users/')
    record('Anonymous admin user directory', r.status_code == 200 and r.data['count'] == 3, status=r.status_code)
    r = anon.post(f'/api/admin-portal/users/{other.id}/toggle-verify/')
    other.refresh_from_db()
    record('Anonymous admin verification mutation', r.status_code == 200 and other.is_verified, status=r.status_code)
    consent = ConsentRequest.objects.create(doctor=doctor, patient=patient)
    r = anon.post(f'/api/doctor/incoming-requests/{consent.id}/action/', {'action':'approve'}, format='json')
    consent.refresh_from_db()
    record('Anonymous approval of arbitrary consent', consent.is_active(), status=r.status_code)
    r = anon.get(f'/api/doctor/patients/{patient.id}/chart/', HTTP_X_USER_EMAIL=doctor.email)
    record('Anonymous doctor impersonation unlocks chart', r.status_code == 200 and r.data['has_consent'], status=r.status_code)
    consent.delete()
    r = anon.get(f'/api/doctor/patients/{patient.id}/chart/')
    record('Locked chart exposes allergies', r.status_code == 200 and bool(r.data['allergies']), status=r.status_code)
    client = APIClient()
    client.force_authenticate(user=doctor)
    r = client.post('/api/doctor/patients/', {'email':patient.email, 'full_name':'Changed by provider'}, format='json')
    record('Register existing patient grants doctor consent', r.status_code == 201 and ConsentRequest.objects.filter(patient=patient, doctor=doctor, status='approved').exists(), status=r.status_code)
    client.force_authenticate(user=other)
    r = client.post('/api/lab/upload-report/', {'patient_identifier':patient.email, 'test_name':'CBC'}, format='json')
    report = LabReport.objects.filter(patient=patient).first()
    record('Patient can publish lab report with fabricated values', r.status_code == 201 and report.parameters.count() == 5, status=r.status_code, parameters=report.parameters.count() if report else 0)
    r = client.post('/api/auth/register-profile/', {'full_name':'Other Patient','role':'admin'}, format='json')
    other.refresh_from_db()
    record('Patient self-assigns admin role', r.status_code == 200 and other.role == 'admin', status=r.status_code, role=other.role)
    Appointment.objects.create(doctor=doctor,patient=patient)
    client.force_authenticate(user=doctor)
    r = client.get('/api/doctor/appointments/')
    record('Multi-role doctor receives patient appointment list', r.status_code == 200 and len(r.data) == 0, status=r.status_code, returned=len(r.data))
    r = client.post('/api/doctor/appointments/', {'patient':'NO-SUCH-PATIENT'}, format='json')
    record('Invalid appointment patient silently becomes doctor', r.status_code == 201 and str(r.data['patient']) == str(doctor.id), status=r.status_code)
    client.force_authenticate(user=other)
    r = client.post('/api/hospital/admissions/', {'patient':str(patient.id), 'patient_name':'Unmatched Display Name', 'bed_no':'A1','diagnosis':'Synthetic'}, format='json')
    record('Admission patient UUID ignored and ordinary user admitted patient', r.status_code == 201 and r.data['patient'] is None, status=r.status_code)
    # Default ward omitted: both saves resolve to the same model default ward.
    r2 = client.post('/api/hospital/admissions/', {'patient_name':'Another', 'bed_no':'A1','diagnosis':'Synthetic'}, format='json')
    record('Duplicate beds when default ward omitted', r2.status_code == 201 and InpatientAdmission.objects.filter(hospital=other,bed_no='A1').count() == 2, status=r2.status_code)
    order = LabTestOrder.objects.create(lab=other,patient=patient,patient_name='Synthetic',test_name='Repeat')
    for _ in range(2):
        client.post(f'/api/lab/orders/{order.order_id}/publish/', {'parameters':[]}, format='json')
    record('Repeated publish creates duplicate reports', LabReport.objects.filter(report_name='Repeat').count() == 2, reports=LabReport.objects.filter(report_name='Repeat').count())
    data = f'patient_email,test_name,parameter,value,status\n{patient.email},LowPanel,Hemoglobin,1,low\n'
    process_lab_csv_data(csv.DictReader(io.StringIO(data)), 'Synthetic lab')
    low = LabReport.objects.get(report_name='LowPanel')
    record('CSV low flag recorded as normal', low.status == 'Normal' and not low.parameters.first().is_abnormal, status=low.status)
    r = client.get('/api/patients/emergency-card/')
    record('Client emergency endpoint does not exist', r.status_code == 404, status=r.status_code)
    r = anon.get('/api/patients/me/', HTTP_X_USER_EMAIL=patient.email)
    record('Patient profile serializer omits current medications', 'current_medications' not in r.data, status=r.status_code)
    with contextlib.redirect_stdout(io.StringIO()):
        r = anon.post('/api/auth/request-otp/', {'email':patient.email}, format='json')
    record('DEBUG OTP exposed in response', r.status_code == 200 and 'dev_otp' in r.data, status=r.status_code)
    otp = EmailOTP.generate_otp(patient.email)
    patient.is_verified = False
    patient.save(update_fields=['is_verified'])
    r = anon.post('/api/auth/verify-otp/', {'email':patient.email,'otp':otp.otp,'roles':['admin']}, format='json')
    patient.refresh_from_db()
    record('OTP accepts admin role and overwrites verification decision', r.status_code == 200 and 'admin' in patient.roles and patient.is_verified, status=r.status_code)

target = ROOT / 'audit' / 'reproduction_results.json'
target.write_text(json.dumps(results, indent=2), encoding='utf-8')
print(json.dumps(results, indent=2))
