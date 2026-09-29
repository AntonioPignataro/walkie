import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'walkie_colors.dart';

class WalkieTheme {
  WalkieTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WalkieColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: WalkieColors.darkPrimary,
        secondary: WalkieColors.darkSecondary,
        surface: WalkieColors.darkSurface,
        error: WalkieColors.darkError,
        onPrimary: WalkieColors.darkBackground,
        onSecondary: WalkieColors.darkBackground,
        onSurface: WalkieColors.darkOnBackground,
        onError: Colors.white,
        outline: WalkieColors.darkDivider,
        surfaceContainerHighest: WalkieColors.darkSurfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: WalkieColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: WalkieColors.darkPrimary,
          letterSpacing: 1.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WalkieColors.darkSurface,
        indicatorColor: WalkieColors.darkPrimary.withAlpha(30),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WalkieColors.darkPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: WalkieColors.darkOnBackgroundMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: WalkieColors.darkPrimary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: WalkieColors.darkOnBackgroundMuted,
            size: 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: WalkieColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: WalkieColors.darkDivider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WalkieColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WalkieColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WalkieColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WalkieColors.darkPrimary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: WalkieColors.darkOnBackgroundMuted,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WalkieColors.darkPrimary,
          foregroundColor: WalkieColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WalkieColors.darkPrimary,
          side: const BorderSide(color: WalkieColors.darkPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: WalkieColors.darkDivider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WalkieColors.darkSurfaceVariant,
        contentTextStyle: GoogleFonts.inter(
          color: WalkieColors.darkOnBackground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: WalkieColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: WalkieColors.lightPrimary,
        secondary: WalkieColors.lightSecondary,
        surface: WalkieColors.lightSurface,
        error: WalkieColors.lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: WalkieColors.lightOnBackground,
        onError: Colors.white,
        outline: WalkieColors.lightDivider,
        surfaceContainerHighest: WalkieColors.lightSurfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: WalkieColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: WalkieColors.lightPrimary,
          letterSpacing: 1.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WalkieColors.lightSurface,
        indicatorColor: WalkieColors.lightPrimary.withAlpha(30),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WalkieColors.lightPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: WalkieColors.lightOnBackgroundMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: WalkieColors.lightPrimary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: WalkieColors.lightOnBackgroundMuted,
            size: 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: WalkieColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: WalkieColors.lightDivider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WalkieColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WalkieColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WalkieColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WalkieColors.lightPrimary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: WalkieColors.lightOnBackgroundMuted,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WalkieColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WalkieColors.lightPrimary,
          side: const BorderSide(color: WalkieColors.lightPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: WalkieColors.lightDivider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WalkieColors.lightSurface,
        contentTextStyle: GoogleFonts.inter(
          color: WalkieColors.lightOnBackground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
