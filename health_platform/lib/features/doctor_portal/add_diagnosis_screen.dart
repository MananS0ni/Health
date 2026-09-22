import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class AddDiagnosisScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const AddDiagnosisScreen({
    super.key,
    this.patientId,
  });

  @override
  ConsumerState<AddDiagnosisScreen> createState() => _AddDiagnosisScreenState();
}

class _AddDiagnosisScreenState extends ConsumerState<AddDiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();

  final List<Map<String, String>> _addedMedicines = [];
  DateTime _followUpDate = DateTime.now().add(const Duration(days: 14));
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
  }

  void _addMedicine() {
    if (_medNameController.text.trim().isNotEmpty) {
      setState(() {
        _addedMedicines.add({
          'name': _medNameController.text.trim(),
          'dosage': _dosageController.text.trim().isEmpty
              ? '1-0-1'
              : _dosageController.text.trim(),
          'duration': '14 Days',
        });
        _medNameController.clear();
        _dosageController.clear();
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = ref.read(userProvider);
        final payload = {
          'patient_id': widget.patientId,
          'doctor_email': (user.email != null && user.email!.isNotEmpty) ? user.email : 'sonimanan2905@gmail.com',
          'doctor_name': user.fullName.isNotEmpty ? user.fullName : 'Dhruv Patel',
          'diagnosis': _diagnosisController.text.trim(),
          'clinical_notes': _notesController.text.trim(),
          'medicines': _addedMedicines.map((m) => {
            'medicine_name': m['name'] ?? '',
            'dosage': m['dosage'] ?? '1-0-1',
            'duration': m['duration'] ?? '14 Days',
            'instructions': 'As prescribed',
          }).toList(),
        };
        await ApiClient().createPrescription(payload);
        ref.read(recordsProvider.notifier).fetchRecords();
        ref.read(timelineProvider.notifier).fetchTimeline();
        if (mounted) {
          setState(() => _isSubmitted = true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save diagnosis: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.emergency,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _medNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(doctorPatientsProvider);
    final patientRecord = patients.firstWhere(
      (p) => (p['id'] != null && p['id'] == widget.patientId) ||
             (p['patient_id'] != null && p['patient_id'] == widget.patientId),
      orElse: () => {
        'patient_id': widget.patientId ?? 'PAT-001',
        'full_name': widget.patientId != null ? 'Patient (${widget.patientId})' : 'Patient',
        'gender': 'Not specified',
        'age': '--',
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Clinical Diagnosis & Rx'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/doctor');
            }
          },
        ),
      ),
      body: _isSubmitted
          ? _buildSuccessView(context, patientRecord['full_name'])
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header Summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kDoctorAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kDoctorAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: kDoctorAccent),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient: ${patientRecord['full_name']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kDoctorAccent,
                                ),
                              ),
                              Text(
                                'ID: ${patientRecord['patient_id']} • ${patientRecord['gender']} • ${patientRecord['age']} yrs',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Primary Diagnosis Input
                    const Text(
                      'Primary Diagnosis *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: _inputDec('e.g. Acute Pharyngitis / Type 2 Diabetes'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter primary diagnosis' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Clinical Notes & Advice
                    const Text(
                      'Clinical Notes & Advice',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: _inputDec('Enter clinical observations, lifestyle advice...'),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Medicines / Prescription Entry Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Prescription (Rx)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Add medicines below',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Inline Medicine Add Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _medNameController,
                            decoration: _inputDec('Medicine Name (e.g. Paracetamol 650mg)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _dosageController,
                            decoration: _inputDec('Dosage (1-0-1)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addMedicine,
                          icon: const Icon(Icons.add, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: kDoctorAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Added Medicines List
                    if (_addedMedicines.isEmpty)
                      const Text(
                        'No medicines added yet.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      )
                    else
                      ..._addedMedicines.map(
                        (med) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medication, size: 16, color: kDoctorAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  med['name']!,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${med['dosage']} • ${med['duration']}',
                                style:
                                    const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: AppColors.emergency),
                                onPressed: () {
                                  setState(() => _addedMedicines.remove(med));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    // Follow-up Date Row
                    Row(
                      children: [
                        const Icon(Icons.event_repeat_rounded, color: kDoctorAccent),
                        const SizedBox(width: 8),
                        const Text(
                          'Follow-Up Date:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _followUpDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setState(() => _followUpDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: Text(
                            '${_followUpDate.day}/${_followUpDate.month}/${_followUpDate.year}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kDoctorAccent,
                            side: const BorderSide(color: kDoctorAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _handleSubmit,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text(
                          'Save & Issue Prescription',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDoctorAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessView(BuildContext context, String patientName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Diagnosis Saved Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prescription and clinical note updated for $patientName. Patient has been notified via WhatsApp & App notification.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                context.go('/doctor');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kDoctorAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Back to Doctor Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kDoctorAccent, width: 1.5),
    ),
  );
}
