import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/records/records_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/timeline/timeline_screen.dart';
import '../../features/family/family_screen.dart';
import '../../features/emergency/emergency_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/notifications/notifications_provider.dart';
import '../../core/theme/app_colors.dart';
import 'adaptive_nav.dart';
import 'web_constraint.dart';
import 'role_context_switcher.dart';
import 'app_badge.dart';

class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RecordsScreen(),
    ReportsScreen(),
    TimelineScreen(),
    FamilyScreen(),
    EmergencyScreen(),
    SettingsScreen(),
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
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleSpacing: 16,
      title: const RoleContextSwitcher(),
      actions: [
        // Notification Bell Icon with Badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: AppBadge(
                    text: '$unreadCount',
                    type: AppBadgeType.error,
                    isSmall: true,
                  ),
                ),
              ),
          ],
        ),
        // Settings Gear Icon
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          tooltip: 'Settings',
          onPressed: () => context.go('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );

    if (isWideScreen) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            AdaptiveNav(
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
      bottomNavigationBar: AdaptiveNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
