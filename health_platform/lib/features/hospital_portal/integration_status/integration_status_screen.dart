import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock_data/mock_hospital_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_badge.dart';

const Color kHospitalAccent = Color(0xFFD97706);

class HospitalIntegrationStatusScreen extends StatelessWidget {
  const HospitalIntegrationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = MockHospitalData.getHospitalStats();
    final logs = MockHospitalData.getHisIntegrationLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HIS Integration & Data-Push Status'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sync_rounded,
                        color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'HIS Auto-Push Gateway',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 8),
                            AppBadge(
                              text: 'CONNECTED',
                              type: AppBadgeType.success,
                              isSmall: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'HL7 ADT Engine • Last Sync: ${stats['his_last_sync']} • Gateway v3.1',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Live Sync Audit Logs Header
            Text(
              'Realtime ADT & EHR Sync Logs (HL7 / FHIR)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Transmission Logs
            ...logs.map((log) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Text(
                          log['timestamp'],
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['event'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'System: ${log['system']} • Patient Ref: ${log['patient_id']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppBadge(
                          text: log['status'],
                          type: AppBadgeType.success,
                          isSmall: true,
                        ),
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
