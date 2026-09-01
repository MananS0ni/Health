import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock_data/mock_doctor_data.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_list_state.dart';

const Color kDoctorAccent = Color(0xFF1E40AF);

class PatientSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const PatientSearchScreen({super.key, this.initialQuery});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  late TextEditingController _searchController;
  late List<Map<String, dynamic>> _allPatients;
  late List<Map<String, dynamic>> _filteredPatients;
  ListStatus _viewStatus = ListStatus.content;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _allPatients = MockDoctorData.getRecentPatients();
    _filterPatients(_searchController.text);
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredPatients = List.from(_allPatients);
      } else {
        final q = query.toLowerCase();
        _filteredPatients = _allPatients.where((p) {
          final name = p['full_name'].toString().toLowerCase();
          final phone = p['phone_number'].toString();
          final pid = p['patient_id'].toString().toLowerCase();
          return name.contains(q) || phone.contains(q) || pid.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStatus = (_viewStatus == ListStatus.content && _filteredPatients.isEmpty)
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            ListStatusSelector(
              currentStatus: _viewStatus,
              onStatusChanged: (s) => setState(() => _viewStatus = s),
            ),
            TextField(
              controller: _searchController,
              onChanged: _filterPatients,
              decoration: InputDecoration(
                hintText: 'Search patient by name, phone, or ID...',
                prefixIcon: const Icon(Icons.search_rounded, color: kDoctorAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _filterPatients('');
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
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AppListState(
                status: activeStatus,
                emptyMessage: 'No Matching Patients Found',
                emptyIcon: Icons.person_search_outlined,
                errorMessage: 'Error querying clinical EMR records.',
                accentColor: kDoctorAccent,
                onRetry: () => setState(() => _viewStatus = ListStatus.content),
                child: ListView.builder(
                  itemCount: _filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _filteredPatients[index];
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

class _PatientSearchResultCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const _PatientSearchResultCard({required this.patient});

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          patient['full_name'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
                            patient['patient_id'],
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
                Text(
                  'Last Diagnosis: ${patient['last_diagnosis']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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
                onPressed: () {
                  context.go('/doctor/add-diagnosis?id=${patient['patient_id']}');
                },
                icon: const Icon(Icons.note_add_outlined, size: 14),
                label: const Text('Add Rx'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kDoctorAccent,
                  side: const BorderSide(color: kDoctorAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
