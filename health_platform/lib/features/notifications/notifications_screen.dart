import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_list_state.dart';
import '../../shared/widgets/web_constraint.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  ListStatus _viewStatus = ListStatus.content;

  IconData _iconForType(String type) {
    switch (type) {
      case 'lab_report':
        return Icons.science_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      case 'admission':
        return Icons.local_hospital_outlined;
      case 'appointment':
        return Icons.calendar_today_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'lab_report':
        return const Color(0xFF059669); // Emerald
      case 'prescription':
        return AppColors.primary;
      case 'admission':
        return const Color(0xFFD97706); // Amber
      case 'appointment':
        return const Color(0xFF1E40AF); // Indigo
      default:
        return AppColors.primary;
    }
  }

  void _handleNotificationTap(NotificationItem item) {
    ref.read(notificationsProvider.notifier).markAsRead(item.id);

    switch (item.type) {
      case 'lab_report':
        context.go('/reports');
        break;
      case 'prescription':
        context.go('/records');
        break;
      case 'admission':
        context.go('/hospital/admissions');
        break;
      case 'appointment':
        context.go('/doctor/appointments');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              AppBadge(
                text: '$unreadCount New',
                type: AppBadgeType.info,
                isSmall: true,
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
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
              // State Toggle Toolbar
              ListStatusSelector(
                currentStatus: _viewStatus,
                onStatusChanged: (status) => setState(() => _viewStatus = status),
              ),

              Expanded(
                child: AppListState(
                  status: _viewStatus == ListStatus.content && notifications.isEmpty
                      ? ListStatus.empty
                      : _viewStatus,
                  emptyMessage: 'No notifications yet',
                  emptyIcon: Icons.notifications_none_rounded,
                  errorMessage: 'Failed to load notifications stream.',
                  onRetry: () => setState(() => _viewStatus = ListStatus.content),
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      final typeColor = _colorForType(item.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () => _handleNotificationTap(item),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _iconForType(item.type),
                                  color: typeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: item.read
                                                  ? FontWeight.w400
                                                  : FontWeight.w700,
                                              color: item.read
                                                  ? AppColors.textSecondary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!item.read) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: typeColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.createdAt,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }
}
