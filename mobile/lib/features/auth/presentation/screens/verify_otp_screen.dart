import 'dart:async';
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

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() => _secondsRemaining = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      BrutalToast.showError(context, 'ENTER FULL 6-DIGIT OTP CODE');
      return;
    }

    final resetToken = await ref.read(authControllerProvider.notifier).verifyOtp(
          email: widget.email,
          otp: otp,
        );

    if (resetToken != null && mounted) {
      BrutalToast.showSuccess(context, 'OTP VERIFIED!');
      context.push('/reset-password', extra: {
        'email': widget.email,
        'resetToken': resetToken,
      });
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Verification failed';
      BrutalToast.showError(context, error);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;

    final msg = await ref.read(authControllerProvider.notifier).forgotPassword(widget.email);
    if (msg != null && mounted) {
      BrutalToast.showSuccess(context, 'NEW OTP SENT');
      _startResendTimer();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('VERIFY OTP', style: BrutalTypography.heroHeading),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit verification code sent to:\n${widget.email}',
                style: BrutalTypography.bodyMedium,
              ),
              const SizedBox(height: 28),

              BrutalCard(
                backgroundColor: BrutalColors.surface,
                borderColor: BrutalColors.border,
                shadowColor: BrutalColors.orange,
                shadowOffset: 6.0,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrutalTextField(
                      controller: _otpController,
                      label: '6-Digit Security OTP',
                      hintText: '123456',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.password, color: BrutalColors.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    BrutalButton(
                      text: 'CONFIRM CODE',
                      isLoading: authState.isLoading,
                      onPressed: _handleVerify,
                      backgroundColor: BrutalColors.orange,
                      textColor: BrutalColors.textDark,
                      height: 52,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'RESEND OTP IN ${_secondsRemaining}S',
                        style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary),
                      )
                    : GestureDetector(
                        onTap: _handleResend,
                        child: Text(
                          'RESEND OTP CODE',
                          style: BrutalTypography.sticker.copyWith(
                            color: BrutalColors.primaryYellow,
                            decoration: TextDecoration.underline,
                            decorationColor: BrutalColors.primaryYellow,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
