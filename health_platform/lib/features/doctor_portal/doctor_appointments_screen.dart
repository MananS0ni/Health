import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/providers.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  String _selectedFilter = 'All';

  void _showBookAppointmentModal(BuildContext context) {
    final registeredPatients = ref.read(doctorPatientsProvider);
    Map<String, dynamic>? selectedPatient;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final ageController = TextEditingController();
    final timeController = TextEditingController(text: '10:30 AM');
    final complaintController = TextEditingController();
    String selectedType = 'Consultation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Book / Schedule Patient Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Select Registered Patient Dropdown
                  if (registeredPatients.isNotEmpty) ...[
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        labelText: 'Select Registered Patient',
                        hintText: 'Choose existing patient by name / email...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search_rounded, color: kDoctorAccent),
                      ),
                      initialValue: selectedPatient,
                      isExpanded: true,
                      items: registeredPatients.map((p) {
                        final pName = p['full_name'] ?? 'Patient';
                        final pEmail = p['email'] ?? '';
                        final pCode = p['patient_id'] ?? '';
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: p,
                          child: Text(
                            '$pName ($pEmail) • $pCode',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) {
                          setModalState(() {
                            selectedPatient = p;
                            nameController.text = p['full_name'] ?? '';
                            emailController.text = p['email'] ?? '';
                            phoneController.text = (p['phone_number'] != null && p['phone_number'] != '--')
                                ? p['phone_number']
                                : '';
                            ageController.text = (p['age'] != null && p['age'] != 'Not specified')
                                ? p['age'].toString().replaceAll(' yrs', '')
                                : '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Full Name *',
                      hintText: 'e.g. Manan Soni',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Patient Email Address *',
                      hintText: 'e.g. manansoni2905@gmail.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g. 9536742526',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age (Years)',
                            hintText: 'e.g. 25',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          decoration: const InputDecoration(
                            labelText: 'Appointment Time',
                            hintText: '11:00 AM',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                            DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                            DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                          ],
                          onChanged: (v) => setModalState(() => selectedType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: complaintController,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint / Reason for Visit',
                      hintText: 'e.g. Routine consultation & clinical checkup',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final now = DateTime.now();
                      final pName = nameController.text.trim();
                      final pEmail = emailController.text.trim().toLowerCase();
                      final pPhone = phoneController.text.trim();
                      final pAge = ageController.text.trim().isNotEmpty ? ageController.text.trim() : 'Not specified';
                      
                      // Resolve patient ID: use real registered code or match
                      String resolvedPatientId = selectedPatient != null
                          ? (selectedPatient!['patient_id'] ?? selectedPatient!['id'] ?? '')
                          : '';
                      if (resolvedPatientId.isEmpty && registeredPatients.isNotEmpty) {
                        final matched = registeredPatients.firstWhere(
                          (p) =>
                              (p['email'] != null && p['email'].toString().toLowerCase() == pEmail) ||
                              (p['phone_number'] != null && p['phone_number'].toString() == pPhone) ||
                              (p['full_name'] != null && p['full_name'].toString().toLowerCase() == pName.toLowerCase()),
                          orElse: () => {},
                        );
                        if (matched.isNotEmpty) {
                          resolvedPatientId = matched['patient_id'] ?? matched['id'] ?? '';
                        }
                      }
                      if (resolvedPatientId.isEmpty) {
                        resolvedPatientId = pEmail.isNotEmpty ? pEmail : 'PAT-${now.millisecondsSinceEpoch.toString().substring(7)}';
                      }

                      final apt = {
                        'id': 'apt_${now.millisecondsSinceEpoch}',
                        'patient_id': resolvedPatientId,
                        'patient': resolvedPatientId,
                        'patient_name': pName,
                        'patient_email': pEmail,
                        'age': pAge,
                        'gender': selectedPatient != null ? (selectedPatient!['gender'] ?? 'Not specified') : 'Not specified',
                        'time': timeController.text.trim().isNotEmpty ? timeController.text.trim() : '10:30 AM',
                        'time_slot': timeController.text.trim().isNotEmpty ? timeController.text.trim() : '10:30 AM',
                        'appointment_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                        'type': selectedType,
                        'consultation_type': selectedType,
                        'status': 'Scheduled',
                        'chief_complaint': complaintController.text.trim().isNotEmpty
                            ? complaintController.text.trim()
                            : 'General Consultation',
                      };
                      await ref.read(doctorAppointmentsProvider.notifier).addAppointment(apt);
                      if (context.mounted) {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appointment scheduled for $pName ($resolvedPatientId).')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDoctorAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: const Text('Confirm Schedule'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(doctorAppointmentsProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kDoctorAccent),
            tooltip: 'Schedule Appointment',
            onPressed: () => _showBookAppointmentModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookAppointmentModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Appointment'),
        backgroundColor: kDoctorAccent,
        foregroundColor: Colors.white,
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
          Builder(builder: (context) {
            final ageStr = (apt['age'] != null && apt['age'] != 'null' && apt['age'] != 'Not specified')
                ? (apt['age'].toString().endsWith('yrs') ? apt['age'].toString() : '${apt['age']} yrs')
                : 'Age not specified';
            final genderStr = (apt['gender'] != null && apt['gender'] != 'null' && apt['gender'] != '--')
                ? apt['gender']
                : 'Not specified';
            final typeStr = (apt['type'] != null && apt['type'] != 'null')
                ? apt['type']
                : (apt['consultation_type'] ?? 'Consultation');
            return Text(
              '$ageStr • $genderStr • $typeStr',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            );
          }),
          const SizedBox(height: 6),
          Builder(builder: (context) {
            final complaint = (apt['chief_complaint'] != null && apt['chief_complaint'] != 'null')
                ? apt['chief_complaint']
                : (apt['consultation_type'] ?? 'General Consultation & Clinical Checkup');
            return Text(
              'Chief Complaint: $complaint',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            );
          }),
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
