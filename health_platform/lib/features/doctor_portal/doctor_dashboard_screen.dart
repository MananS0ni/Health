import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock_data/mock_doctor_data.dart';
import '../../shared/widgets/app_avatar.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = MockDoctorData.getAppointments();
    final recentPatients = MockDoctorData.getRecentPatients();

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
                  const Text(
                    'Welcome, Dr. Max Patel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'General Physician • Reg. MH-12345 • Apollo Clinic',
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
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    context.go('/doctor/patients?q=${Uri.encodeComponent(query)}');
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Quick search patient by mobile number or name...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: kDoctorAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: kDoctorAccent),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        context.go(
                            '/doctor/patients?q=${Uri.encodeComponent(_searchController.text)}');
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
                    title: "Today's Appts",
                    value: "${appointments.length}",
                    icon: Icons.calendar_today_rounded,
                    color: kDoctorAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: '1',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'In Queue',
                    value: '4',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Today's Appointments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Appointments",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/doctor/appointments'),
                  child: const Text(
                    'View All',
                    style: TextStyle(color: kDoctorAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ...appointments.map((apt) => _AppointmentTile(appointment: apt)),

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

class _AppointmentTile extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] as String;
    final isCompleted = status == 'Completed';
    final isInProgress = status == 'In Progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isInProgress
              ? kDoctorAccent.withValues(alpha: 0.5)
              : AppColors.border,
          width: isInProgress ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: kDoctorAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              appointment['time'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kDoctorAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['patient_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appointment['age']} yrs • ${appointment['gender']} • ${appointment['chief_complaint']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context.go('/doctor/patient-detail?id=${appointment['patient_id']}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? Colors.grey.shade200
                  : (isInProgress ? kDoctorAccent : Colors.white),
              foregroundColor: isCompleted
                  ? AppColors.textSecondary
                  : (isInProgress ? Colors.white : kDoctorAccent),
              elevation: 0,
              side: isCompleted
                  ? BorderSide.none
                  : (isInProgress
                      ? BorderSide.none
                      : const BorderSide(color: kDoctorAccent)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isCompleted ? 'View Record' : 'Open Chart',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                  '${patient['gender']} • Last Visit: ${patient['last_visit']}',
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
