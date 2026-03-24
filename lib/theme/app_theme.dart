import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color coral = Color(0xFFD4849A);
  static const Color mint = Color(0xFF7AB8A0);
  static const Color offWhite = Color(0xFFFFF8F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFF0EDEB);
  static const Color darkGray = Color(0xFF2D3436);
  static const Color mediumGray = Color(0xFF636E72);
  static const Color successGreen = Color(0xFF00B894);
  static const Color errorRed = Color(0xFFE17055);
  static const Color macroProtein = Color(0xFFD4849A);
  static const Color macroCarbs = Color(0xFF7AB8A0);
  static const Color macroFat = Color(0xFFFFD166);
}

/// Hard pixel-art style shadow — blurRadius 0 gives the "stamped" retro look.
BoxDecoration pixelCard({
  Color color = AppColors.white,
  Color borderColor = AppColors.darkGray,
  double borderWidth = 1.5,
  double shadowOffset = 3,
  double radius = 6,
  Color? shadowColor,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor.withValues(alpha: 0.22), width: borderWidth),
    boxShadow: [
      BoxShadow(
        color: (shadowColor ?? borderColor).withValues(alpha: 0.28),
        blurRadius: 0,
        offset: Offset(shadowOffset, shadowOffset),
      ),
    ],
  );
}

// ── Text Styles ───────────────────────────────────────────────────────────────

class AppTextStyles {
  static TextStyle heading({Color color = AppColors.darkGray}) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3);

  static TextStyle subheading({Color color = AppColors.darkGray}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextStyle body({Color color = AppColors.darkGray}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  static TextStyle caption({Color color = AppColors.mediumGray}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle label({Color color = AppColors.mediumGray}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.2);

  static TextStyle number({Color color = AppColors.darkGray, double size = 30}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5);
}

// ── Spacing ───────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.coral,
        primary: AppColors.coral,
        secondary: AppColors.mint,
        surface: AppColors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: AppColors.offWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.softGray,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkGray,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: AppColors.darkGray, width: 0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.softGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.softGray, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.coral, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: AppColors.mediumGray,
          fontSize: 15,
        ),
      ),
      useMaterial3: true,
    );
  }
}
