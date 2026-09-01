import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock_data/mock_doctor_data.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appointments = MockDoctorData.getAppointments();

    final filtered = appointments.where((apt) {
      if (_selectedFilter == 'All') return true;
      return apt['status'] == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments Schedule'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Scheduled', 'In Progress', 'Completed'].map((filter) {
                  final selected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                      selectedColor: kDoctorAccent.withValues(alpha: 0.15),
                      checkmarkColor: kDoctorAccent,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? kDoctorAccent : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: selected ? kDoctorAccent : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Appointment Cards List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No appointments found for "$_selectedFilter"',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final apt = filtered[index];
                        return _AppointmentCard(apt: apt);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> apt;

  const _AppointmentCard({required this.apt});

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] as String;
    final isCompleted = status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kDoctorAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  apt['time'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kDoctorAccent,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.success : kDoctorAccent,
                  ),
                ),
                backgroundColor: isCompleted
                    ? AppColors.successLight
                    : kDoctorAccent.withValues(alpha: 0.08),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            apt['patient_name'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${apt['age']} yrs • ${apt['gender']} • ${apt['type']}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Chief Complaint: ${apt['chief_complaint']}',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  context.go('/doctor/patient-detail?id=${apt['patient_id']}');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kDoctorAccent,
                  side: const BorderSide(color: kDoctorAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Open Chart', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  context.go('/doctor/add-diagnosis?id=${apt['patient_id']}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDoctorAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Consult & Add Rx', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
