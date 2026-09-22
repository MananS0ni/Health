import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/network/api_client.dart';

const Color kLabAccent = Color(0xFF059669); // Teal-Green

class LabDashboardScreen extends ConsumerWidget {
  const LabDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingReports = ref.watch(labPendingReportsProvider);
    final user = ref.watch(currentUserProvider);

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
                    Text(
                      '${user?.orgProfile?.orgName ?? "Diagnostic Laboratory Hub"} • LIMS Gateway Ready',
                      style: const TextStyle(
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
                    value: '${pendingReports.length}',
                    subtitle: pendingReports.isEmpty ? 'Queue clear' : 'Requires upload',
                    icon: Icons.assignment_late_outlined,
                    accentColor: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryStatCard(
                    title: 'Completed Reports',
                    value: '0',
                    subtitle: 'Published to EHR',
                    icon: Icons.task_alt_rounded,
                    accentColor: kLabAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryStatCard(
                    title: 'Integration Status',
                    value: 'Connected',
                    subtitle: 'Real-time LIMS active',
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
                    title: 'Batch CSV Ingest',
                    subtitle: 'Zero-work bulk machine upload',
                    icon: Icons.table_chart_rounded,
                    onTap: () => _showBatchUploadModal(context, ref),
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
            if (pendingReports.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No pending diagnostic orders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'New test requests from linked doctors or patients will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...pendingReports.take(3).map((report) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () => context
                          .go('/lab/upload?order=${report['order_id'] ?? report['id']}'),
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
                                  report['test_name'] ?? 'Diagnostic Test',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Patient: ${_maskName(report['patient_name'] ?? 'Patient')} • ${report['category'] ?? 'General'}',
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

void _showBatchUploadModal(BuildContext context, WidgetRef ref) {
  const defaultCsv = '''patient_email,patient_name,test_name,category,parameter_name,value,unit,reference_range,is_abnormal,doctor_name,summary
manansoni2905@gmail.com,Manan Soni,Lipid Profile,Biochemistry,Total Cholesterol,195,mg/dL,125-200,false,Dr. Patel,Routine Lipid screening
manansoni2905@gmail.com,Manan Soni,Lipid Profile,Biochemistry,HDL Cholesterol,52,mg/dL,40-60,false,Dr. Patel,Good HDL level
manansoni2905@gmail.com,Manan Soni,Lipid Profile,Biochemistry,LDL Cholesterol,110,mg/dL,<100,true,Dr. Patel,Borderline elevated LDL''';

  final controller = TextEditingController(text: defaultCsv);
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.table_chart_rounded, color: kLabAccent),
            SizedBox(width: 8),
            Text('Batch CSV Ingest (Zero Work)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Directly ingest automated diagnostic batches from lab machines or CSV exports. Automatically binds reports to patient lockers.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'Paste CSV with patient_email, test_name, parameter_name, value...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Reset Template', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => controller.text = defaultCsv),
                  ),
                  const Text('Expected: patient_email, test_name, parameter_name, value...', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kLabAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: isSubmitting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_rounded, size: 16),
            label: Text(isSubmitting ? 'Ingesting...' : 'Ingest & Push to Lockers'),
            onPressed: isSubmitting
                ? null
                : () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    setState(() => isSubmitting = true);
                    try {
                      final res = await ApiClient().uploadLabBatchCsv(csvText: text);
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ref.read(labPendingReportsProvider.notifier).fetchOrders();
                        ref.read(reportsProvider.notifier).fetchReports();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${res['message'] ?? 'Batch uploaded successfully!'}'),
                            backgroundColor: kLabAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: AppColors.emergency,
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
}

