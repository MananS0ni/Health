import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock_data/mock_lab_data.dart';
import '../../../shared/widgets/app_card.dart';

const Color kLabAccent = Color(0xFF059669); // Teal-Green

class LabDashboardScreen extends StatelessWidget {
  const LabDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingReports = MockLabData.getPendingReports();
    final stats = MockLabData.getLabStats();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title Area
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kLabAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: kLabAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lab Portal Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Text(
                      'Metropolis Diagnostic Hub • LIMS Gateway Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _SummaryStatCard(
                    title: 'Pending Reports',
                    value: '${stats['pending_queue']}',
                    subtitle: 'Requires upload',
                    icon: Icons.assignment_late_outlined,
                    accentColor: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryStatCard(
                    title: 'Uploaded Today',
                    value: '${stats['processed_today']}',
                    subtitle: 'Published to EHR',
                    icon: Icons.task_alt_rounded,
                    accentColor: kLabAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryStatCard(
                    title: 'Integration Status',
                    value: stats['lims_sync_status'] ?? 'Connected',
                    subtitle: 'Last sync: ${stats['lims_last_sync']}',
                    icon: Icons.cloud_done_rounded,
                    accentColor: const Color(0xFF2563EB),
                    isStatus: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick Access Nav Section
            Text(
              'Quick Actions & Navigation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuickNavCard(
                    title: 'Pending Reports',
                    subtitle: 'Review & process test queue',
                    icon: Icons.assignment_outlined,
                    onTap: () => context.go('/lab/pending'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickNavCard(
                    title: 'Upload Report',
                    subtitle: 'Form & parameter entry',
                    icon: Icons.upload_file_outlined,
                    onTap: () => context.go('/lab/upload'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickNavCard(
                    title: 'LIMS Sync',
                    subtitle: 'Automated data-push logs',
                    icon: Icons.sync_rounded,
                    onTap: () => context.go('/lab/integration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Pending Queue Preview List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Pending Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/lab/pending'),
                  child: const Text(
                    'View All Queue',
                    style: TextStyle(
                        color: kLabAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ...pendingReports.take(3).map((report) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () => context
                        .go('/lab/upload?order=${report['order_id']}'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kLabAccent.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(Icons.science_outlined,
                              color: kLabAccent, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report['test_name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Patient: ${_maskName(report['patient_name'])} • ${report['category']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  static String _maskName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first} ${parts.last[0]}.';
    }
    return fullName;
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isStatus;

  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isStatus ? 15 : 20,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kLabAccent),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
