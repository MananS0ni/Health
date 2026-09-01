class MockDashboard {
  static List<Map<String, dynamic>> getUpcomingAppointments() {
    return [
      {
        'appointment_id': 'APT001',
        'doctor_name': 'Dr. Priya Patel',
        'specialization': 'General Physician',
        'appointment_date': '2024-02-20',
        'appointment_time': '10:30 AM',
        'facility_name': 'City General Hospital',
        'reason': 'Follow-up - Lipid Profile',
      },
      {
        'appointment_id': 'APT002',
        'doctor_name': 'Dr. Rajesh Kumar',
        'specialization': 'Surgeon',
        'appointment_date': '2024-03-15',
        'appointment_time': '2:00 PM',
        'facility_name': 'Apollo Hospital',
        'reason': 'Post-surgery checkup',
      },
    ];
  }

  static List<Map<String, dynamic>> getAlerts() {
    return [
      {
        'alert_id': 'ALT001',
        'alert_type': 'medication_reminder',
        'title': 'Medication Reminder',
        'message': 'Take Vitamin D supplement after lunch',
        'priority': 'medium',
        'due_date': '2024-01-20',
      },
      {
        'alert_id': 'ALT002',
        'alert_type': 'health_alert',
        'title': 'Health Alert',
        'message': 'Cholesterol levels elevated. Schedule follow-up with cardiologist.',
        'priority': 'high',
        'due_date': '2024-01-25',
      },
      {
        'alert_id': 'ALT003',
        'alert_type': 'appointment_reminder',
        'title': 'Appointment Reminder',
        'message': 'Dr. Priya Patel appointment on Feb 20 at 10:30 AM',
        'priority': 'low',
        'due_date': '2024-02-20',
      },
    ];
  }

  static Map<String, dynamic> getHealthSummary() {
    return {
      'total_records': 5,
      'total_reports': 5,
      'upcoming_appointments': 2,
      'active_alerts': 3,
      'last_checkup': '2024-01-15',
    };
  }
}
