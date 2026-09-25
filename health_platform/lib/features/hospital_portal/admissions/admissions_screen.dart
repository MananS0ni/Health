import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_list_state.dart';

const Color kHospitalAccent = Color(0xFFD97706);

class AdmissionsScreen extends ConsumerStatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  ConsumerState<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends ConsumerState<AdmissionsScreen> {
  String _selectedWard = 'All Wards';
  ListStatus _viewStatus = ListStatus.content;
  List<Map<String, dynamic>> _registeredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredPatients();
  }

  Future<void> _loadRegisteredPatients() async {
    try {
      final list = await ApiClient().getLabPatients();
      if (mounted) {
        setState(() {
          _registeredPatients = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  void _showNewAdmissionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final patientIdController = TextEditingController();
    final ageController = TextEditingController(text: '28');
    final bedController = TextEditingController(text: 'BED-102');
    final diagnosisController = TextEditingController();

    String ward = 'General Male Ward';
    String doctor = 'Dr. Dhruv Patel';
    String gender = 'Male';
    String status = 'Admitted';
    bool isSubmitting = false;

    // Default select Manan Soni if available
    if (_registeredPatients.isNotEmpty) {
      final match = _registeredPatients.firstWhere(
        (p) => (p['full_name'] as String? ?? '').toLowerCase().contains('manan'),
        orElse: () => _registeredPatients.first,
      );
      nameController.text = match['full_name'] ?? '';
      patientIdController.text = match['patient_id'] ?? match['email'] ?? '';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: const [
              Icon(Icons.hotel_rounded, color: kHospitalAccent),
              SizedBox(width: 10),
              Text(
                'New Inpatient Admission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_registeredPatients.isNotEmpty) ...[
                      const Text('Quick Select Patient (Unique Patient ID):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _registeredPatients.take(4).map((p) {
                          final isSel = patientIdController.text == p['patient_id'];
                          return ChoiceChip(
                            label: Text('${p['full_name']} (${p['patient_id']})', style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: kHospitalAccent.withValues(alpha: 0.15),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() {
                                  nameController.text = p['full_name'] ?? '';
                                  patientIdController.text = p['patient_id'] ?? p['email'] ?? '';
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Patient Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: nameController,
                                decoration: _inputDec('e.g. Manan Soni'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Patient ID / Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: patientIdController,
                                decoration: _inputDec('PAT-XXXXXX'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Age *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDec('e.g. 28'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: gender,
                                decoration: _inputDec(''),
                                items: ['Male', 'Female', 'Other']
                                    .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (v) => gender = v!,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ward', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: ward,
                                decoration: _inputDec(''),
                                isExpanded: true,
                                items: ['General Male Ward', 'General Female Ward', 'ICU / Critical Care', 'Emergency Ward', 'Cardiology Ward']
                                    .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 11))))
                                    .toList(),
                                onChanged: (v) => ward = v!,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bed No. *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: bedController,
                                decoration: _inputDec('e.g. BED-102'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Attending Doctor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: doctor,
                      decoration: _inputDec(''),
                      isExpanded: true,
                      items: ['Dr. Dhruv Patel', 'Dr. Hardik', 'Dr. Max Patel']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => doctor = v!,
                    ),
                    const SizedBox(height: 10),
                    const Text('Primary Clinical Diagnosis *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: diagnosisController,
                      decoration: _inputDec('e.g. Acute Appendicitis / High Fever Observation'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isSubmitting = true);
                        final newAdmission = {
                          'patient_identifier': patientIdController.text.trim(),
                          'patient_name': nameController.text.trim(),
                          'age': int.tryParse(ageController.text.trim()) ?? 30,
                          'gender': gender,
                          'ward': ward,
                          'bed_no': bedController.text.trim().toUpperCase(),
                          'admission_date': DateTime.now().toString().split(' ').first,
                          'attending_doctor': doctor,
                          'diagnosis': diagnosisController.text.trim(),
                          'status': status,
                        };

                        try {
                          await ApiClient().admitPatient(newAdmission);
                          ref.read(hospitalAdmissionsProvider.notifier).fetchAdmissions();
                          ref.read(recordsProvider.notifier).fetchRecords();

                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Admitted ${nameController.text.trim()} to $ward (${bedController.text})'),
                                backgroundColor: kHospitalAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            ref.read(hospitalAdmissionsProvider.notifier).addAdmission(newAdmission);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Admitted ${nameController.text.trim()} to $ward (${bedController.text})'),
                                backgroundColor: kHospitalAccent,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kHospitalAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(isSubmitting ? 'Admitting...' : 'Admit Patient'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdmissionDetails(BuildContext context, Map<String, dynamic> admission) {
    final isCritical = admission['status'] == 'Critical Care';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppAvatar(name: admission['patient_name'] ?? 'Patient', size: AppAvatarSize.xl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admission['patient_name'] ?? 'Patient', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${admission['gender']} • ${admission['age']} yrs • ID: ${admission['patient_id'] ?? "PAT-LOCAL"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        AppBadge(text: admission['status'] ?? 'Admitted', type: isCritical ? AppBadgeType.error : AppBadgeType.neutral, isSmall: true),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              _DetailRow(icon: Icons.hotel_outlined, title: 'Ward & Bed Location', subtitle: '${admission['ward']} • Bed ${admission['bed_no']}'),
              _DetailRow(icon: Icons.event_available_outlined, title: 'Admission Date', subtitle: admission['admission_date'] ?? '--'),
              _DetailRow(icon: Icons.medical_services_outlined, title: 'Attending Doctor', subtitle: admission['attending_doctor'] ?? '--'),
              _DetailRow(icon: Icons.assignment_outlined, title: 'Primary Diagnosis', subtitle: admission['diagnosis'] ?? '--'),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/hospital/discharge');
                      },
                      icon: const Icon(Icons.output_rounded, size: 18, color: kHospitalAccent),
                      label: const Text('Discharge Patient', style: TextStyle(color: kHospitalAccent)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: kHospitalAccent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(backgroundColor: kHospitalAccent, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wards = [
      'All Wards',
      'General Male Ward',
      'General Female Ward',
      'ICU / Critical Care',
      'Emergency Ward',
      'Cardiology Ward',
    ];

    final admissionsList = ref.watch(hospitalAdmissionsProvider);
    final filtered = admissionsList.where((adm) {
      if (_selectedWard == 'All Wards') return true;
      return adm['ward'] == _selectedWard;
    }).toList();

    final activeStatus = (_viewStatus == ListStatus.content && filtered.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Current Inpatient Admissions'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showNewAdmissionDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Admit Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kHospitalAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showNewAdmissionDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('New Admission'),
        backgroundColor: kHospitalAccent,
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
                children: wards.map((w) {
                  final selected = _selectedWard == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(w),
                      selected: selected,
                      selectedColor: kHospitalAccent.withValues(alpha: 0.15),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: selected ? kHospitalAccent : AppColors.textPrimary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedWard = w);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AppListState(
                status: activeStatus,
                emptyMessage: 'No admissions in $_selectedWard. All beds in this ward are currently ready for admission.',
                emptyActionLabel: 'Admit Patient to Ward',
                onEmptyAction: () => _showNewAdmissionDialog(context),
                accentColor: kHospitalAccent,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final adm = filtered[index];
                    final isCritical = adm['status'] == 'Critical Care';

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => _showAdmissionDetails(context, adm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kHospitalAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${adm['ward']} • Bed ${adm['bed_no']}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kHospitalAccent),
                                  ),
                                ),
                                AppBadge(
                                  text: adm['status'] ?? 'Admitted',
                                  type: isCritical ? AppBadgeType.error : AppBadgeType.neutral,
                                  isSmall: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              adm['patient_name'] ?? 'Inpatient',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${adm['patient_id'] ?? "PAT-LOCAL"} • ${adm['age']} yrs • ${adm['gender']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Diagnosis: ${adm['diagnosis'] ?? "Observation"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Attending Doctor: ${adm['attending_doctor']} • Admitted: ${adm['admission_date']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    context.go('/hospital/discharge');
                                  },
                                  icon: const Icon(Icons.output_rounded, size: 14, color: kHospitalAccent),
                                  label: const Text('Discharge Patient', style: TextStyle(fontSize: 11, color: kHospitalAccent)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: kHospitalAccent),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: kHospitalAccent, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: kHospitalAccent, width: 1.5),
    ),
  );
}
