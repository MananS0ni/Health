import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/config/providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_list_state.dart';

const Color kLabAccent = Color(0xFF059669);

class PendingReportsScreen extends ConsumerStatefulWidget {
  const PendingReportsScreen({super.key});

  @override
  ConsumerState<PendingReportsScreen> createState() => _PendingReportsScreenState();
}

class _PendingReportsScreenState extends ConsumerState<PendingReportsScreen> {
  String _selectedCategory = 'All';
  ListStatus _viewStatus = ListStatus.content;

  static String _maskPatientName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first} ${parts.last[0]}.';
    }
    return fullName;
  }

  void _showAddTestModal(BuildContext context) {
    final nameController = TextEditingController();
    final patientController = TextEditingController();
    final doctorController = TextEditingController();
    String category = 'Biochemistry';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                    'Queue New Diagnostic Test',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: patientController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Full Name *',
                      hintText: 'e.g. Meera Desai',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Test Name *',
                      hintText: 'e.g. Lipid Profile, Serum Creatinine',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Test Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Biochemistry', child: Text('Biochemistry')),
                      DropdownMenuItem(value: 'Endocrinology', child: Text('Endocrinology')),
                      DropdownMenuItem(value: 'Cardiology', child: Text('Cardiology')),
                      DropdownMenuItem(value: 'Diabetology', child: Text('Diabetology')),
                      DropdownMenuItem(value: 'Nephrology', child: Text('Nephrology')),
                    ],
                    onChanged: (v) => setModalState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Referring Doctor',
                      hintText: 'e.g. Dr. Verma',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty || patientController.text.trim().isEmpty) return;
                      final now = DateTime.now();
                      final test = {
                        'order_id': 'ORD-${now.millisecondsSinceEpoch.toString().substring(8)}',
                        'test_id': 'TST-${now.millisecondsSinceEpoch.toString().substring(9)}',
                        'patient_name': patientController.text.trim(),
                        'test_name': nameController.text.trim(),
                        'category': category,
                        'ordered_by': doctorController.text.trim().isNotEmpty
                            ? doctorController.text.trim()
                            : 'OPD Physician',
                        'sample_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                        'status': 'Sample Collected',
                        'urgency': 'Routine',
                      };
                      ref.read(labPendingReportsProvider.notifier).addPendingTest(test);
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Test queued for ${test['patient_name']}.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kLabAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: const Text('Add Test to Queue'),
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
    final pendingReports = ref.watch(labPendingReportsProvider);
    final categories = [
      'All',
      'Biochemistry',
      'Endocrinology',
      'Cardiology',
      'Diabetology',
      'Nephrology'
    ];

    final filtered = pendingReports.where((r) {
      if (_selectedCategory == 'All') return true;
      return r['category'] == _selectedCategory;
    }).toList();

    final activeStatus = (_viewStatus == ListStatus.content && filtered.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pending Reports Queue'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: kLabAccent),
            tooltip: 'Queue Test Order',
            onPressed: () => _showAddTestModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddTestModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Queue Test'),
        backgroundColor: kLabAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListStatusSelector(
              currentStatus: _viewStatus,
              onStatusChanged: (s) => setState(() => _viewStatus = s),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: kLabAccent.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? kLabAccent : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: selected ? kLabAccent : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AppListState(
                status: activeStatus,
                emptyMessage: 'No Pending Lab Orders',
                emptyIcon: Icons.assignment_turned_in_outlined,
                errorMessage: 'LIMS order synchronization error.',
                accentColor: kLabAccent,
                onRetry: () => setState(() => _viewStatus = ListStatus.content),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final report = filtered[index];
                    final isUrgent = report['urgency'] == 'Urgent';
                    final maskedName = _maskPatientName(report['patient_name']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        onTap: () {
                          context.go(
                              '/lab/upload?order=${report['order_id']}&patient=$maskedName&test=${Uri.encodeComponent(report['test_name'])}&category=${report['category']}');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kLabAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    report['order_id'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kLabAccent,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (isUrgent) ...[
                                      const AppBadge(
                                        text: 'URGENT',
                                        type: AppBadgeType.warning,
                                        isSmall: true,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    AppBadge(
                                      text: report['status'],
                                      type: report['status'] == 'Testing In Progress'
                                          ? AppBadgeType.info
                                          : AppBadgeType.neutral,
                                      isSmall: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              report['test_name'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient: $maskedName (${report['patient_id']}) • Category: ${report['category']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Requested Date: ${report['ordered_date']} • By: ${report['ordered_by']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    context.go(
                                        '/lab/upload?order=${report['order_id']}&patient=$maskedName&test=${Uri.encodeComponent(report['test_name'])}&category=${report['category']}');
                                  },
                                  icon: const Icon(Icons.upload_file_outlined, size: 14),
                                  label: const Text('Process & Fill Parameters'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: kLabAccent,
                                  ),
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
    );
  }
}
