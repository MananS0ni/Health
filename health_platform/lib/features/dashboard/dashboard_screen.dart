import 'dart:async';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _consentPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientConsentsProvider.notifier).fetchConsents();
      ref.read(recordsProvider.notifier).fetchRecords();
      ref.read(reportsProvider.notifier).fetchReports();
      ref.read(timelineProvider.notifier).fetchTimeline();
    });
    // Auto-poll every 3 seconds so doctor requests and new prescriptions sync in real time
    _consentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.read(patientConsentsProvider.notifier).fetchConsents();
        ref.read(recordsProvider.notifier).fetchRecords();
        ref.read(reportsProvider.notifier).fetchReports();
      }
    });
  }

  @override
  void dispose() {
    _consentPollTimer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);
    final alerts = ref.watch(alertsProvider);
    final healthSummary = ref.watch(healthSummaryProvider);
    final rawLinked = ref.watch(linkedProvidersProvider);
    final approvedConsents = ref.watch(patientConsentsProvider).where((c) => c['status'] == 'approved').toList();
    final linkedProviders = <Map<String, dynamic>>[
      ...approvedConsents.map((c) {
        final raw = (c['doctor_name'] ?? c['doctor_email'] ?? 'Doctor').toString();
        final name = raw.toLowerCase().startsWith('dr.') ? raw : 'Dr. $raw';
        return {
          'id': c['id']?.toString() ?? '',
          'consent_id': c['id']?.toString() ?? '',
          'name': name,
          'specialty': c['purpose'] != null && c['purpose'].toString().isNotEmpty
              ? c['purpose'].toString()
              : 'General Medicine • Clinical Practice',
          'type': 'doctor',
          'valid_until': c['valid_until'],
        };
      }),
      ...rawLinked.where((p) => !approvedConsents.any((c) {
        final raw = (c['doctor_name'] ?? '').toString();
        final name = raw.toLowerCase().startsWith('dr.') ? raw : 'Dr. $raw';
        return name.toLowerCase() == (p['name'] ?? '').toString().toLowerCase();
      })),
    ];

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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified_user_outlined, size: 15, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'ABHA Verified',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pending Provider (Doctor / Lab / Hospital) Access Requests
              if (ref.watch(patientConsentsProvider).any((c) => c['status'] == 'pending'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Incoming Provider Access Requests',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${ref.watch(patientConsentsProvider).where((c) => c['status'] == 'pending').length} Pending',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Only approved providers can access your health records. Review and grant 24-hr clinical access below.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                          ),
                          const SizedBox(height: 8),
                          ...ref
                              .watch(patientConsentsProvider)
                              .where((c) => c['status'] == 'pending')
                              .map((consent) {
                            final rawName = consent['doctor_name'] ?? consent['doctor_email'] ?? 'Healthcare Provider';
                            final requesterName = rawName.toString().toLowerCase().startsWith('dr.')
                                ? rawName.toString()
                                : 'Dr. $rawName';
                            final purpose = consent['purpose'] ?? 'Clinical Consultation & Record Access';
                            final consentId = consent['id'].toString();

                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.medical_services_outlined, color: Color(0xFF1E40AF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(requesterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(purpose, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        const Text('Access duration: 24 Hours upon approval', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB))),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.emergency,
                                      side: const BorderSide(color: AppColors.emergency),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => ref.read(patientConsentsProvider.notifier).actionConsent(consentId, 'reject'),
                                    child: const Text('Deny', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => ref.read(patientConsentsProvider.notifier).actionConsent(consentId, 'approve'),
                                    child: const Text('Approve (24h)', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
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

              // Authorized Healthcare Providers Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Authorized Healthcare Providers',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (linkedProviders.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: Text(
                                    '${linkedProviders.length} Active',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (linkedProviders.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No Healthcare Providers Currently Authorized',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Only Doctors, Diagnostic Labs, and Hospitals can request access to your records. When a request arrives, you can approve or deny it above.',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: linkedProviders.map((provider) {
                            final isDoc = provider['type'] == 'doctor';
                            final consentId = provider['consent_id']?.toString() ?? '';
                            final providerName = provider['name']?.toString() ?? 'Provider';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDoc
                                            ? const Color(0xFF1E40AF).withValues(alpha: 0.1)
                                            : const Color(0xFF059669).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isDoc ? Icons.medical_services_outlined : Icons.science_outlined,
                                        color: isDoc ? const Color(0xFF1E40AF) : const Color(0xFF059669),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  providerName,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Active Consent',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            provider['specialty'] ?? '',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFDC2626),
                                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.block_rounded, size: 14),
                                      label: const Text('Revoke Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text('Revoke Access for $providerName?'),
                                            content: Text(
                                              'Are you sure you want to revoke clinical record access for $providerName? They will immediately lose access to your medical history.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFDC2626),
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Revoke'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          if (consentId.isNotEmpty) {
                                            await ref.read(patientConsentsProvider.notifier).actionConsent(consentId, 'revoke');
                                          }
                                          ref.read(linkedProvidersProvider.notifier).removeProvider(providerName);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Access revoked for $providerName.'),
                                                backgroundColor: const Color(0xFFDC2626),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
