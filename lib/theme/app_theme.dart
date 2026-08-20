import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Teal-Inspired Aesthetic Theme (H&M Style: Sharp, Flat, Editorial)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryLight,
        onSecondary: Colors.white,
        tertiary: AppColors.accentLight,
        onTertiary: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textMainLight,
        surfaceContainerHighest: AppColors.hoverLight,
      ),

      // AppBar - Sharp, Minimal, Flat
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.0, // Editorial spacing
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Card design - Sharp, Flat, Bordered
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0, // Flat
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),

      // Elevated buttons - Sharp Rectangles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0, // Flat
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 20,
          ), // Larger click area
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5, // Uppercase look
          ),
        ),
      ),

      // Outlined buttons - Sharp Borders
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            decoration: TextDecoration.underline,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 32,
      ),

      // Typography - High Contrast Editorial
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 48, // Larger
            fontWeight: FontWeight.w900, // Heavier
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
          displaySmall: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          titleMedium: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
          bodySmall: TextStyle(
            color: AppColors.textSubLight,
            fontSize: 12,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
          ),
          labelLarge: TextStyle(
            color: AppColors.textMainLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input fields - Sharp, Flat, Underlined or Boxed
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderLight),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderLight),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        labelStyle: GoogleFonts.outfit(color: AppColors.textSubLight),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textSubLight.withOpacity(0.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),

      iconTheme: const IconThemeData(color: AppColors.textMainLight),

      // Bottom Navigation Bar - Sharp
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSubLight,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          letterSpacing: 1.0,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Chip theme - Sharp
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.hoverLight,
        disabledColor: AppColors.disabledLight,
        selectedColor: AppColors.primaryLight.withOpacity(0.1),
        secondarySelectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.outfit(color: AppColors.textMainLight),
        secondaryLabelStyle: GoogleFonts.outfit(color: AppColors.primaryLight),
        brightness: Brightness.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp
          side: BorderSide(color: AppColors.borderLight),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        onPrimary: Colors.black,
        secondary: AppColors.secondaryDark,
        onSecondary: Colors.black,
        tertiary: AppColors.accentDark,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.black,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textMainDark,
        surfaceContainerHighest: AppColors.hoverDark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textMainDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textMainDark,
          letterSpacing: 1.0,
        ),
        iconTheme: const IconThemeData(color: AppColors.textMainDark),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp
          side: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 32,
      ),

      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
          displaySmall: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          titleMedium: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
          bodySmall: TextStyle(
            color: AppColors.textSubDark,
            fontSize: 12,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
          ),
          labelLarge: TextStyle(
            color: AppColors.textMainDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderDark),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderDark),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        labelStyle: GoogleFonts.outfit(color: AppColors.textSubDark),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textSubDark.withOpacity(0.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),

      iconTheme: const IconThemeData(color: AppColors.textMainDark),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSubDark,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          letterSpacing: 1.0,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        disabledColor: AppColors.disabledDark,
        selectedColor: AppColors.primaryDark.withOpacity(0.2),
        secondarySelectedColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.outfit(color: AppColors.textMainDark),
        secondaryLabelStyle: GoogleFonts.outfit(color: AppColors.primaryDark),
        brightness: Brightness.dark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderDark),
        ),
      ),
    );
  }
}
