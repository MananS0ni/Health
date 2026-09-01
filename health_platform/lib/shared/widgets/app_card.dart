import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? backgroundColor;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.trailing,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: backgroundColor,
      elevation: elevation,
      margin: margin ?? const EdgeInsets.all(AppSpacing.sm),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: child),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: card,
      );
    }

    return card;
  }
}
