import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).resetPassword(
          email: widget.email,
          resetToken: widget.resetToken,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (success && mounted) {
      BrutalToast.showSuccess(context, 'PASSWORD UPDATED! PLEASE LOG IN.');
      context.go('/login');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Password reset failed';
      BrutalToast.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: AppBar(
        backgroundColor: BrutalColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('NEW PASSWORD', style: BrutalTypography.heroHeading),
                const SizedBox(height: 6),
                Text('Set your new master security key for ${widget.email}.', style: BrutalTypography.bodyMedium),
                const SizedBox(height: 28),

                BrutalCard(
                  backgroundColor: BrutalColors.surface,
                  borderColor: BrutalColors.border,
                  shadowColor: BrutalColors.hotPink,
                  shadowOffset: 6.0,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BrutalTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hintText: '••••••••',
                        obscureText: true,
                        enablePasswordToggle: true,
                        prefixIcon: const Icon(Icons.lock_outline, color: BrutalColors.textPrimary),
                        validator: (val) {
                          if (val == null || val.length < 8) return 'Min 8 chars required';
                          if (!RegExp(r'[0-9]').hasMatch(val)) return 'At least 1 number required';
                          if (!RegExp(r'[a-zA-Z]').hasMatch(val)) return 'At least 1 letter required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      BrutalTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hintText: '••••••••',
                        obscureText: true,
                        enablePasswordToggle: true,
                        prefixIcon: const Icon(Icons.lock_reset, color: BrutalColors.textPrimary),
                        validator: (val) {
                          if (val != _newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BrutalButton(
                        text: 'LOCK NEW PASSWORD',
                        isLoading: authState.isLoading,
                        onPressed: _handleReset,
                        backgroundColor: BrutalColors.hotPink,
                        textColor: BrutalColors.textPrimary,
                        height: 52,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
