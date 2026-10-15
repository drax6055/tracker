import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Block
              BrutalCard(
                backgroundColor: BrutalColors.primaryYellow,
                borderColor: BrutalColors.border,
                shadowColor: BrutalColors.cyan,
                shadowOffset: 6.0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    Text(
                      'LEDGER',
                      style: BrutalTypography.heroHeading.copyWith(
                        fontSize: 42,
                        color: BrutalColors.textDark,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const BrutalChip(
                      label: 'MONEY ENGINE // v1.0',
                      backgroundColor: BrutalColors.textDark,
                      textColor: BrutalColors.primaryYellow,
                      shadowOffset: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Segmented loading indicator block
              Container(
                width: 140,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: BrutalColors.border, width: 2.5),
                ),
                child: const LinearProgressIndicator(
                  backgroundColor: BrutalColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(BrutalColors.lime),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'INITIALIZING SECURE VAULT...',
                style: BrutalTypography.sticker.copyWith(
                  color: BrutalColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
