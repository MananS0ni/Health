import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

const Color kHospitalAccent = Color(0xFFD97706);

class DischargeSummaryScreen extends ConsumerStatefulWidget {
  final String? dischargeId;

  const DischargeSummaryScreen({super.key, this.dischargeId});

  @override
  ConsumerState<DischargeSummaryScreen> createState() => _DischargeSummaryScreenState();
}

class _DischargeSummaryScreenState extends ConsumerState<DischargeSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _admissionDateController = TextEditingController();
  final _dischargeDateController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _followUpController = TextEditingController();

  Map<String, dynamic>? _selectedAdmission;
  List<int>? _documentBytes;
  String? _documentName;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _dischargeDateController.text = DateTime.now().toString().split(' ').first;
    _treatmentController.text = '';
    _followUpController.text = '';
  }

  void _selectInpatient(Map<String, dynamic> adm) {
    setState(() {
      _selectedAdmission = adm;
      _patientNameController.text = adm['patient_name'] ?? '';
      _patientIdController.text = adm['patient_id'] ?? '';
      _admissionDateController.text = adm['admission_date'] ?? DateTime.now().toString().split(' ').first;
      _diagnosisController.text = adm['diagnosis'] ?? '';
    });
  }

  Future<void> _handleDischarge() async {
    if (_selectedAdmission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active inpatient.'),
          backgroundColor: AppColors.emergency,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final admissionId = _selectedAdmission!['admission_id'] as String;
      final notes = '${_treatmentController.text.trim()}\n\nFollow-up Instructions:\n${_followUpController.text.trim()}';

      final fields = {'discharge_notes':notes,'discharge_date':_dischargeDateController.text.trim()};
      if (_documentBytes != null) {
        await ApiClient().uploadDocument('/hospital/admissions/$admissionId/discharge/',fields,_documentName!,_documentBytes!);
      } else { await ApiClient().dischargePatient(admissionId,fields); }

      // Refresh stores so patient records and hospital admissions reflect immediately
      ref.read(hospitalAdmissionsProvider.notifier).fetchAdmissions();
      ref.read(recordsProvider.notifier).fetchRecords();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Discharge failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
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
    final admissions = ref.watch(hospitalAdmissionsProvider);
    final activeInpatients = admissions.where((a) => a['status'] != 'Discharged').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hospital Discharge Summary Note'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions:[TextButton.icon(onPressed:_isSubmitting ? null : () async {
          try {
            final file=await FilePicker.pickFile(type:FileType.custom,allowedExtensions:['pdf','doc','docx']);
            if(file==null)return;
            final bytes=await file.readAsBytes();
            if(bytes.length>10*1024*1024)throw Exception('File exceeds 10 MB.');
            if(mounted)setState((){_documentBytes=bytes;_documentName=file.name;});
          }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
        },icon:const Icon(Icons.attach_file),label:Text(_documentName ?? 'Attach Word/PDF'))],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/hospital'),
        ),
      ),
      body: _isSubmitted
          ? _buildSuccessState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kHospitalAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kHospitalAccent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.output_rounded, color: kHospitalAccent, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Discharge Engine: Finalizes hospital stay, frees ward bed, and automatically synchronizes the certified Discharge Summary into the patient\'s personal Medical Records.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Active Inpatient Selector
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.hotel_rounded, color: kHospitalAccent, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Select Admitted Patient to Discharge',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Text(
                                '${activeInpatients.length} Active Inpatients',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kHospitalAccent),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (activeInpatients.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No active inpatients in hospital beds. You can enter patient details manually below or admit a patient first.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: activeInpatients.map((adm) {
                                final isSel = _selectedAdmission?['admission_id'] == adm['admission_id'];
                                return ChoiceChip(
                                  label: Text('${adm['patient_name']} (${adm['ward']} • Bed ${adm['bed_no']})'),
                                  selected: isSel,
                                  selectedColor: kHospitalAccent.withValues(alpha: 0.15),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? kHospitalAccent : AppColors.textPrimary,
                                  ),
                                  onSelected: (val) {
                                    if (val) _selectInpatient(adm);
                                  },
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Patient Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _patientNameController,
                                      decoration: _inputDec('e.g. Manan Soni'),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Unique Patient ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _patientIdController,
                                      decoration: _inputDec('e.g. PAT-4726A2'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Admission & Discharge Dates & Diagnosis
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Admission Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _admissionDateController,
                                      decoration: _inputDec('YYYY-MM-DD'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Discharge Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _dischargeDateController,
                                      decoration: _inputDec('YYYY-MM-DD'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Final Discharge Diagnosis *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _diagnosisController,
                            decoration: _inputDec('e.g. Acute Gastroenteritis, Resolved'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Clinical Course & Follow-up
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Treatment & Clinical Course Summary *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _treatmentController,
                            maxLines: 4,
                            decoration: _inputDec('Summary of inpatient care and interventions...'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          const Text('Discharge Advice & Follow-Up Protocol', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _followUpController,
                            maxLines: 3,
                            decoration: _inputDec('Medications, precautions, and return visit date...'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Action
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleDischarge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kHospitalAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _isSubmitting ? 'Finalizing Discharge & Syncing Locker...' : 'Finalize Discharge & Push to Patient Locker',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded, color: kHospitalAccent, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Discharge Finalized & Synced!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The bed has been marked available and the Discharge Summary has been attached directly to ${_patientNameController.text}\'s digital health locker.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSubmitted = false;
                        _selectedAdmission = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Discharge Another Patient'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/hospital'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kHospitalAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Return to Hospital Portal'),
                  ),
                ),
              ],
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
