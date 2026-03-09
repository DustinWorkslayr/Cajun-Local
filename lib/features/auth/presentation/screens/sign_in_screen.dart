import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/auth/providers/auth_provider.dart';
import 'package:my_app/core/preferences/sign_in_preferences.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/auth/presentation/screens/forgot_password_request_screen.dart';
import 'package:my_app/features/auth/presentation/screens/privacy_policy_agreement_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';

/// Branded sign-in/sign-up screen. Uses Supabase Auth when configured
/// (backend-cheatsheet §9: handle_new_user creates profile + user role on signup).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum AuthMode { signIn, signUp }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late AuthMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  /// Sign-up only: user must scroll to bottom of privacy policy and tap "I agree".
  bool _privacyAgreed = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
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
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim();

    try {
      if (_mode == AuthMode.signUp) {
        await ref
            .read(authNotifierProvider.notifier)
            .signUp(email: email, password: password, displayName: displayName);
        // Confirmation email is sent by Supabase Auth using your project's custom SMTP.
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Account created. You are now logged in.')));
        }
      } else {
        await ref.read(authNotifierProvider.notifier).signIn(email: email, password: password);
        if (mounted) {
          if (_rememberMe) {
            await SignInPreferences.setRememberMe(true);
            await SignInPreferences.setLastEmail(email);
          } else {
            await SignInPreferences.setRememberMe(false);
            await SignInPreferences.clear();
          }
        }
      }
      // Check for errors
      final state = ref.read(authNotifierProvider);
      if (state.hasError) {
        throw state.error!;
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        final isConfirmationEmailError =
            (msg.contains('confirmation') && msg.contains('email')) || msg.contains('error sending');
        setState(() {
          _errorMessage = isConfirmationEmailError
              ? 'Your account may have been created, but we couldn\'t send the confirmation email. '
                    'Try signing in below, or use "Forgot password?" to receive an email.'
              : e.toString().replaceAll('Exception: ', '');
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
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
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
                                        _mode == AuthMode.signIn ? 'Sign in to your account' : 'Create an account',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.specNavy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Center(
                                      child: _SignInFormCard(
                                        mode: _mode,
                                        loading: _loading,
                                        rememberMe: _rememberMe,
                                        errorMessage: _errorMessage,
                                        formKey: _formKey,
                                        emailController: _emailController,
                                        passwordController: _passwordController,
                                        displayNameController: _displayNameController,
                                        isTablet: isTablet,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        primary: primary,
                                        surfaceColor: surfaceColor,
                                        cardBorderColor: cardBorderColor,
                                        cardShadowColor: cardShadowColor,
                                        onRememberMeChanged: (v) => setState(() => _rememberMe = v),
                                        onForgotPassword: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => const ForgotPasswordRequestScreen(),
                                            ),
                                          );
                                        },
                                        onPrimaryAction: () async {
                                          if (!(_formKey.currentState?.validate() ?? false)) return;
                                          if (_mode == AuthMode.signUp && !_privacyAgreed) {
                                            final agreed = await Navigator.of(context).push<bool>(
                                              MaterialPageRoute<bool>(
                                                builder: (_) => const PrivacyPolicyAgreementScreen(),
                                              ),
                                            );
                                            if (!mounted) return;
                                            if (agreed == true) {
                                              setState(() => _privacyAgreed = true);
                                              _submit();
                                            }
                                            return;
                                          }
                                          _submit();
                                        },
                                        onToggleMode: () {
                                          setState(() {
                                            _mode = _mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
                                            _errorMessage = null;
                                            if (_mode == AuthMode.signIn) _privacyAgreed = false;
                                          });
                                        },
                                        onSignInWithGoogle: _signInWithGoogle,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (Navigator.of(context).canPop())
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: _loading ? null : () => Navigator.of(context).pop(),
                                          icon: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.specNavy),
                                          label: Text(
                                            'Back',
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

/// Form card (email, password, actions) used by [SignInScreen].
class _SignInFormCard extends StatelessWidget {
  const _SignInFormCard({
    required this.mode,
    required this.loading,
    required this.rememberMe,
    required this.errorMessage,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.displayNameController,
    required this.isTablet,
    required this.theme,
    required this.colorScheme,
    required this.primary,
    required this.surfaceColor,
    required this.cardBorderColor,
    required this.cardShadowColor,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    required this.onPrimaryAction,
    required this.onToggleMode,
    required this.onSignInWithGoogle,
  });

  final AuthMode mode;
  final bool loading;
  final bool rememberMe;
  final String? errorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final bool isTablet;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Color primary;
  final Color surfaceColor;
  final Color cardBorderColor;
  final Color cardShadowColor;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onPrimaryAction;
  final VoidCallback onToggleMode;
  final VoidCallback onSignInWithGoogle;

  static const String _googleIconAsset = 'assets/images/googleicon.webp';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
            if (mode == AuthMode.signUp) ...[
              TextFormField(
                controller: displayNameController,
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
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: emailController,
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
              controller: passwordController,
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
              onFieldSubmitted: (_) => onPrimaryAction(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (mode == AuthMode.signUp && v.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            if (mode == AuthMode.signIn) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: loading ? null : (v) => onRememberMeChanged(v ?? false),
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) =>
                            states.contains(WidgetState.selected) ? AppTheme.specRed : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: loading ? null : () => onRememberMeChanged(!rememberMe),
                    child: Text('Remember me', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: loading ? null : onForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(color: AppTheme.specRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AppPrimaryButton(
              onPressed: loading ? null : onPrimaryAction,
              child: loading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                    )
                  : Text(
                      mode == AuthMode.signIn ? 'Sign in' : 'Create account',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
              onPressed: loading ? null : onSignInWithGoogle,
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
                    _googleIconAsset,
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
                onPressed: loading ? null : onToggleMode,
                child: Text(
                  mode == AuthMode.signIn ? 'Need an account? Sign up' : 'Already have an account? Sign in',
                  style: TextStyle(color: AppTheme.specRed, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
