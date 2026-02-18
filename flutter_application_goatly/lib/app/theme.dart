import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF3F2EF);
  static const surface = Colors.white;

  static const primaryYellow = Color(0xFFF2B705);

  static const darkText = Color(0xFF1F2328);
  static const greyText = Color(0xFF5E6C84);

  static const border = Color(0xFFE6E6E6);

  static const success = Color(0xFF1A7F37);
  static const danger = Color(0xFFD1242F);
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
    );
  }
}
