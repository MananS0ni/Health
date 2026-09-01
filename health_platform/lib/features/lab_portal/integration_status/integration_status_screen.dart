import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock_data/mock_lab_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_badge.dart';

const Color kLabAccent = Color(0xFF059669);

class LabIntegrationStatusScreen extends StatelessWidget {
  const LabIntegrationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = MockLabData.getLabStats();
    final logs = MockLabData.getLimsSyncLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIMS Integration & Data-Push Status'),
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
            // Connection Status Card
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
                    child: const Icon(Icons.cloud_done_rounded,
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
                              'LIMS Auto-Push Gateway',
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
                          'Uptime: ${stats['lims_uptime']} • Last Sync: ${stats['lims_last_sync']} • Queue: 0 pending',
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

            // Live Transmission Audit Logs Header
            Text(
              'Realtime Transmission Logs (HL7 ORU_R01 / REST)',
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
                          log['time'],
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
                                'Order Ref: ${log['order_id']} • Code: ${log['response_code']}',
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
