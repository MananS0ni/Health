import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/web_constraint.dart';
import '../../shared/widgets/role_context_switcher.dart';
import '../../shared/widgets/app_badge.dart';
import '../notifications/notifications_provider.dart';
import 'doctor_dashboard_screen.dart';
import 'patient_search_screen.dart';
import 'doctor_appointments_screen.dart';

const Color kDoctorAccent = Color(0xFF1E40AF); // Deep Blue / Indigo
const Color kDoctorAccentLight = Color(0xFF3B82F6);

class DoctorShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const DoctorShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends ConsumerState<DoctorShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DoctorDashboardScreen(),
    PatientSearchScreen(),
    DoctorAppointmentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 768;

    final appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleSpacing: 16,
      title: const RoleContextSwitcher(accentColor: kDoctorAccent),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
            ),
            if (ref.watch(unreadNotificationsCountProvider) > 0)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: AppBadge(
                    text: '${ref.watch(unreadNotificationsCountProvider)}',
                    type: AppBadgeType.error,
                    isSmall: true,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          tooltip: 'Settings',
          onPressed: () => context.go('/settings'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: Chip(
            avatar: const Icon(Icons.verified, size: 14, color: kDoctorAccent),
            label: const Text(
              'Dr. Max Patel',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kDoctorAccent,
              ),
            ),
            backgroundColor: kDoctorAccent.withValues(alpha: 0.08),
            side: BorderSide(color: kDoctorAccent.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ),
      ],
    );

    if (isWideScreen) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            _DoctorSidebar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: WebConstraint(
                maxWidth: 1000,
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kDoctorAccent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_outlined),
            activeIcon: Icon(Icons.person_search),
            label: 'Search Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
        ],
      ),
    );
  }
}

class _DoctorSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DoctorSidebar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      indicatorColor: kDoctorAccent.withValues(alpha: 0.12),
      selectedIconTheme: const IconThemeData(color: kDoctorAccent),
      selectedLabelTextStyle: const TextStyle(
        color: kDoctorAccent,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kDoctorAccent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Doctor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: kDoctorAccent,
              ),
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_search_outlined),
          selectedIcon: Icon(Icons.person_search),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: Text('Appointments'),
        ),
      ],
    );
  }
}
