import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/preferences/sign_in_preferences.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/screens/forgot_password_request_screen.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final rememberMe = await SignInPreferences.getRememberMe();
    final lastEmail = await SignInPreferences.getLastEmail();
    if (!mounted) return;
    setState(() {
      _rememberMe = rememberMe;
      if (lastEmail != null && lastEmail.isNotEmpty) {
        _emailController.text = lastEmail;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await ref.read(authControllerProvider.notifier).signIn(email: email, password: password);
      if (mounted) {
        if (_rememberMe) {
          await SignInPreferences.setRememberMe(true);
          await SignInPreferences.setLastEmail(email);
        } else {
          await SignInPreferences.setRememberMe(false);
          await SignInPreferences.clear();
        }
      }
      
      final state = ref.read(authControllerProvider);
      if (state.hasError) {
        throw state.error!;
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
                                        'Sign in to your account',
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
                                                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                                                onFieldSubmitted: (_) => _submit(),
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) return 'Enter your password';
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: Checkbox(
                                                      value: _rememberMe,
                                                      onChanged: _loading ? null : (v) => setState(() => _rememberMe = v ?? false),
                                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                                        (Set<WidgetState> states) =>
                                                            states.contains(WidgetState.selected) ? AppTheme.specRed : Colors.transparent,
                                                      ),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  GestureDetector(
                                                    onTap: _loading ? null : () => setState(() => _rememberMe = !_rememberMe),
                                                    child: Text('Remember me', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy)),
                                                  ),
                                                  const Spacer(),
                                                  TextButton(
                                                    onPressed: _loading ? null : () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute<void>(
                                                          builder: (_) => const ForgotPasswordRequestScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      'Forgot password?',
                                                      style: TextStyle(color: AppTheme.specRed, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ],
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
                                                        'Sign in',
                                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                                      ),
                                              ),
                                              const SizedBox(height: 22),
                                              Row(
                                                children: [
                                                  Expanded(child: Divider(color: AppTheme.specNavy.withValues(alpha: 0.25))),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                                    child: Text(
                                                      'or',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.specNavy.withValues(alpha: 0.7),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(child: Divider(color: AppTheme.specNavy.withValues(alpha: 0.25))),
                                                ],
                                              ),
                                              const SizedBox(height: 22),
                                              OutlinedButton(
                                                onPressed: _loading ? null : _signInWithGoogle,
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  side: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.5), width: 1.5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  foregroundColor: AppTheme.specNavy,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/googleicon.webp',
                                                      width: 22,
                                                      height: 22,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata_rounded, size: 22, color: AppTheme.specNavy),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Sign in with Google',
                                                      style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Center(
                                                child: TextButton(
                                                  onPressed: _loading ? null : () => context.go('/auth/register'),
                                                  child: const Text(
                                                    'Need an account? Sign up',
                                                    style: TextStyle(color: AppTheme.specRed, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
