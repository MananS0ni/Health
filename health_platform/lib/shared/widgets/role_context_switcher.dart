import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/providers.dart';

class RoleContextSwitcher extends ConsumerWidget {
  final Color? accentColor;

  const RoleContextSwitcher({
    super.key,
    this.accentColor,
  });

  String _label(String role) {
    switch (role) {
      case 'patient':
        return 'My Health';
      case 'doctor':
        return 'Doctor Portal';
      case 'lab_staff':
        return 'Lab Portal';
      case 'hospital_staff':
        return 'Hospital Portal';
      default:
        return role;
    }
  }

  IconData _icon(String role) {
    switch (role) {
      case 'patient':
        return Icons.favorite_outline_rounded;
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'lab_staff':
        return Icons.science_outlined;
      case 'hospital_staff':
        return Icons.local_hospital_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _routeForRole(String role) {
    switch (role) {
      case 'patient':
        return '/dashboard';
      case 'doctor':
        return '/doctor';
      case 'lab_staff':
        return '/lab';
      case 'hospital_staff':
        return '/hospital';
      default:
        return '/dashboard';
    }
  }

  Color _accentForRole(String role) {
    switch (role) {
      case 'patient':
        return AppColors.primary;
      case 'doctor':
        return const Color(0xFF1E40AF); // Indigo
      case 'lab_staff':
        return const Color(0xFF059669); // Emerald
      case 'hospital_staff':
        return const Color(0xFFD97706); // Amber
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final activeRole = ref.watch(activeRoleProvider);

    if (!user.hasProRole && user.roles.length <= 1) {
      return const SizedBox.shrink();
    }

    final currentColor = accentColor ?? _accentForRole(activeRole);

    return PopupMenuButton<String>(
      onSelected: (role) {
        ref.read(activeRoleProvider.notifier).setRole(role);
        context.go(_routeForRole(role));
      },
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: currentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: currentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon(activeRole),
              size: 16,
              color: currentColor,
            ),
            const SizedBox(width: 7),
            Text(
              _label(activeRole),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: currentColor,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: currentColor,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => user.roles
          .map(
            (role) => PopupMenuItem<String>(
              value: role,
              child: Row(
                children: [
                  Icon(
                    _icon(role),
                    size: 16,
                    color: activeRole == role
                        ? _accentForRole(role)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _label(role),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: activeRole == role
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: activeRole == role
                          ? _accentForRole(role)
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (activeRole == role) ...[
                    const Spacer(),
                    Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: _accentForRole(role),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
