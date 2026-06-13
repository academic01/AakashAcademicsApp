import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary
  static const Color primary = Color(0xFF0D2240); // Navy Blue
  static const Color secondary = Color(0xFFF5A623); // Orange
  static const Color background = Colors.white;

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0A1628); // Deep Navy
  static const Color darkCard = Color(0xFF132238); // Dark Navy Surface
  static const Color darkBorder = Color(0xFF1F324E); // Navy Border
  static const Color darkDivider = Color(0xFF1F324E);

  // Text Colors
  static const Color textDark = Color(0xFF0A0A0A);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF888888);
  static const Color textMutedDark = Color(0xFF90A4AE);

  // Surface Colors
  static const Color card = Color(0xFFF9F9F9);
  static const Color border = Color(0xFFE5E5E5);
  static const Color divider = Color(0xFFEEEEEE);

  // Status Colors
  static const Color success = Color(0xFF22C55E); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Category Colors
  static const Color cuet = Color(0xFF7C3AED); // Purple
  static const Color govt = Color(0xFF16A34A); // Dark Green
  static const Color jee = Color(0xFFDC2626); // Crimson
  static const Color neet = Color(0xFF0891B2); // Cyan

  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D2240), Color(0xFF1A3A52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFE89E0E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF070F1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x66000000);

  // Transparent Colors
  static const Color transparent = Colors.transparent;
  static const Color black20 = Color(0x33000000);
  static const Color black50 = Color(0x80000000);
  static const Color white50 = Color(0x80FFFFFF);
}
