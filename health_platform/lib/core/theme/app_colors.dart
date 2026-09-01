import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - calm blues and teals
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700

  // Secondary colors - soft greens
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color secondaryLight = Color(0xFF34D399); // Emerald 400
  static const Color secondaryDark = Color(0xFF059669); // Emerald 600

  // Neutral colors
  static const Color background = Color(0xFFFAFAFA); // Gray 50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Gray 100

  // Text colors
  static const Color textPrimary = Color(0xFF111827); // Gray 900
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray 400

  // Border colors
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color borderLight = Color(0xFFF3F4F6); // Gray 100

  // Status colors - calm, not alarming
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // Emergency and error colors
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color emergency = Color(0xFFDC2626); // Red 600
  static const Color emergencyLight = Color(0xFFFEE2E2); // Red 100
  static const Color emergencyDark = Color(0xFFB91C1C); // Red 700

  // Test result flags
  static const Color flagNormal = Color(0xFF10B981); // Emerald 500
  static const Color flagHigh = Color(0xFFF59E0B); // Amber 500 - not alarming
  static const Color flagLow = Color(0xFF3B82F6); // Blue 500 - not alarming
  static const Color flagCritical = Color(0xFFDC2626); // Red 600 - only for critical

  // Shadow colors
  static const Color shadow = Color(0x1A000000); // Black with 10% opacity
  static const Color shadowLight = Color(0x0D000000); // Black with 5% opacity
}
