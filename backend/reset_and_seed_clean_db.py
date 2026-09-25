import os
import shutil
import uuid
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.conf import settings
from apps.accounts.models import User, Role, DoctorProfile, LabProfile, HospitalProfile, EmailOTP
from apps.patients.models import PatientProfile, HealthVital, FamilyMember
from apps.doctor.models import Appointment, Prescription, PrescriptionItem, ConsentRequest
from apps.reports.models import MedicalRecord, LabReport, TestParameter
from apps.hospital.models import InpatientAdmission
from apps.lab.models import LabTestOrder

def reset_and_seed():
    print("--- 1. Purging all existing operational data ---")
    TestParameter.objects.all().delete()
    LabReport.objects.all().delete()
    MedicalRecord.objects.all().delete()
    InpatientAdmission.objects.all().delete()
    LabTestOrder.objects.all().delete()
    PrescriptionItem.objects.all().delete()
    Prescription.objects.all().delete()
    Appointment.objects.all().delete()
    ConsentRequest.objects.all().delete()
    HealthVital.objects.all().delete()
    FamilyMember.objects.all().delete()
    PatientProfile.objects.all().delete()
    DoctorProfile.objects.all().delete()
    LabProfile.objects.all().delete()
    HospitalProfile.objects.all().delete()
    EmailOTP.objects.all().delete()

    # Clear media storage files
    media_root = settings.MEDIA_ROOT
    if os.path.exists(media_root):
        for sub in ['reports', 'records']:
            sub_path = os.path.join(media_root, sub)
            if os.path.exists(sub_path):
                shutil.rmtree(sub_path)
            os.makedirs(sub_path, exist_ok=True)
        print(f"Cleaned media storage at: {media_root}")

    # Delete all users
    user_count = User.objects.count()
    User.objects.all().delete()
    print(f"Deleted {user_count} previous users.")

    print("\n--- 2. Seeding fresh core platform accounts ---")

    # 1. Admin
    admin_user = User.objects.create(
        email='admin@health.com',
        full_name='System Administrator',
        phone_number='+91 99999 00000',
        role=Role.ADMIN,
        roles=['admin', 'patient', 'doctor', 'hospital', 'lab'],
        is_staff=True,
        is_superuser=True,
        is_verified=True,
    )
    admin_user.set_password('Admin@123')
    admin_user.save()
    print(f"Created Admin: {admin_user.email} (Password: Admin@123)")

    # 2. Patient: Manan Soni
    patient_uuid = uuid.UUID('4726a2de-10aa-4765-b19c-bcaf30b827b9')
    patient_user = User.objects.create(
        id=patient_uuid,
        email='manansoni2905@gmail.com',
        full_name='Manan Soni',
        phone_number='+91 98765 43210',
        role=Role.PATIENT,
        roles=['patient', 'doctor', 'hospital', 'lab', 'admin'],
        is_staff=True,
        is_verified=True,
    )
    patient_user.set_unusable_password()
    patient_user.save()

    PatientProfile.objects.create(
        user=patient_user,
        blood_group='O+',
        gender='Male',
        date_of_birth='2002-05-29',
        address='Ahmedabad, Gujarat, India',
        allergies=['Penicillin', 'Peanuts'],
        medical_conditions=['Mild Asthma'],
        emergency_contact_name='Rajesh Soni',
        emergency_contact_phone='+91 98765 11111',
        emergency_contact_relation='Father',
    )
    print(f"Created Patient: {patient_user.full_name} ({patient_user.email}) -> PID: PAT-{str(patient_uuid)[:6].upper()}")

    # 3. Doctor: Dr. Parthil Rana
    doctor_user = User.objects.create(
        email='23ci2020115@gmail.com',
        full_name='Dr. Parthil Rana',
        phone_number='+91 98765 12345',
        role=Role.DOCTOR,
        roles=['doctor'],
        is_verified=True,
    )
    doctor_user.set_unusable_password()
    doctor_user.save()

    DoctorProfile.objects.create(
        user=doctor_user,
        registration_number='GMC-2021-9481',
        specialization='Cardiologist',
        clinic_name='Apex Heart & Multispeciality',
    )
    print(f"Created Doctor: {doctor_user.full_name} ({doctor_user.email})")

    # 4. Lab: Apex Diagnostic Hub
    lab_user = User.objects.create(
        email='23ci2020125@gmail.com',
        full_name='Apex Diagnostic Hub',
        phone_number='+91 98765 88888',
        role=Role.LAB,
        roles=['lab'],
        is_verified=True,
    )
    lab_user.set_unusable_password()
    lab_user.save()

    LabProfile.objects.create(
        user=lab_user,
        lab_name='Apex Diagnostic Hub',
        license_number='LAB-GJ-2022-881',
        address='101 Medical Enclave, Health City',
    )
    print(f"Created Lab: {lab_user.full_name} ({lab_user.email})")

    # 5. Hospital: City Multispeciality Hospital
    hospital_user = User.objects.create(
        email='city.hospital@health.com',
        full_name='City Multispeciality Hospital',
        phone_number='+91 98765 99999',
        role=Role.HOSPITAL,
        roles=['hospital'],
        is_verified=True,
    )
    hospital_user.set_unusable_password()
    hospital_user.save()

    HospitalProfile.objects.create(
        user=hospital_user,
        hospital_name='City Multispeciality Hospital',
        registration_id='HOSP-REG-4491',
        departments='Emergency, Cardiology, Orthopedics, General Medicine',
    )
    print(f"Created Hospital: {hospital_user.full_name} ({hospital_user.email})")

    print("\n--- 3. Platform Fresh Start Complete ---")
    print(f"Total Users: {User.objects.count()}")
    print(f"Total Records: {MedicalRecord.objects.count()}")
    print(f"Total Lab Reports: {LabReport.objects.count()}")
    print(f"Total Inpatient Admissions: {InpatientAdmission.objects.count()}")

if __name__ == '__main__':
    reset_and_seed()
