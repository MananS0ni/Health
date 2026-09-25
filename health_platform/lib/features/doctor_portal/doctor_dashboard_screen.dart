import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/providers.dart';
import '../../shared/widgets/app_avatar.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  final _searchController = TextEditingController();

  Future<void> _handleAcceptRequest(Map<String, dynamic> req) async {
    final consentId = req['id']?.toString() ?? '';
    final patientName = req['patient_name'] ?? 'Patient';
    final patientCode = req['patient_code'] ?? req['patient'] ?? '';

    final res = await ref.read(doctorIncomingRequestsProvider.notifier).actionRequest(consentId, 'accept');

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connection accepted! 24h access granted for $patientName.'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        final pEmail = req['patient_email']?.toString() ?? req['email']?.toString() ?? '';
        if (pEmail.isNotEmpty) {
          ref.read(doctorPatientsProvider.notifier).fetchPatients(pEmail);
        }
        context.go('/doctor/patient-detail?id=$patientCode');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${res['error'] ?? 'Could not accept request'}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineRequest(Map<String, dynamic> req) async {
    final consentId = req['id']?.toString() ?? '';
    final patientName = req['patient_name'] ?? 'Patient';

    await ref.read(doctorIncomingRequestsProvider.notifier).actionRequest(consentId, 'decline');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request from $patientName was declined.'),
          backgroundColor: const Color(0xFF475569),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentPatients = ref.watch(doctorPatientsProvider);
    final incomingRequests = ref.watch(doctorIncomingRequestsProvider);
    final pendingRequests = incomingRequests.where((r) => r['status'] == 'pending').toList();

    final user = ref.watch(userProvider);
    final cleanName = user.fullName.trim();
    final displayName = cleanName.toLowerCase().startsWith('dr.') ? cleanName : 'Dr. $cleanName';
    final docProfile = user.doctorProfile;
    final spec = (docProfile != null && docProfile.specialization.isNotEmpty)
        ? docProfile.specialization
        : 'Specialist';
    final reg = (docProfile != null && docProfile.registrationNumber.isNotEmpty)
        ? 'Reg. ${docProfile.registrationNumber}'
        : 'Reg. Verified';
    final clinic = (docProfile != null && docProfile.clinicName != null && docProfile.clinicName!.isNotEmpty)
        ? ' • ${docProfile.clinicName}'
        : '';
    final subText = '$spec • $reg$clinic';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner / Welcome
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'DOCTOR PORTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome, $displayName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (query) {
                  final clean = query.trim();
                  if (clean.isNotEmpty) {
                    context.go('/doctor/patients?q=${Uri.encodeComponent(clean)}');
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search patient by registered email (e.g. manansoni2905@gmail.com)...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: kDoctorAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: kDoctorAccent),
                    tooltip: 'Search Patient',
                    onPressed: () {
                      final clean = _searchController.text.trim();
                      if (clean.isNotEmpty) {
                        context.go('/doctor/patients?q=${Uri.encodeComponent(clean)}');
                      }
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Patients",
                    value: "${recentPatients.length}",
                    icon: Icons.people_outline_rounded,
                    color: kDoctorAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Active Consents',
                    value: '${incomingRequests.where((r) => r['status'] == 'approved' || r['status'] == 'accepted').length}',
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Approvals',
                    value: '${pendingRequests.length}',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Incoming Patient Link & Access Requests Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Incoming Patient Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (pendingRequests.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Text(
                          '${pendingRequests.length} Pending Approval',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          '0 Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => ref.read(doctorIncomingRequestsProvider.notifier).fetchRequests(),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: kDoctorAccent),
                  label: const Text('Refresh', style: TextStyle(color: kDoctorAccent, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (incomingRequests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.link_rounded, color: AppColors.textSecondary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No pending patient requests. To connect with a patient, use the Search tab or enter their registered email above to send an access request.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...incomingRequests.map((req) => _IncomingPatientRequestCard(
                    request: req,
                    onAccept: () => _handleAcceptRequest(req),
                    onDecline: () => _handleDeclineRequest(req),
                    onOpenChart: () {
                      final pCode = req['patient_code'] ?? req['patient'] ?? '';
                      context.go('/doctor/patient-detail?id=$pCode');
                    },
                  )),
            const SizedBox(height: AppSpacing.lg),


            // Recent Patients Viewed Section
            const Text(
              'Recent Patients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (recentPatients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.people_outline_rounded, color: AppColors.textSecondary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No recent patient consultations yet. Search for a patient by email above to view their records.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentPatients.map((patient) => _RecentPatientCard(patient: patient)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _RecentPatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const _RecentPatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final gender = (patient['gender'] != null && patient['gender'] != 'null' && patient['gender'] != '--')
        ? patient['gender']
        : 'Patient';
    final lastVisit = (patient['last_visit'] != null && patient['last_visit'] != 'null' && patient['last_visit'] != '--')
        ? patient['last_visit']
        : 'First Consultation (New Patient)';
    final bloodGroup = (patient['blood_group'] != null && patient['blood_group'] != 'null' && patient['blood_group'] != '--')
        ? ' • Blood: ${patient['blood_group']}'
        : '';

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
          AppAvatar(name: patient['full_name'], size: AppAvatarSize.md),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['full_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$gender$bloodGroup • Last Visit: $lastVisit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              context.go('/doctor/patient-detail?id=${patient['patient_id']}');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: kDoctorAccent,
              side: const BorderSide(color: kDoctorAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('View Record', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _IncomingPatientRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onOpenChart;

  const _IncomingPatientRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onOpenChart,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final patientName = (request['patient_name'] != null && request['patient_name'].toString().isNotEmpty)
        ? request['patient_name']
        : 'Patient';
    final patientCode = request['patient_code'] ?? 'PAT-NEW';
    final patientPhone = (request['patient_phone'] != null && request['patient_phone'].toString().isNotEmpty)
        ? request['patient_phone']
        : (request['patient_email'] ?? '--');
    final purpose = request['purpose'] ?? 'Patient Link & Record Access Request';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFEFCE8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? const Color(0xFFFDE047) : AppColors.border,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isPending ? 0.04 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(name: patientName, size: AppAvatarSize.md),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            patientCode,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Contact: $patientPhone',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isPending ? Icons.pending_actions_rounded : Icons.verified_user_rounded,
                          size: 14,
                          color: isPending ? const Color(0xFFB45309) : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isPending ? 'Request: $purpose' : 'Status: Connected (24-Hour Access Active)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isPending ? const Color(0xFF92400E) : const Color(0xFF065F46),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPending) ...[
                OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: const Text('Decline', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Accept & Open Chart',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else if (isApproved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'Connected & Authorized',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onOpenChart,
                  icon: const Icon(Icons.folder_shared_rounded, size: 15, color: Colors.white),
                  label: const Text('Open Chart', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDoctorAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
