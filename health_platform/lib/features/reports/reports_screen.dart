import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_list_state.dart';
import '../../shared/widgets/web_constraint.dart';
import '../../core/config/providers.dart';
import '../../shared/models/lab_report.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ListStatus _viewStatus = ListStatus.content;

  void _showUploadReportModal(BuildContext context) {
    final nameController = TextEditingController();
    final labController = TextEditingController();
    final doctorController = TextEditingController();
    final notesController = TextEditingController();
    String selectedStatus = 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SingleChildScrollView(
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
                  const Text(
                    'Upload / Add Lab Diagnostic Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Report / Test Name *',
                      hintText: 'e.g. Complete Blood Count (CBC)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labController,
                    decoration: const InputDecoration(
                      labelText: 'Diagnostic Laboratory',
                      hintText: 'e.g. Metro Path Labs',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Prescribing Doctor',
                      hintText: 'e.g. Dr. Verma',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Test Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                    ],
                    onChanged: (v) => setModalState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Key Findings / Values',
                      hintText: 'e.g. Hemoglobin 14.2 g/dL, Platelets normal...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Save Report',
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;
                      final now = DateTime.now();
                      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final newReport = LabReport(
                        reportId: 'rep_${now.millisecondsSinceEpoch}',
                        patientId: 'patient_self',
                        reportName: nameController.text.trim(),
                        facilityName: labController.text.trim().isNotEmpty
                            ? labController.text.trim()
                            : 'Direct Upload',
                        reportDate: dateStr,
                        status: selectedStatus,
                        doctorName: doctorController.text.trim().isNotEmpty
                            ? doctorController.text.trim()
                            : null,
                        testParameters: [],
                      );
                      ref.read(reportsProvider.notifier).addReport(newReport);
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lab report saved successfully.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider);

    final activeStatus = (_viewStatus == ListStatus.content && reports.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lab & Diagnostic Reports'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
            tooltip: 'Upload Report',
            onPressed: () => _showUploadReportModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadReportModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: WebConstraint(
        maxWidth: 720,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListStatusSelector(
                currentStatus: _viewStatus,
                onStatusChanged: (s) => setState(() => _viewStatus = s),
              ),
              Expanded(
                child: AppListState(
                  status: activeStatus,
                  emptyMessage: 'No Diagnostic Reports',
                  emptyIcon: Icons.science_outlined,
                  errorMessage: 'Failed to fetch lab reports.',
                  onRetry: () => setState(() => _viewStatus = ListStatus.content),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () => _showReportDetail(context, report),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.science_outlined,
                                      color: Color(0xFF059669),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report.reportName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              report.reportDate,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  ...report.testParameters.take(3).map((param) {
                                    return _ParameterChip(
                                      name: param.parameterName,
                                      flag: param.flag,
                                    );
                                  }),
                                  if (report.testParameters.length > 3)
                                    AppBadge(
                                      text: '+${report.testParameters.length - 3} more',
                                      type: AppBadgeType.neutral,
                                      isSmall: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetail(BuildContext context, dynamic report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.science_outlined, color: Color(0xFF059669), size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report.reportName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(report.reportDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    if (report.facilityName != null)
                      _DetailRow(icon: Icons.local_hospital_outlined, label: 'Laboratory', value: report.facilityName!),
                    if (report.doctorName != null)
                      _DetailRow(icon: Icons.person_outlined, label: 'Ordering Doctor', value: report.doctorName!),
                    const Divider(height: AppSpacing.lg),
                    const Text('Test Parameters & Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    ...report.testParameters.map((param) => _ParameterCard(parameter: param)),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: 'Download PDF Report',
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading report PDF...')),
                        );
                      },
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final dynamic parameter;

  const _ParameterCard({required this.parameter});

  @override
  Widget build(BuildContext context) {
    final flagColor = _getFlagColor(parameter.flag);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: flagColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flagColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parameter.parameterName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '${parameter.value} ${parameter.unit ?? ""}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: flagColor),
                ),
              ],
            ),
          ),
          AppBadge(
            text: parameter.flag.toUpperCase(),
            type: _getBadgeType(parameter.flag),
            isSmall: true,
          ),
        ],
      ),
    );
  }

  Color _getFlagColor(String flag) {
    switch (flag.toLowerCase()) {
      case 'normal':
        return const Color(0xFF059669);
      case 'high':
        return const Color(0xFFD97706);
      case 'critical':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  AppBadgeType _getBadgeType(String flag) {
    switch (flag.toLowerCase()) {
      case 'normal':
        return AppBadgeType.success;
      case 'high':
        return AppBadgeType.warning;
      case 'critical':
        return AppBadgeType.error;
      default:
        return AppBadgeType.neutral;
    }
  }
}

class _ParameterChip extends StatelessWidget {
  final String name;
  final String flag;

  const _ParameterChip({required this.name, required this.flag});

  @override
  Widget build(BuildContext context) {
    final flagColor = _getFlagColor(flag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: flagColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: flagColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$name (${flag.toUpperCase()})',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: flagColor),
      ),
    );
  }

  Color _getFlagColor(String flag) {
    switch (flag.toLowerCase()) {
      case 'normal':
        return const Color(0xFF059669);
      case 'high':
        return const Color(0xFFD97706);
      case 'critical':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
