class TimelineEvent {
  final String eventId;
  final String patientId;
  final String eventType;
  final String title;
  final String? description;
  final String eventDate;
  final String? facilityName;
  final String? doctorName;
  final Map<String, dynamic>? metadata;

  TimelineEvent({
    required this.eventId,
    required this.patientId,
    required this.eventType,
    required this.title,
    this.description,
    required this.eventDate,
    this.facilityName,
    this.doctorName,
    this.metadata,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      eventId: json['event_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? json['type']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: json['event_date']?.toString() ?? json['date']?.toString() ?? '',
      facilityName: json['facility_name'] ?? json['facility'],
      doctorName: json['doctor_name'] ?? json['doctor'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'patient_id': patientId,
      'event_type': eventType,
      'title': title,
      'description': description,
      'event_date': eventDate,
      'facility_name': facilityName,
      'doctor_name': doctorName,
      'metadata': metadata,
    };
  }
}
