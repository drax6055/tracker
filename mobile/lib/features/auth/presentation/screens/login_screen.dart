import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'bruce@wayne.corp';
      _passwordController.text = 'Batman123!';
    });
    BrutalToast.showSuccess(context, 'DEMO CREDENTIALS LOADED');
  }

  void _showActiveSessionDialog(String activeDevice) {
    BrutalDialog.show(
      context: context,
      title: 'SESSION ACTIVE',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrutalColors.surfaceElevated,
              border: Border.all(color: BrutalColors.orange, width: 2.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.devices_outlined, color: BrutalColors.orange, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOGGED IN ON ANOTHER DEVICE:',
                        style: BrutalTypography.sticker.copyWith(
                          color: BrutalColors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeDevice,
                        style: BrutalTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrutalColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ledger security enforces 1 active device at a time. To log in on this device, the session on "$activeDevice" must be terminated.',
            style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'Terminate the other session and log in here?',
            style: BrutalTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: BrutalColors.primaryYellow,
            ),
          ),
        ],
      ),
      confirmText: 'LOGOUT OTHER & LOGIN',
      confirmColor: BrutalColors.primaryYellow,
      cancelText: 'CANCEL',
      onConfirm: () => _handleLogin(force: true),
    );
  }

  Future<void> _handleLogin({bool force = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text.trim(),
          force: force,
        );

    if (result.success && mounted) {
      BrutalToast.showSuccess(context, 'WELCOME BACK!');
      context.go('/dashboard');
    } else if (result.hasActiveSession && mounted) {
      _showActiveSessionDialog(result.activeDevice ?? 'Another Device');
    } else if (mounted) {
      final error = result.errorMessage ?? 'Login failed';
      BrutalToast.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: BrutalColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LEDGER // AUTH', style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow)),
                          const SizedBox(height: 4),
                          Text('LOG IN', style: BrutalTypography.heroHeading),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BrutalColors.primaryYellow,
                          border: Border.all(color: BrutalColors.border, width: 3.0),
                        ),
                        child: const Icon(Icons.lock_outline, size: 28, color: BrutalColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1-Tap Fill Demo Credentials
                  GestureDetector(
                    onTap: _fillDemoCredentials,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.primaryYellow, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: BrutalColors.primaryYellow,
                            offset: Offset(3.0, 3.0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, size: 20, color: BrutalColors.primaryYellow),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '1-TAP AUTO-FILL DEMO LOGIN (BRUCE WAYNE)',
                              style: BrutalTypography.sticker.copyWith(
                                color: BrutalColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Active Session Warning / Revocation Banner
                  if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.red, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: BrutalColors.red,
                            offset: Offset(3.0, 3.0),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: BrutalColors.red, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: BrutalTypography.bodyMedium.copyWith(
                                color: BrutalColors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Login Card
                  BrutalCard(
                    backgroundColor: BrutalColors.surface,
                    borderColor: BrutalColors.border,
                    shadowColor: BrutalColors.primaryYellow,
                    shadowOffset: 6.0,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BrutalTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'bruce@wayne.corp',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.alternate_email, color: BrutalColors.textPrimary),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(val.trim())) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        BrutalTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: '••••••••',
                          obscureText: true,
                          enablePasswordToggle: true,
                          prefixIcon: const Icon(Icons.key_outlined, color: BrutalColors.textPrimary),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text(
                              'FORGOT PASSWORD?',
                              style: BrutalTypography.sticker.copyWith(
                                color: BrutalColors.cyan,
                                decoration: TextDecoration.underline,
                                decorationColor: BrutalColors.cyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        BrutalButton(
                          text: 'AUTHENTICATE',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                          backgroundColor: BrutalColors.primaryYellow,
                          textColor: BrutalColors.textDark,
                          shadowColor: BrutalColors.border,
                          height: 52,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Register Link Button
                  BrutalButton(
                    text: 'NEW USER? CREATE ACCOUNT',
                    onPressed: () => context.push('/register'),
                    backgroundColor: BrutalColors.surfaceElevated,
                    textColor: BrutalColors.textPrimary,
                    borderColor: BrutalColors.border,
                    shadowColor: BrutalColors.border,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
