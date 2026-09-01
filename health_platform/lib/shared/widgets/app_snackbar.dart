import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum SnackbarType { success, error, info, warning }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.hideCurrentSnackBar();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: _getColor(type)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _getBackgroundColor(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.info:
        return Icons.info;
      case SnackbarType.warning:
        return Icons.warning;
    }
  }

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppColors.success;
      case SnackbarType.error:
        return AppColors.emergency;
      case SnackbarType.info:
        return AppColors.info;
      case SnackbarType.warning:
        return AppColors.warning;
    }
  }

  static Color _getBackgroundColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppColors.successLight;
      case SnackbarType.error:
        return AppColors.emergencyLight;
      case SnackbarType.info:
        return AppColors.infoLight;
      case SnackbarType.warning:
        return AppColors.warningLight;
    }
  }
}
