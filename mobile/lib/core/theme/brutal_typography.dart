import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brutal_colors.dart';

class BrutalTypography {
  BrutalTypography._();

  // Headings (Archivo Black / Space Grotesk Bold, UPPERCASE, tight letter-spacing)
  static TextStyle heroHeading = GoogleFonts.archivoBlack(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: BrutalColors.textPrimary,
  );

  static TextStyle headingLarge = GoogleFonts.archivoBlack(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
    color: BrutalColors.textPrimary,
  );

  static TextStyle headingMedium = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: BrutalColors.textPrimary,
  );

  static TextStyle headingSmall = GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: BrutalColors.textPrimary,
  );

  // Numbers & Amounts (Space Mono Bold, chunky)
  static TextStyle amountHero = GoogleFonts.spaceMono(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: BrutalColors.textPrimary,
  );

  static TextStyle amountLarge = GoogleFonts.spaceMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: BrutalColors.textPrimary,
  );

  static TextStyle amountMedium = GoogleFonts.spaceMono(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: BrutalColors.textPrimary,
  );

  static TextStyle amountSmall = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: BrutalColors.textPrimary,
  );

  // Body & Labels (Space Grotesk)
  static TextStyle bodyLarge = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: BrutalColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: BrutalColors.textSecondary,
  );

  static TextStyle bodySmall = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: BrutalColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: BrutalColors.textPrimary,
  );

  static TextStyle sticker = GoogleFonts.spaceMono(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: BrutalColors.textDark,
  );
}
