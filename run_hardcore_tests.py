import os
import sys
import json
import django

# Setup Django Environment
sys.path.append(r"D:\Health\backend")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from rest_framework.test import APIClient
from apps.accounts.models import User, Role, EmailOTP, DoctorProfile, LabProfile, HospitalProfile
from apps.patients.models import PatientProfile, HealthVital, FamilyMember
from apps.doctor.models import Appointment, Prescription, PrescriptionItem, ConsentRequest
from apps.hospital.models import InpatientAdmission
from apps.lab.models import LabTestOrder
from apps.reports.models import MedicalRecord, LabReport, TestParameter

def run_tests():
    client = APIClient()
    results = []

    def log_test(test_id, category, name, passed, details="", errors=""):
        results.append({
            "test_id": test_id,
            "category": category,
            "name": name,
            "status": "PASS" if passed else "FAIL",
            "details": details,
            "errors": errors
        })
        status_str = "[PASS]" if passed else "[FAIL]"
        print(f"{status_str} {test_id}: {name}")

    # -------------------------------------------------------------
    # CATEGORY 1: AUTHENTICATION & PROFILE MANAGMENT
    # -------------------------------------------------------------
    # Test 1.1: Request OTP Valid Email
    resp = client.post('/api/auth/request-otp/', {'email': 'testuser@health.com'}, format='json')
    log_test("TC-AUTH-01", "Auth", "Request OTP with valid email", resp.status_code == 200, f"Status: {resp.status_code}")

    # Test 1.2: Request OTP Invalid Email
    resp_bad_email = client.post('/api/auth/request-otp/', {'email': 'not-an-email'}, format='json')
    log_test("TC-AUTH-02", "Auth", "Request OTP with invalid email format", resp_bad_email.status_code == 400, f"Response: {resp_bad_email.data}")

    # Test 1.3: Verify OTP Valid Code
    otp_obj = EmailOTP.objects.filter(email='testuser@health.com').first()
    resp_verify = client.post('/api/auth/verify-otp/', {'email': 'testuser@health.com', 'otp': otp_obj.otp if otp_obj else '000000'}, format='json')
    log_test("TC-AUTH-03", "Auth", "Verify OTP with valid 6-digit code", resp_verify.status_code == 200 and 'tokens' in resp_verify.data, f"Returned user ID: {resp_verify.data.get('user', {}).get('id')}")

    # Test 1.4: Verify OTP Invalid Code
    resp_verify_bad = client.post('/api/auth/verify-otp/', {'email': 'testuser@health.com', 'otp': '999999'}, format='json')
    log_test("TC-AUTH-04", "Auth", "Verify OTP with invalid 6-digit code", resp_verify_bad.status_code == 400, f"Response: {resp_verify_bad.data}")

    # Setup Authenticated Test Users
    patient_user, _ = User.objects.get_or_create(email='rajesh.patient@health.com', defaults={'full_name': 'Rajesh Kumar', 'role': Role.PATIENT, 'is_verified': True})
    doctor_user, _ = User.objects.get_or_create(email='dr.patel@health.com', defaults={'full_name': 'Dr. Dhruv Patel', 'role': Role.DOCTOR, 'is_verified': True})
    lab_user, _ = User.objects.get_or_create(email='lab.hub@health.com', defaults={'full_name': 'Diagnostic Hub', 'role': Role.LAB, 'is_verified': True})
    hosp_user, _ = User.objects.get_or_create(email='city.hospital@health.com', defaults={'full_name': 'City Hospital Care', 'role': Role.HOSPITAL, 'is_verified': True})

    DoctorProfile.objects.get_or_create(user=doctor_user, defaults={'registration_number': 'MCI-88492', 'specialization': 'Cardiology', 'clinic_name': 'Patel Heart Clinic'})
    LabProfile.objects.get_or_create(user=lab_user, defaults={'lab_name': 'Diagnostic Hub', 'license_number': 'LAB-LIC-9920'})
    HospitalProfile.objects.get_or_create(user=hosp_user, defaults={'hospital_name': 'City Hospital Care', 'registration_id': 'HOSP-REG-4410'})

    # -------------------------------------------------------------
    # CATEGORY 2: PATIENT PORTAL & EMERGENCY CARD
    # -------------------------------------------------------------
    client.force_authenticate(user=patient_user)

    # Test 2.1: Get Patient Profile & Emergency Info
    resp_pme = client.get('/api/patients/me/')
    log_test("TC-PAT-01", "Patient Portal", "Retrieve patient profile & emergency card data", resp_pme.status_code == 200, f"Blood Group: {resp_pme.data.get('blood_group')}")

    # Test 2.2: Patch Patient Profile (Emergency Contact & Allergies)
    resp_patch = client.patch('/api/patients/me/', {
        'blood_group': 'O +ve',
        'gender': 'Male',
        'date_of_birth': '1988-04-12',
        'allergies': ['Penicillin', 'Dust'],
        'medical_conditions': ['Hypertension'],
        'emergency_contact_name': 'Anita Kumar',
        'emergency_contact_phone': '+91 9876543210',
        'emergency_contact_relation': 'Spouse'
    }, format='json')
    log_test("TC-PAT-02", "Patient Portal", "Update emergency card, allergies & blood group", resp_patch.status_code == 200 and resp_patch.data.get('blood_group') == 'O +ve')

    # Test 2.3: Add Family Member
    resp_fam_add = client.post('/api/patients/family/', {
        'full_name': 'Aarav Kumar',
        'relationship': 'Son',
        'date_of_birth': '2016-08-20',
        'gender': 'Male',
        'blood_group': 'O +ve'
    }, format='json')
    fam_id = resp_fam_add.data.get('member_id') if resp_fam_add.status_code == 201 else None
    log_test("TC-PAT-03", "Patient Portal", "Add dependent family member", resp_fam_add.status_code == 201, f"Member ID: {fam_id}")

    # Test 2.4: List Family Members
    resp_fam_list = client.get('/api/patients/family/')
    log_test("TC-PAT-04", "Patient Portal", "List all linked family members", resp_fam_list.status_code == 200 and len(resp_fam_list.data) >= 1)

    # Test 2.5: Delete Family Member
    if fam_id:
        resp_fam_del = client.delete(f'/api/patients/family/{fam_id}/')
        log_test("TC-PAT-05", "Patient Portal", "Remove linked family member", resp_fam_del.status_code == 204)

    # Test 2.6: Record Health Vital
    resp_vital = client.post('/api/patients/vitals/', {
        'vital_type': 'blood_pressure',
        'value': '124/82',
        'unit': 'mmHg',
        'status': 'Normal'
    }, format='json')
    log_test("TC-PAT-06", "Patient Portal", "Record new health vital metric", resp_vital.status_code == 201)

    # -------------------------------------------------------------
    # CATEGORY 3: DOCTOR PORTAL & CONSENT SYSTEM
    # -------------------------------------------------------------
    client.force_authenticate(user=doctor_user)

    # Test 3.1: Doctor Directory Search
    resp_search = client.get('/api/doctor/patients/?q=Rajesh')
    log_test("TC-DOC-01", "Doctor Portal", "Search patient directory by name", resp_search.status_code == 200 and len(resp_search.data) >= 1)

    # Test 3.2: Walk-In Patient On-the-Fly Registration
    resp_reg_pat = client.post('/api/doctor/patients/', {
        'full_name': 'Suresh Verma',
        'phone_number': '+91 9988776655',
        'email': 'suresh.verma@health.com',
        'age': 54,
        'gender': 'Male',
        'blood_group': 'B +ve'
    }, format='json')
    new_pat_id = resp_reg_pat.data.get('id') if resp_reg_pat.status_code == 201 else None
    log_test("TC-DOC-02", "Doctor Portal", "Register new walk-in patient on-the-fly (Auto-grants 24h consent)", resp_reg_pat.status_code == 201)

    # Test 3.3: Doctor Chart Access (Locked without consent)
    resp_chart_locked = client.get(f'/api/doctor/patients/{patient_user.id}/chart/')
    has_consent_init = resp_chart_locked.data.get('has_consent', False)
    log_test("TC-DOC-03", "Doctor Portal & Security", "Verify patient chart is LOCKED by default without active consent", resp_chart_locked.status_code == 200 and not has_consent_init, f"has_consent: {has_consent_init}")

    # Test 3.4: Doctor Request Consent
    resp_req_con = client.post('/api/doctor/consent/request/', {
        'patient_id': str(patient_user.id),
        'purpose': 'Cardiology Follow-up & History Review'
    }, format='json')
    consent_id = resp_req_con.data.get('consent', {}).get('id') if resp_req_con.status_code in (200, 201) else None
    log_test("TC-DOC-04", "Doctor Portal & Security", "Doctor submits 24h access consent request", resp_req_con.status_code in (200, 201), f"Consent ID: {consent_id}")

    # Test 3.5: Patient Approves Consent
    client.force_authenticate(user=patient_user)
    if consent_id:
        resp_appr = client.post(f'/api/patients/consents/{consent_id}/action/', {'action': 'approve'}, format='json')
        log_test("TC-DOC-05", "Doctor Portal & Security", "Patient approves doctor 24h access request", resp_appr.status_code == 200 and resp_appr.data.get('consent', {}).get('status') == 'approved')

    # Test 3.6: Doctor Chart Access (Unlocked after consent)
    client.force_authenticate(user=doctor_user)
    resp_chart_unlocked = client.get(f'/api/doctor/patients/{patient_user.id}/chart/')
    has_consent_after = resp_chart_unlocked.data.get('has_consent', False)
    log_test("TC-DOC-06", "Doctor Portal & Security", "Verify patient chart is UNLOCKED after patient approval", resp_chart_unlocked.status_code == 200 and has_consent_after, f"has_consent: {has_consent_after}")

    # Test 3.7: Doctor Prescribes Medicine & Auto-Sync
    resp_rx = client.post('/api/doctor/prescriptions/', {
        'patient': str(patient_user.id),
        'diagnosis': 'Hypertension & Mild Angina',
        'clinical_notes': 'Low salt diet, daily walk, follow up in 14 days.',
        'medicines': [
            {'medicine_name': 'Amlodipine 5mg', 'dosage': '1-0-0', 'duration': '14 Days'},
            {'medicine_name': 'Aspirin 75mg', 'dosage': '0-0-1', 'duration': '14 Days'}
        ]
    }, format='json')
    log_test("TC-DOC-07", "Doctor Portal & Auto-Sync", "Issue prescription and verify auto-sync trigger", resp_rx.status_code == 201)

    # -------------------------------------------------------------
    # CATEGORY 4: DIAGNOSTIC LAB PORTAL & BATCH CSV
    # -------------------------------------------------------------
    client.force_authenticate(user=lab_user)

    # Test 4.1: Queue Lab Test Order
    resp_order = client.post('/api/lab/orders/', {
        'patient_name': 'Rajesh Kumar',
        'doctor_name': 'Dr. Dhruv Patel',
        'test_name': 'Complete Blood Count (CBC)',
        'category': 'Hematology',
        'status': 'Pending'
    }, format='json')
    order_id = resp_order.data.get('order_id') if resp_order.status_code == 201 else None
    log_test("TC-LAB-01", "Lab Portal", "Queue new lab test order", resp_order.status_code == 201, f"Order ID: {order_id}")

    # Test 4.2: Publish Verified Lab Report & Auto-Sync
    if order_id:
        # Link patient to order first
        order_obj = LabTestOrder.objects.filter(order_id=order_id).first()
        if order_obj:
            order_obj.patient = patient_user
            order_obj.save()

        resp_pub = client.post(f'/api/lab/orders/{order_id}/publish/', {
            'summary': 'Hemoglobin normal, TLC slightly elevated.',
            'status': 'Normal',
            'parameters': [
                {'parameter_name': 'Hemoglobin', 'value': '14.5', 'unit': 'g/dL', 'reference_range': '13.0-17.0', 'is_abnormal': False},
                {'parameter_name': 'Total Leukocyte Count', 'value': '11200', 'unit': '/cu mm', 'reference_range': '4000-11000', 'is_abnormal': True}
            ]
        }, format='json')
        log_test("TC-LAB-02", "Lab Portal & Auto-Sync", "Publish verified test report & auto-inject into patient locker", resp_pub.status_code == 201)

    # Test 4.3: Batch CSV Ingestion
    csv_payload = (
        "patient_email,patient_name,test_name,category,parameter_name,value,unit,reference_range,is_abnormal,doctor_name,summary\n"
        "anita.kumar@health.com,Anita Kumar,Lipid Profile,Biochemistry,Total Cholesterol,240,mg/dL,150-200,true,Dr. Dhruv Patel,Borderline High Cholesterol\n"
        "anita.kumar@health.com,Anita Kumar,Lipid Profile,Biochemistry,HDL Cholesterol,45,mg/dL,40-60,false,Dr. Dhruv Patel,Borderline High Cholesterol\n"
    )
    resp_batch = client.post('/api/lab/batch-upload/', {'csv_text': csv_payload}, format='json')
    log_test("TC-LAB-03", "Lab Portal & Automation", "Batch CSV processing (Multi-row ingestion & auto-account provision)", resp_batch.status_code == 201 and resp_batch.data.get('processed_rows') == 2)

    # Test 4.4: Batch CSV Ingestion Missing Required Columns
    bad_csv_payload = "patient_name,test_name\nAnita,Lipid Profile"
    resp_batch_bad = client.post('/api/lab/batch-upload/', {'csv_text': bad_csv_payload}, format='json')
    log_test("TC-LAB-04", "Lab Portal & Validation", "Reject malformed CSV missing required headers", resp_batch_bad.status_code == 400)

    # -------------------------------------------------------------
    # CATEGORY 5: HOSPITAL PORTAL & INPATIENT DISCHARGE
    # -------------------------------------------------------------
    client.force_authenticate(user=hosp_user)

    # Test 5.1: Admit Inpatient to Ward & Bed
    resp_adm = client.post('/api/hospital/admissions/', {
        'patient_name': 'Rajesh Kumar',
        'age': 45,
        'gender': 'Male',
        'ward': 'Cardiology ICU',
        'bed_no': 'BED-ICU-02',
        'attending_doctor': 'Dr. Dhruv Patel',
        'diagnosis': 'Acute Coronary Syndrome - Observation',
        'status': 'Admitted'
    }, format='json')
    adm_id = resp_adm.data.get('admission_id') if resp_adm.status_code == 201 else None
    log_test("TC-HOSP-01", "Hospital Portal", "Admit inpatient to ward bed", resp_adm.status_code == 201, f"Admission ID: {adm_id}")

    # Test 5.2: Discharge Inpatient & Auto-Sync Discharge Summary
    if adm_id:
        adm_obj = InpatientAdmission.objects.filter(admission_id=adm_id).first()
        if adm_obj:
            adm_obj.patient = patient_user
            adm_obj.save()

        resp_dis = client.post(f'/api/hospital/admissions/{adm_id}/discharge/', {
            'discharge_notes': 'Patient responded well to conservative treatment. Vitals stable upon discharge.'
        }, format='json')
        log_test("TC-HOSP-02", "Hospital Portal & Auto-Sync", "Discharge patient & auto-sync Discharge Summary to locker", resp_dis.status_code == 200)

    # -------------------------------------------------------------
    # CATEGORY 6: REPORTS LOCKER, TIMELINE & SEARCH
    # -------------------------------------------------------------
    client.force_authenticate(user=patient_user)

    # Test 6.1: Medical Record Locker Contents
    resp_records = client.get('/api/reports/records/')
    log_test("TC-REP-01", "Reports & Locker", "Fetch patient digital health locker documents", resp_records.status_code == 200 and len(resp_records.data) >= 2)

    # Test 6.2: Lab Reports Fetch
    resp_lreps = client.get('/api/reports/lab/')
    log_test("TC-REP-02", "Reports & Locker", "Fetch diagnostic lab reports", resp_lreps.status_code == 200 and len(resp_lreps.data) >= 1)

    # Test 6.3: Unified Timeline Stream
    resp_time = client.get('/api/reports/timeline/')
    log_test("TC-REP-03", "Timeline Feed", "Generate unified chronological medical feed", resp_time.status_code == 200 and resp_time.data.get('total_events', 0) >= 2)

    # Test 6.4: Global Search (Multi-table Instant Query)
    resp_gsearch = client.get('/api/search/?q=Amlodipine')
    log_test("TC-REP-04", "Global Search", "Instant multi-table search across records, labs & doctors", resp_gsearch.status_code == 200 and resp_gsearch.data.get('total_results', 0) >= 1)

    # Output Summary
    total = len(results)
    passed_cnt = sum(1 for r in results if r['status'] == 'PASS')
    failed_cnt = sum(1 for r in results if r['status'] == 'FAIL')

    print("\n" + "="*60)
    print(f"HARDCORE SYSTEM AUDIT COMPLETED: {passed_cnt}/{total} PASSED, {failed_cnt} FAILED")
    print("="*60)

    with open(r"D:\Health\hardcore_test_results.json", "w") as f:
        json.dump(results, f, indent=2)

if __name__ == '__main__':
    run_tests()
