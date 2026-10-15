import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color shadowColor;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final IconData? icon;

  const BrutalChip({
    super.key,
    required this.label,
    this.backgroundColor = BrutalColors.primaryYellow,
    this.textColor = BrutalColors.textDark,
    this.borderColor = BrutalColors.border,
    this.shadowColor = BrutalColors.border,
    this.shadowOffset = 3.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.onTap,
    this.isSelected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected ? BrutalColors.primaryYellow : backgroundColor;
    final effectiveText = isSelected ? BrutalColors.textDark : textColor;

    Widget chipContent = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: BorderRadius.zero,
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveText),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: BrutalTypography.sticker.copyWith(
              color: effectiveText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      chipContent = InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: chipContent,
      );
    }

    if (shadowOffset <= 0) return chipContent;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: shadowOffset,
          top: shadowOffset,
          right: -shadowOffset,
          bottom: -shadowOffset,
          child: Container(
            decoration: BoxDecoration(
              color: shadowColor,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        chipContent,
      ],
    );
  }
}
