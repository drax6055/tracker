import 'package:flutter/material.dart';
import 'brutal_colors.dart';
import 'brutal_typography.dart';

class BrutalTheme {
  BrutalTheme._();

  static const double borderWidth = 3.0;
  static const double borderRadius = 0.0; // Strictly square or near-square
  static const Offset shadowOffset = Offset(5.0, 5.0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BrutalColors.background,
      primaryColor: BrutalColors.primaryYellow,
      colorScheme: const ColorScheme.dark(
        primary: BrutalColors.primaryYellow,
        secondary: BrutalColors.cyan,
        surface: BrutalColors.surface,
        error: BrutalColors.red,
        onPrimary: BrutalColors.textDark,
        onSecondary: BrutalColors.textDark,
        onSurface: BrutalColors.textPrimary,
        onError: BrutalColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrutalColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: BrutalColors.textPrimary, size: 24),
      ),
      dividerTheme: const DividerThemeData(
        color: BrutalColors.border,
        thickness: 2.0,
        space: 2.0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: BrutalColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: BrutalColors.border, width: borderWidth),
          borderRadius: BorderRadius.zero,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrutalColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: BrutalColors.border, width: borderWidth),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: BrutalColors.border, width: borderWidth),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: BrutalColors.primaryYellow, width: borderWidth),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: BrutalColors.red, width: borderWidth),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: BrutalColors.red, width: borderWidth),
        ),
        labelStyle: BrutalTypography.bodyMedium,
        hintStyle: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textMuted),
        errorStyle: BrutalTypography.bodySmall.copyWith(color: BrutalColors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}
