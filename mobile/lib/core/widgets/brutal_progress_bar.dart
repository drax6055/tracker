import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0 (or greater for over-budget)
  final double height;
  final Color? fillColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showPercentage;
  final int segments; // if > 1, renders as blocky segments

  const BrutalProgressBar({
    super.key,
    required this.value,
    this.height = 20.0,
    this.fillColor,
    this.backgroundColor = BrutalColors.surface,
    this.borderColor = BrutalColors.border,
    this.showPercentage = false,
    this.segments = 1,
  });

  Color _getAdaptiveColor(double clampedVal) {
    if (fillColor != null) return fillColor!;
    if (clampedVal >= 1.0) return BrutalColors.red;
    if (clampedVal >= 0.8) return BrutalColors.orange;
    return BrutalColors.lime;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final activeColor = _getAdaptiveColor(clamped);

    Widget bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: BorderRadius.zero,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final filledWidth = totalWidth * clamped;

          if (segments <= 1) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: filledWidth,
                color: activeColor,
              ),
            );
          }

          // Segmented blocky mode
          final activeSegments = (clamped * segments).round();
          return Row(
            children: List.generate(segments, (index) {
              final isFilled = index < activeSegments;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < segments - 1 ? 2.0 : 0.0),
                  color: isFilled ? activeColor : Colors.transparent,
                ),
              );
            }),
          );
        },
      ),
    );

    if (!showPercentage) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: BrutalTypography.amountSmall.copyWith(
              color: activeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
