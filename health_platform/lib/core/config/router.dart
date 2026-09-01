import 'package:go_router/go_router.dart';
import '../../features/auth/phone_entry_screen.dart';
import '../../features/auth/otp_entry_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../shared/widgets/main_shell.dart';

// Portals
import '../../features/doctor_portal/doctor_shell.dart';
import '../../features/doctor_portal/patient_record_view_screen.dart';
import '../../features/doctor_portal/add_diagnosis_screen.dart';

import '../../features/lab_portal/lab_shell.dart';
import '../../features/hospital_portal/hospital_shell.dart';

import '../../features/notifications/notifications_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/phone',
      builder: (context, state) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpEntryScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),

    // ── Patient Portal Routes ───────────────────────────────────────
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/records',
      builder: (context, state) => const MainShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const MainShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/timeline',
      builder: (context, state) => const MainShell(initialIndex: 3),
    ),
    GoRoute(
      path: '/family',
      builder: (context, state) => const MainShell(initialIndex: 4),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const MainShell(initialIndex: 5),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainShell(initialIndex: 6),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MainShell(initialIndex: 6),
    ),

    // ── Doctor Portal Routes ────────────────────────────────────────
    GoRoute(
      path: '/doctor',
      builder: (context, state) => const DoctorShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/doctor/patients',
      builder: (context, state) => const DoctorShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => const DoctorShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/doctor/patient-detail',
      builder: (context, state) => PatientRecordViewScreen(
        patientId: state.uri.queryParameters['id'] ?? 'PAT001',
      ),
    ),
    GoRoute(
      path: '/doctor/add-diagnosis',
      builder: (context, state) => AddDiagnosisScreen(
        patientId: state.uri.queryParameters['id'] ?? 'PAT001',
      ),
    ),

    // ── Lab Portal Routes ───────────────────────────────────────────
    GoRoute(
      path: '/lab',
      builder: (context, state) => const LabShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/lab/pending',
      builder: (context, state) => const LabShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/lab/upload',
      builder: (context, state) => const LabShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/lab/integration',
      builder: (context, state) => const LabShell(initialIndex: 3),
    ),

    // ── Hospital Portal Routes ──────────────────────────────────────
    GoRoute(
      path: '/hospital',
      builder: (context, state) => const HospitalShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/hospital/admissions',
      builder: (context, state) => const HospitalShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/hospital/discharge',
      builder: (context, state) => const HospitalShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/hospital/integration',
      builder: (context, state) => const HospitalShell(initialIndex: 3),
    ),
  ],
);
