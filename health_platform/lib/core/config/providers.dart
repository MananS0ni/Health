import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../shared/models/user.dart';
import '../../shared/models/medical_record.dart';
import '../../shared/models/lab_report.dart';
import '../../shared/models/timeline_event.dart';
import '../../shared/models/family_member.dart';

// ─────────────────────────────────────────────────────────────
// Auth State & Registration
// ─────────────────────────────────────────────────────────────

enum LoginMode { phone, email }

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool otpSent;
  final LoginMode loginMode;
  final String? phoneNumber;
  final String? email;
  final User? user;
  final String? error;

  // Pending signup details inputted by user
  final String? pendingFullName;
  final List<String> pendingRoles;
  final DoctorProfile? pendingDoctorProfile;
  final OrgProfile? pendingOrgProfile;
  final String? pendingBloodGroup;
  final String? devOtp;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    required this.otpSent,
    required this.loginMode,
    this.phoneNumber,
    this.email,
    this.user,
    this.error,
    this.pendingFullName,
    this.pendingRoles = const ['patient'],
    this.pendingDoctorProfile,
    this.pendingOrgProfile,
    this.pendingBloodGroup,
    this.devOtp,
  });

  factory AuthState.initial() => const AuthState(
        isAuthenticated: false,
        isLoading: false,
        otpSent: false,
        loginMode: LoginMode.email,
      );

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? otpSent,
    LoginMode? loginMode,
    String? phoneNumber,
    String? email,
    User? user,
    String? error,
    bool clearError = false,
    String? pendingFullName,
    List<String>? pendingRoles,
    DoctorProfile? pendingDoctorProfile,
    OrgProfile? pendingOrgProfile,
    String? pendingBloodGroup,
    String? devOtp,
    bool clearDevOtp = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      otpSent: otpSent ?? this.otpSent,
      loginMode: loginMode ?? this.loginMode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      pendingFullName: pendingFullName ?? this.pendingFullName,
      pendingRoles: pendingRoles ?? this.pendingRoles,
      pendingDoctorProfile: pendingDoctorProfile ?? this.pendingDoctorProfile,
      pendingOrgProfile: pendingOrgProfile ?? this.pendingOrgProfile,
      pendingBloodGroup: pendingBloodGroup ?? this.pendingBloodGroup,
      devOtp: clearDevOtp ? null : (devOtp ?? this.devOtp),
    );
  }

  /// Display label for whichever credential is currently stored
  String get contactDisplay {
    if (loginMode == LoginMode.phone && phoneNumber != null) {
      return '+91 $phoneNumber';
    }
    return email ?? '';
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.initial();

  void setLoginMode(LoginMode mode) {
    state = state.copyWith(loginMode: mode, clearError: true);
  }

  void setRegistrationDetails({
    required String fullName,
    required String contact,
    required bool isPhone,
    String? phoneNumber,
    required List<String> roles,
    DoctorProfile? doctorProfile,
    OrgProfile? orgProfile,
    String? bloodGroup,
  }) {
    state = state.copyWith(
      pendingFullName: fullName,
      phoneNumber: phoneNumber ?? (isPhone ? contact : null),
      email: isPhone ? null : contact,
      loginMode: isPhone ? LoginMode.phone : LoginMode.email,
      pendingRoles: roles,
      pendingDoctorProfile: doctorProfile,
      pendingOrgProfile: orgProfile,
      pendingBloodGroup: bloodGroup,
      isLoading: true,
      clearError: true,
    );
    if (!isPhone) {
      sendOtpByEmail(contact);
    } else {
      sendOtpByPhone(contact);
    }
  }

  void sendOtpByPhone(String phoneNumber) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      loginMode: LoginMode.phone,
      isLoading: true,
      clearError: true,
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      state = state.copyWith(isLoading: false, otpSent: true);
    });
  }

  Future<void> sendOtpByEmail(String email) async {
    state = state.copyWith(
      email: email,
      loginMode: LoginMode.email,
      isLoading: true,
      clearError: true,
    );
    try {
      final role = state.pendingRoles.isNotEmpty ? state.pendingRoles.first : 'patient';
      final res = await ApiClient().requestOtp(email: email, role: role);
      final devOtp = res['dev_otp'] as String?;
      state = state.copyWith(isLoading: false, otpSent: true, devOtp: devOtp);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        otpSent: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void sendOtp(String phoneNumber) => sendOtpByPhone(phoneNumber);

  Future<void> verifyOtp(String otp) async {
    if (otp.length != 6) {
      state = state.copyWith(
        error: 'Please enter all 6 digits of the OTP.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (state.loginMode == LoginMode.email && state.email != null && state.email!.isNotEmpty) {
      try {
        final role = state.pendingRoles.isNotEmpty ? state.pendingRoles.first : 'patient';
        final res = await ApiClient().verifyOtp(
          email: state.email!,
          otp: otp,
          role: role,
          fullName: state.pendingFullName,
          phoneNumber: state.phoneNumber,
          roles: state.pendingRoles,
          doctorProfile: state.pendingDoctorProfile?.toJson(),
          orgProfile: state.pendingOrgProfile?.toJson(),
        );

        final userData = res['user'] as Map<String, dynamic>?;
        final baseUser = userData != null ? User.fromJson(userData) : null;

        // Ensure all registered roles and sub-profiles are present
        final effectiveRoles = baseUser != null && baseUser.roles.length > 1
            ? baseUser.roles
            : (state.pendingRoles.isNotEmpty ? state.pendingRoles : (baseUser?.roles ?? ['patient']));

        final verifiedUser = (baseUser ??
            User(
              id: 'usr_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
              fullName: state.pendingFullName ?? state.email!,
              email: state.email,
              phoneNumber: state.phoneNumber ?? '',
              roles: effectiveRoles,
              isVerified: true,
            )).copyWith(
          roles: effectiveRoles,
          doctorProfile: baseUser?.doctorProfile ?? state.pendingDoctorProfile,
          orgProfile: baseUser?.orgProfile ?? state.pendingOrgProfile,
          bloodGroup: state.pendingBloodGroup,
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: verifiedUser,
        );

        // Fetch live user data across all portals
        ref.read(recordsProvider.notifier).fetchRecords();
        ref.read(reportsProvider.notifier).fetchReports();
        ref.read(timelineProvider.notifier).fetchTimeline();
        ref.read(familyMembersProvider.notifier).fetchMembers();
        ref.read(upcomingAppointmentsProvider.notifier).fetchAppointments();
        ref.read(doctorAppointmentsProvider.notifier).fetchAppointments();
        ref.read(doctorPatientsProvider.notifier).fetchPatients();
        ref.read(labPendingReportsProvider.notifier).fetchOrders();
        ref.read(hospitalAdmissionsProvider.notifier).fetchAdmissions();
        ref.read(patientConsentsProvider.notifier).fetchConsents();
        ref.read(doctorIncomingRequestsProvider.notifier).fetchRequests();
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } else {
      // Phone / Fallback offline mode
      await Future.delayed(const Duration(milliseconds: 600));
      final enteredName = state.pendingFullName != null && state.pendingFullName!.trim().isNotEmpty
          ? state.pendingFullName!.trim()
          : (state.phoneNumber != null && state.phoneNumber!.isNotEmpty
              ? 'User ${state.phoneNumber}'
              : 'User');

      final realUser = User(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        fullName: enteredName,
        phoneNumber: state.phoneNumber ?? '',
        email: state.email,
        roles: state.pendingRoles.isNotEmpty ? state.pendingRoles : ['patient'],
        isVerified: true,
        doctorProfile: state.pendingDoctorProfile,
        orgProfile: state.pendingOrgProfile,
        bloodGroup: state.pendingBloodGroup,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: realUser,
      );
    }
  }

  void updateCurrentUser(User updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  void logout() {
    ApiClient().logout();
    ref.read(recordsProvider.notifier).reset();
    ref.read(reportsProvider.notifier).reset();
    ref.read(timelineProvider.notifier).reset();
    ref.read(familyMembersProvider.notifier).reset();
    ref.read(upcomingAppointmentsProvider.notifier).reset();
    ref.read(alertsProvider.notifier).reset();
    ref.read(linkedProvidersProvider.notifier).reset();
    ref.read(doctorAppointmentsProvider.notifier).reset();
    ref.read(doctorPatientsProvider.notifier).reset();
    ref.read(labPendingReportsProvider.notifier).reset();
    ref.read(hospitalAdmissionsProvider.notifier).reset();
    ref.read(patientConsentsProvider.notifier).reset();
    ref.read(doctorIncomingRequestsProvider.notifier).reset();
    state = AuthState.initial();
  }


  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

// ─────────────────────────────────────────────────────────────
// Active Role Context (patient vs professional view)
// ─────────────────────────────────────────────────────────────

class ActiveRoleNotifier extends Notifier<String> {
  @override
  String build() => 'patient';

  void setRole(String role) => state = role;
}

final activeRoleProvider = NotifierProvider<ActiveRoleNotifier, String>(
  ActiveRoleNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// User Provider
// ─────────────────────────────────────────────────────────────

final userProvider = Provider<User>((ref) {
  final authState = ref.watch(authStateProvider);
  final User user;
  if (authState.user != null) {
    user = authState.user!;
  } else {
    final activeRole = ref.watch(activeRoleProvider);
    if (activeRole == 'doctor') {
      user = const User(
        id: 'ab948105-1d21-4e60-9a86-d09884364c73',
        fullName: 'Dr. Rana Parthil',
        email: '23ci2020115@gmail.com',
        phoneNumber: '+91 98765 12345',
        roles: ['doctor'],
        isVerified: true,
      );
    } else {
      user = const User(
        id: '4726a2de-10aa-4765-b19c-bcaf30b827b9',
        fullName: 'Manan Soni',
        email: 'manansoni2905@gmail.com',
        phoneNumber: '+91 98765 43210',
        roles: ['patient', 'doctor', 'hospital', 'lab', 'admin'],
        isVerified: true,
      );
    }
  }
  ApiClient().currentUserEmail = user.email;
  return user;
});

// ─────────────────────────────────────────────────────────────
// Dynamic Data Notifiers (Connected to Django Backend API)
// ─────────────────────────────────────────────────────────────

// Medical Records
class RecordsNotifier extends Notifier<List<MedicalRecord>> {
  @override
  List<MedicalRecord> build() {
    fetchRecords();
    return [];
  }

  Future<void> fetchRecords() async {
    try {
      final list = await ApiClient().getRecords();
      if (list.isNotEmpty) {
        state = list.map((item) => MedicalRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> addRecord(MedicalRecord record) async {
    state = [record, ...state];
    try {
      await ApiClient().createRecord({
        'title': record.title,
        'record_type': record.recordType,
        'record_date': record.recordDate,
        'facility_name': record.facilityName,
        'doctor_name': record.doctorName,
        'description': record.description,
      });
      await fetchRecords();
    } catch (_) {}
  }

  void deleteRecord(String recordId) {
    state = state.where((r) => r.recordId != recordId).toList();
  }

  void reset() => state = [];
}

final recordsProvider = NotifierProvider<RecordsNotifier, List<MedicalRecord>>(
  RecordsNotifier.new,
);

// Lab Reports
class ReportsNotifier extends Notifier<List<LabReport>> {
  @override
  List<LabReport> build() {
    fetchReports();
    return [];
  }

  Future<void> fetchReports() async {
    try {
      final list = await ApiClient().getLabReports();
      if (list.isNotEmpty) {
        state = list.map((item) => LabReport.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> addReport(LabReport report) async {
    state = [report, ...state];
    try {
      await ApiClient().createLabReport(report.toJson());
      await fetchReports();
    } catch (_) {}
  }

  void deleteReport(String reportId) {
    state = state.where((r) => r.reportId != reportId).toList();
  }

  void reset() => state = [];
}

final reportsProvider = NotifierProvider<ReportsNotifier, List<LabReport>>(
  ReportsNotifier.new,
);

// Timeline Events
class TimelineNotifier extends Notifier<List<TimelineEvent>> {
  @override
  List<TimelineEvent> build() {
    fetchTimeline();
    return [];
  }

  Future<void> fetchTimeline() async {
    try {
      final list = await ApiClient().getTimeline();
      if (list.isNotEmpty) {
        state = list.map((item) => TimelineEvent.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  void addEvent(TimelineEvent event) {
    state = [event, ...state];
  }

  void reset() => state = [];
}

final timelineProvider = NotifierProvider<TimelineNotifier, List<TimelineEvent>>(
  TimelineNotifier.new,
);

// Family Members
class FamilyMembersNotifier extends Notifier<List<FamilyMember>> {
  @override
  List<FamilyMember> build() {
    fetchMembers();
    return [];
  }

  Future<void> fetchMembers() async {
    try {
      final list = await ApiClient().getFamilyMembers();
      if (list.isNotEmpty) {
        state = list.map((item) => FamilyMember.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> addMember(FamilyMember member) async {
    state = [...state, member];
    try {
      await ApiClient().createFamilyMember({
        'full_name': member.fullName,
        'relationship': member.relationship,
        'date_of_birth': member.dateOfBirth,
        'gender': member.gender,
        'blood_group': member.bloodGroup,
      });
      await fetchMembers();
    } catch (_) {}
  }

  Future<void> removeMember(String id) async {
    state = state.where((m) => m.memberId != id).toList();
    try {
      await ApiClient().deleteFamilyMember(id);
      await fetchMembers();
    } catch (_) {}
  }

  void reset() => state = [];
}

final familyMembersProvider =
    NotifierProvider<FamilyMembersNotifier, List<FamilyMember>>(
  FamilyMembersNotifier.new,
);

// Upcoming Appointments
class AppointmentsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    fetchAppointments();
    return [];
  }

  Future<void> fetchAppointments() async {
    try {
      final list = await ApiClient().getAppointments();
      if (list.isNotEmpty) {
        state = list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }

  Future<void> addAppointment(Map<String, dynamic> appointment) async {
    state = [appointment, ...state];
    try {
      await ApiClient().createAppointment(appointment);
      await fetchAppointments();
    } catch (_) {}
  }

  void cancelAppointment(String id) {
    state = state.where((apt) => apt['id']?.toString() != id && apt['appointment_id'] != id).toList();
  }

  void reset() => state = [];
}

final upcomingAppointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Map<String, dynamic>>>(
  AppointmentsNotifier.new,
);

// Alerts
class AlertsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addAlert(Map<String, dynamic> alert) {
    state = [alert, ...state];
  }

  void dismissAlert(String id) {
    state = state.where((a) => a['id'] != id).toList();
  }

  void reset() => state = [];
}

final alertsProvider = NotifierProvider<AlertsNotifier, List<Map<String, dynamic>>>(
  AlertsNotifier.new,
);

// Linked Providers (Doctors / Diagnostic Labs)
class LinkedProvidersNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addProvider(Map<String, dynamic> provider) {
    state = [...state, provider];
  }

  void removeProvider(String name) {
    state = state.where((p) => (p['name'] ?? '').toString().toLowerCase() != name.toLowerCase()).toList();
  }

  void reset() => state = [];
}

final linkedProvidersProvider =
    NotifierProvider<LinkedProvidersNotifier, List<Map<String, dynamic>>>(
  LinkedProvidersNotifier.new,
);

// Patient Consent Requests (Doctor access control)
class PatientConsentsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    fetchConsents();
    return [];
  }

  Future<void> fetchConsents() async {
    try {
      final list = await ApiClient().getPatientConsents();
      state = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {}
  }

  Future<void> actionConsent(String consentId, String action) async {
    try {
      await ApiClient().actionPatientConsent(consentId: consentId, action: action);
      await fetchConsents();
    } catch (_) {}
  }

  void reset() => state = [];
}

final patientConsentsProvider =
    NotifierProvider<PatientConsentsNotifier, List<Map<String, dynamic>>>(
  PatientConsentsNotifier.new,
);

// Health Summary: Dynamically derived from real patient inputs
final healthSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final records = ref.watch(recordsProvider);
  final reports = ref.watch(reportsProvider);
  final alerts = ref.watch(alertsProvider);

  return {
    'total_records': records.length,
    'total_reports': reports.length,
    'active_alerts': alerts.length,
    'blood_pressure': {
      'systolic': null,
      'diastolic': null,
      'unit': 'mmHg',
      'status': 'Not recorded',
    },
    'heart_rate': {
      'value': null,
      'unit': 'bpm',
      'status': 'Not recorded',
    },
    'blood_sugar': {
      'value': null,
      'unit': 'mg/dL',
      'status': 'Not recorded',
    },
    'bmi': {
      'value': null,
      'status': 'Not recorded',
    },
  };
});

// ─────────────────────────────────────────────────────────────
// Doctor Portal Dynamic State
// ─────────────────────────────────────────────────────────────

class DoctorAppointmentsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    fetchAppointments();
    return [];
  }

  Future<void> fetchAppointments() async {
    try {
      final list = await ApiClient().getAppointments();
      if (list.isNotEmpty) {
        state = list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }

  Future<void> addAppointment(Map<String, dynamic> appointment) async {
    state = [appointment, ...state];
    try {
      await ApiClient().createAppointment(appointment);
      await fetchAppointments();
    } catch (_) {}
  }

  void reset() => state = [];
}

final doctorAppointmentsProvider =
    NotifierProvider<DoctorAppointmentsNotifier, List<Map<String, dynamic>>>(
  DoctorAppointmentsNotifier.new,
);

class DoctorPatientsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  Future<void> fetchPatients([String query = '']) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      state = [];
      return;
    }
    try {
      final list = await ApiClient().searchPatients(cleanQuery);
      state = list.cast<Map<String, dynamic>>();
    } catch (_) {
      state = [];
    }
  }

  Future<Map<String, dynamic>?> addPatient(Map<String, dynamic> patient) async {
    try {
      final res = await ApiClient().registerDoctorPatient(patient);
      final email = patient['email']?.toString() ?? '';
      if (email.isNotEmpty) {
        await fetchPatients(email);
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  void reset() => state = [];
}

final doctorPatientsProvider =
    NotifierProvider<DoctorPatientsNotifier, List<Map<String, dynamic>>>(
  DoctorPatientsNotifier.new,
);

class DoctorIncomingRequestsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    fetchRequests();
    return [];
  }

  Future<void> fetchRequests() async {
    try {
      final list = await ApiClient().getDoctorIncomingRequests();
      state = list.cast<Map<String, dynamic>>();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> actionRequest(String consentId, String action) async {
    try {
      final res = await ApiClient().actionDoctorIncomingRequest(consentId: consentId, action: action);
      await fetchRequests();
      ref.read(doctorPatientsProvider.notifier).fetchPatients();
      return res;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  void reset() => state = [];
}

final doctorIncomingRequestsProvider =
    NotifierProvider<DoctorIncomingRequestsNotifier, List<Map<String, dynamic>>>(
  DoctorIncomingRequestsNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// Lab Portal Dynamic State
// ─────────────────────────────────────────────────────────────

class LabPendingReportsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    fetchOrders();
    return [];
  }

  Future<void> fetchOrders() async {
    try {
      final list = await ApiClient().getLabOrders();
      if (list.isNotEmpty) {
        state = list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }

  Future<void> addPendingTest(Map<String, dynamic> test) async {
    state = [test, ...state];
    try {
      await ApiClient().createLabOrder(test);
      await fetchOrders();
    } catch (_) {}
  }

  Future<void> completeTest(String testId, [Map<String, dynamic>? publishPayload]) async {
    state = state.where((t) => t['id']?.toString() != testId && t['order_id'] != testId && t['test_id'] != testId).toList();
    if (publishPayload != null) {
      try {
        await ApiClient().publishLabReport(testId, publishPayload);
        await fetchOrders();
      } catch (_) {}
    }
  }

  void reset() => state = [];
}

final labPendingReportsProvider =
    NotifierProvider<LabPendingReportsNotifier, List<Map<String, dynamic>>>(
  LabPendingReportsNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// Hospital Portal Dynamic State
// ─────────────────────────────────────────────────────────────

class HospitalAdmissionsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    fetchAdmissions();
    return [];
  }

  Future<void> fetchAdmissions() async {
    try {
      final list = await ApiClient().getAdmissions();
      if (list.isNotEmpty) {
        state = list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }

  Future<void> addAdmission(Map<String, dynamic> admission) async {
    state = [admission, ...state];
    try {
      await ApiClient().admitPatient(admission);
      await fetchAdmissions();
    } catch (_) {}
  }

  Future<void> dischargePatient(String admissionId, [String? notes]) async {
    state = state.where((a) => a['id']?.toString() != admissionId && a['admission_id'] != admissionId).toList();
    try {
      await ApiClient().dischargePatient(admissionId, {'discharge_notes': notes ?? 'Patient discharged in stable condition.'});
      await fetchAdmissions();
    } catch (_) {}
  }

  void reset() => state = [];
}

final hospitalAdmissionsProvider =
    NotifierProvider<HospitalAdmissionsNotifier, List<Map<String, dynamic>>>(
  HospitalAdmissionsNotifier.new,
);
