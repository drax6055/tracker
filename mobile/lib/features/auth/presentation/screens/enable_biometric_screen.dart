import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_toast.dart';

class EnableBiometricScreen extends StatefulWidget {
  const EnableBiometricScreen({super.key});

  @override
  State<EnableBiometricScreen> createState() => _EnableBiometricScreenState();
}

class _EnableBiometricScreenState extends State<EnableBiometricScreen> {
  bool _isAuthenticating = false;

  Future<void> _enableBiometric() async {
    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: 'Verify your fingerprint to enable biometric vault unlock',
      );

      if (authenticated) {
        await SecureStorageService.saveBiometricEnabled(true);
        await SecureStorageService.saveBiometricPromptShown(true);

        if (mounted) {
          BrutalToast.showSuccess(context, 'FINGERPRINT UNLOCK ACTIVATED');
          context.go('/dashboard');
        }
      } else {
        if (mounted) {
          BrutalToast.showWarning(context, 'Biometric verification cancelled');
        }
      }
    } catch (e) {
      if (mounted) {
        BrutalToast.showError(context, 'Could not verify biometrics: $e');
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _skip() async {
    await SecureStorageService.saveBiometricEnabled(false);
    await SecureStorageService.saveBiometricPromptShown(true);
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    label: 'SECURITY ENHANCEMENT',
                    backgroundColor: BrutalColors.cyan,
                    textColor: BrutalColors.textDark,
                    shadowOffset: 3.0,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Brutal Card
                BrutalCard(
                  backgroundColor: BrutalColors.surface,
                  borderColor: BrutalColors.border,
                  shadowColor: BrutalColors.primaryYellow,
                  shadowOffset: 6.0,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Fingerprint Icon Container
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: BrutalColors.primaryYellow,
                          border: Border.all(color: BrutalColors.border, width: 3.0),
                          boxShadow: const [
                            BoxShadow(
                              color: BrutalColors.border,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 58,
                          color: BrutalColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'ENABLE BIOMETRICS',
                        style: BrutalTypography.heroHeading.copyWith(
                          fontSize: 26,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Unlock your Ledger Vault instantly using your fingerprint instead of entering your password every time.',
                        style: BrutalTypography.bodyMedium.copyWith(
                          color: BrutalColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Benefit points
                      _buildBenefitRow(Icons.bolt, '1-TAP INSTANT ACCESS', 'Open your vault directly with your fingerprint'),
                      const SizedBox(height: 12),
                      _buildBenefitRow(Icons.lock_outline, 'HARDWARE ENCRYPTED', 'Biometrics stay securely on your device'),
                      const SizedBox(height: 12),
                      _buildBenefitRow(Icons.history, 'NO PASSWORD FATIGUE', 'Never type email and password on launch'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Enable Button
                BrutalButton(
                  text: _isAuthenticating ? 'VERIFYING SENSOR...' : 'ENABLE FINGERPRINT',
                  backgroundColor: BrutalColors.primaryYellow,
                  textColor: BrutalColors.textDark,
                  height: 54,
                  onPressed: _isAuthenticating ? null : _enableBiometric,
                ),
                const SizedBox(height: 12),

                // Skip Button
                BrutalButton(
                  text: 'NOT NOW (ASK PASSWORD EACH TIME)',
                  backgroundColor: BrutalColors.surfaceElevated,
                  textColor: BrutalColors.textSecondary,
                  borderColor: BrutalColors.borderDim,
                  height: 48,
                  offset: 2.0,
                  onPressed: _isAuthenticating ? null : _skip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: BrutalColors.surfaceElevated,
            border: Border.all(color: BrutalColors.border, width: 2),
          ),
          child: Icon(icon, size: 18, color: BrutalColors.primaryYellow),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: BrutalTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: BrutalTypography.sticker.copyWith(fontSize: 11, color: BrutalColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
