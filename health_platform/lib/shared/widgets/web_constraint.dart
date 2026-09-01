import 'package:flutter/material.dart';

/// Constrains content to a max width and centers it horizontally.
/// Use this on all main screens so they don't stretch edge-to-edge on wide
/// (web/desktop) viewports. The content area is left unconstrained on mobile.
class WebConstraint extends StatelessWidget {
  final Widget child;

  /// Maximum content width. 900px works well for list/detail screens;
  /// use 1100px for dashboard-style wide layouts.
  final double maxWidth;

  const WebConstraint({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
