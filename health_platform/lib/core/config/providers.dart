import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user.dart';
import '../../shared/models/medical_record.dart';
import '../../shared/models/lab_report.dart';
import '../../shared/models/timeline_event.dart';
import '../../mock_data/mock_user.dart';
import '../../mock_data/mock_records.dart';
import '../../mock_data/mock_reports.dart';
import '../../mock_data/mock_timeline.dart';
import '../../mock_data/mock_dashboard.dart';
import '../../shared/models/family_member.dart';
import '../../mock_data/mock_family.dart';

// ─────────────────────────────────────────────────────────────
// Auth State
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

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    required this.otpSent,
    required this.loginMode,
    this.phoneNumber,
    this.email,
    this.user,
    this.error,
  });

  factory AuthState.initial() => const AuthState(
        isAuthenticated: false,
        isLoading: false,
        otpSent: false,
        loginMode: LoginMode.phone,
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

  void sendOtpByPhone(String phoneNumber) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      loginMode: LoginMode.phone,
      isLoading: true,
      clearError: true,
    );
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(isLoading: false, otpSent: true);
    });
  }

  void sendOtpByEmail(String email) {
    state = state.copyWith(
      email: email,
      loginMode: LoginMode.email,
      isLoading: true,
      clearError: true,
    );
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(isLoading: false, otpSent: true);
    });
  }

  // kept for backwards compat
  void sendOtp(String phoneNumber) => sendOtpByPhone(phoneNumber);

  void verifyOtp(String otp) {
    state = state.copyWith(isLoading: true);
    Future.delayed(const Duration(seconds: 1), () {
      if (otp.length == 6) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: MockUser.getCurrentUser(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid OTP. Please enter all 6 digits.',
        );
      }
    });
  }

  void logout() {
    state = AuthState.initial();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// Active Role Context (patient vs professional view)
// ─────────────────────────────────────────────────────────────

/// 'patient' = My Health view  |  'doctor'/'lab_staff'/'hospital_staff' = Pro view
class ActiveRoleNotifier extends Notifier<String> {
  @override
  String build() => 'patient';

  void setRole(String role) => state = role;
}

final activeRoleProvider = NotifierProvider<ActiveRoleNotifier, String>(
  ActiveRoleNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// Data Providers
// ─────────────────────────────────────────────────────────────

final userProvider = Provider<User>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user ?? MockUser.getCurrentUser();
});

final recordsProvider = Provider<List<MedicalRecord>>((ref) {
  return MockRecords.getRecords();
});

final reportsProvider = Provider<List<LabReport>>((ref) {
  return MockReports.getReports();
});

final timelineProvider = Provider<List<TimelineEvent>>((ref) {
  return MockTimeline.getTimelineEvents();
});

final familyMembersProvider = Provider<List<FamilyMember>>((ref) {
  return MockFamily.getFamilyMembers();
});

final upcomingAppointmentsProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return MockDashboard.getUpcomingAppointments();
});

final alertsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return MockDashboard.getAlerts();
});

final healthSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  return MockDashboard.getHealthSummary();
});
