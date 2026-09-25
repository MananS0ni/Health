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

  String get orgName => organizationName;

  Map<String, dynamic> toJson() => {
        'organization_name': organizationName,
        'employee_id': employeeId,
      };
}

class User {
  final String id;
  final String? patientId;
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
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> currentMedications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const User({
    required this.id,
    this.patientId,
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
    this.allergies = const [],
    this.medicalConditions = const [],
    this.currentMedications = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  bool get isDoctor => roles.contains('doctor');
  bool get isLabStaff => roles.contains('lab_staff') || roles.contains('lab');
  bool get isHospitalStaff => roles.contains('hospital_staff') || roles.contains('hospital');
  bool get isAdmin => roles.contains('admin');
  bool get hasProRole => isDoctor || isLabStaff || isHospitalStaff || isAdmin;

  /// Convenience — first non-patient role, or null.
  String? get primaryProRole {
    for (final r in roles) {
      if (r != 'patient') return r;
    }
    return null;
  }

  User copyWith({
    String? id,
    String? patientId,
    String? fullName,
    String? email,
    String? phoneNumber,
    List<String>? roles,
    bool? isVerified,
    DoctorProfile? doctorProfile,
    OrgProfile? orgProfile,
    String? bloodGroup,
    String? dateOfBirth,
    String? gender,
    String? address,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return User(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      isVerified: isVerified ?? this.isVerified,
      doctorProfile: doctorProfile ?? this.doctorProfile,
      orgProfile: orgProfile ?? this.orgProfile,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesList = <String>[];
    final rolesRaw = json['roles'];
    if (rolesRaw is List) {
      rolesList.addAll(rolesRaw.map((e) => e.toString()));
    }
    if (json['role'] != null) {
      final r = json['role'].toString();
      if (!rolesList.contains(r)) rolesList.add(r);
    }
    if (rolesList.contains('lab') && !rolesList.contains('lab_staff')) rolesList.add('lab_staff');
    if (rolesList.contains('lab_staff') && !rolesList.contains('lab')) rolesList.add('lab');
    if (rolesList.contains('hospital') && !rolesList.contains('hospital_staff')) rolesList.add('hospital_staff');
    if (rolesList.contains('hospital_staff') && !rolesList.contains('hospital')) rolesList.add('hospital');
    if (!rolesList.contains('patient')) rolesList.insert(0, 'patient');
    final roles = rolesList;

    final allergiesRaw = json['allergies'];
    final allergies = allergiesRaw is List
        ? List<String>.from(allergiesRaw)
        : <String>[];

    final conditionsRaw = json['medical_conditions'];
    final conditions = conditionsRaw is List
        ? List<String>.from(conditionsRaw)
        : <String>[];

    final medsRaw = json['current_medications'];
    final meds = medsRaw is List
        ? List<String>.from(medsRaw)
        : <String>[];

    final rawId = json['id'] as String? ?? '';
    final computedPid = json['patient_id'] as String? ??
        (rawId.isNotEmpty
            ? 'PAT-${rawId.replaceAll('-', '').padRight(6).substring(0, 6).toUpperCase()}'
            : 'PAT-LOCAL');

    return User(
      id: rawId,
      patientId: computedPid,
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
      allergies: allergies,
      medicalConditions: conditions,
      currentMedications: meds,
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
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
        'allergies': allergies,
        'medical_conditions': medicalConditions,
        'current_medications': currentMedications,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
      };
}
