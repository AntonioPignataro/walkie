import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalkieTypography {
  WalkieTypography._();

  static TextStyle heading({required Color color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      );

  static TextStyle title({required Color color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle subtitle({required Color color}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle body({required Color color}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({required Color color}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption({required Color color}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle mono({required Color color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 4,
      );

  static TextStyle button({required Color color}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
