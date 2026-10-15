import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';
import 'brutal_button.dart';

class BrutalDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmText;
  final VoidCallback? onConfirm;
  final String cancelText;
  final VoidCallback? onCancel;
  final Color confirmColor;

  const BrutalDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.onConfirm,
    this.cancelText = 'CANCEL',
    this.onCancel,
    this.confirmColor = BrutalColors.primaryYellow,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? confirmText,
    VoidCallback? onConfirm,
    String cancelText = 'CANCEL',
    VoidCallback? onCancel,
    Color confirmColor = BrutalColors.primaryYellow,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BrutalDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
        cancelText: cancelText,
        onCancel: onCancel,
        confirmColor: confirmColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            top: 6,
            right: -6,
            bottom: -6,
            child: Container(color: BrutalColors.border),
          ),
          Container(
            decoration: BoxDecoration(
              color: BrutalColors.surface,
              border: Border.all(color: BrutalColors.border, width: 3.0),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: BrutalTypography.headingMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: BrutalColors.border, thickness: 2.0),
                const SizedBox(height: 16),
                content,
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: BrutalButton(
                        text: cancelText,
                        backgroundColor: BrutalColors.surfaceElevated,
                        textColor: BrutalColors.textPrimary,
                        height: 44,
                        onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (confirmText != null && onConfirm != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: BrutalButton(
                          text: confirmText!,
                          backgroundColor: confirmColor,
                          height: 44,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm!();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
