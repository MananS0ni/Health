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

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  ListStatus _viewStatus = ListStatus.content;

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relController = TextEditingController(text: 'Spouse');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Family Member Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relController,
              decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse, Child, Parent)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Family member added.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Member'),
          ),
        ],
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
