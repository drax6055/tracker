import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalNavItem {
  final IconData icon;
  final String label;

  const BrutalNavItem({
    required this.icon,
    required this.label,
  });
}

class BrutalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BrutalNavItem> items;

  const BrutalBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrutalColors.background,
        border: Border(
          top: BorderSide(color: BrutalColors.border, width: 3.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? BrutalColors.primaryYellow : Colors.transparent,
                      border: Border(
                        right: index < items.length - 1
                            ? const BorderSide(color: BrutalColors.border, width: 2.0)
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected ? BrutalColors.textDark : BrutalColors.textPrimary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label.toUpperCase(),
                          style: BrutalTypography.sticker.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? BrutalColors.textDark : BrutalColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
