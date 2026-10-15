import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color titleColor;
  final bool showBottomBorder;
  final Widget? bottom;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;

  const BrutalAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor = BrutalColors.background,
    this.titleColor = BrutalColors.textPrimary,
    this.showBottomBorder = true,
    this.bottom,
    this.showBackButton,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom != null ? 48.0 : 0));

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;

    if (effectiveLeading == null) {
      final canPop = context.canPop() || (ModalRoute.of(context)?.canPop ?? false);
      final shouldShowBack = showBackButton ?? canPop;

      if (shouldShowBack) {
        effectiveLeading = IconButton(
          icon: const Icon(Icons.arrow_back, color: BrutalColors.textPrimary, size: 24),
          tooltip: 'Back',
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: BrutalColors.border, width: 3.0),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: NavigationToolbar(
                leading: effectiveLeading,
                middle: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrutalTypography.headingMedium.copyWith(
                      color: titleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                trailing: actions != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    : null,
                centerMiddle: false,
                middleSpacing: 8.0,
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
