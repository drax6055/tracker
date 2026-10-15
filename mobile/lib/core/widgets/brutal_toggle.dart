import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/brutal_colors.dart';

class BrutalToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const BrutalToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = BrutalColors.lime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 3,
            top: 3,
            right: -3,
            bottom: -3,
            child: Container(color: BrutalColors.border),
          ),
          Container(
            width: 56,
            height: 30,
            decoration: BoxDecoration(
              color: value ? activeColor : BrutalColors.surfaceElevated,
              border: Border.all(color: BrutalColors.border, width: 2.5),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: BrutalColors.textDark,
                  border: Border.all(color: BrutalColors.border, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
