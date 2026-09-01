import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/web_constraint.dart';
import '../../shared/widgets/role_context_switcher.dart';
import '../../shared/widgets/app_badge.dart';
import '../notifications/notifications_provider.dart';
import 'lab_dashboard/lab_dashboard_screen.dart';
import 'pending_reports/pending_reports_screen.dart';
import 'upload_report/upload_report_screen.dart';
import 'integration_status/integration_status_screen.dart';

const Color kLabAccent = Color(0xFF059669); // Teal-Green

class LabShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const LabShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<LabShell> createState() => _LabShellState();
}

class _LabShellState extends ConsumerState<LabShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    LabDashboardScreen(),
    PendingReportsScreen(),
    UploadReportScreen(),
    LabIntegrationStatusScreen(),
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
      title: const RoleContextSwitcher(accentColor: kLabAccent),
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
            avatar: const Icon(Icons.science, size: 14, color: kLabAccent),
            label: const Text(
              'Metropolis Lab Staff',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kLabAccent,
              ),
            ),
            backgroundColor: kLabAccent.withValues(alpha: 0.08),
            side: BorderSide(color: kLabAccent.withValues(alpha: 0.2)),
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
            _LabSidebar(
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
        selectedItemColor: kLabAccent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            activeIcon: Icon(Icons.upload_file),
            label: 'Upload Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync_alt_rounded),
            activeIcon: Icon(Icons.sync_rounded),
            label: 'LIMS Sync',
          ),
        ],
      ),
    );
  }
}

class _LabSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LabSidebar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      indicatorColor: kLabAccent.withValues(alpha: 0.12),
      selectedIconTheme: const IconThemeData(color: kLabAccent),
      selectedLabelTextStyle: const TextStyle(
        color: kLabAccent,
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
                color: kLabAccent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.science_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Lab Staff',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: kLabAccent,
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
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: Text('Pending'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.upload_file_outlined),
          selectedIcon: Icon(Icons.upload_file),
          label: Text('Upload'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sync_alt_rounded),
          selectedIcon: Icon(Icons.sync_rounded),
          label: Text('LIMS Sync'),
        ),
      ],
    );
  }
}
