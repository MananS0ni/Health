import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';

const Color kLabAccent = Color(0xFF059669);

class ParameterRow {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final TextEditingController rangeController;
  String flag;

  ParameterRow({
    required String name,
    required String value,
    required String unit,
    required String range,
    this.flag = 'Normal',
  })  : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value),
        unitController = TextEditingController(text: unit),
        rangeController = TextEditingController(text: range);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
    rangeController.dispose();
  }
}

class UploadReportScreen extends StatefulWidget {
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
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _reportTypeController = TextEditingController();
  final _reportDateController = TextEditingController();
  final _facilityController = TextEditingController();

  final List<ParameterRow> _parameters = [];
  String? _attachedFileName;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _patientIdController.text = widget.patient ?? 'Rahul S. (PAT001)';
    _reportTypeController.text = widget.test ?? 'Lipid Profile - Serum Cholesterol';
    _reportDateController.text = DateTime.now().toString().split(' ').first;
    _facilityController.text = 'Metropolis Healthcare Lab Hub';
    _attachedFileName = 'Report_Scan_${widget.orderId ?? "LAB_801"}.pdf';

    // Default sample parameters
    _parameters.addAll([
      ParameterRow(
        name: 'Total Cholesterol',
        value: '218',
        unit: 'mg/dL',
        range: '< 200',
        flag: 'High',
      ),
      ParameterRow(
        name: 'HDL (Good Cholesterol)',
        value: '45',
        unit: 'mg/dL',
        range: '> 40',
        flag: 'Normal',
      ),
      ParameterRow(
        name: 'Triglycerides',
        value: '160',
        unit: 'mg/dL',
        range: '< 150',
        flag: 'High',
      ),
    ]);
  }

  void _addParameter() {
    setState(() {
      _parameters.add(ParameterRow(
        name: '',
        value: '',
        unit: '',
        range: '',
        flag: 'Normal',
      ));
    });
  }

  void _removeParameter(int index) {
    setState(() {
      _parameters[index].dispose();
      _parameters.removeAt(index);
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitted = true);
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _reportTypeController.dispose();
    _reportDateController.dispose();
    _facilityController.dispose();
    for (var p in _parameters) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Fill Lab Report'),
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
                    if (widget.orderId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kLabAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: kLabAccent.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_turned_in_rounded,
                                color: kLabAccent),
                            const SizedBox(width: 10),
                            Text(
                              'Processing Order #${widget.orderId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kLabAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Patient Identifier & Report Type
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Patient Identifier *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _patientIdController,
                                decoration: _dec('Patient Name / ID'),
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
                              const Text('Report Type / Category *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _reportTypeController,
                                decoration: _dec('e.g. Lipid Profile'),
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

                    // Date & Facility
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Report Date *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _reportDateController,
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
                              const Text('Facility Name',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _facilityController,
                                decoration: _dec('Diagnostic Hub Name'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Parameter Repeatable List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Test Parameters & Measured Values',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addParameter,
                          icon: const Icon(Icons.add,
                              size: 16, color: kLabAccent),
                          label: const Text(
                            'Add Parameter',
                            style: TextStyle(
                                color: kLabAccent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Repeatable Parameter List Items
                    ..._parameters.asMap().entries.map((entry) {
                      final i = entry.key;
                      final param = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: param.nameController,
                                    decoration:
                                        _dec('Param Name (e.g. Glucose)'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: param.valueController,
                                    decoration: _dec('Value'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: param.unitController,
                                    decoration: _dec('Unit'),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.emergency, size: 18),
                                  onPressed: () => _removeParameter(i),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: param.rangeController,
                                    decoration:
                                        _dec('Normal Range (e.g. 70-99)'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: param.flag,
                                    decoration: _dec(''),
                                    isExpanded: true,
                                    items: ['Normal', 'High', 'Low', 'Critical']
                                        .map((f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(f,
                                                style: const TextStyle(
                                                    fontSize: 12))))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => param.flag = v!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),

                    // Document Upload Control
                    const Text('Attach Scanned PDF / Image Document',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              color: AppColors.emergency, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _attachedFileName ?? 'No file selected',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const Text(
                                  'PDF or High-Res Image (Max 10MB)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _attachedFileName =
                                    'Lab_Report_Scan_2026.pdf';
                              });
                            },
                            icon:
                                const Icon(Icons.attach_file_rounded, size: 14),
                            label: const Text('Choose File'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kLabAccent,
                              side: const BorderSide(color: kLabAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit CTA Button
                    AppButton(
                      text: 'Submit & Publish Report',
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
              'Lab Report Uploaded Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The report parameters and document have been attached to the patient\'s EHR timeline and pushed to LIMS sync queue.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/lab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kLabAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Return to Lab Dashboard'),
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
      borderSide: const BorderSide(color: kLabAccent, width: 1.5),
    ),
  );
}
