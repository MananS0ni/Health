class MockDoctorData {
  static List<Map<String, dynamic>> getAppointments() {
    return [
      {
        'id': 'apt_101',
        'patient_id': 'PAT001',
        'patient_name': 'Rahul Sharma',
        'age': 34,
        'gender': 'Male',
        'time': '09:30 AM',
        'type': 'Follow-up',
        'status': 'Completed',
        'chief_complaint': 'Hypertension evaluation & blood pressure check',
      },
      {
        'id': 'apt_102',
        'patient_id': 'PAT002',
        'patient_name': 'Sunita Sharma',
        'age': 32,
        'gender': 'Female',
        'time': '10:15 AM',
        'type': 'In-Person',
        'status': 'In Progress',
        'chief_complaint': 'Mild fever and routine thyroid checkup',
      },
      {
        'id': 'apt_103',
        'patient_id': 'PAT003',
        'patient_name': 'Aarav Sharma',
        'age': 6,
        'gender': 'Male',
        'time': '11:00 AM',
        'type': 'Pediatric Check',
        'status': 'Scheduled',
        'chief_complaint': 'Seasonal allergy & vaccination inquiry',
      },
      {
        'id': 'apt_104',
        'patient_id': 'PAT005',
        'patient_name': 'Vikram Malhotra',
        'age': 48,
        'gender': 'Male',
        'time': '02:00 PM',
        'type': 'Consultation',
        'status': 'Scheduled',
        'chief_complaint': 'Chest discomfort and lipid panel review',
      },
      {
        'id': 'apt_105',
        'patient_id': 'PAT006',
        'patient_name': 'Ananya Roy',
        'age': 29,
        'gender': 'Female',
        'time': '03:30 PM',
        'type': 'Follow-up',
        'status': 'Scheduled',
        'chief_complaint': 'Migraine tracking & medication adjustment',
      },
    ];
  }

  static List<Map<String, dynamic>> getRecentPatients() {
    return [
      {
        'patient_id': 'PAT001',
        'full_name': 'Rahul Sharma',
        'phone_number': '9876543210',
        'age': 34,
        'gender': 'Male',
        'last_visit': '2026-08-05',
        'last_diagnosis': 'Essential Hypertension',
        'vitals': {'bp': '128/84', 'hr': '72 bpm', 'spo2': '98%', 'temp': '98.6°F'},
      },
      {
        'patient_id': 'PAT002',
        'full_name': 'Sunita Sharma',
        'phone_number': '9876543211',
        'age': 32,
        'gender': 'Female',
        'last_visit': '2026-08-01',
        'last_diagnosis': 'Hypothyroidism',
        'vitals': {'bp': '118/76', 'hr': '68 bpm', 'spo2': '99%', 'temp': '98.4°F'},
      },
      {
        'patient_id': 'PAT005',
        'full_name': 'Vikram Malhotra',
        'phone_number': '9988776655',
        'age': 48,
        'gender': 'Male',
        'last_visit': '2026-07-28',
        'last_diagnosis': 'Hyperlipidemia',
        'vitals': {'bp': '134/88', 'hr': '78 bpm', 'spo2': '97%', 'temp': '98.6°F'},
      },
      {
        'patient_id': 'PAT006',
        'full_name': 'Ananya Roy',
        'phone_number': '9123456789',
        'age': 29,
        'gender': 'Female',
        'last_visit': '2026-07-20',
        'last_diagnosis': 'Chronic Migraine',
        'vitals': {'bp': '112/70', 'hr': '70 bpm', 'spo2': '99%', 'temp': '98.2°F'},
      },
    ];
  }

  static Map<String, dynamic> getPatientDetailRecord(String patientId) {
    return {
      'patient_id': patientId,
      'full_name': 'Rahul Sharma',
      'phone_number': '+91 98765 43210',
      'email': 'rahul.sharma@email.com',
      'age': 34,
      'gender': 'Male',
      'blood_group': 'B+',
      'date_of_birth': '1992-05-15',
      'address': 'Flat 402, Sunshine Apts, Bandra West, Mumbai',
      'allergies': ['Penicillin', 'Dust Mites'],
      'chronic_conditions': ['Hypertension (Stage 1)'],
      'vitals': {
        'blood_pressure': '128/84 mmHg',
        'heart_rate': '72 bpm',
        'spo2': '98%',
        'temperature': '98.6 °F',
        'weight': '74 kg',
        'bmi': '23.8',
      },
      'prescriptions': [
        {
          'date': '2026-08-01',
          'doctor_name': 'Dr. Max Patel',
          'diagnosis': 'Primary Hypertension',
          'medicines': [
            {'name': 'Telmisartan 40mg', 'dosage': '1-0-0 (Morning)', 'duration': '30 days'},
            {'name': 'Amlodipine 5mg', 'dosage': '0-0-1 (Night)', 'duration': '30 days'},
          ],
        },
        {
          'date': '2026-07-10',
          'doctor_name': 'Dr. Max Patel',
          'diagnosis': 'Acute Pharyngitis',
          'medicines': [
            {'name': 'Amoxicillin 500mg', 'dosage': '1-1-1', 'duration': '5 days'},
            {'name': 'Paracetamol 650mg', 'dosage': 'As needed', 'duration': '3 days'},
          ],
        },
      ],
      'recent_lab_reports': [
        {
          'title': 'Complete Blood Count (CBC)',
          'date': '2026-07-25',
          'facility': 'Metropolis Healthcare',
          'status': 'Normal',
        },
        {
          'title': 'Lipid Profile',
          'date': '2026-06-14',
          'facility': 'Dr. Lal PathLabs',
          'status': 'Borderline High',
        },
      ],
    };
  }
}
