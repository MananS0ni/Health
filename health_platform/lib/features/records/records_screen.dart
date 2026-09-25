import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_list_state.dart';
import '../../shared/widgets/web_constraint.dart';
import '../../core/config/providers.dart';
import '../../shared/models/medical_record.dart';

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

  void _showAddRecordModal(BuildContext context) {
    final titleController = TextEditingController();
    final facilityController = TextEditingController();
    final doctorController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'prescription';

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
                    'Add New Medical Record',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Record Title *',
                      hintText: 'e.g. Health Checkup Consultation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Record Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                      DropdownMenuItem(value: 'discharge_summary', child: Text('Discharge Summary')),
                      DropdownMenuItem(value: 'imaging', child: Text('Diagnostic Imaging')),
                      DropdownMenuItem(value: 'vaccination', child: Text('Vaccination Record')),
                    ],
                    onChanged: (val) => setModalState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: facilityController,
                    decoration: const InputDecoration(
                      labelText: 'Health Facility / Hospital',
                      hintText: 'e.g. City Health Clinic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Attending Doctor Name',
                      hintText: 'e.g. Dr. Rajesh Verma',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes / Instructions',
                      hintText: 'Enter clinical observations or medicine advice...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Save Record',
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      final now = DateTime.now();
                      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final newRecord = MedicalRecord(
                        recordId: 'rec_${now.millisecondsSinceEpoch}',
                        patientId: 'patient_self',
                        title: titleController.text.trim(),
                        recordType: selectedType,
                        recordDate: dateStr,
                        facilityName: facilityController.text.trim().isNotEmpty
                            ? facilityController.text.trim()
                            : null,
                        doctorName: doctorController.text.trim().isNotEmpty
                            ? doctorController.text.trim()
                            : null,
                        description: notesController.text.trim().isNotEmpty
                            ? notesController.text.trim()
                            : null,
                      );
                      ref.read(recordsProvider.notifier).addRecord(newRecord);
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medical record added successfully.'),
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

  void _showAuthorizedProvidersModal(BuildContext context, dynamic record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer(
        builder: (context, ref, _) {
          final approvedConsents = ref
              .watch(patientConsentsProvider)
              .where((c) => c['status'] == 'approved')
              .toList();

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
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
                    Icon(Icons.shield_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Record Access Permissions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Only approved healthcare providers can view your medical history. You can revoke access at any time.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (approvedConsents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.lock_person_outlined, size: 36, color: AppColors.textSecondary),
                        SizedBox(height: 10),
                        Text(
                          'No Active Provider Access',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No doctor, lab, or hospital currently has access to your records.\n\nHealthcare providers must send access requests to you directly, which will appear on your Dashboard for approval.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: approvedConsents.length,
                      itemBuilder: (ctx, i) {
                        final consent = approvedConsents[i];
                        final rawName = consent['doctor_name'] ?? consent['doctor_email'] ?? 'Healthcare Provider';
                        final providerName = rawName.toString().toLowerCase().startsWith('dr.')
                            ? rawName.toString()
                            : 'Dr. $rawName';
                        final purpose = consent['purpose'] ?? 'Clinical Consultation';
                        final consentId = consent['id'].toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
                                    Row(
                                      children: [
                                        Text(
                                          providerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                      purpose,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.block_rounded, size: 14),
                                label: const Text('Revoke', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  Navigator.pop(modalContext);
                                  await ref.read(patientConsentsProvider.notifier).actionConsent(consentId, 'revoke');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Access revoked for $providerName.'),
                                        backgroundColor: const Color(0xFFDC2626),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Add Record',
            onPressed: () => _showAddRecordModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddRecordModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Record'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    if (record.attachments != null && record.attachments!.isNotEmpty) ...[
                      const Divider(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.description_rounded, color: Color(0xFF16A34A), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Certified File Attached to this Health Record',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        text: 'Open Attached Document',
                        onPressed: () {
                          final rawUrl = record.attachments!.first;
                          final fullUrl = rawUrl.startsWith('http')
                              ? rawUrl
                              : 'http://127.0.0.1:8000$rawUrl';
                          launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
                        },
                        isFullWidth: true,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      text: 'Record Access Permissions & Revoke',
                      onPressed: () {
                        Navigator.pop(context);
                        _showAuthorizedProvidersModal(context, record);
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
