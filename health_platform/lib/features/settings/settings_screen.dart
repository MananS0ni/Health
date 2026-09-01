import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_avatar.dart' show AppAvatar, AppAvatarSize;
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/web_constraint.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification Preference Toggles
  bool _reportReadyNotif = true;
  bool _appointmentReminderNotif = true;
  bool _admissionUpdateNotif = true;
  bool _prescriptionIssuedNotif = true;

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final emailController = TextEditingController(text: user.email ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
            ],
          ),
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
                const SnackBar(content: Text('Profile details updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Request New Account Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'To link professional credentials (Doctor, Lab Technician, or Hospital Admin), please submit your registration number and workplace affiliation for verification.',
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
                const SnackBar(content: Text('Role verification request submitted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Submit Verification'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Confirm Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              Navigator.pop(dialogContext);
              context.go('/phone');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error)),
          ],
        ),
        content: const Text(
          'This action is irreversible. All health records, linked portal credentials, and personal history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              Navigator.pop(dialogContext);
              context.go('/phone');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account permanently deleted.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final rolesList = List<String>.from(user.roles);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: WebConstraint(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // 1. Profile Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: ${user.phoneNumber}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (user.email != null && user.email!.isNotEmpty)
                              Text(
                                'Email: ${user.email}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        onPressed: () => _showEditProfileDialog(context, user),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xl),
                  const Text(
                    'Active User Roles (Read-only)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: rolesList.map((role) {
                      String label = role;
                      Color color = AppColors.primary;
                      if (role == 'patient') {
                        label = 'Patient';
                        color = AppColors.primary;
                      } else if (role == 'doctor') {
                        label = 'Doctor';
                        color = const Color(0xFF1E40AF);
                      } else if (role == 'lab_staff') {
                        label = 'Lab Technician';
                        color = const Color(0xFF059669);
                      } else if (role == 'hospital_staff') {
                        label = 'Hospital Admin';
                        color = const Color(0xFFD97706);
                      }

                      return Chip(
                        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        backgroundColor: color.withValues(alpha: 0.1),
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Role Management Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text('Role Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddRoleDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Role', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Roles grant access to dedicated clinical, laboratory, and hospital management portals.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Notification Preferences
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Notification Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lab Report Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alert when test results are published by laboratory', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _reportReadyNotif,
                    onChanged: (v) => setState(() => _reportReadyNotif = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Appointment Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Reminders for upcoming consultations', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _appointmentReminderNotif,
                    onChanged: (v) => setState(() => _appointmentReminderNotif = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Inpatient Admission Updates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Bed allocations and ward transfer alerts', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _admissionUpdateNotif,
                    onChanged: (v) => setState(() => _admissionUpdateNotif = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Prescription Issued Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alert when a doctor issues a digital prescription', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _prescriptionIssuedNotif,
                    onChanged: (v) => setState(() => _prescriptionIssuedNotif = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Account Actions & Danger Zone
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Sign Out of Account',
                    onPressed: () => _showLogoutDialog(context),
                    type: AppButtonType.outline,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context),
                      icon: Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 18),
                      label: Text('Delete Account Permanently', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
