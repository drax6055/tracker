import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';
import 'brutal_button.dart';

class BrutalEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const BrutalEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: BrutalColors.surface,
        border: Border.all(color: BrutalColors.border, width: 3.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrutalColors.primaryYellow,
              border: Border.all(color: BrutalColors.border, width: 3.0),
            ),
            child: Icon(icon, size: 36, color: BrutalColors.textDark),
          ),
          const SizedBox(height: 20),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: BrutalTypography.headingMedium.copyWith(letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: BrutalTypography.bodyMedium,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            BrutalButton(
              text: actionText!,
              onPressed: onAction,
              height: 44,
              backgroundColor: BrutalColors.lime,
            ),
          ],
        ],
      ),
    );
  }
}
