import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum AppBadgeType { success, warning, info, error, neutral }

typedef BadgeType = AppBadgeType;

class AppBadge extends StatelessWidget {
  final String text;
  final AppBadgeType type;
  final bool isSmall;

  const AppBadge({
    super.key,
    required this.text,
    this.type = AppBadgeType.neutral,
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
      case AppBadgeType.success:
        return (background: AppColors.successLight, text: AppColors.success);
      case AppBadgeType.warning:
        return (background: AppColors.warningLight, text: AppColors.warning);
      case AppBadgeType.info:
        return (background: AppColors.infoLight, text: AppColors.info);
      case AppBadgeType.error:
        return (background: AppColors.warningLight, text: AppColors.warning); // Red reserved for emergency only
      case AppBadgeType.neutral:
        return (background: AppColors.surfaceVariant, text: AppColors.textSecondary);
    }
  }
}
