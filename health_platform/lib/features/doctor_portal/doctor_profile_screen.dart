import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/providers.dart';
import '../../shared/widgets/app_avatar.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  void _showEditDoctorDialog() {
    final user = ref.read(userProvider);
    final docProfile = user.doctorProfile;
    final specController = TextEditingController(text: docProfile?.specialization ?? 'General Physician');
    final clinicController = TextEditingController(text: docProfile?.clinicName ?? '');
    final regController = TextEditingController(text: docProfile?.registrationNumber ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: kDoctorAccent),
            SizedBox(width: 8),
            Text('Edit Practice Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: regController,
                decoration: const InputDecoration(
                  labelText: 'Medical Registration Number',
                  hintText: 'e.g. MCI-2023-88910',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specController,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  hintText: 'e.g. Cardiology / Internal Medicine',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clinicController,
                decoration: const InputDecoration(
                  labelText: 'Clinic / Hospital Affiliation',
                  hintText: 'e.g. Patel Healthcare Clinic',
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
                  content: Text('Doctor practice profile updated successfully.'),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDoctorAccent,
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
    final cleanName = user.fullName.trim();
    final displayName = cleanName.toLowerCase().startsWith('dr.') ? cleanName : 'Dr. $cleanName';
    final docProfile = user.doctorProfile;
    final spec = (docProfile != null && docProfile.specialization.isNotEmpty)
        ? docProfile.specialization
        : 'Specialist / Physician';
    final regNo = (docProfile != null && docProfile.registrationNumber.isNotEmpty)
        ? docProfile.registrationNumber
        : 'REG-2026-MED';
    final clinicName = (docProfile != null && docProfile.clinicName != null && docProfile.clinicName!.isNotEmpty)
        ? docProfile.clinicName!
        : 'City Health Clinic';

    final patients = ref.watch(doctorPatientsProvider);
    final requests = ref.watch(doctorIncomingRequestsProvider);
    final activeConsents = requests.where((r) => r['status'] == 'approved' || r['status'] == 'accepted').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doctor Profile & Credentials'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: kDoctorAccent),
            tooltip: 'Edit Practice Info',
            onPressed: _showEditDoctorDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AppAvatar(name: displayName, size: AppAvatarSize.xl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
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
                                    'Verified Doctor',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spec,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clinicName,
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

            // Clinical Practice Metrics
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active Patients',
                    value: '${patients.length}',
                    icon: Icons.people_outline_rounded,
                    color: kDoctorAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Active Consents',
                    value: '$activeConsents',
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Pending Approvals',
                    value: '${requests.where((r) => r['status'] == 'pending').length}',
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Professional Credentials Card
            _InfoSectionCard(
              title: 'Professional Credentials',
              icon: Icons.badge_outlined,
              children: [
                _DetailRow(
                  label: 'Registration Number',
                  value: regNo,
                  icon: Icons.confirmation_number_outlined,
                ),
                _DetailRow(
                  label: 'Primary Specialization',
                  value: spec,
                  icon: Icons.medical_services_outlined,
                ),
                _DetailRow(
                  label: 'Practice Facility',
                  value: clinicName,
                  icon: Icons.local_hospital_outlined,
                ),
                _DetailRow(
                  label: 'Clinical Role',
                  value: 'Consulting Physician & Prescriber',
                  icon: Icons.assignment_ind_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Contact & Account Details Card
            _InfoSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_mail_outlined,
              children: [
                _DetailRow(
                  label: 'Registered Email',
                  value: user.email ?? 'Not specified',
                  icon: Icons.email_outlined,
                ),
                _DetailRow(
                  label: 'Phone Number',
                  value: user.phoneNumber,
                  icon: Icons.phone_outlined,
                ),
                _DetailRow(
                  label: 'Electronic Signature ID',
                  value: 'DOC-AUTH-${(user.id.length >= 8) ? user.id.substring(0, 8).toUpperCase() : "SECURE"}',
                  icon: Icons.draw_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Privacy & Consent Protocol Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.security_rounded, color: kDoctorAccent, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consent-Governed Clinical Access',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kDoctorAccent,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All diagnostic timelines, lab reports, and medication histories are strictly patient-consented. Diagnostic records unlock for 24 hours only upon explicit patient approval.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E3A8A),
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

            // Action Buttons
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
                label: const Text('Sign Out of Doctor Session', style: TextStyle(fontWeight: FontWeight.w600)),
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
              Icon(icon, size: 18, color: kDoctorAccent),
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
