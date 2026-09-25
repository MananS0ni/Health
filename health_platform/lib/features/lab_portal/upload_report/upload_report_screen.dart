import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Uint8List? _attachedFileBytes;
  List<Map<String, dynamic>>? _customExtractedParameters;

  bool _isLoadingPatients = false;
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

    _initTargetPatient();
  }

  void _initTargetPatient() {
    if (widget.patient != null && widget.patient!.isNotEmpty) {
      _patientIdentifierController.text = widget.patient!;
      _lookupPatient();
    }
  }

  Future<void> _lookupPatient() async {
    final query = _patientIdentifierController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoadingPatients = true);
    try {
      final list = await ApiClient().getLabPatients(query);
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          if (list.isNotEmpty) {
            final p = Map<String, dynamic>.from(list.first as Map);
            _selectedPatient = p;
            _patientIdentifierController.text = p['patient_id'] ?? query;
            _patientNameController.text = p['full_name'] ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found Verified Patient: ${p['full_name']} (${p['patient_id']})'),
                backgroundColor: kLabAccent,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No patient found for that ID/Email. You can type their details manually.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
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

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  List<Map<String, dynamic>> _parseCsvReport(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes);
      final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
      if (lines.length < 2) return [];

      final headerCols = _parseCsvLine(lines.first).map((c) => c.toLowerCase().trim()).toList();

      int colIdx(List<String> synonyms) {
        for (final s in synonyms) {
          final idx = headerCols.indexOf(s);
          if (idx != -1) return idx;
        }
        return -1;
      }

      final pIdIdx = colIdx(['patient_id', 'patient_email', 'email', 'patient']);
      final pNameIdx = colIdx(['patient_name', 'name']);
      final testIdx = colIdx(['test_name', 'test', 'panel']);
      final catIdx = colIdx(['test_category', 'category']);
      final paramIdx = colIdx(['parameter_name', 'parameter']);
      final valIdx = colIdx(['result_value', 'value', 'result']);
      final unitIdx = colIdx(['unit', 'units']);
      final rangeIdx = colIdx(['reference_range', 'range', 'normal_range']);
      final statusIdx = colIdx(['result_status', 'flag', 'status', 'is_abnormal']);
      final docIdx = colIdx(['lab_technician', 'doctor_name', 'doctor', 'technician']);
      final notesIdx = colIdx(['notes', 'summary']);

      final List<Map<String, dynamic>> parsed = [];

      for (int i = 1; i < lines.length; i++) {
        final cols = _parseCsvLine(lines[i]);
        if (cols.isEmpty) continue;

        String getCol(int idx) => (idx >= 0 && idx < cols.length) ? cols[idx].trim() : '';

        final pId = getCol(pIdIdx);
        final pName = getCol(pNameIdx);
        final tName = getCol(testIdx);
        final cat = getCol(catIdx);
        final param = getCol(paramIdx).isNotEmpty ? getCol(paramIdx) : (tName.isNotEmpty ? tName : 'Parameter $i');
        final val = getCol(valIdx);
        final unit = getCol(unitIdx);
        final range = getCol(rangeIdx);
        final rawStatus = getCol(statusIdx);
        final doc = getCol(docIdx);
        final notes = getCol(notesIdx);

        final isAbn = ['high', 'low', 'abnormal', 'critical', 'positive', 'true', '1'].contains(rawStatus.toLowerCase());
        final flag = rawStatus.isNotEmpty ? rawStatus : (isAbn ? 'High' : 'Normal');

        final displayVal = val.isNotEmpty
            ? (unit.isNotEmpty && !val.contains(unit) ? '$val $unit' : val)
            : (flag.isNotEmpty ? flag : 'Completed');

        parsed.add({
          'name': param,
          'parameter_name': param,
          'value': displayVal,
          'raw_value': val,
          'unit': unit,
          'range': range.isNotEmpty ? range : '-',
          'reference_range': range,
          'flag': flag,
          'is_abnormal': isAbn,
          'patient_id': pId,
          'patient_name': pName,
          'test_name': tName.isNotEmpty ? tName : param,
          'category': cat,
          'doctor': doc,
          'notes': notes,
        });
      }

      return parsed;
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
      return [];
    }
  }

  Future<void> _pickRealFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'png', 'jpg', 'jpeg'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final size = await file.length() ?? bytes.length;

        List<Map<String, dynamic>> extractedParams = [];
        if (file.name.toLowerCase().endsWith('.csv')) {
          extractedParams = _parseCsvReport(bytes);
        }

        setState(() {
          _isCustomFile = true;
          _attachedFileName = file.name;
          _attachedFileSizeKb = (size / 1024).round();
          _attachedFileBytes = bytes;

          if (extractedParams.isNotEmpty) {
            _customExtractedParameters = extractedParams;
            final first = extractedParams.first;
            // Retain the user's manually entered patient details in Section 1 (NO auto-fill of patient ID or name!)
            if (first['test_name']?.toString().isNotEmpty == true) {
              _selectedTest = first['test_name'];
            }
            if (first['category']?.toString().isNotEmpty == true) {
              _selectedCategory = first['category'];
            }
            if (first['doctor']?.toString().isNotEmpty == true) {
              _doctorController.text = first['doctor'];
            }
            if (first['notes']?.toString().isNotEmpty == true) {
              _summaryController.text = first['notes'];
            }
          }
        });

        if (mounted) {
          final isCsvWithData = extractedParams.isNotEmpty;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCsvWithData
                          ? 'Auto-extracted ${extractedParams.length} clinical parameters from ${file.name}. Target patient remains as selected.'
                          : 'Attached device file: ${file.name} ($_attachedFileSizeKb KB)',
                    ),
                  ),
                ],
              ),
              backgroundColor: kLabAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  Future<void> _handleUploadAndSync() async {
    final identifier = _patientIdentifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or search the Target Patient ID or Email in Section 1.'),
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
        fileBytes: _attachedFileBytes,
        parameters: _customExtractedParameters,
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
                                : ((_customExtractedParameters != null && _customExtractedParameters!.length > 1)
                                    ? 'Publish & Push ${_customExtractedParameters!.length} Extracted Reports to Patient Lockers'
                                    : 'Publish & Push Directly to Patient Locker'),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (_isLoadingPatients)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kLabAccent),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedPatient != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kLabAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kLabAccent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: kLabAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified Patient: ${_selectedPatient!['full_name']} • ${_selectedPatient!['patient_id']} (${_selectedPatient!['email'] ?? ""})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPatient = null;
                        _patientIdentifierController.clear();
                        _patientNameController.clear();
                      });
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 12, color: AppColors.emergency, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient ID or Email *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _patientIdentifierController,
                      decoration: _inputDec('e.g. PAT-4726A2 or manansoni2905@gmail.com').copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20, color: kLabAccent),
                          tooltip: 'Lookup Patient',
                          onPressed: _lookupPatient,
                        ),
                      ),
                      onFieldSubmitted: (_) => _lookupPatient(),
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
    final bool hasRealBytes = _attachedFileBytes != null;

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
            children: [
              const Icon(Icons.upload_file_rounded, color: kLabAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                '3. Document Dropzone (PDF / CSV File)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              if (hasRealBytes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Device File Ready',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickRealFile,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: hasRealBytes ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasRealBytes ? kLabAccent : kLabAccent.withValues(alpha: 0.4),
                  width: hasRealBytes ? 2.0 : 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kLabAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasRealBytes ? Icons.task_rounded : Icons.picture_as_pdf_rounded,
                      color: kLabAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _attachedFileName ?? 'Click to Browse Device File (PDF / CSV)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasRealBytes
                        ? 'Size: $_attachedFileSizeKb KB • Actual Device File Loaded in Memory • Ready for Server Upload'
                        : 'Size: $_attachedFileSizeKb KB • Click anywhere here to select a real file from your PC',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: hasRealBytes ? const Color(0xFF065F46) : AppColors.textSecondary,
                      fontWeight: hasRealBytes ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickRealFile,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(
                          hasRealBytes ? 'Change Selected File...' : 'Browse Device File (Real PDF)...',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasRealBytes ? kLabAccent : Colors.white,
                          foregroundColor: hasRealBytes ? Colors.white : AppColors.textPrimary,
                          elevation: 0,
                          side: const BorderSide(color: kLabAccent),
                        ),
                      ),
                      if (hasRealBytes)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isCustomFile = false;
                              _attachedFileBytes = null;
                              _customExtractedParameters = null;
                              final preset = _presetTests[_selectedTest];
                              _attachedFileName = preset?['sample_file'] ?? 'CBC_Automated_Hemogram_Report.pdf';
                              _attachedFileSizeKb = preset?['size_kb'] ?? 142;
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reset to Standard Sample', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textSecondary,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          const sampleCsv = '''patient_id,patient_name,test_name,test_category,sample_collected_date,report_date,result_value,unit,reference_range,result_status,lab_name,lab_technician,report_file_name,notes
HLTH-2026-00147,Rahul Mehta,Complete Blood Count (CBC),Hematology,2026-09-20,2026-09-21,Normal,,Normal,Normal,Sunrise Diagnostics,Dr. Priya Shah,HLTH-2026-00147_CBC_20260921.pdf,
HLTH-2026-00147,Rahul Mehta,Fasting Blood Sugar,Biochemistry,2026-09-20,2026-09-21,118,mg/dL,70-100,High,Sunrise Diagnostics,Dr. Priya Shah,HLTH-2026-00147_FBS_20260921.pdf,Slightly elevated; recommend follow-up
HLTH-2026-00289,Ananya Patel,Lipid Profile,Biochemistry,2026-09-18,2026-09-19,210,mg/dL,<200,High,Sunrise Diagnostics,Dr. Priya Shah,HLTH-2026-00289_LIPID_20260919.pdf,Total cholesterol
HLTH-2026-00289,Ananya Patel,Thyroid Panel (TSH),Endocrinology,2026-09-18,2026-09-19,2.4,mIU/L,0.4-4.0,Normal,Sunrise Diagnostics,Dr. Priya Shah,HLTH-2026-00289_TSH_20260919.pdf,
HLTH-2026-00312,Vikram Nair,Urinalysis,Pathology,2026-09-22,2026-09-22,Normal,,Normal,Normal,Sunrise Diagnostics,Dr. Priya Shah,HLTH-2026-00312_URINE_20260922.pdf,
HLTH-2026-00312,Vikram Nair,Chest X-Ray,Radiology,2026-09-22,2026-09-23,No abnormality detected,,,Normal,Sunrise Diagnostics,Dr. Priya Shah,HLTH-2026-00312_XRAY_20260923.pdf,Reviewed by radiologist''';
                          final bytes = Uint8List.fromList(utf8.encode(sampleCsv));
                          final extractedParams = _parseCsvReport(bytes);
                          setState(() {
                            _isCustomFile = true;
                            _attachedFileName = 'lab_reports_template.csv';
                            _attachedFileSizeKb = (bytes.length / 1024).round().clamp(1, 9999);
                            _attachedFileBytes = bytes;
                            _customExtractedParameters = extractedParams;
                            final first = extractedParams.first;
                            if (first['test_name']?.toString().isNotEmpty == true) {
                              _selectedTest = first['test_name'];
                            }
                            if (first['category']?.toString().isNotEmpty == true) {
                              _selectedCategory = first['category'];
                            }
                            if (first['doctor']?.toString().isNotEmpty == true) {
                              _doctorController.text = first['doctor'];
                            }
                            if (first['notes']?.toString().isNotEmpty == true) {
                              _summaryController.text = first['notes'];
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Loaded ${extractedParams.length} clinical parameters from template. Target patient remains as selected.'),
                              backgroundColor: kLabAccent,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.table_view_rounded, size: 16),
                        label: const Text('Load Sample CSV Template', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          foregroundColor: const Color(0xFF1D4ED8),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersPreviewCard() {
    final bool hasCustom = _customExtractedParameters != null && _customExtractedParameters!.isNotEmpty;
    final preset = _presetTests[_selectedTest];
    final previewList = hasCustom
        ? _customExtractedParameters!
        : ((preset?['preview'] as List<dynamic>?) ?? []);

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
                children: [
                  Icon(
                    hasCustom ? Icons.verified_rounded : Icons.auto_awesome_rounded,
                    color: hasCustom ? kLabAccent : const Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasCustom
                        ? '4. Verified Extracted Parameters from File'
                        : '4. Auto-Extracted Clinical Parameters (Zero Typing)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasCustom ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hasCustom ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasCustom) ...[
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 13),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      hasCustom
                          ? '${previewList.length} Extracted from File'
                          : '${previewList.length} Parameters Ready',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasCustom ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasCustom
                ? 'The following parameters were parsed from your file and will be saved directly into the patient\'s health locker and EHR timeline:'
                : 'The following verified parameters will be published and plotted directly into the patient\'s health locker and EHR timeline:',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1, borderRadius: BorderRadius.circular(6)),
            columnWidths: const {
              0: FlexColumnWidth(2.4),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.6),
              3: FlexColumnWidth(1.0),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
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
                final isAbnormal = item['flag'] == 'High' ||
                    item['flag'] == 'Abnormal' ||
                    item['is_abnormal'] == true;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item['name'] ?? item['parameter_name'] ?? item['test_name'] ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item['value'] ?? '', style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item['range'] ?? item['reference_range'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                          item['flag'] ?? (isAbnormal ? 'High' : 'Normal'),
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
            if (_submissionResult?['file_url'] != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final rawUrl = _submissionResult!['file_url'].toString();
                    final fullUrl = rawUrl.startsWith('http')
                        ? rawUrl
                        : 'http://127.0.0.1:8000$rawUrl';
                    launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open & Verify Uploaded File in Browser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kLabAccent,
                    side: const BorderSide(color: kLabAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSubmitted = false;
                        _submissionResult = null;
                        _attachedFileBytes = null;
                        _isCustomFile = false;
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
