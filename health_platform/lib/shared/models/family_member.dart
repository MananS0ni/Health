class FamilyMember {
  final String memberId;
  final String patientId;
  final String fullName;
  final String relationship;
  final String dateOfBirth;
  final String gender;
  final String bloodGroup;
  final int totalRecords;

  FamilyMember({
    required this.memberId,
    required this.patientId,
    required this.fullName,
    required this.relationship,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodGroup,
    required this.totalRecords,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      memberId: json['member_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      relationship: json['relationship'] ?? '',
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      gender: json['gender'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      totalRecords: json['total_records'] is int
          ? json['total_records'] as int
          : int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'patient_id': patientId,
      'full_name': fullName,
      'relationship': relationship,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_group': bloodGroup,
      'total_records': totalRecords,
    };
  }
}
