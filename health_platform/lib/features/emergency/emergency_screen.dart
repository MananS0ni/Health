import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_avatar.dart' show AppAvatar, AppAvatarSize;
import '../../shared/widgets/app_button.dart';
import '../../core/config/providers.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  void _showEditEmergencyModal(BuildContext context, WidgetRef ref, dynamic user) {
    final bloodGroupController = TextEditingController(text: user.bloodGroup ?? '');
    final allergyController = TextEditingController(text: (user.allergies as List<String>).join(', '));
    final conditionController = TextEditingController(text: (user.medicalConditions as List<String>).join(', '));
    final contactNameController = TextEditingController(text: user.emergencyContactName ?? '');
    final contactPhoneController = TextEditingController(text: user.emergencyContactPhone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
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
                  'Edit Emergency Medical Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bloodGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group (e.g. O+, A+, B-, AB+)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergyController,
                  decoration: const InputDecoration(
                    labelText: 'Allergies (comma separated)',
                    hintText: 'e.g. Penicillin, Peanuts, Sulfa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conditionController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Conditions (comma separated)',
                    hintText: 'e.g. Asthma, Hypertension, Diabetes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Emergency Contact Name',
                    hintText: 'e.g. Spouse / Parent name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone Number',
                    hintText: 'e.g. 98765 43210',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Save Emergency Details',
                  onPressed: () {
                    final allergiesList = allergyController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    final conditionsList = conditionController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final updatedUser = user.copyWith(
                      bloodGroup: bloodGroupController.text.trim().isNotEmpty
                          ? bloodGroupController.text.trim()
                          : user.bloodGroup,
                      allergies: allergiesList,
                      medicalConditions: conditionsList,
                      emergencyContactName: contactNameController.text.trim().isNotEmpty
                          ? contactNameController.text.trim()
                          : user.emergencyContactName,
                      emergencyContactPhone: contactPhoneController.text.trim().isNotEmpty
                          ? contactPhoneController.text.trim()
                          : user.emergencyContactPhone,
                    );
                    ref.read(authStateProvider.notifier).updateCurrentUser(updatedUser);
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Emergency info updated successfully.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callEmergency(BuildContext context, String? phone) async {
    final cleanPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '112';
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing $cleanPhone directly on your device keypad.'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  void _showShareCardModal(BuildContext context, dynamic user) {
    final pid = user.patientId ?? user.id;
    final shareLink = 'https://healthrecord.in/emergency/$pid';
    final shareSummary = '''
EMERGENCY MEDICAL CARD
Name: ${user.fullName}
Patient ID: $pid
Blood Group: ${user.bloodGroup ?? 'Not specified'}
Emergency Contact: ${user.emergencyContactName ?? 'None'} (${user.emergencyContactPhone ?? '112'})
Allergies: ${user.allergies.isNotEmpty ? (user.allergies as List).join(', ') : 'None reported'}
Conditions: ${user.medicalConditions.isNotEmpty ? (user.medicalConditions as List).join(', ') : 'None reported'}
Digital Card: $shareLink
'''.trim();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.share_rounded, color: AppColors.emergency),
            SizedBox(width: 8),
            Text('Share Emergency Medical Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emergencyLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emergency.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Patient ID: $pid • Blood: ${user.bloodGroup ?? "--"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('Emergency Contact: ${user.emergencyContactName ?? "Primary"} (${user.emergencyContactPhone ?? "112"})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.emergencyDark)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Public Emergency URL:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shareLink,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Emergency card link copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareSummary));
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Full Emergency Card text copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('Copy Card Summary'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Card'),
        centerTitle: true,
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            tooltip: 'Edit Emergency Details',
            onPressed: () => _showEditEmergencyModal(context, ref, user),
          ),
        ],
      ),
      body: Container(
        color: AppColors.emergencyLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Emergency Header — compact for mobile
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.emergency,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY CARD',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Critical health info — show to first responders',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
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
              
              // Patient Information
              _EmergencySection(
                title: 'PATIENT INFORMATION',
                icon: Icons.person,
                color: AppColors.emergency,
                child: Column(
                  children: [
                    Row(
                      children: [
                        AppAvatar(
                          name: user.fullName,
                          size: AppAvatarSize.xl,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.dateOfBirth ?? 'DOB: Not provided',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                user.gender ?? 'Gender: Not provided',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _EmergencyRow(
                      icon: Icons.phone,
                      label: 'Emergency Contact',
                      value: user.phoneNumber,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Blood Group
              _EmergencySection(
                title: 'BLOOD GROUP',
                icon: Icons.bloodtype,
                color: AppColors.emergencyDark,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.emergency,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Text(
                        user.bloodGroup ?? 'Unknown',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Blood Type',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Allergies
              _EmergencySection(
                title: 'ALLERGIES',
                icon: Icons.warning,
                color: AppColors.emergencyDark,
                child: _AllergyList(
                  allergies: user.allergies,
                  severity: user.allergies.isNotEmpty ? 'Active' : 'None',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Medical Conditions
              _EmergencySection(
                title: 'MEDICAL CONDITIONS',
                icon: Icons.medical_information,
                color: AppColors.emergencyDark,
                child: _ConditionList(
                  conditions: user.medicalConditions,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Current Medications (Derived dynamically from active prescriptions)
              _EmergencySection(
                title: 'CURRENT MEDICATIONS',
                icon: Icons.medication,
                color: AppColors.emergencyDark,
                child: _MedicationList(
                  medications: ref
                      .watch(recordsProvider)
                      .where((r) => r.recordType == 'prescription')
                      .map((r) => {
                            'name': r.title,
                            'dosage': r.description ?? 'As prescribed',
                            'frequency': r.doctorName ?? 'Verified Rx',
                          })
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Emergency Contacts
              _EmergencySection(
                title: 'EMERGENCY CONTACTS',
                icon: Icons.contacts,
                color: AppColors.emergencyDark,
                child: user.emergencyContactName != null && user.emergencyContactName!.isNotEmpty
                    ? _EmergencyContactCard(
                        name: user.emergencyContactName!,
                        relationship: 'Primary Emergency Contact',
                        phone: user.emergencyContactPhone ?? 'Not specified',
                      )
                    : Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No emergency contact listed. Tap the Edit button on top to add.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Call Emergency',
                      onPressed: () => _callEmergency(context, user.emergencyContactPhone),
                      icon: const Icon(Icons.call),
                      type: AppButtonType.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Share Card',
                      onPressed: () => _showShareCardModal(context, user),
                      icon: const Icon(Icons.share),
                      type: AppButtonType.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.emergencyDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.emergencyDark.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.emergencyDark,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This card contains critical health information. Keep it updated and share with emergency contacts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.emergencyDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _EmergencySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _EmergencyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  const _EmergencyRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.emergencyLight
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isHighlighted
            ? Border.all(color: AppColors.emergency)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighlighted ? AppColors.emergency : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted ? AppColors.emergency : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyList extends StatelessWidget {
  final List<String> allergies;
  final String severity;

  const _AllergyList({
    required this.allergies,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    if (allergies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No known medical or drug allergies recorded.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.emergency,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            'Severity: $severity',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...allergies.map((allergy) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.block,
                    color: AppColors.emergency,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      allergy,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ConditionList extends StatelessWidget {
  final List<String> conditions;

  const _ConditionList({required this.conditions});

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No chronic medical conditions recorded.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: conditions.map((condition) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  color: AppColors.emergencyDark,
                  size: 8,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    condition,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }
}

class _MedicationList extends StatelessWidget {
  final List<Map<String, String>> medications;

  const _MedicationList({required this.medications});

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No active medications or prescriptions recorded.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: medications.map((med) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['name']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${med['dosage']} - ${med['frequency']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )).toList(),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final String name;
  final String relationship;
  final String phone;

  const _EmergencyContactCard({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.emergencyLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.emergency.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: AppColors.emergency,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  relationship,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            color: AppColors.emergency,
            onPressed: () {
              // Call contact
            },
          ),
        ],
      ),
    );
  }
}
