import 'package:flutter/material.dart';

class AppColors {
  // Colores principales (tonos azulados)
  static const Color primaryBlue = Color(0xFF0066CC); // Azul principal
  static const Color lightBlue = Color(0xFF4D94FF); // Azul claro
  static const Color darkBlue = Color(0xFF003D99); // Azul oscuro
  static const Color accentBlue = Color(0xFF1976D2); // Azul acentuado

  // Verdes (para botones de acción)
  static const Color successGreen = Color(0xFF25D366);
  static const Color darkGreen = Color(0xFF1AA251);

  // Grises y neutrales
  static const Color lightGrey = Color(0xFFF0F2F5);
  static const Color mediumGrey = Color(0xFFE4E6EB);
  static const Color darkGrey = Color(0xFF65676B);
  static const Color textDark = Color(0xFF050505);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBlue, primaryBlue, darkBlue],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [successGreen, darkGreen],
  );
}
