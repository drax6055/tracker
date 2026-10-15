import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';

class BrutalCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double rotationAngle;

  const BrutalCard({
    super.key,
    required this.child,
    this.backgroundColor = BrutalColors.surface,
    this.borderColor = BrutalColors.border,
    this.shadowColor = BrutalColors.border,
    this.borderWidth = 3.0,
    this.shadowOffset = 5.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.rotationAngle = 0.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.zero,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: cardContent,
      );
    }

    Widget structuredCard = Padding(
      padding: margin,
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          // Hard Shadow (Offset, 0 blur)
          if (shadowOffset > 0)
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
          cardContent,
        ],
      ),
    );

    if (rotationAngle != 0.0) {
      return Transform.rotate(
        angle: rotationAngle,
        child: structuredCard,
      );
    }

    return structuredCard;
  }
}
