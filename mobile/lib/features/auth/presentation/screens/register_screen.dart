import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasLetter = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRules);
  }

  void _validatePasswordRules() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasLetter = RegExp(r'[a-zA-Z]').hasMatch(text);
      _hasNumber = RegExp(r'[0-9]').hasMatch(text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasMinLength || !_hasLetter || !_hasNumber) {
      BrutalToast.showError(context, 'PASSWORD DOES NOT MEET ALL CRITERIA');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (success && mounted) {
      BrutalToast.showSuccess(context, 'ACCOUNT CREATED SUCCESSFULLY!');
      context.go('/dashboard');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Registration failed';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('JOIN LEDGER', style: BrutalTypography.heroHeading),
                const SizedBox(height: 4),
                Text('ENTER THE HIGH-PRECISION MONEY SYSTEM', style: BrutalTypography.bodyMedium),
                const SizedBox(height: 24),

                BrutalCard(
                  backgroundColor: BrutalColors.surface,
                  borderColor: BrutalColors.border,
                  shadowColor: BrutalColors.lime,
                  shadowOffset: 6.0,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BrutalTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Bruce Wayne',
                        prefixIcon: const Icon(Icons.person_outline, color: BrutalColors.textPrimary),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Name is required';
                          if (val.trim().length < 2) return 'Min 2 characters required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
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
                      const SizedBox(height: 18),
                      BrutalTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: '••••••••',
                        obscureText: true,
                        enablePasswordToggle: true,
                        prefixIcon: const Icon(Icons.lock_outline, color: BrutalColors.textPrimary),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password criteria badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          BrutalChip(
                            label: '8+ CHARS',
                            backgroundColor: _hasMinLength ? BrutalColors.green : BrutalColors.surfaceElevated,
                            textColor: _hasMinLength ? BrutalColors.textDark : BrutalColors.textSecondary,
                            borderColor: _hasMinLength ? BrutalColors.green : BrutalColors.borderDim,
                            shadowOffset: 0,
                          ),
                          BrutalChip(
                            label: '1+ NUMBER',
                            backgroundColor: _hasNumber ? BrutalColors.green : BrutalColors.surfaceElevated,
                            textColor: _hasNumber ? BrutalColors.textDark : BrutalColors.textSecondary,
                            borderColor: _hasNumber ? BrutalColors.green : BrutalColors.borderDim,
                            shadowOffset: 0,
                          ),
                          BrutalChip(
                            label: '1+ LETTER',
                            backgroundColor: _hasLetter ? BrutalColors.green : BrutalColors.surfaceElevated,
                            textColor: _hasLetter ? BrutalColors.textDark : BrutalColors.textSecondary,
                            borderColor: _hasLetter ? BrutalColors.green : BrutalColors.borderDim,
                            shadowOffset: 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      BrutalTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hintText: '••••••••',
                        obscureText: true,
                        enablePasswordToggle: true,
                        prefixIcon: const Icon(Icons.lock_reset, color: BrutalColors.textPrimary),
                        validator: (val) {
                          if (val != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BrutalButton(
                        text: 'CREATE ACCOUNT',
                        isLoading: authState.isLoading,
                        onPressed: _handleRegister,
                        backgroundColor: BrutalColors.lime,
                        textColor: BrutalColors.textDark,
                        height: 52,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'ALREADY REGISTERED? LOG IN',
                      style: BrutalTypography.sticker.copyWith(
                        color: BrutalColors.textPrimary,
                        decoration: TextDecoration.underline,
                        decorationColor: BrutalColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
