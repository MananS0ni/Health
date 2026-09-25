import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_list_state.dart';
import '../../shared/widgets/web_constraint.dart';
import '../../core/config/providers.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/family_member.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  ListStatus _viewStatus = ListStatus.content;

  void _showAddMemberDialog(BuildContext context) {
    final patientIdController = TextEditingController();
    final nameController = TextEditingController();
    final bloodGroupController = TextEditingController(text: 'B+');
    String selectedRelationship = 'Spouse';
    String selectedGender = 'Male';
    bool isSearching = false;

    final relationships = [
      'Spouse',
      'Child',
      'Father',
      'Mother',
      'Brother',
      'Sister',
      'Guardian',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: const [
              Icon(Icons.family_restroom_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add Family Member Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Link by Patient ID or Email (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: patientIdController,
                    decoration: InputDecoration(
                      hintText: 'e.g. PAT-4726A2 or email@gmail.com',
                      border: const OutlineInputBorder(),
                      suffixIcon: isSearching
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                              tooltip: 'Lookup Patient Record',
                              onPressed: () async {
                                final q = patientIdController.text.trim();
                                if (q.isEmpty) return;
                                setDialogState(() => isSearching = true);
                                try {
                                  final list = await ApiClient().getLabPatients(q);
                                  if (list.isNotEmpty) {
                                    final p = Map<String, dynamic>.from(list.first as Map);
                                    setDialogState(() {
                                      isSearching = false;
                                      nameController.text = p['full_name'] ?? '';
                                      patientIdController.text = p['patient_id'] ?? q;
                                      if (p['gender'] != null && ['Male', 'Female', 'Other'].contains(p['gender'])) {
                                        selectedGender = p['gender'];
                                      }
                                      if (p['blood_group'] != null && p['blood_group'].toString().isNotEmpty) {
                                        bloodGroupController.text = p['blood_group'];
                                      }
                                    });
                                  } else {
                                    setDialogState(() => isSearching = false);
                                  }
                                } catch (_) {
                                  setDialogState(() => isSearching = false);
                                }
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Member Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Relationship *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRelationship,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (val) => setDialogState(() => selectedRelationship = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gender *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) => setDialogState(() => selectedGender = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Blood Group', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bloodGroupController.text)
                        ? bloodGroupController.text
                        : 'B+',
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                    ],
                    onChanged: (val) => setDialogState(() => bloodGroupController.text = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final now = DateTime.now();
                final pid = patientIdController.text.trim().isNotEmpty
                    ? patientIdController.text.trim()
                    : 'PAT-${now.millisecondsSinceEpoch.toString().substring(7)}';
                final newMember = FamilyMember(
                  memberId: 'mem_${now.millisecondsSinceEpoch}',
                  patientId: pid,
                  fullName: nameController.text.trim(),
                  relationship: selectedRelationship,
                  dateOfBirth: 'Not specified',
                  gender: selectedGender,
                  bloodGroup: bloodGroupController.text.trim().isNotEmpty ? bloodGroupController.text.trim() : 'Unknown',
                  totalRecords: 0,
                );
                ref.read(familyMembersProvider.notifier).addMember(newMember);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${newMember.fullName} linked as $selectedRelationship.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save Member'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyMembers = ref.watch(familyMembersProvider);

    final activeStatus = (_viewStatus == ListStatus.content && familyMembers.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Family Profiles'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showAddMemberDialog(context),
          ),
        ],
      ),
      body: WebConstraint(
        maxWidth: 720,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListStatusSelector(
                currentStatus: _viewStatus,
                onStatusChanged: (s) => setState(() => _viewStatus = s),
              ),
              Expanded(
                child: AppListState(
                  status: activeStatus,
                  emptyMessage: 'No Family Members Linked',
                  emptyIcon: Icons.people_outline,
                  errorMessage: 'Failed to retrieve family members list.',
                  onRetry: () => setState(() => _viewStatus = ListStatus.content),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: familyMembers.length,
                    itemBuilder: (context, index) {
                      final member = familyMembers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () => _showMemberDetail(context, member),
                          child: Row(
                            children: [
                              AppAvatar(name: member.fullName, size: AppAvatarSize.md),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'DOB: ${member.dateOfBirth} • Blood: ${member.bloodGroup}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              AppBadge(text: member.relationship, type: AppBadgeType.info, isSmall: true),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddMemberDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }

  void _showMemberDetail(BuildContext context, dynamic member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                AppAvatar(name: member.fullName, size: AppAvatarSize.lg),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    AppBadge(text: member.relationship, type: AppBadgeType.info, isSmall: true),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Text('Date of Birth: ${member.dateOfBirth}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Gender: ${member.gender}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Blood Group: ${member.bloodGroup}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'View Health Records',
              onPressed: () => Navigator.pop(context),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
