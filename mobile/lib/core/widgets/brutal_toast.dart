import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalToast {
  BrutalToast._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, BrutalColors.green, BrutalColors.textDark, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, BrutalColors.red, BrutalColors.textPrimary, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, BrutalColors.cyan, BrutalColors.textDark, Icons.info_outline);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, BrutalColors.primaryYellow, BrutalColors.textDark, Icons.warning_amber_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color bg,
    Color textColor,  
    IconData icon,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 3000),
        content: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 4,
              top: 4,
              right: -4,
              bottom: -4,
              child: Container(color: BrutalColors.border),
            ),
            Container(
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: BrutalColors.border, width: 3.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: textColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: BrutalTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
