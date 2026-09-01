import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum AvatarSize { xs, sm, md, lg, xl }

typedef AppAvatarSize = AvatarSize;

class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final AvatarSize size;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AvatarSize.md,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = _getSize();
    final fontSize = _getFontSize();

    if (imageUrl != null) {
      return CircleAvatar(
        radius: avatarSize / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: backgroundColor ?? AppColors.surfaceVariant,
      );
    }

    final initials = _getInitials();
    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: backgroundColor ?? AppColors.primaryLight,
      child: Text(
        initials,
        style: AppTextStyles.titleMedium.copyWith(
          color: Colors.white,
          fontSize: fontSize,
        ),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case AvatarSize.xs:
        return AppSpacing.avatarXs;
      case AvatarSize.sm:
        return AppSpacing.avatarSm;
      case AvatarSize.md:
        return AppSpacing.avatarMd;
      case AvatarSize.lg:
        return AppSpacing.avatarLg;
      case AvatarSize.xl:
        return AppSpacing.avatarXl;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AvatarSize.xs:
        return 10;
      case AvatarSize.sm:
        return 12;
      case AvatarSize.md:
        return 14;
      case AvatarSize.lg:
        return 18;
      case AvatarSize.xl:
        return 24;
    }
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    
    final parts = name!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
