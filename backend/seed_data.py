import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.accounts.models import CustomUser
from apps.patients.models import PatientProfile
from apps.reports.models import LabReport
from apps.consent.models import ConsentPermission
from apps.timeline.models import TimelineEvent

def seed():
    print("Seeding initial data into Django database (No ABHA ID)...")

    user, created = CustomUser.objects.get_or_create(
        phone='+91 9876543210',
        defaults={
            'full_name': 'Manan Soni',
            'role': 'PATIENT',
            'is_verified': True
        }
    )

    profile, _ = PatientProfile.objects.get_or_create(
        user=user,
        defaults={
            'blood_group': 'O +ve',
            'known_allergies': 'Penicillin, Sulfa Antibiotics',
            'chronic_conditions': 'Mild Asthma',
            'emergency_contact_name': 'Pooja Soni',
            'emergency_contact_phone': '+91 98765 43210',
            'emergency_contact_relation': 'Kin / Spouse'
        }
    )

    LabReport.objects.get_or_create(
        report_id='REP-881',
        defaults={
            'patient': user,
            'title': 'Complete Blood Count (CBC) & Lipid Profile',
            'report_type': 'Blood Test',
            'category': 'Blood Tests',
            'provider': 'Dr. Lal PathLabs',
            'facility_type': 'Diagnostic Lab',
            'doctor_name': 'Dr. A. K. Sharma',
            'status': 'Verified & Synced',
            'source': 'Auto-Pulled via LIS API',
            'summary': 'Hemoglobin (14.2 g/dL) & Cholesterol (185 mg/dL) are in healthy normal ranges.'
        }
    )

    LabReport.objects.get_or_create(
        report_id='REP-742',
        defaults={
            'patient': user,
            'title': 'Annual Heart & ECG Checkup',
            'report_type': 'Heart & ECG',
            'category': 'Prescriptions',
            'provider': 'Max Healthcare Hospital',
            'facility_type': 'Hospital',
            'doctor_name': 'Dr. Ritu Verma (Cardiologist)',
            'status': 'Verified',
            'source': 'Hospital HIS Auto-Push',
            'summary': 'Heart rhythm is normal (72 bpm) and blood pressure is healthy (118/78 mmHg).'
        }
    )

    ConsentPermission.objects.get_or_create(
        consent_id='CNS-8812',
        defaults={
            'patient': user,
            'doctor_name': 'Dr. Ritu Verma',
            'specialty': 'Cardiologist',
            'hospital_name': 'Max Healthcare Hospital',
            'purpose': 'Follow-up Heart Review',
            'scope': 'All Heart & ECG Reports',
            'expires_in': 'Valid for 23 hours',
            'status': 'ACTIVE'
        }
    )

    TimelineEvent.objects.get_or_create(
        title='Blood Sample Collection & Lipid Screening',
        defaults={
            'patient': user,
            'provider': 'Dr. Lal PathLabs (Delhi Central Branch)',
            'event_type': 'Diagnostic Test',
            'event_date': 'August 04, 2026',
            'event_time': '09:30 AM',
            'status': 'Report Issued & Auto-Imported',
            'details': 'Fasted blood sample submitted for Complete Blood Count and Lipid Panel.'
        }
    )

    print("Data seeding complete! Database is ready.")

if __name__ == '__main__':
    seed()
