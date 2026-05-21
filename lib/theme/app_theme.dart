import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Drive Go theme — Light + Dark variants.
/// Cairo font supports both Arabic and Latin scripts.
class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        surface: AppColors.white,
        onSurface: AppColors.grey900,
        error: AppColors.statusBooked,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.grey50,
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.grey900,
        displayColor: AppColors.grey900,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.navy,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        surface: AppColors.navyDark,
        onSurface: AppColors.white,
        error: AppColors.statusBooked,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A1A30),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.gold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.navyDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
    );
  }
}
