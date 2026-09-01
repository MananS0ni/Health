import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock_data/mock_hospital_data.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_list_state.dart';

const Color kHospitalAccent = Color(0xFFD97706);

class AdmissionsScreen extends StatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  String _selectedWard = 'All Wards';
  late List<Map<String, dynamic>> _admissionsList;
  ListStatus _viewStatus = ListStatus.content;

  @override
  void initState() {
    super.initState();
    _admissionsList = List.from(MockHospitalData.getAdmissions());
  }

  void _showNewAdmissionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final bedController = TextEditingController();
    final diagnosisController = TextEditingController();

    String ward = 'General Male Ward';
    String doctor = 'Dr. Max Patel';
    String gender = 'Male';
    String status = 'Admitted';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDec('e.g. Rajesh Kumar'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                              decoration: _inputDec('e.g. 42'),
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
                              items: ['General Male Ward', 'ICU Ward 2', 'Private Ward A', 'Semi-Private Ward B']
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
                              decoration: _inputDec('e.g. B-105'),
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
                    items: ['Dr. Max Patel', 'Dr. S. K. Gupta', 'Dr. R. Mehta']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => doctor = v!,
                  ),
                  const SizedBox(height: 10),
                  const Text('Primary Diagnosis *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: diagnosisController,
                    decoration: _inputDec('Reason for admission'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newAdmission = {
                  'admission_id': 'ADM_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  'patient_id': 'PAT010',
                  'patient_name': nameController.text.trim(),
                  'age': int.tryParse(ageController.text.trim()) ?? 35,
                  'gender': gender,
                  'ward': ward,
                  'bed_no': bedController.text.trim().toUpperCase(),
                  'admission_date': DateTime.now().toString().split(' ').first,
                  'attending_doctor': doctor,
                  'diagnosis': diagnosisController.text.trim(),
                  'status': status,
                };

                setState(() {
                  _admissionsList.insert(0, newAdmission);
                });

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admitted ${nameController.text.trim()} to $ward ($bedController)'),
                    backgroundColor: kHospitalAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kHospitalAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Admit Patient'),
          ),
        ],
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
                  AppAvatar(name: admission['patient_name'], size: AppAvatarSize.xl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admission['patient_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${admission['gender']} • ${admission['age']} yrs • ID: ${admission['patient_id']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        AppBadge(text: admission['status'], type: isCritical ? AppBadgeType.error : AppBadgeType.neutral, isSmall: true),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              _DetailRow(icon: Icons.hotel_outlined, title: 'Ward & Bed Location', subtitle: '${admission['ward']} • Bed ${admission['bed_no']}'),
              _DetailRow(icon: Icons.event_available_outlined, title: 'Admission Date', subtitle: admission['admission_date']),
              _DetailRow(icon: Icons.medical_services_outlined, title: 'Attending Doctor', subtitle: admission['attending_doctor']),
              _DetailRow(icon: Icons.assignment_outlined, title: 'Primary Diagnosis', subtitle: admission['diagnosis']),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Close Details'),
                style: ElevatedButton.styleFrom(backgroundColor: kHospitalAccent, foregroundColor: Colors.white),
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
      'ICU Ward 2',
      'Private Ward A',
      'Semi-Private Ward B'
    ];

    final filtered = _admissionsList.where((adm) {
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
        onPressed: () => _showNewAdmissionDialog(context),
        backgroundColor: kHospitalAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Admit Patient'),
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
                children: wards.map((ward) {
                  final selected = _selectedWard == ward;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(ward),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedWard = ward);
                      },
                      selectedColor: kHospitalAccent.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? kHospitalAccent : AppColors.textSecondary,
                      ),
                      side: BorderSide(color: selected ? kHospitalAccent : AppColors.border),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AppListState(
                status: activeStatus,
                emptyMessage: 'No Admissions in Selected Ward',
                emptyIcon: Icons.hotel_outlined,
                errorMessage: 'HIS Ward Occupancy Sync Error.',
                accentColor: kHospitalAccent,
                onRetry: () => setState(() => _viewStatus = ListStatus.content),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final adm = filtered[index];
                    final isCritical = adm['status'] == 'Critical Care';

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                  text: adm['status'],
                                  type: isCritical ? AppBadgeType.error : AppBadgeType.neutral,
                                  isSmall: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              adm['patient_name'],
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${adm['patient_id']} • ${adm['age']} yrs • ${adm['gender']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Diagnosis: ${adm['diagnosis']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Attending Doctor: ${adm['attending_doctor']} • Admitted: ${adm['admission_date']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
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
