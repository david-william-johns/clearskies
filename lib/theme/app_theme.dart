import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF090E1A);
  static const surface = Color(0xFF111827);
  static const surfaceElevated = Color(0xFF1C2539);
  static const surfaceBorder = Color(0xFF2A3650);

  static const primary = Color(0xFF4FC3F7); // star-blue accent
  static const primaryDim = Color(0xFF1E88B4);

  static const scoreExcellent = Color(0xFF4FC3F7); // bright sky-blue  (≥80)
  static const scoreGood      = Color(0xFF80DEEA); // cyan-teal         (65–79)
  static const scoreFair      = Color(0xFFB0BEC5); // silver-blue grey  (50–64)
  static const scoreAmber     = Color(0xFF78909C); // medium slate      (35–49)
  static const scorePoor      = Color(0xFF607D8B); // dark slate        (<35)

  static const textPrimary = Color(0xFFE8EAF6);
  static const textSecondary = Color(0xFF9BA4BC);
  static const textMuted = Color(0xFF5C6882);

  static const moonGold = Color(0xFFFFD54F);
  static const moonSilver = Color(0xFFB0BEC5);

  static Color scoreColor(int score) {
    if (score >= 80) return scoreExcellent;
    if (score >= 65) return scoreGood;
    if (score >= 50) return scoreFair;
    if (score >= 35) return scoreAmber;
    return scorePoor;
  }

  static String scoreLabel(int score) {
    if (score >= 80) return 'EXCELLENT';
    if (score >= 65) return 'GOOD';
    if (score >= 50) return 'FAIR';
    if (score >= 35) return 'POOR';
    return 'CLOUDY';
  }
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        onSurface: AppColors.textPrimary,
        outline: AppColors.surfaceBorder,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 16),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
