import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF094CB2);
  static const Color backgroundColor = Color(0xFFFAF9FA);
  static const Color surfaceContainer = Color(0xFFEFEDEE);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E9);
  static const Color tertiaryColor = Color(0xFF6D5E00);
  static const Color onSurface = Color(0xFF1B1C1D);
  static const Color onSurfaceVariant = Color(0xFF434653);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: backgroundColor,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        tertiary: tertiaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.notoSerif(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: onSurface,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.notoSerif(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.notoSerif(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.publicSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: onSurfaceVariant,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
      ),
    );
  }
}
