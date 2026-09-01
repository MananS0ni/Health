import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum StatusBadgeType { success, warning, info, error, neutral }

class StatusBadge extends StatelessWidget {
  final String text;
  final StatusBadgeType type;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = StatusBadgeType.neutral,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final textStyle = isSmall ? AppTextStyles.labelSmall : AppTextStyles.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
        vertical: isSmall ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        text,
        style: textStyle.copyWith(color: colors.text),
      ),
    );
  }

  ({Color background, Color text}) _getColors() {
    switch (type) {
      case StatusBadgeType.success:
        return (background: AppColors.successLight, text: AppColors.success);
      case StatusBadgeType.warning:
        return (background: AppColors.warningLight, text: AppColors.warning);
      case StatusBadgeType.info:
        return (background: AppColors.infoLight, text: AppColors.info);
      case StatusBadgeType.error:
        return (background: AppColors.emergencyLight, text: AppColors.emergency);
      case StatusBadgeType.neutral:
        return (background: AppColors.surfaceVariant, text: AppColors.textSecondary);
    }
  }
}
