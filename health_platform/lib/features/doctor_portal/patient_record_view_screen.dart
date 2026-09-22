import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../core/network/api_client.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class PatientRecordViewScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientRecordViewScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<PatientRecordViewScreen> createState() => _PatientRecordViewScreenState();
}

class _PatientRecordViewScreenState extends ConsumerState<PatientRecordViewScreen> {
  bool _isLoading = true;
  bool _hasConsent = false;
  String _consentStatus = 'none'; // 'none', 'pending', 'approved'
  Map<String, dynamic> _chartData = {};
  bool _isRequestingConsent = false;

  @override
  void initState() {
    super.initState();
    _loadPatientChart();
  }

  Future<void> _loadPatientChart() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient().getDoctorPatientChart(widget.patientId);
      if (mounted) {
        setState(() {
          _chartData = data;
          _hasConsent = data['has_consent'] == true;
          _consentStatus = data['consent_status'] ?? 'none';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestConsent() async {
    setState(() => _isRequestingConsent = true);
    try {
      final res = await ApiClient().requestDoctorConsent(patientId: widget.patientId);
      if (mounted) {
        setState(() {
          _isRequestingConsent = false;
          _consentStatus = 'pending';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${res['message'] ?? 'Consent request sent to patient.'}'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingConsent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.emergency,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(doctorPatientsProvider);
    final fallbackRecord = patients.firstWhere(
      (p) =>
          (p['id'] != null && p['id'] == widget.patientId) ||
          (p['patient_id'] != null && p['patient_id'] == widget.patientId),
      orElse: () => {
        'patient_id': widget.patientId,
        'full_name': 'Patient (${widget.patientId})',
        'gender': 'Not specified',
        'age': '--',
        'blood_group': '--',
        'phone_number': '--',
        'email': '--',
      },
    );

    final record = _chartData.isNotEmpty ? _chartData : fallbackRecord;
    final fullName = record['full_name'] ?? fallbackRecord['full_name'] ?? 'Patient';
    final patientCode = record['patient_id'] ?? fallbackRecord['patient_id'] ?? widget.patientId;
    final bloodGroup = record['blood_group'] ?? fallbackRecord['blood_group'] ?? '--';
    final gender = record['gender'] ?? fallbackRecord['gender'] ?? '--';
    final phone = record['phone_number'] ?? fallbackRecord['phone_number'] ?? '--';
    final email = record['email'] ?? fallbackRecord['email'] ?? '--';

    final allergies = List<String>.from(record['allergies'] ?? []);
    final chronicConditions = List<String>.from(record['chronic_conditions'] ?? []);
    final prescriptions = List<Map<String, dynamic>>.from(record['prescriptions'] ?? []);
    final reports = List<Map<String, dynamic>>.from(record['reports'] ?? record['recent_lab_reports'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Clinical Chart: $fullName'),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/doctor/add-diagnosis?id=${widget.patientId}');
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Rx / Diagnosis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDoctorAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppAvatar(name: fullName, size: AppAvatarSize.xl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kDoctorAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    patientCode,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kDoctorAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$gender • Blood: $bloodGroup',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: $phone • Email: $email',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Warning Chips (Allergies & Conditions)
                  if (allergies.isNotEmpty || chronicConditions.isNotEmpty) ...[
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (allergies.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ALLERGIES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.emergency,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: allergies
                                      .map(
                                        (a) => Chip(
                                          label: Text(a, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: AppColors.emergencyLight,
                                          side: BorderSide.none,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        if (chronicConditions.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHRONIC CONDITIONS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: chronicConditions
                                      .map(
                                        (c) => Chip(
                                          label: Text(c, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: AppColors.warningLight,
                                          side: BorderSide.none,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Consent Protocol Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hasConsent ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _hasConsent ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasConsent ? Icons.verified_user_rounded : Icons.lock_person_rounded,
                    color: _hasConsent ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasConsent ? 'Active Patient Consent (24h Clinical Window)' : 'Patient History Locked by Consent Protocol',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _hasConsent ? const Color(0xFF15803D) : const Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          _hasConsent
                              ? 'Authorized to review historical lab reports, vitals, and past prescriptions.'
                              : (_consentStatus == 'pending'
                                  ? 'Consent request sent to patient. Awaiting authorization on their dashboard.'
                                  : 'Consent is required to view historical diagnostic reports & vitals.'),
                          style: TextStyle(
                            fontSize: 11,
                            color: _hasConsent ? const Color(0xFF166534) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_hasConsent) ...[
                    const SizedBox(width: 8),
                    if (_consentStatus == 'pending')
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Check Status', style: TextStyle(fontSize: 11)),
                        onPressed: _isLoading ? null : _loadPatientChart,
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: _isRequestingConsent
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.shield_outlined, size: 14),
                        label: const Text('Request Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _isRequestingConsent ? null : _requestConsent,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (!_hasConsent) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, size: 40, color: Color(0xFFD97706)),
                    const SizedBox(height: 12),
                    const Text(
                      'Historical Vitals, Prescriptions & Lab Reports Locked',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This patient has not yet approved clinical access for your account. Once the patient approves the consent request on their dashboard, their full medical timeline will unlock automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDoctorAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => context.go('/doctor/add-diagnosis?id=${widget.patientId}'),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Add Today\'s Consultation & Rx'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Latest Vitals Section
              const Text(
                'Latest Vitals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Builder(builder: (context) {
                final vitals = (_chartData['vitals'] is List && (_chartData['vitals'] as List).isNotEmpty)
                    ? {for (var v in _chartData['vitals']) v['vital_type'].toString(): '${v['value']} ${v['unit'] ?? ""}'.trim()}
                    : <String, String>{};

                return GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _VitalTile('Blood Pressure', vitals['blood_pressure'] ?? '--', Icons.favorite_rounded),
                    _VitalTile('Heart Rate', vitals['heart_rate'] ?? '--', Icons.monitor_heart_rounded),
                    _VitalTile('SpO2', vitals['spo2'] ?? '--', Icons.air_rounded),
                    _VitalTile('Temperature', vitals['temperature'] ?? '--', Icons.thermostat_rounded),
                    _VitalTile('Weight', vitals['weight'] ?? '--', Icons.scale_rounded),
                    _VitalTile('BMI', vitals['bmi'] ?? '--', Icons.accessibility_new_rounded),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.lg),

              // Prescription History Section
              const Text(
                'Prescription History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (prescriptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No prescriptions issued yet for this patient.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...prescriptions.map((rx) => _PrescriptionHistoryCard(rx: rx)),

            const SizedBox(height: AppSpacing.lg),

            // Lab Reports History
            const Text(
              'Lab & Diagnostic Reports',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (reports.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No diagnostic reports linked yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...reports.map((report) => _LabReportHistoryTile(report: report)),
            ],
          ],
        ),
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _VitalTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kDoctorAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionHistoryCard extends StatelessWidget {
  final Map<String, dynamic> rx;

  const _PrescriptionHistoryCard({required this.rx});

  @override
  Widget build(BuildContext context) {
    final medicines = List<Map<String, dynamic>>.from(rx['medicines'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnosis: ${rx['diagnosis']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kDoctorAccent,
                ),
              ),
              Text(
                rx['date'],
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(
            'Prescribed by ${rx['doctor_name']}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const Divider(height: 16),
          ...medicines.map(
            (med) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined, size: 15, color: kDoctorAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      med['name'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${med['dosage']} • ${med['duration']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabReportHistoryTile extends StatelessWidget {
  final Map<String, dynamic> report;

  const _LabReportHistoryTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kDoctorAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_outlined, color: kDoctorAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${report['facility']} • ${report['date']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              report['status'],
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            backgroundColor: report['status'] == 'Normal'
                ? AppColors.successLight
                : AppColors.warningLight,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
