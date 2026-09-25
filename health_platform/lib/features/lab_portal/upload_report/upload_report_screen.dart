import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

const Color kLabAccent = Color(0xFF059669);

class UploadReportScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? patient;
  final String? test;
  final String? category;

  const UploadReportScreen({
    super.key,
    this.orderId,
    this.patient,
    this.test,
    this.category,
  });

  @override
  ConsumerState<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends ConsumerState<UploadReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdentifierController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _doctorController = TextEditingController();
  final _summaryController = TextEditingController();

  String _selectedTest = 'Complete Blood Count (CBC)';
  String _selectedCategory = 'Hematology';
  String? _attachedFileName;
  int _attachedFileSizeKb = 148;
  bool _isCustomFile = false;

  bool _isLoadingPatients = false;
  List<Map<String, dynamic>> _registeredPatients = [];
  Map<String, dynamic>? _selectedPatient;

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  Map<String, dynamic>? _submissionResult;

  final Map<String, Map<String, dynamic>> _presetTests = {
    'Complete Blood Count (CBC)': {
      'category': 'Hematology',
      'sample_file': 'CBC_Automated_Hemogram_Report.pdf',
      'size_kb': 142,
      'preview': [
        {'name': 'Hemoglobin', 'value': '14.2 g/dL', 'range': '13.0 - 17.0', 'flag': 'Normal'},
        {'name': 'RBC Count', 'value': '4.85 mil/uL', 'range': '4.50 - 5.90', 'flag': 'Normal'},
        {'name': 'Total WBC Count', 'value': '7,100 /cumm', 'range': '4,000 - 11,000', 'flag': 'Normal'},
        {'name': 'Platelet Count', 'value': '240,000 /cumm', 'range': '150,000 - 450,000', 'flag': 'Normal'},
        {'name': 'Packed Cell Volume (PCV)', 'value': '42.8 %', 'range': '40.0 - 50.0', 'flag': 'Normal'},
      ],
    },
    'Lipid Profile Panel': {
      'category': 'Biochemistry',
      'sample_file': 'Lipid_Profile_Serum_Panel.pdf',
      'size_kb': 186,
      'preview': [
        {'name': 'Total Cholesterol', 'value': '194 mg/dL', 'range': '< 200', 'flag': 'Normal'},
        {'name': 'HDL (Good Cholesterol)', 'value': '53 mg/dL', 'range': '> 40', 'flag': 'Normal'},
        {'name': 'LDL (Bad Cholesterol)', 'value': '112 mg/dL', 'range': '< 100', 'flag': 'High'},
        {'name': 'Triglycerides', 'value': '142 mg/dL', 'range': '< 150', 'flag': 'Normal'},
      ],
    },
    'HbA1c & Fasting Glucose': {
      'category': 'Biochemistry',
      'sample_file': 'Glycemic_Index_HbA1c_Report.pdf',
      'size_kb': 118,
      'preview': [
        {'name': 'Fasting Blood Glucose', 'value': '95 mg/dL', 'range': '70 - 100', 'flag': 'Normal'},
        {'name': 'HbA1c (Glycated Hb)', 'value': '5.5 %', 'range': '< 5.7', 'flag': 'Normal'},
        {'name': 'Est. Average Glucose', 'value': '111 mg/dL', 'range': '90 - 120', 'flag': 'Normal'},
      ],
    },
    'Thyroid Function Panel': {
      'category': 'Endocrinology',
      'sample_file': 'Thyroid_Stimulating_Hormone_Panel.pdf',
      'size_kb': 124,
      'preview': [
        {'name': 'TSH (Ultrasensitive)', 'value': '2.40 uIU/mL', 'range': '0.35 - 4.94', 'flag': 'Normal'},
        {'name': 'Free T3', 'value': '3.10 pg/mL', 'range': '1.71 - 3.71', 'flag': 'Normal'},
        {'name': 'Free T4', 'value': '1.15 ng/dL', 'range': '0.70 - 1.48', 'flag': 'Normal'},
      ],
    },
    'Liver Function Test (LFT)': {
      'category': 'Biochemistry',
      'sample_file': 'Hepatic_Profile_LFT_Screen.pdf',
      'size_kb': 155,
      'preview': [
        {'name': 'SGOT / AST', 'value': '28 U/L', 'range': '10 - 40', 'flag': 'Normal'},
        {'name': 'SGPT / ALT', 'value': '32 U/L', 'range': '7 - 56', 'flag': 'Normal'},
        {'name': 'Serum Bilirubin Total', 'value': '0.80 mg/dL', 'range': '0.2 - 1.2', 'flag': 'Normal'},
        {'name': 'Alkaline Phosphatase', 'value': '84 U/L', 'range': '44 - 147', 'flag': 'Normal'},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _doctorController.text = 'Dr. Dhruv Patel';
    _summaryController.text = 'Automated diagnostic analysis completed. Verified parameters mapped to digital health locker.';

    _selectedTest = widget.test ?? 'Complete Blood Count (CBC)';
    final preset = _presetTests[_selectedTest];
    if (preset != null) {
      _selectedCategory = preset['category'] as String;
      _attachedFileName = preset['sample_file'] as String;
      _attachedFileSizeKb = preset['size_kb'] as int;
    } else {
      _selectedCategory = widget.category ?? 'Hematology';
      _attachedFileName = 'Certified_Diagnostic_Report.pdf';
    }

    _loadRegisteredPatients();
  }

  Future<void> _loadRegisteredPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final list = await ApiClient().getLabPatients();
      if (mounted) {
        setState(() {
          _registeredPatients = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoadingPatients = false;

          // Default select Manan Soni or first patient
          if (_registeredPatients.isNotEmpty) {
            final match = _registeredPatients.firstWhere(
              (p) =>
                  (p['email'] as String? ?? '').toLowerCase().contains('manan') ||
                  (p['full_name'] as String? ?? '').toLowerCase().contains('manan'),
              orElse: () => _registeredPatients.first,
            );
            _selectPatient(match);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
      _patientIdentifierController.text = patient['patient_id'] ?? patient['email'] ?? '';
      _patientNameController.text = patient['full_name'] ?? '';
    });
  }

  void _applyTestPreset(String testName) {
    setState(() {
      _selectedTest = testName;
      final preset = _presetTests[testName];
      if (preset != null) {
        _selectedCategory = preset['category'] as String;
        if (!_isCustomFile) {
          _attachedFileName = preset['sample_file'] as String;
          _attachedFileSizeKb = preset['size_kb'] as int;
        }
      }
    });
  }

  Future<void> _handleUploadAndSync() async {
    final identifier = _patientIdentifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a Patient ID / Email'),
          backgroundColor: AppColors.emergency,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiClient().uploadDirectLabReport(
        patientIdentifier: identifier,
        patientName: _patientNameController.text.trim().isNotEmpty
            ? _patientNameController.text.trim()
            : null,
        testName: _selectedTest,
        category: _selectedCategory,
        summary: _summaryController.text.trim(),
        doctorName: _doctorController.text.trim(),
        fileName: _attachedFileName ?? 'Certified_Lab_Report.pdf',
      );

      // Refresh stores so Patient Locker and Lab Orders update instantly
      ref.read(reportsProvider.notifier).fetchReports();
      ref.read(labPendingReportsProvider.notifier).fetchOrders();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
          _submissionResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _patientIdentifierController.dispose();
    _patientNameController.dispose();
    _doctorController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Smart Diagnostic Ingestion (Zero Manual Entry)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lab'),
        ),
      ),
      body: _isSubmitted
          ? _buildSuccessView(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Info Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kLabAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kLabAccent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.bolt_rounded, color: kLabAccent, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Automated Ingestion Pipeline: Simply drop the PDF report or CSV export. Clinical parameters are automatically mapped and synchronized with the patient\'s personal locker.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // SECTION 1: Patient Selector
                    _buildPatientSelectionCard(),
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 2: Test Type & Quick Presets
                    _buildTestSelectionCard(),
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 3: Smart File Dropzone
                    _buildDropzoneCard(),
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 4: Extracted Parameters Preview
                    _buildParametersPreviewCard(),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Action Button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleUploadAndSync,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLabAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: Text(
                            _isSubmitting
                                ? 'Parsing & Synchronizing with Health Locker...'
                                : 'Publish & Push Directly to Patient Locker',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
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

  Widget _buildPatientSelectionCard() {
    return Container(
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
            children: const [
              Icon(Icons.person_pin_rounded, color: kLabAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '1. Target Patient Identification (Unique Patient ID / Email)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingPatients)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(color: kLabAccent),
            )
          else if (_registeredPatients.isNotEmpty) ...[
            const Text(
              'Select Registered Patient:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _registeredPatients.map((p) {
                final isSel = _selectedPatient?['id'] == p['id'];
                return ChoiceChip(
                  label: Text('${p['full_name']} (${p['patient_id']})'),
                  selected: isSel,
                  selectedColor: kLabAccent.withValues(alpha: 0.15),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? kLabAccent : AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) _selectPatient(p);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient ID or Email *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _patientIdentifierController,
                      decoration: _inputDec('e.g. PAT-4726A2 or manansoni2905@gmail.com'),
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
                    const Text('Patient Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _patientNameController,
                      decoration: _inputDec('e.g. Manan Soni'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestSelectionCard() {
    return Container(
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
            children: const [
              Icon(Icons.biotech_rounded, color: kLabAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '2. Diagnostic Test Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick Test Presets (Auto-Configures Parameters & Reference Ranges):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetTests.keys.map((testName) {
              final isSel = _selectedTest == testName;
              return ChoiceChip(
                label: Text(testName),
                selected: isSel,
                selectedColor: kLabAccent.withValues(alpha: 0.15),
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? kLabAccent : AppColors.textPrimary,
                ),
                onSelected: (val) {
                  if (val) _applyTestPreset(testName);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropzoneCard() {
    return Container(
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
            children: const [
              Icon(Icons.upload_file_rounded, color: kLabAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '3. Document Dropzone (PDF / CSV File)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kLabAccent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kLabAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: kLabAccent, size: 32),
                ),
                const SizedBox(height: 10),
                Text(
                  _attachedFileName ?? 'No document attached',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: $_attachedFileSizeKb KB • Certified Electronic Document • Ready for Ingestion',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Demo file switch simulation
                        setState(() {
                          _isCustomFile = true;
                          _attachedFileName = 'Patient_${_selectedPatient?['patient_id'] ?? "PAT4726A2"}_Full_Report.pdf';
                          _attachedFileSizeKb = 215;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Attached custom report: $_attachedFileName'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Browse Device File...', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCustomFile = false;
                          final preset = _presetTests[_selectedTest];
                          _attachedFileName = preset?['sample_file'] ?? 'CBC_Automated_Hemogram_Report.pdf';
                          _attachedFileSizeKb = preset?['size_kb'] ?? 142;
                        });
                      },
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Use Standard Lab PDF', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLabAccent.withValues(alpha: 0.1),
                        foregroundColor: kLabAccent,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersPreviewCard() {
    final preset = _presetTests[_selectedTest];
    final previewList = (preset?['preview'] as List<dynamic>?) ?? [];

    return Container(
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
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '4. Auto-Extracted Clinical Parameters (Zero Typing)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${previewList.length} Parameters Ready',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The following verified parameters will be published and plotted directly into the patient\'s health locker and EHR timeline:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1, borderRadius: BorderRadius.circular(6)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Test Parameter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Observed Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Reference Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Flag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              ...previewList.map((item) {
                final isAbnormal = item['flag'] == 'High' || item['flag'] == 'Abnormal';
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item['value'] ?? '', style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item['range'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAbnormal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isAbnormal ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Text(
                          item['flag'] ?? 'Normal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAbnormal ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final patientName = _submissionResult?['patient_name'] ?? _patientNameController.text;
    final patientPid = _submissionResult?['patient_id'] ?? _patientIdentifierController.text;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
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
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: kLabAccent, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diagnostic Report Published & Synced!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully synchronized with $patientName ($patientPid)\'s Digital Health Locker.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _successRow('Test Name:', _selectedTest),
                  const SizedBox(height: 6),
                  _successRow('Attached Document:', _attachedFileName ?? 'Certified_Report.pdf'),
                  const SizedBox(height: 6),
                  _successRow('Report Status:', _submissionResult?['status'] ?? 'Normal'),
                  const SizedBox(height: 6),
                  _successRow('Patient Locker Binding:', patientPid),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSubmitted = false;
                        _submissionResult = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Upload Another Report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/lab'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kLabAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Return to Lab Portal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _successRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
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
      borderSide: const BorderSide(color: kLabAccent, width: 1.5),
    ),
  );
}
