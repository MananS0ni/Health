import '../../features/care/demo_screen.dart';
import '../../features/care/conditions_screen.dart';
import '../../features/lab_portal/upload_report/upload_report_screen.dart';
import '../../features/lab_portal/integration_status/integration_status_screen.dart';
import '../../features/hospital_portal/integration_status/integration_status_screen.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
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
import '../../features/admin_portal/admin_portal_screen.dart';

import '../../features/notifications/notifications_screen.dart';
import '../../features/care/care_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: ApiClient(),
  redirect: (context, state) {
    final api = ApiClient();
    final path = state.uri.path;
    if (['/', '/phone', '/otp', '/signup', '/demo'].contains(path)) return null;
    if (api.accessToken == null) return '/';
    final pro = path.startsWith('/doctor') ? 'doctor' : path.startsWith('/lab') ? 'lab' : path.startsWith('/hospital') ? 'hospital' : path.startsWith('/admin') ? 'admin' : null;
    if (pro != null) {
      if (!kIsWeb) return '/dashboard';
      if (!api.currentRoles.contains(pro) || (pro != 'admin' && !api.professionalVerified)) return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(path:'/demo',builder:(context,state)=>const DemoScreen()),
    GoRoute(path:'/conditions',builder:(context,state)=>const ConditionsScreen()),
    GoRoute(path:'/care',builder:(context,state)=>const CareScreen()),
    GoRoute(path:'/doctor/bookings',builder:(context,state)=>const CareScreen(professional:true)),
    GoRoute(path:'/lab/bookings',builder:(context,state)=>const CareScreen(professional:true)),
    GoRoute(path:'/hospital/bookings',builder:(context,state)=>const CareScreen(professional:true)),
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
      builder: (context, state) => DoctorShell(
        initialIndex: 1,
        searchQuery: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => const DoctorShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/doctor/patient-detail',
      builder: (context, state) => PatientRecordViewScreen(
        patientId: state.uri.queryParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/doctor/add-diagnosis',
      builder: (context, state) => AddDiagnosisScreen(
        patientId: state.uri.queryParameters['id'] ?? '',
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
      builder: (context, state) => UploadReportScreen(orderId:state.uri.queryParameters['order'],patient:state.uri.queryParameters['patient'],test:state.uri.queryParameters['test'],category:state.uri.queryParameters['category']),
    ),
    GoRoute(
      path: '/lab/integration',
      builder: (context, state) => const LabIntegrationStatusScreen(),
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
      builder: (context, state) => const HospitalIntegrationStatusScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPortalScreen(),
    ),
    GoRoute(
      path: '/admin-portal',
      builder: (context, state) => const AdminPortalScreen(),
    ),
  ],
);
