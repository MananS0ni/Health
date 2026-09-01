class MockLabData {
  static List<Map<String, dynamic>> getPendingReports() {
    return [
      {
        'order_id': 'LAB_801',
        'patient_id': 'PAT001',
        'patient_name': 'Rahul Sharma',
        'phone_number': '9876543210',
        'test_name': 'Comprehensive Lipid Panel',
        'category': 'Biochemistry',
        'ordered_by': 'Dr. Max Patel',
        'ordered_date': '2026-08-07 08:30 AM',
        'urgency': 'Normal',
        'status': 'Sample Collected',
      },
      {
        'order_id': 'LAB_802',
        'patient_id': 'PAT002',
        'patient_name': 'Sunita Sharma',
        'phone_number': '9876543211',
        'test_name': 'Thyroid Profile (T3, T4, TSH)',
        'category': 'Endocrinology',
        'ordered_by': 'Dr. Max Patel',
        'ordered_date': '2026-08-07 09:15 AM',
        'urgency': 'Normal',
        'status': 'Testing In Progress',
      },
      {
        'order_id': 'LAB_803',
        'patient_id': 'PAT005',
        'patient_name': 'Vikram Malhotra',
        'phone_number': '9988776655',
        'test_name': 'Cardiac Troponin I',
        'category': 'Cardiology',
        'ordered_by': 'Dr. S. K. Gupta',
        'ordered_date': '2026-08-07 10:00 AM',
        'urgency': 'Urgent',
        'status': 'Ready to Upload',
      },
      {
        'order_id': 'LAB_804',
        'patient_id': 'PAT006',
        'patient_name': 'Ananya Roy',
        'phone_number': '9123456789',
        'test_name': 'HbA1c & Fasting Glucose',
        'category': 'Diabetology',
        'ordered_by': 'Dr. R. Mehta',
        'ordered_date': '2026-08-06 04:45 PM',
        'urgency': 'Normal',
        'status': 'Sample Collected',
      },
      {
        'order_id': 'LAB_805',
        'patient_id': 'PAT007',
        'patient_name': 'Karan Verma',
        'phone_number': '9811223344',
        'test_name': 'Serum Creatinine & Electrolytes',
        'category': 'Nephrology',
        'ordered_by': 'Dr. Max Patel',
        'ordered_date': '2026-08-06 02:20 PM',
        'urgency': 'Urgent',
        'status': 'Ready to Upload',
      },
    ];
  }

  static Map<String, dynamic> getLabStats() {
    return {
      'processed_today': 38,
      'pending_queue': 5,
      'critical_alerts': 1,
      'lims_sync_status': 'Healthy',
      'lims_last_sync': '2 mins ago',
      'lims_uptime': '99.9%',
    };
  }

  static List<Map<String, dynamic>> getLimsSyncLogs() {
    return [
      {
        'time': '13:25:10',
        'event': 'HL7 ORU_R01 Message Transmitted',
        'order_id': 'LAB_799',
        'status': 'SUCCESS',
        'response_code': 200,
      },
      {
        'time': '13:10:04',
        'event': 'Auto-Sync Completed (14 records)',
        'order_id': 'BATCH_88',
        'status': 'SUCCESS',
        'response_code': 200,
      },
      {
        'time': '12:45:30',
        'event': 'PDF Report Storage Sync (GCS Bucket)',
        'order_id': 'LAB_795',
        'status': 'SUCCESS',
        'response_code': 201,
      },
      {
        'time': '12:00:15',
        'event': 'LIMS Gateway Heartbeat',
        'order_id': 'SYSTEM',
        'status': 'HEALTHY',
        'response_code': 200,
      },
    ];
  }
}
