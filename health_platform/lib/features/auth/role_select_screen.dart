import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/providers.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final roles = user.roles;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Mark
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome back, ${user.fullName.split(' ').first}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a portal to continue your session',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Role Cards List
                      if (roles.contains('patient'))
                        _RoleCard(
                          title: 'My Health (Patient)',
                          subtitle:
                              'View personal health records, lab reports, timeline & emergency card',
                          icon: Icons.favorite_rounded,
                          accentColor: AppColors.primary,
                          onTap: () {
                            ref
                                .read(activeRoleProvider.notifier)
                                .setRole('patient');
                            context.go('/dashboard');
                          },
                        ),
                      if (roles.contains('doctor')) ...[
                        const SizedBox(height: 12),
                        _RoleCard(
                          title: 'Doctor Portal',
                          subtitle:
                              'Consultations, appointments, patient records & write prescriptions',
                          icon: Icons.medical_services_rounded,
                          accentColor: const Color(0xFF1E40AF), // Indigo
                          onTap: () {
                            ref
                                .read(activeRoleProvider.notifier)
                                .setRole('doctor');
                            context.go('/doctor');
                          },
                        ),
                      ],
                      if (roles.contains('lab_staff')) ...[
                        const SizedBox(height: 12),
                        _RoleCard(
                          title: 'Lab Staff Portal',
                          subtitle:
                              'Process test orders, upload lab reports & monitor LIMS sync',
                          icon: Icons.science_rounded,
                          accentColor: const Color(0xFF059669), // Emerald
                          onTap: () {
                            ref
                                .read(activeRoleProvider.notifier)
                                .setRole('lab_staff');
                            context.go('/lab');
                          },
                        ),
                      ],
                      if (roles.contains('hospital_staff')) ...[
                        const SizedBox(height: 12),
                        _RoleCard(
                          title: 'Hospital Staff Portal',
                          subtitle:
                              'Manage admissions, ward occupancy & discharge summaries',
                          icon: Icons.local_hospital_rounded,
                          accentColor: const Color(0xFFD97706), // Amber
                          onTap: () {
                            ref
                                .read(activeRoleProvider.notifier)
                                .setRole('hospital_staff');
                            context.go('/hospital');
                          },
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Sign Out Link
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            ref.read(authStateProvider.notifier).logout();
                            context.go('/phone');
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Sign out'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
