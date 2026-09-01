import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/app_avatar.dart' show AppAvatar, AppAvatarSize;
import '../../shared/widgets/web_constraint.dart';
import '../../core/config/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showLinkDoctorOrLabModal(BuildContext context) {
    final searchController = TextEditingController();
    int selectedTab = 0; // 0 = Doctor, 1 = Lab

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.add_link_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Link Doctor or Laboratory',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Search for registered clinics, doctors, or diagnostic labs to automatically receive prescriptions and test reports.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              // Segmented selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Doctor / Clinic')),
                      selected: selectedTab == 0,
                      onSelected: (val) {
                        if (val) setModalState(() => selectedTab = 0);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                        color: selectedTab == 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Diagnostic Lab')),
                      selected: selectedTab == 1,
                      onSelected: (val) {
                        if (val) setModalState(() => selectedTab = 1);
                      },
                      selectedColor: const Color(0xFF059669).withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                        color: selectedTab == 1 ? const Color(0xFF059669) : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: selectedTab == 0
                      ? 'Search Doctor by Name, Medical Reg No, or Phone...'
                      : 'Search Lab by Name, License No, or Location...',
                  prefixIcon: Icon(
                    selectedTab == 0 ? Icons.medical_services_outlined : Icons.science_outlined,
                    color: selectedTab == 0 ? AppColors.primary : const Color(0xFF059669),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Suggested Registrations', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              if (selectedTab == 0) ...[
                _SuggestedProviderTile(
                  name: 'Dr. Max Patel (MD, General Medicine)',
                  subtext: 'Reg: MCI-987452 • Max Healthcare',
                  icon: Icons.person_pin_rounded,
                  color: const Color(0xFF1E40AF),
                  onLink: () {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dr. Max Patel linked to your profile!')),
                    );
                  },
                ),
                _SuggestedProviderTile(
                  name: 'Dr. S. K. Gupta (Cardiologist)',
                  subtext: 'Reg: MCI-441209 • Apollo Hospitals',
                  icon: Icons.favorite_border_rounded,
                  color: AppColors.primary,
                  onLink: () {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dr. S. K. Gupta linked to your profile!')),
                    );
                  },
                ),
              ] else ...[
                _SuggestedProviderTile(
                  name: 'Metropolis Diagnostics Lab',
                  subtext: 'License: LAB-IND-9982 • Connaught Place Branch',
                  icon: Icons.science_rounded,
                  color: const Color(0xFF059669),
                  onLink: () {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Metropolis Diagnostics Lab linked to your profile!')),
                    );
                  },
                ),
                _SuggestedProviderTile(
                  name: 'Dr. Lal PathLabs',
                  subtext: 'License: LAB-IND-4410 • Sector 18 Branch',
                  icon: Icons.local_hospital_outlined,
                  color: const Color(0xFFD97706),
                  onLink: () {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dr. Lal PathLabs linked to your profile!')),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);
    final alerts = ref.watch(alertsProvider);
    final healthSummary = ref.watch(healthSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: WebConstraint(
          maxWidth: 1000,
          child: CustomScrollView(
            slivers: [
              // App Bar Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: user.fullName,
                        size: AppAvatarSize.lg,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showLinkDoctorOrLabModal(context),
                        icon: const Icon(Icons.add_link_rounded, size: 16),
                        label: const Text('+ Link Doctor/Lab', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Health Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Records',
                          value: healthSummary['total_records'].toString(),
                          icon: Icons.folder_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Reports',
                          value: healthSummary['total_reports'].toString(),
                          icon: Icons.assignment_outlined,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Alerts',
                          value: healthSummary['active_alerts'].toString(),
                          icon: Icons.notifications_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Linked Healthcare Providers Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Linked Healthcare Providers',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => _showLinkDoctorOrLabModal(context),
                            child: const Text('Add Provider', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              onTap: () => _showLinkDoctorOrLabModal(context),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.medical_services_outlined, color: Color(0xFF1E40AF), size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Dr. Max Patel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        Text('General Medicine', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppCard(
                              onTap: () => _showLinkDoctorOrLabModal(context),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.science_outlined, color: Color(0xFF059669), size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Metropolis Lab', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        Text('Diagnostic Center', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Upcoming Appointments
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Appointments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ),
              if (upcomingAppointments.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.event_busy,
                      title: 'No Upcoming Appointments',
                      subtitle: 'You have no scheduled appointments',
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final appointment = upcomingAppointments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: AppCard(
                          onTap: () {},
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appointment['doctor_name'],
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      appointment['specialization'],
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${appointment['appointment_date']} at ${appointment['appointment_time']}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: upcomingAppointments.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Alerts
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Health Alerts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              if (alerts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.check_circle,
                      title: 'No Alerts',
                      subtitle: 'You have no active alerts',
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alert = alerts[index];
                      final priority = alert['priority'] as String;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: AppCard(
                          backgroundColor: _getAlertColor(priority),
                          child: Row(
                            children: [
                              Icon(
                                _getAlertIcon(priority),
                                color: _getAlertIconColor(priority),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['title'],
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      alert['message'],
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppBadge(
                                text: priority.toUpperCase(),
                                type: _getBadgeType(priority),
                                isSmall: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: alerts.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.warningLight;
      case 'medium':
        return AppColors.warningLight;
      default:
        return AppColors.infoLight;
    }
  }

  IconData _getAlertIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getAlertIconColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  AppBadgeType _getBadgeType(String priority) {
    switch (priority) {
      case 'high':
        return AppBadgeType.warning;
      case 'medium':
        return AppBadgeType.warning;
      default:
        return AppBadgeType.info;
    }
  }
}

class _SuggestedProviderTile extends StatelessWidget {
  final String name;
  final String subtext;
  final IconData icon;
  final Color color;
  final VoidCallback onLink;

  const _SuggestedProviderTile({
    required this.name,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onLink,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Link', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
