class MedicalRecord {
  final String recordId;
  final String patientId;
  final String recordType;
  final String title;
  final String? description;
  final String recordDate;
  final String? facilityName;
  final String? doctorName;
  final List<String>? attachments;

  MedicalRecord({
    required this.recordId,
    required this.patientId,
    required this.recordType,
    required this.title,
    this.description,
    required this.recordDate,
    this.facilityName,
    this.doctorName,
    this.attachments,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      recordId: json['record_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      recordType: json['record_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      recordDate: json['record_date'] ?? '',
      facilityName: json['facility_name'],
      doctorName: json['doctor_name'],
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'patient_id': patientId,
      'record_type': recordType,
      'title': title,
      'description': description,
      'record_date': recordDate,
      'facility_name': facilityName,
      'doctor_name': doctorName,
      'attachments': attachments,
    };
  }
}
