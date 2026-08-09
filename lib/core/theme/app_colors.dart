import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFFB61E2E);
  static const Color primaryDark = Color(0xFF7F0F1B);
  static const Color secondary = Color(0xFF16233E);
  static const Color accent = Color(0xFFC8A24A);
  static const Color background = Color(0xFFF7F2E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1EADF);
  static const Color border = Color(0xFFE4D9CA);
  static const Color text = Color(0xFF1E2330);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color muted = Color(0xFF9AA2B2);
  static const Color success = Color(0xFF1F7A4C);
  static const Color warning = Color(0xFFB8791F);
  static const Color error = Color(0xFFC2412C);
  static const Color info = Color(0xFF355C8B);

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF131C31);
  static const Color darkSurfaceVariant = Color(0xFF19243C);
  static const Color darkBorder = Color(0xFF27324E);
  static const Color darkText = Color(0xFFF7F9FC);
  static const Color darkTextSecondary = Color(0xFFAFB8CD);
  static const Color darkMuted = Color(0xFF8B95A9);
  static const Color darkPrimary = Color(0xFFE05555);
  static const Color darkAccent = Color(0xFFE1C37B);

  static Color facultyColor(String code) {
    switch (code.toUpperCase()) {
      case 'FAMSS':
        return const Color(0xFFD65C5C);
      case 'FCOM':
        return const Color(0xFFDE8A45);
      case 'FENG':
        return const Color(0xFF5F7DA8);
      case 'FEVS':
        return const Color(0xFF4FA36E);
      case 'FNAS':
        return const Color(0xFF9B6BB7);
      default:
        return accent;
    }
  }
}

