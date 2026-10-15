import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

/// PrivacyCurtain wraps the application to shield sensitive financial balances
/// whenever the app is minimized, in transition, or shown in the recent apps drawer.
class PrivacyCurtain extends StatefulWidget {
  final Widget child;
  const PrivacyCurtain({super.key, required this.child});

  @override
  State<PrivacyCurtain> createState() => _PrivacyCurtainState();
}

class _PrivacyCurtainState extends State<PrivacyCurtain> with WidgetsBindingObserver {
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app is minimized, in app switcher, or paused -> shield content
    final shouldShield = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;

    if (shouldShield != _isBackgrounded) {
      setState(() {
        _isBackgrounded = shouldShield;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBackgrounded)
          Positioned.fill(
            child: Material(
              color: Colors.black,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: BrutalColors.surface,
                    border: Border.all(color: BrutalColors.primaryYellow, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: BrutalColors.primaryYellow,
                        offset: Offset(6, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BrutalColors.primaryYellow,
                          border: Border.all(color: BrutalColors.border, width: 2),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: BrutalColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SECURE VAULT SHIELD',
                        style: BrutalTypography.headingSmall.copyWith(
                          color: BrutalColors.textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sensitive financial intelligence & account balances are protected.',
                        textAlign: TextAlign.center,
                        style: BrutalTypography.bodySmall.copyWith(
                          color: BrutalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
