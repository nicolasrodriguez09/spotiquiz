import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF1ED760);
  const ink = Color(0xFF16181C);
  const mist = Color(0xFFF7F2E7);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      secondary: const Color(0xFFFF7A59),
      surface: Colors.white,
      onPrimary: ink,
      onSecondary: Colors.white,
      onSurface: ink,
    ),
  );

  final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      height: 0.96,
      color: ink,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: ink,
      height: 1.35,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF4D535C),
      height: 1.4,
    ),
    labelLarge: GoogleFonts.spaceGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: mist,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      labelStyle: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: Color(0x2216181C)),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1116181C),
      thickness: 1,
    ),
  );
}
