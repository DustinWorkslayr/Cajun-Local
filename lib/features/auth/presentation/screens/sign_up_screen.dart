import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/screens/privacy_policy_agreement_screen.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _privacyAgreed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_privacyAgreed) {
      final agreed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const PrivacyPolicyAgreementScreen(),
        ),
      );
      if (!mounted) return;
      if (agreed == true) {
        setState(() => _privacyAgreed = true);
      } else {
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim();

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(email: email, password: password, displayName: displayName);
      
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Account created. You are now logged in.')));
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        final isConfirmationEmailError =
            (msg.contains('confirmation') && msg.contains('email')) || msg.contains('error sending');
        setState(() {
          _errorMessage = isConfirmationEmailError
              ? 'Your account may have been created, but we couldn\'t send the confirmation email.'
              : e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final isTablet = MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final skylineHeight = isTablet ? mediaHeight * 0.08 : mediaHeight * 0.14;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? colorScheme.surface : AppTheme.specWhite;
    final cardBorderColor = isDark
        ? colorScheme.outlineVariant.withValues(alpha: 0.5)
        : AppTheme.specNavy.withValues(alpha: 0.12);
    final cardShadowColor = isDark ? Colors.black26 : AppTheme.specNavy.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppTheme.specOffWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: LayoutBuilder(
                        builder: (context, formConstraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: formConstraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 16),
                                    Center(child: AppLogo(height: 88)),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Container(
                                        width: 56,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppTheme.specGold,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: Text(
                                        'Create an account',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.specNavy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                                          decoration: BoxDecoration(
                                            color: surfaceColor,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: cardBorderColor, width: 1),
                                            boxShadow: [BoxShadow(color: cardShadowColor, blurRadius: 24, offset: const Offset(0, 8))],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              TextFormField(
                                                controller: _displayNameController,
                                                decoration: InputDecoration(
                                                  labelText: 'Display name',
                                                  hintText: 'How we\'ll show your name',
                                                  prefixIcon: Icon(Icons.person_outline_rounded, color: primary),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: const BorderSide(color: AppTheme.specNavy, width: 1.5),
                                                  ),
                                                ),
                                                textCapitalization: TextCapitalization.words,
                                                textInputAction: TextInputAction.next,
                                              ),
                                              const SizedBox(height: 18),
                                              TextFormField(
                                                controller: _emailController,
                                                decoration: InputDecoration(
                                                  labelText: 'Email',
                                                  hintText: 'you@example.com',
                                                  prefixIcon: Icon(Icons.email_outlined, color: primary),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: const BorderSide(color: AppTheme.specNavy, width: 1.5),
                                                  ),
                                                ),
                                                keyboardType: TextInputType.emailAddress,
                                                autocorrect: false,
                                                textInputAction: TextInputAction.next,
                                                validator: (v) {
                                                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 18),
                                              TextFormField(
                                                controller: _passwordController,
                                                decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  hintText: '••••••••',
                                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: primary),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: const BorderSide(color: AppTheme.specNavy, width: 1.5),
                                                  ),
                                                ),
                                                obscureText: true,
                                                textInputAction: TextInputAction.done,
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) return 'Enter your password';
                                                  if (v.length < 6) return 'Use at least 6 characters';
                                                  return null;
                                                },
                                              ),
                                              if (_errorMessage != null) ...[
                                                const SizedBox(height: 18),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 24),
                                              AppPrimaryButton(
                                                onPressed: _loading ? null : _submit,
                                                child: _loading
                                                    ? SizedBox(
                                                        height: 22,
                                                        width: 22,
                                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                                                      )
                                                    : const Text(
                                                        'Create account',
                                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                                      ),
                                              ),
                                              const SizedBox(height: 22),
                                              Center(
                                                child: TextButton(
                                                  onPressed: () => context.go('/auth/login'),
                                                  child: const Text(
                                                    'Already have an account? Sign in',
                                                    style: TextStyle(color: AppTheme.specRed, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: _loading ? null : () => context.go('/auth/login'),
                                        icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.specNavy),
                                        label: const Text(
                                          'Back to Sign In',
                                          style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: skylineHeight,
                width: double.infinity,
                child: Image.asset('assets/images/skyline-2.png', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
              ),
            ],
          );
        },
      ),
    );
  }
}
