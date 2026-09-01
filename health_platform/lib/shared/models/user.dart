// Sub-profiles and user model for the HealthRecord platform.
library;

class DoctorProfile {
  final String registrationNumber;
  final String specialization;
  final String? clinicName;

  const DoctorProfile({
    required this.registrationNumber,
    required this.specialization,
    this.clinicName,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) => DoctorProfile(
        registrationNumber: json['registration_number'] ?? '',
        specialization: json['specialization'] ?? '',
        clinicName: json['clinic_name'],
      );

  Map<String, dynamic> toJson() => {
        'registration_number': registrationNumber,
        'specialization': specialization,
        'clinic_name': clinicName,
      };
}

class OrgProfile {
  final String organizationName;
  final String? employeeId;

  const OrgProfile({
    required this.organizationName,
    this.employeeId,
  });

  factory OrgProfile.fromJson(Map<String, dynamic> json) => OrgProfile(
        organizationName: json['organization_name'] ?? '',
        employeeId: json['employee_id'],
      );

  Map<String, dynamic> toJson() => {
        'organization_name': organizationName,
        'employee_id': employeeId,
      };
}

class User {
  final String id;
  final String fullName;
  final String? email;
  final String phoneNumber;
  final List<String> roles; // e.g. ["patient"], ["patient","doctor"]
  final bool isVerified;

  // Professional sub-profiles (null if role not present)
  final DoctorProfile? doctorProfile;
  final OrgProfile? orgProfile; // shared for lab_staff / hospital_staff

  // Health / personal fields
  final String? bloodGroup;
  final String? dateOfBirth;
  final String? gender;
  final String? address;

  const User({
    required this.id,
    required this.fullName,
    this.email,
    required this.phoneNumber,
    required this.roles,
    this.isVerified = false,
    this.doctorProfile,
    this.orgProfile,
    this.bloodGroup,
    this.dateOfBirth,
    this.gender,
    this.address,
  });

  bool get isDoctor => roles.contains('doctor');
  bool get isLabStaff => roles.contains('lab_staff');
  bool get isHospitalStaff => roles.contains('hospital_staff');
  bool get hasProRole => isDoctor || isLabStaff || isHospitalStaff;

  /// Convenience — first non-patient role, or null.
  String? get primaryProRole {
    for (final r in roles) {
      if (r != 'patient') return r;
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final roles = rolesRaw is List
        ? List<String>.from(rolesRaw)
        : <String>['patient'];

    return User(
      id: json['id'] ?? json['patient_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? '',
      roles: roles,
      isVerified: json['is_verified'] ?? false,
      doctorProfile: json['doctor_profile'] != null
          ? DoctorProfile.fromJson(json['doctor_profile'])
          : null,
      orgProfile: json['org_profile'] != null
          ? OrgProfile.fromJson(json['org_profile'])
          : null,
      bloodGroup: json['blood_group'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'roles': roles,
        'is_verified': isVerified,
        'doctor_profile': doctorProfile?.toJson(),
        'org_profile': orgProfile?.toJson(),
        'blood_group': bloodGroup,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'address': address,
      };
}
