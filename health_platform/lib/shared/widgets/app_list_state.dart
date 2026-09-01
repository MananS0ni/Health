import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';

enum ListStatus { content, loading, empty, error }

class AppListState extends StatelessWidget {
  final ListStatus status;
  final Widget child;
  final String emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String errorMessage;
  final VoidCallback? onRetry;
  final Color? accentColor;

  const AppListState({
    super.key,
    required this.status,
    required this.child,
    this.emptyMessage = 'No items found',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorMessage = 'Something went wrong while fetching data.',
    this.onRetry,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = accentColor ?? AppColors.primary;

    switch (status) {
      case ListStatus.loading:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(activeAccent),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Loading data...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );

      case ListStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: activeAccent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    emptyIcon,
                    size: 38,
                    color: activeAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check back later or try adjusting your filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (emptyActionLabel != null && onEmptyAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: emptyActionLabel!,
                    onPressed: onEmptyAction!,
                    isFullWidth: false,
                  ),
                ],
              ],
            ),
          ),
        );

      case ListStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 38,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Failed to load data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

      case ListStatus.content:
        return child;
    }
  }
}

/// A compact state selector toolbar widget to visually toggle between
/// Content, Loading, Empty, and Error states on list screens.
class ListStatusSelector extends StatelessWidget {
  final ListStatus currentStatus;
  final ValueChanged<ListStatus> onStatusChanged;

  const ListStatusSelector({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text(
            'State View:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          ...ListStatus.values.map((s) {
            final selected = currentStatus == s;
            final label = s.name[0].toUpperCase() + s.name.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => onStatusChanged(s),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: selected
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
