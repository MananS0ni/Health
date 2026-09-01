import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_avatar.dart' show AppAvatar, AppAvatarSize;
import '../../shared/widgets/app_button.dart';
import '../../core/config/providers.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

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
                  allergies: [
                    'Penicillin',
                    'Sulfa drugs',
                    'Peanuts',
                  ],
                  severity: 'Severe',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Medical Conditions
              _EmergencySection(
                title: 'MEDICAL CONDITIONS',
                icon: Icons.medical_information,
                color: AppColors.emergencyDark,
                child: _ConditionList(
                  conditions: [
                    'Hypertension (Stage 1)',
                    'Type 2 Diabetes',
                    'Previous Appendix Surgery (2023)',
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Current Medications
              _EmergencySection(
                title: 'CURRENT MEDICATIONS',
                icon: Icons.medication,
                color: AppColors.emergencyDark,
                child: _MedicationList(
                  medications: [
                    {'name': 'Metformin', 'dosage': '500mg', 'frequency': 'Twice daily'},
                    {'name': 'Amlodipine', 'dosage': '5mg', 'frequency': 'Once daily'},
                    {'name': 'Vitamin D3', 'dosage': '1000 IU', 'frequency': 'Once daily'},
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Emergency Contacts
              _EmergencySection(
                title: 'EMERGENCY CONTACTS',
                icon: Icons.contacts,
                color: AppColors.emergencyDark,
                child: Column(
                  children: [
                    _EmergencyContactCard(
                      name: 'Sunita Sharma',
                      relationship: 'Spouse',
                      phone: '+91 98765 43211',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _EmergencyContactCard(
                      name: 'Dr. Priya Patel',
                      relationship: 'Primary Physician',
                      phone: '+91 98765 43212',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Call Emergency',
                      onPressed: () {
                        // Call emergency services
                      },
                      icon: const Icon(Icons.call),
                      type: AppButtonType.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Share Card',
                      onPressed: () {
                        // Share emergency card
                      },
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
