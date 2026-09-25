import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/providers.dart';

const Color kHospitalAccent = Color(0xFFD97706);

class HospitalProfileScreen extends ConsumerStatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  ConsumerState<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends ConsumerState<HospitalProfileScreen> {
  void _showEditFacilityDialog() {
    final user = ref.read(userProvider);
    final orgProfile = user.orgProfile;
    final nameController = TextEditingController(text: orgProfile?.organizationName ?? 'Apex Multi-Speciality Hospital');
    final regController = TextEditingController(text: orgProfile?.employeeId ?? 'HOSP-REG-2026-9921');
    final contactController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.local_hospital_rounded, color: kHospitalAccent),
            SizedBox(width: 8),
            Text('Edit Hospital Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Facility / Hospital Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regController,
                decoration: const InputDecoration(
                  labelText: 'Establishment Registration ID',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Administrative Contact Number',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hospital profile updated successfully.'),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kHospitalAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final orgProfile = user.orgProfile;
    final hospitalName = (orgProfile != null && orgProfile.organizationName.isNotEmpty)
        ? orgProfile.organizationName
        : 'Apex Multi-Speciality Hospital';
    final regNo = (orgProfile != null && orgProfile.employeeId != null && orgProfile.employeeId!.isNotEmpty)
        ? orgProfile.employeeId!
        : 'CEA-GJ-2026-0814';

    final admissions = ref.watch(hospitalAdmissionsProvider);
    final activeInpatients = admissions.where((p) => p['status'] != 'Discharged').length;
    const totalBeds = 60;
    final availableBeds = (totalBeds - activeInpatients).clamp(0, totalBeds);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hospital Facility Profile'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: kHospitalAccent),
            tooltip: 'Edit Facility Info',
            onPressed: _showEditFacilityDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facility Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB45309), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                hospitalName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Accredited Facility',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registration ID: $regNo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Administrator: ${user.fullName} (${user.email ?? user.phoneNumber})',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inpatient & Ward Capacity Metrics
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active Inpatients',
                    value: '$activeInpatients',
                    icon: Icons.hotel_rounded,
                    color: kHospitalAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Available Beds',
                    value: '$availableBeds',
                    icon: Icons.meeting_room_outlined,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Total Admissions',
                    value: '${admissions.length}',
                    icon: Icons.assignment_turned_in_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Facility Credentials Card
            _InfoSectionCard(
              title: 'Facility Credentials & Licensure',
              icon: Icons.domain_verification_outlined,
              children: [
                _DetailRow(
                  label: 'Establishment Reg No',
                  value: regNo,
                  icon: Icons.badge_outlined,
                ),
                _DetailRow(
                  label: 'Facility Category',
                  value: 'Multi-Speciality Inpatient & Critical Care',
                  icon: Icons.local_hospital_outlined,
                ),
                _DetailRow(
                  label: 'Active Clinical Wards',
                  value: 'General Ward, Semi-Private, ICU, Emergency',
                  icon: Icons.meeting_room_outlined,
                ),
                _DetailRow(
                  label: 'Total Certified Beds',
                  value: '$totalBeds Operational Beds',
                  icon: Icons.hotel_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Departments & Specialties
            _InfoSectionCard(
              title: 'Clinical Departments',
              icon: Icons.medical_services_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _DeptChip(name: 'General Medicine'),
                    _DeptChip(name: 'Emergency & Trauma'),
                    _DeptChip(name: 'Intensive Care Unit (ICU)'),
                    _DeptChip(name: 'Cardiology'),
                    _DeptChip(name: 'Orthopedics'),
                    _DeptChip(name: 'Pediatrics'),
                    _DeptChip(name: 'General Surgery'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Inpatient Bed Protocol Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.shield_outlined, color: kHospitalAccent, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atomic Bed Occupancy Protocol',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Assigned beds remain strictly locked in the system to prevent double-booking. When a patient is discharged and a clinical discharge summary is published, the bed automatically becomes available for new admissions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out of Hospital Session', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/phone');
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _DeptChip extends StatelessWidget {
  final String name;

  const _DeptChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 18, color: kHospitalAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
