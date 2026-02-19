import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const background = Color(0xFFF3F2EF);
  static const surface = Colors.white;
  static const primaryYellow = Color(0xFFF2B705);
  static const darkText = Color(0xFF1F2328);
  static const greyText = Color(0xFF5E6C84);
  static const border = Color(0xFFE6E6E6);
  static const success = Color(0xFF1A7F37);
  static const danger = Color(0xFFD1242F);

  // Dark Mode Colors
  static const darkBackground = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF2A2A2A);
  static const darkModeText = Color(0xFFE0E0E0);
  static const darkGreyText = Color(0xFFB0B0B0);
  static const darkBorder = Color(0xFF404040);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryYellow,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.darkText,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryYellow,
        surface: AppColors.darkSurface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.darkModeText,
        displayColor: AppColors.darkModeText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkModeText,
      ),
    );
  }
}
