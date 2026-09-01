import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock_data/mock_hospital_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_badge.dart';

const Color kHospitalAccent = Color(0xFFD97706); // Warm Amber / Orange

class HospitalDashboardScreen extends StatelessWidget {
  const HospitalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admissions = MockHospitalData.getAdmissions();
    final stats = MockHospitalData.getHospitalStats();

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
                    color: kHospitalAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: kHospitalAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hospital Portal Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Text(
                      'Apollo Multi-Specialty Hospital • HIS Engine Active',
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
                  child: _HospStatCard(
                    title: 'Current Admissions',
                    value: '${stats['occupied_beds']} / ${stats['total_beds']}',
                    subtitle: 'Occupancy: ${stats['occupancy_rate']}',
                    icon: Icons.hotel_rounded,
                    accentColor: kHospitalAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HospStatCard(
                    title: 'Discharges Today',
                    value: '${stats['discharges_pending']}',
                    subtitle: 'Summaries pending',
                    icon: Icons.output_rounded,
                    accentColor: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HospStatCard(
                    title: 'Integration Status',
                    value: stats['his_sync_status'] ?? 'Active',
                    subtitle: 'Last sync: ${stats['his_last_sync']}',
                    icon: Icons.sync_rounded,
                    accentColor: const Color(0xFF2563EB),
                    isStatus: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick Nav Cards Section
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
                    title: 'Inpatient Admissions',
                    subtitle: 'Ward beds & active patients',
                    icon: Icons.hotel_outlined,
                    onTap: () => context.go('/hospital/admissions'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickNavCard(
                    title: 'Discharge Summary',
                    subtitle: 'Draft & sign discharge notes',
                    icon: Icons.description_outlined,
                    onTap: () => context.go('/hospital/discharge'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickNavCard(
                    title: 'HIS Sync Status',
                    subtitle: 'HL7 ADT & EHR gateway',
                    icon: Icons.sync_alt_rounded,
                    onTap: () => context.go('/hospital/integration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Active Admissions Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Ward Admissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/hospital/admissions'),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Admit Patient', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kHospitalAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => context.go('/hospital/admissions'),
                      child: const Text(
                        'View All Wards',
                        style: TextStyle(
                            color: kHospitalAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ...admissions.take(3).map((adm) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () => context.go('/hospital/admissions'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kHospitalAccent.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(Icons.bed_rounded,
                              color: kHospitalAccent, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    adm['patient_name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppBadge(
                                    text: adm['bed_no'],
                                    type: AppBadgeType.info,
                                    isSmall: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${adm['ward']} • Diagnosis: ${adm['diagnosis']}',
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
}

class _HospStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isStatus;

  const _HospStatCard({
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
          Icon(icon, size: 20, color: kHospitalAccent),
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
