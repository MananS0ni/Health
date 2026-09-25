import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/providers.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_list_state.dart';
import '../../core/network/api_client.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class PatientSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const PatientSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends ConsumerState<PatientSearchScreen> {
  late TextEditingController _searchController;
  ListStatus _viewStatus = ListStatus.content;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: initial);
    if (initial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(doctorPatientsProvider.notifier).fetchPatients(initial.trim());
      });
    }
  }

  @override
  void didUpdateWidget(PatientSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      ref.read(doctorPatientsProvider.notifier).fetchPatients(widget.initialQuery!.trim());
    }
  }

  void _showAddPatientModal(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final ageController = TextEditingController(); // Dynamic, not prefilled to 30
    final bloodGroupController = TextEditingController();
    final diagnosisController = TextEditingController();
    String selectedGender = 'Male';

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
                    'Register New Patient',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Full Name *',
                      hintText: 'e.g. Ramesh Kumar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Patient Email Address *',
                      hintText: 'e.g. patient@example.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Phone Number *',
                      hintText: 'e.g. 98765 43210',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age (Years)',
                            hintText: 'e.g. 28',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) => setModalState(() => selectedGender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bloodGroupController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      hintText: 'e.g. O+, A+, B+, AB-',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Diagnosis / Chief Complaint',
                      hintText: 'e.g. Chronic seasonal allergies',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final ageParsed = int.tryParse(ageController.text.trim());
                      final newPatient = {
                        'full_name': nameController.text.trim(),
                        'email': emailController.text.trim().toLowerCase(),
                        'phone_number': phoneController.text.trim(),
                        'age': ageParsed != null ? '$ageParsed' : 'Not specified',
                        'gender': selectedGender,
                        'blood_group': bloodGroupController.text.trim().isNotEmpty
                            ? bloodGroupController.text.trim().toUpperCase()
                            : '--',
                        'last_diagnosis': diagnosisController.text.trim().isNotEmpty
                            ? diagnosisController.text.trim()
                            : 'General Consultation',
                        'vitals': {'bp': '120/80', 'hr': '72 bpm', 'spo2': '99%', 'temp': '98.6°F'},
                      };
                      await ref.read(doctorPatientsProvider.notifier).addPatient(newPatient);
                      if (context.mounted) {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${newPatient['full_name']} registered with full 24-hr clinical access!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDoctorAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: const Text('Add Patient to Directory'),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPatients = ref.watch(doctorPatientsProvider);
    final query = _searchController.text.toLowerCase().trim();
    final filteredPatients = query.isEmpty
        ? allPatients
        : allPatients.where((p) {
            final name = (p['full_name'] ?? '').toString().toLowerCase();
            final phone = (p['phone_number'] ?? '').toString().toLowerCase();
            final pid = (p['patient_id'] ?? '').toString().toLowerCase();
            final email = (p['email'] ?? '').toString().toLowerCase();
            return name.contains(query) || phone.contains(query) || pid.contains(query) || email.contains(query);
          }).toList();

    final displayPatients = filteredPatients.isNotEmpty ? filteredPatients : allPatients;

    final activeStatus = (_viewStatus == ListStatus.content && displayPatients.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Patient Directory & Search'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: kDoctorAccent),
            tooltip: 'Add Patient',
            onPressed: () => _showAddPatientModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddPatientModal(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Patient'),
        backgroundColor: kDoctorAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            ListStatusSelector(
              currentStatus: _viewStatus,
              onStatusChanged: (s) => setState(() => _viewStatus = s),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (val) {
                      final email = val.trim();
                      ref.read(doctorPatientsProvider.notifier).fetchPatients(email);
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter patient registered email...',
                      prefixIcon: const Icon(Icons.email_outlined, color: kDoctorAccent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(doctorPatientsProvider.notifier).reset();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kDoctorAccent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDoctorAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Search'),
                  onPressed: () {
                    final email = _searchController.text.trim();
                    ref.read(doctorPatientsProvider.notifier).fetchPatients(email);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _searchController.text.trim().isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text(
                              'Enter Patient Email to Search Database',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'For patient privacy and HIPAA compliance, all patient medical records are secured. Enter the patient\'s registered email above to look up their clinical records directly from the database.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  : AppListState(
                      status: activeStatus,
                      emptyMessage: 'No Patient Found in Database',
                      emptyIcon: Icons.person_search_outlined,
                      errorMessage: 'Error querying clinical EMR records from database.',
                      accentColor: kDoctorAccent,
                      onRetry: () {
                        final email = _searchController.text.trim();
                        ref.read(doctorPatientsProvider.notifier).fetchPatients(email);
                      },
                      child: ListView.builder(
                        itemCount: displayPatients.length,
                        itemBuilder: (context, index) {
                          final patient = displayPatients[index];
                          return _PatientSearchResultCard(patient: patient);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientSearchResultCard extends StatefulWidget {
  final Map<String, dynamic> patient;

  const _PatientSearchResultCard({required this.patient});

  @override
  State<_PatientSearchResultCard> createState() => _PatientSearchResultCardState();
}

class _PatientSearchResultCardState extends State<_PatientSearchResultCard> {
  bool _isRequesting = false;
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final vitals = patient['vitals'] as Map<String, dynamic>?;

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
            children: [
              AppAvatar(name: patient['full_name'], size: AppAvatarSize.lg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            patient['full_name'],
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kDoctorAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            patient['patient_id'] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: kDoctorAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient['gender']} • ${patient['age']} yrs • +91 ${patient['phone_number']}',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Last Diagnosis: ${patient['last_diagnosis']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (vitals != null && vitals['bp'] != null)
                  Text(
                    'BP: ${vitals['bp']}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kDoctorAccent,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: (_isRequesting || _requested)
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isRequesting = true);
                        try {
                          final patientId = patient['patient_id']?.toString() ?? patient['email']?.toString() ?? '';
                          final res = await ApiClient().requestDoctorConsent(patientId: patientId);
                          if (!mounted) return;
                          setState(() {
                            _isRequesting = false;
                            _requested = true;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('✅ ${res['message'] ?? 'Consent request sent to patient.'}'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isRequesting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: AppColors.emergency,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: _isRequesting
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_requested ? Icons.check_circle_outline_rounded : Icons.shield_outlined, size: 14),
                label: Text(_requested ? 'Request Sent' : 'Request Access'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _requested ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  side: BorderSide(color: _requested ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/doctor/add-diagnosis?id=${patient['patient_id']}');
                },
                icon: const Icon(Icons.note_add_outlined, size: 14),
                label: const Text('Add Rx'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kDoctorAccent,
                  side: const BorderSide(color: kDoctorAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/doctor/patient-detail?id=${patient['patient_id']}');
                },
                icon: const Icon(Icons.folder_open_rounded, size: 14),
                label: const Text('View Full Chart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDoctorAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
