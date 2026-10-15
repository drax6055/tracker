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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final msg = await ref.read(authControllerProvider.notifier).forgotPassword(email);

    if (msg != null && mounted) {
      BrutalToast.showSuccess(context, 'OTP DISPATCHED TO $email');
      context.push('/verify-otp', extra: email);
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Failed to send OTP';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrutalColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('RECOVER ACCOUNT', style: BrutalTypography.heroHeading),
                const SizedBox(height: 6),
                Text(
                  'Enter your registered email. We will send a 6-digit cryptographic security OTP valid for 10 minutes.',
                  style: BrutalTypography.bodyMedium,
                ),
                const SizedBox(height: 28),

                BrutalCard(
                  backgroundColor: BrutalColors.surface,
                  borderColor: BrutalColors.border,
                  shadowColor: BrutalColors.cyan,
                  shadowOffset: 6.0,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BrutalTextField(
                        controller: _emailController,
                        label: 'Registered Email',
                        hintText: 'bruce@wayne.corp',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.alternate_email, color: BrutalColors.textPrimary),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(val.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BrutalButton(
                        text: 'DISPATCH 6-DIGIT OTP',
                        isLoading: authState.isLoading,
                        onPressed: _handleSendOtp,
                        backgroundColor: BrutalColors.cyan,
                        textColor: BrutalColors.textDark,
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
