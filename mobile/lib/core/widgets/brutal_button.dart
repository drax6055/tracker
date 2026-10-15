import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color shadowColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double offset;
  final EdgeInsetsGeometry padding;

  const BrutalButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = BrutalColors.primaryYellow,
    this.textColor = BrutalColors.textDark,
    this.borderColor = BrutalColors.border,
    this.shadowColor = BrutalColors.border,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
    this.offset = 4.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return SizedBox(
      width: widget.width,
      height: widget.height + widget.offset,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Hard Shadow (behind)
            if (!isDisabled && !_isPressed)
              Positioned(
                left: widget.offset,
                top: widget.offset,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.shadowColor,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),

            // Button Body (shifts on press)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              left: _isPressed ? widget.offset : 0,
              top: _isPressed ? widget.offset : 0,
              right: _isPressed ? 0 : widget.offset,
              bottom: _isPressed ? 0 : widget.offset,
              child: Container(
                alignment: Alignment.center,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: isDisabled ? BrutalColors.surfaceElevated : widget.backgroundColor,
                  border: Border.all(
                    color: isDisabled ? BrutalColors.borderDim : widget.borderColor,
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: widget.isLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 20,
                              color: isDisabled ? BrutalColors.textMuted : widget.textColor,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              widget.text.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BrutalTypography.headingSmall.copyWith(
                                color: isDisabled ? BrutalColors.textMuted : widget.textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
