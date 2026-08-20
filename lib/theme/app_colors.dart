import 'package:flutter/material.dart';

class AppColors {
  // Teal-Inspired Aesthetic Theme

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // PANTONE 320C PALETTE DEFINITIONS (Blue-Green)
  // ---------------------------------------------------------------------------
  static const Color tealPrimary = Color(0xFF009CA6); // Pantone 320C
  static const Color tealLight = Color(0xFFE0F7FA); // Soft Cyan/White mix
  static const Color tealDark = Color(
    0xFF006972,
  ); // Darker shade of Pantone 320C
  static const Color tealAccent = Color(
    0xFF009CA6,
  ); // Pantone 320C for consistency

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF009CA6), // Pantone 320C
      Color(0xFF00757D), // Darker shade
    ],
  );

  static const Color coralAccent = Color(
    0xFFFF7043,
  ); // Complementary aesthetic pop
  static const Color amberWarning = Color(0xFFFFA000);

  // ---------------------------------------------------------------------------
  // LIGHT MODE COLORS
  // ---------------------------------------------------------------------------
  static const Color primaryLight = tealPrimary;
  static const Color secondaryLight = Color(0xFF455A64); // Blue Grey
  static const Color accentLight = tealLight;

  static const Color backgroundLight = Color(
    0xFFF0F7F6,
  ); // Very faint cool mint/grey
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White sheets

  static const Color textMainLight = Color(
    0xFF263238,
  ); // Dark Blue Grey (softer than black)
  static const Color textSubLight = Color(0xFF607D8B); // Blue Grey Medium

  static const Color borderLight = Color(0xFFCFD8DC); // Light Blue Grey
  static const Color disabledLight = Color(0xFFB0BEC5);
  static const Color hoverLight = Color(0xFFE0F2F1); // Very light teal

  // ---------------------------------------------------------------------------
  // DARK MODE COLORS
  // ---------------------------------------------------------------------------
  static const Color primaryDark =
      tealPrimary; // Pantone 320C for dark mode pop
  static const Color secondaryDark = Color(0xFFB0BEC5); // Light Blue Grey
  static const Color accentDark = tealPrimary;

  static const Color backgroundDark = Color(0xFF1C2224); // Dark Gunmetal
  static const Color surfaceDark = Color(0xFF263238); // Blue Grey Dark

  static const Color textMainDark = Color(0xFFECEFF1); // White/Grey
  static const Color textSubDark = Color(0xFF90A4AE); // Muted Blue Grey

  static const Color borderDark = Color(0xFF37474F);
  static const Color disabledDark = Color(0xFF546E7A);
  static const Color cardDark = Color(0xFF263238);
  static const Color hoverDark = Color(0xFF004D40);

  // ---------------------------------------------------------------------------
  // SEMANTIC COLORS
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF2E7D32); // Green
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color warning = amberWarning; // Amber
  static const Color info = Color(0xFF0288D1); // Light Blue

  static const Color cardLight = surfaceLight;

  // AI Score Colors
  static const Color scoreExcellent = Color(0xFF00C853);
  static const Color scoreGood = Color(0xFF0091EA);
  static const Color scoreFair = Color(0xFFFFAB00);
  static const Color scorePoor = Color(0xFFDD2C00);

  // Backward compatibility / Aliases
  static const Color successLight = success;
}
