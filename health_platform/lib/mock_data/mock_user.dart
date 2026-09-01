import '../../shared/models/user.dart';

class MockUser {
  static User getCurrentUser() {
    return const User(
      id: 'usr_001',
      fullName: 'Max Patel',
      phoneNumber: '9998887776',
      email: null,
      roles: ['patient', 'doctor', 'lab_staff', 'hospital_staff'],
      isVerified: true,
      doctorProfile: DoctorProfile(
        registrationNumber: 'MH-12345',
        specialization: 'General Physician',
        clinicName: 'Apollo Clinic',
      ),
      orgProfile: OrgProfile(
        organizationName: 'Metropolis & Apollo Healthcare Hub',
        employeeId: 'EMP-9901',
      ),
      bloodGroup: 'O+',
      dateOfBirth: '1990-05-15',
      gender: 'Male',
      address: '12, Linking Road, Bandra West, Mumbai 400050',
    );
  }

  /// A pure patient user — no professional role.
  static User getPatientUser() {
    return const User(
      id: 'usr_002',
      fullName: 'Priya Singh',
      phoneNumber: '9876543210',
      email: 'priya.singh@example.com',
      roles: ['patient'],
      isVerified: true,
      bloodGroup: 'A+',
      dateOfBirth: '1995-08-22',
      gender: 'Female',
      address: '45, MG Road, Bengaluru 560001',
    );
  }
}
