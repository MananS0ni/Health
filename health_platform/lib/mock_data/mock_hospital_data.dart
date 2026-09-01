class MockHospitalData {
  static List<Map<String, dynamic>> getAdmissions() {
    return [
      {
        'admission_id': 'ADM_501',
        'patient_id': 'PAT001',
        'patient_name': 'Rahul Sharma',
        'age': 34,
        'gender': 'Male',
        'ward': 'General Male Ward',
        'bed_no': 'B-104',
        'admission_date': '2026-08-04',
        'attending_doctor': 'Dr. Max Patel',
        'diagnosis': 'Severe Acute Pharyngitis & Dehydration',
        'status': 'Admitted',
      },
      {
        'admission_id': 'ADM_502',
        'patient_id': 'PAT005',
        'patient_name': 'Vikram Malhotra',
        'age': 48,
        'gender': 'Male',
        'ward': 'ICU Ward 2',
        'bed_no': 'ICU-08',
        'admission_date': '2026-08-06',
        'attending_doctor': 'Dr. S. K. Gupta',
        'diagnosis': 'Acute Coronary Syndrome (Observation)',
        'status': 'Critical Care',
      },
      {
        'admission_id': 'ADM_503',
        'patient_id': 'PAT008',
        'patient_name': 'Meena Deshmukh',
        'age': 62,
        'gender': 'Female',
        'ward': 'Private Ward A',
        'bed_no': 'P-302',
        'admission_date': '2026-08-02',
        'attending_doctor': 'Dr. R. Mehta',
        'diagnosis': 'Post-Op Total Knee Replacement',
        'status': 'Pending Discharge',
      },
      {
        'admission_id': 'ADM_504',
        'patient_id': 'PAT009',
        'patient_name': 'Sanjay Kulkarni',
        'age': 55,
        'gender': 'Male',
        'ward': 'Semi-Private Ward B',
        'bed_no': 'SP-215',
        'admission_date': '2026-08-05',
        'attending_doctor': 'Dr. Max Patel',
        'diagnosis': 'Dengue Fever (Platelet Monitoring)',
        'status': 'Admitted',
      },
    ];
  }

  static List<Map<String, dynamic>> getPendingDischarges() {
    return [
      {
        'discharge_id': 'DIS_201',
        'admission_id': 'ADM_503',
        'patient_name': 'Meena Deshmukh',
        'ward_bed': 'P-302',
        'attending_doctor': 'Dr. R. Mehta',
        'discharge_date': '2026-08-07',
        'summary_status': 'Draft Ready',
      },
      {
        'discharge_id': 'DIS_202',
        'admission_id': 'ADM_498',
        'patient_name': 'Devendra Joshi',
        'ward_bed': 'B-108',
        'attending_doctor': 'Dr. Max Patel',
        'discharge_date': '2026-08-07',
        'summary_status': 'Final Approval Pending',
      },
    ];
  }

  static Map<String, dynamic> getHospitalStats() {
    return {
      'total_beds': 150,
      'occupied_beds': 112,
      'occupancy_rate': '74.6%',
      'admissions_today': 8,
      'discharges_pending': 5,
      'his_sync_status': 'Active',
      'his_last_sync': '1 min ago',
    };
  }

  static List<Map<String, dynamic>> getHisIntegrationLogs() {
    return [
      {
        'timestamp': '13:28:44',
        'system': 'Apex HIS Gateway',
        'event': 'ADT^A01 Admission Message Processed',
        'patient_id': 'PAT009',
        'status': 'SUCCESS',
      },
      {
        'timestamp': '13:15:02',
        'system': 'Bed Management Module',
        'event': 'Bed Status Updated (ICU-08 -> OCCUPIED)',
        'patient_id': 'PAT005',
        'status': 'SUCCESS',
      },
      {
        'timestamp': '12:50:11',
        'system': 'Billing & EHR Sync',
        'event': 'Discharge Summary Export (FHIR Composition)',
        'patient_id': 'PAT003',
        'status': 'SUCCESS',
      },
    ];
  }
}
