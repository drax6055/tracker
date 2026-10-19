import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/auth_controller.dart';

class BiometricUnlockScreen extends ConsumerStatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  ConsumerState<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends ConsumerState<BiometricUnlockScreen> {
  bool _isAuthenticating = false;
  String? _userDisplayName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Prompt biometric scan immediately after the view renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricAuth();
    });
  }

  Future<void> _loadUser() async {
    final cachedUser = await SecureStorageService.getUser();
    if (mounted && cachedUser != null) {
      setState(() {
        _userDisplayName = cachedUser['name']?.toString();
        _userEmail = cachedUser['email']?.toString();
      });
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: 'Scan your fingerprint to unlock your Ledger Vault',
      );

      if (authenticated && mounted) {
        context.go('/dashboard');
      } else if (mounted) {
        BrutalToast.showWarning(context, 'Authentication cancelled. Tap to retry.');
      }
    } catch (e) {
      if (mounted) {
        BrutalToast.showError(context, 'Biometric sensor error: $e');
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _loginWithPassword() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _userDisplayName ?? 'OPERATOR';
    final email = _userEmail ?? 'Protected Vault';

    return Scaffold(
      backgroundColor: BrutalColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Badge
                Center(
                  child: BrutalChip(
                    label: 'VAULT ENCRYPTED & LOCKED',
                    backgroundColor: BrutalColors.red,
                    textColor: BrutalColors.textPrimary,
                    shadowOffset: 3.0,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Card
                BrutalCard(
                  backgroundColor: BrutalColors.surface,
                  borderColor: BrutalColors.border,
                  shadowColor: BrutalColors.primaryYellow,
                  shadowOffset: 6.0,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Interactive Fingerprint Scanner Icon
                      GestureDetector(
                        onTap: _isAuthenticating ? null : _triggerBiometricAuth,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _isAuthenticating ? BrutalColors.surfaceElevated : BrutalColors.primaryYellow,
                            border: Border.all(color: BrutalColors.border, width: 3.0),
                            boxShadow: const [
                              BoxShadow(
                                color: BrutalColors.border,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            size: 64,
                            color: _isAuthenticating ? BrutalColors.primaryYellow : BrutalColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'WELCOME BACK',
                        style: BrutalTypography.sticker.copyWith(
                          fontSize: 12,
                          color: BrutalColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name.toUpperCase(),
                        style: BrutalTypography.heroHeading.copyWith(
                          fontSize: 24,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: BrutalTypography.bodySmall.copyWith(
                          color: BrutalColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.border, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: BrutalColors.lime),
                            const SizedBox(width: 8),
                            Text(
                              'PROTECTED BY BIOMETRICS',
                              style: BrutalTypography.sticker.copyWith(
                                color: BrutalColors.lime,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Unlock Button
                BrutalButton(
                  text: _isAuthenticating ? 'SCANNING FINGERPRINT...' : 'UNLOCK WITH FINGERPRINT',
                  backgroundColor: BrutalColors.primaryYellow,
                  textColor: BrutalColors.textDark,
                  height: 54,
                  onPressed: _isAuthenticating ? null : _triggerBiometricAuth,
                ),
                const SizedBox(height: 12),

                // Password fallback Button
                BrutalButton(
                  text: 'LOG IN WITH PASSWORD INSTEAD',
                  backgroundColor: BrutalColors.surfaceElevated,
                  textColor: BrutalColors.textSecondary,
                  borderColor: BrutalColors.borderDim,
                  height: 48,
                  offset: 2.0,
                  onPressed: _loginWithPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
