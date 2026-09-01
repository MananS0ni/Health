import '../shared/models/family_member.dart';

class MockFamily {
  static List<FamilyMember> getFamilyMembers() {
    return [
      FamilyMember(
        memberId: 'FAM001',
        patientId: 'PAT002',
        fullName: 'Sunita Sharma',
        relationship: 'Spouse',
        dateOfBirth: '1992-08-24',
        gender: 'Female',
        bloodGroup: 'O+',
        totalRecords: 8,
      ),
      FamilyMember(
        memberId: 'FAM002',
        patientId: 'PAT003',
        fullName: 'Aarav Sharma',
        relationship: 'Son',
        dateOfBirth: '2018-11-10',
        gender: 'Male',
        bloodGroup: 'B+',
        totalRecords: 4,
      ),
      FamilyMember(
        memberId: 'FAM003',
        patientId: 'PAT004',
        fullName: 'Ramesh Sharma',
        relationship: 'Father',
        dateOfBirth: '1962-03-12',
        gender: 'Male',
        bloodGroup: 'A+',
        totalRecords: 12,
      ),
    ];
  }
}
