import '../../shared/models/medical_record.dart';

class MockRecords {
  static List<MedicalRecord> getRecords() {
    return [
      MedicalRecord(
        recordId: 'REC001',
        patientId: 'PAT001',
        recordType: 'prescription',
        title: 'Prescription - Annual Checkup',
        description: 'Medications prescribed for annual health checkup',
        recordDate: '2024-01-15',
        facilityName: 'City General Hospital',
        doctorName: 'Dr. Priya Patel',
        attachments: ['prescription_jan15.pdf'],
      ),
      MedicalRecord(
        recordId: 'REC002',
        patientId: 'PAT001',
        recordType: 'discharge_summary',
        title: 'Discharge Summary - Appendix Surgery',
        description: 'Post-operative care instructions and summary',
        recordDate: '2023-11-20',
        facilityName: 'Apollo Hospital',
        doctorName: 'Dr. Rajesh Kumar',
        attachments: ['discharge_summary.pdf', 'care_instructions.pdf'],
      ),
      MedicalRecord(
        recordId: 'REC003',
        patientId: 'PAT001',
        recordType: 'imaging',
        title: 'X-Ray - Chest PA View',
        description: 'Chest X-ray for routine examination',
        recordDate: '2023-08-10',
        facilityName: 'Diagno Labs',
        doctorName: 'Dr. Suresh Reddy',
        attachments: ['xray_chest_aug10.jpg'],
      ),
      MedicalRecord(
        recordId: 'REC004',
        patientId: 'PAT001',
        recordType: 'vaccination',
        title: 'COVID-19 Booster Dose',
        description: 'COVID-19 vaccination record - booster dose',
        recordDate: '2023-06-15',
        facilityName: 'Primary Health Center',
        doctorName: 'Dr. Anita Desai',
        attachments: ['vaccination_certificate.pdf'],
      ),
      MedicalRecord(
        recordId: 'REC005',
        patientId: 'PAT001',
        recordType: 'prescription',
        title: 'Prescription - Flu Treatment',
        description: 'Antibiotics and supportive care for viral fever',
        recordDate: '2023-03-22',
        facilityName: 'City Clinic',
        doctorName: 'Dr. Vikram Singh',
        attachments: ['prescription_mar22.pdf'],
      ),
    ];
  }
}
