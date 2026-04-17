import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Títulos grandes (para encabezados principales)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  // Títulos medianos
  static const TextStyle titleMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  // Subtítulos
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGrey,
  );

  // Texto normal
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  // Texto pequeño (para timestamps, etc)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGrey,
  );

  // Texto blanco para botones
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Link/Texto clickeable
  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBlue,
    decoration: TextDecoration.underline,
  );
}
