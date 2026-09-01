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

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  String _selectedFilter = 'all';
  ListStatus _viewStatus = ListStatus.content;
  final Map<String, String> _sharedRecordsMap = {}; // recordId -> doctorName + duration

  final List<String> _filters = [
    'all',
    'prescription',
    'discharge_summary',
    'imaging',
    'vaccination',
  ];

  void _showShareDoctorModal(BuildContext context, dynamic record) {
    String selectedDoctor = 'Dr. Max Patel (General Medicine)';
    String accessDuration = '7 Days';

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
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.share_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Share Health Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Grant secure access for "${record.title}" to a verified doctor.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              const Text('Select Doctor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedDoctor,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'Dr. Max Patel (General Medicine)', child: Text('Dr. Max Patel (General Medicine)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Dr. S. K. Gupta (Cardiology)', child: Text('Dr. S. K. Gupta (Cardiology)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Dr. R. Mehta (Ortho)', child: Text('Dr. R. Mehta (Ortho)', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) => setModalState(() => selectedDoctor = v!),
              ),
              const SizedBox(height: 14),

              const Text('Access Validity Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['24 Hours', '7 Days', '30 Days', 'Permanent'].map((duration) {
                  final selected = accessDuration == duration;
                  return ChoiceChip(
                    label: Text(duration),
                    selected: selected,
                    onSelected: (val) {
                      if (val) setModalState(() => accessDuration = duration);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              AppButton(
                text: 'Grant Access to $selectedDoctor',
                onPressed: () {
                  final doctorShortName = selectedDoctor.split(' (').first;
                  setState(() {
                    _sharedRecordsMap[record.recordId] = '$doctorShortName ($accessDuration)';
                  });
                  Navigator.pop(modalContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Access granted to $doctorShortName for $accessDuration.'),
                      backgroundColor: AppColors.primary,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recordsProvider);
    final filteredRecords = _selectedFilter == 'all'
        ? records
        : records.where((r) => r.recordType == _selectedFilter).toList();

    final activeStatus = (_viewStatus == ListStatus.content && filteredRecords.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: WebConstraint(
        maxWidth: 720,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
              child: ListStatusSelector(
                currentStatus: _viewStatus,
                onStatusChanged: (s) => setState(() => _viewStatus = s),
              ),
            ),
            // Filter Chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: AppColors.surfaceVariant,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppListState(
                  status: activeStatus,
                  emptyMessage: 'No Health Records Found',
                  emptyIcon: Icons.folder_open_outlined,
                  errorMessage: 'Failed to retrieve records from health server.',
                  onRetry: () => setState(() => _viewStatus = ListStatus.content),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      final sharedInfo = _sharedRecordsMap[record.recordId];

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () => _showRecordDetail(context, record),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _getRecordTypeColor(record.recordType).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getRecordTypeIcon(record.recordType),
                                      color: _getRecordTypeColor(record.recordType),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.title,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              record.recordDate,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                            if (record.facilityName != null) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.local_hospital_outlined, size: 12, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  record.facilityName!,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppBadge(
                                    text: _getFilterLabel(record.recordType),
                                    type: AppBadgeType.neutral,
                                    isSmall: true,
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                                ],
                              ),
                              if (sharedInfo != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_open_rounded, size: 12, color: Color(0xFF059669)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Shared with $sharedInfo',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'prescription':
        return 'Prescription';
      case 'discharge_summary':
        return 'Discharge';
      case 'imaging':
        return 'Imaging';
      case 'vaccination':
        return 'Vaccination';
      default:
        return filter;
    }
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type) {
      case 'prescription':
        return Icons.medication_outlined;
      case 'discharge_summary':
        return Icons.description_outlined;
      case 'imaging':
        return Icons.image_outlined;
      case 'vaccination':
        return Icons.vaccines_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Color _getRecordTypeColor(String type) {
    switch (type) {
      case 'prescription':
        return AppColors.primary;
      case 'discharge_summary':
        return const Color(0xFFD97706);
      case 'imaging':
        return const Color(0xFF1E40AF);
      case 'vaccination':
        return const Color(0xFF059669);
      default:
        return AppColors.textSecondary;
    }
  }

  void _showRecordDetail(BuildContext context, dynamic record) {
    final sharedInfo = _sharedRecordsMap[record.recordId];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                            color: _getRecordTypeColor(record.recordType).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getRecordTypeIcon(record.recordType), color: _getRecordTypeColor(record.recordType), size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              AppBadge(text: _getFilterLabel(record.recordType), type: AppBadgeType.neutral, isSmall: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(icon: Icons.calendar_today_outlined, label: 'Record Date', value: record.recordDate),
                    if (record.facilityName != null)
                      _DetailRow(icon: Icons.local_hospital_outlined, label: 'Health Facility', value: record.facilityName!),
                    if (record.doctorName != null)
                      _DetailRow(icon: Icons.person_outlined, label: 'Attending Doctor', value: record.doctorName!),

                    if (sharedInfo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Active Access Granted: Shared with $sharedInfo',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (record.description != null) ...[
                      const Divider(height: AppSpacing.lg),
                      const Text('Clinical Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(record.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      text: sharedInfo == null ? 'Share Record with Doctor' : 'Update / Revoke Doctor Access',
                      onPressed: () {
                        Navigator.pop(context);
                        _showShareDoctorModal(context, record);
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
