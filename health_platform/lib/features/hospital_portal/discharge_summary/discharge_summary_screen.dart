import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';

const Color kHospitalAccent = Color(0xFFD97706);

class DischargeSummaryScreen extends StatefulWidget {
  final String? dischargeId;

  const DischargeSummaryScreen({super.key, this.dischargeId});

  @override
  State<DischargeSummaryScreen> createState() => _DischargeSummaryScreenState();
}

class _DischargeSummaryScreenState extends State<DischargeSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _admissionDateController = TextEditingController();
  final _dischargeDateController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _followUpController = TextEditingController();

  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _patientIdController.text = 'Meena Deshmukh (PAT008)';
    _admissionDateController.text = '2026-08-02';
    _dischargeDateController.text = '2026-08-07';
    _diagnosisController.text = 'Post-Op Total Knee Replacement (Right)';
    _treatmentController.text =
        'Right total knee replacement performed on 02-Aug-2026. Post-op recovery uneventful. Mobilized with walker. Wound healthy, clean dressing applied.';
    _followUpController.text =
        '1. Suture removal on 16-Aug-2026 at OPD Room 104.\n2. Tablet Pan-40 1-0-0 before breakfast for 7 days.\n3. Daily knee isometric exercises under physio guidance.';
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitted = true);
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _admissionDateController.dispose();
    _dischargeDateController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discharge Summary Note'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isSubmitted
          ? _buildSuccessState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kHospitalAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: kHospitalAccent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.output_rounded, color: kHospitalAccent),
                          SizedBox(width: 10),
                          Text(
                            'Official Hospital Discharge Document Entry',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kHospitalAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Patient Identifier
                    const Text('Patient Identifier *',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _patientIdController,
                      decoration: _dec('Patient Name / ID'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dates Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Admission Date *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _admissionDateController,
                                decoration: _dec('YYYY-MM-DD'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Discharge Date *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _dischargeDateController,
                                decoration: _dec('YYYY-MM-DD'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Diagnosis Summary
                    const Text('Diagnosis Summary *',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: _dec('Primary & secondary diagnosis'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Treatment Summary
                    const Text('Hospital Course & Treatment Summary *',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _treatmentController,
                      maxLines: 4,
                      decoration: _dec('Summary of procedures & progress...'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Follow-Up Instructions
                    const Text('Follow-Up Instructions & Discharge Advice *',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _followUpController,
                      maxLines: 4,
                      decoration: _dec('Medications, precautions, OPD date...'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Button
                    AppButton(
                      text: 'Finalize & Sign Discharge Note',
                      onPressed: _handleSubmit,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Discharge Summary Finalized!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The official discharge note has been generated and published to the patient\'s EHR timeline & hospital billing gateway.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/hospital'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kHospitalAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Return to Hospital Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      borderSide: const BorderSide(color: kHospitalAccent, width: 1.5),
    ),
  );
}
