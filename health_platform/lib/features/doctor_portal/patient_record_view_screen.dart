import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock_data/mock_doctor_data.dart';
import '../../shared/widgets/app_avatar.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class PatientRecordViewScreen extends StatelessWidget {
  final String patientId;

  const PatientRecordViewScreen({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final record = MockDoctorData.getPatientDetailRecord(patientId);
    final vitals = record['vitals'] as Map<String, dynamic>;
    final allergies = List<String>.from(record['allergies'] ?? []);
    final chronicConditions = List<String>.from(record['chronic_conditions'] ?? []);
    final prescriptions = List<Map<String, dynamic>>.from(record['prescriptions'] ?? []);
    final reports = List<Map<String, dynamic>>.from(record['recent_lab_reports'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Clinical Chart: ${record['full_name']}'),
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
                context.go('/doctor/add-diagnosis?id=$patientId');
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
                      AppAvatar(name: record['full_name'], size: AppAvatarSize.xl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  record['full_name'],
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
                                    record['patient_id'],
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
                              '${record['gender']} • ${record['age']} yrs • Blood: ${record['blood_group']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: ${record['phone_number']} • Email: ${record['email']}',
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
            const SizedBox(height: AppSpacing.lg),

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
            GridView.count(
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
            ),
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
            ...reports.map((report) => _LabReportHistoryTile(report: report)),
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
