import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/preferences/sign_in_preferences.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/auth/presentation/screens/forgot_password_request_screen.dart';
import 'package:my_app/features/auth/presentation/screens/privacy_policy_agreement_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Branded sign-in/sign-up screen. Uses Supabase Auth when configured
/// (backend-cheatsheet §9: handle_new_user creates profile + user role on signup).
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.initialMode = AuthMode.signIn,
  });

  final AuthMode initialMode;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum AuthMode { signIn, signUp }

class _SignInScreenState extends State<SignInScreen> {
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

    final auth = AppDataScope.of(context).authRepository;
    if (!auth.isConfigured) {
      setState(() {
        _errorMessage = 'Sign-in is not configured.';
        _loading = false;
      });
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim().isEmpty
        ? null
        : _displayNameController.text.trim();

    try {
      if (_mode == AuthMode.signUp) {
        await auth.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
        // Confirmation email is sent by Supabase Auth using your project's custom SMTP.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm your account.'),
            ),
          );
          setState(() => _mode = AuthMode.signIn);
        }
      } else {
        await auth.signIn(email: email, password: password);
        if (mounted) {
          if (_rememberMe) {
            await SignInPreferences.setRememberMe(true);
            await SignInPreferences.setLastEmail(email);
          } else {
            await SignInPreferences.setRememberMe(false);
            await SignInPreferences.clear();
          }
        }
        // Do not pop: home is StreamBuilder; auth state change will switch to MainShell.
        if (mounted) setState(() => _loading = false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        final isConfirmationEmailError = (msg.contains('confirmation') && msg.contains('email')) ||
            msg.contains('error sending');
        setState(() {
          _errorMessage = isConfirmationEmailError
              ? 'Your account may have been created, but we couldn\'t send the confirmation email. '
                'Try signing in below, or use "Forgot password?" to receive an email.'
              : e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }

    if (mounted && _mode == AuthMode.signIn) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;

    final isTablet = MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final skylineHeight = isTablet ? mediaHeight * 0.08 : mediaHeight * 0.14;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                    child: Form(
                      key: _formKey,
                      child: LayoutBuilder(
                        builder: (context, formConstraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: formConstraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                      const SizedBox(height: 24),
                      Center(
                        child: AppLogo(height: 100),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 48,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _mode == AuthMode.signIn
                              ? 'Sign in to your account'
                              : 'Create an account',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 420 : double.infinity,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: secondary.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_mode == AuthMode.signUp) ...[
                                  TextFormField(
                                    controller: _displayNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Display name',
                                      hintText: 'How we\'ll show your name',
                                      prefixIcon: Icon(Icons.person_outline_rounded, color: primary),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: primary, width: 1.5),
                                      ),
                                    ),
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).nextFocus(),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.email_outlined, color: primary),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: primary, width: 1.5),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter your email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: primary),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: primary, width: 1.5),
                                    ),
                                  ),
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your password';
                                    }
                                    if (_mode == AuthMode.signUp && v.length < 6) {
                                      return 'Use at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                if (_mode == AuthMode.signIn) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: _loading
                                              ? null
                                              : (v) => setState(() => _rememberMe = v ?? false),
                                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) => states.contains(WidgetState.selected) ? primary : Colors.transparent),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: _loading
                                            ? null
                                            : () => setState(() => _rememberMe = !_rememberMe),
                                        child: Text(
                                          'Remember me',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: secondary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _loading
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        const ForgotPasswordRequestScreen(),
                                                  ),
                                                );
                                              },
                                        child: Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                AppPrimaryButton(
                                  onPressed: _loading
                                      ? null
                                      : () async {
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
                                  child: _loading
                                      ? SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colorScheme.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          _mode == AuthMode.signIn
                                              ? 'Sign in'
                                              : 'Create account',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            setState(() {
                                              _mode = _mode == AuthMode.signIn
                                                  ? AuthMode.signUp
                                                  : AuthMode.signIn;
                                              _errorMessage = null;
                                              if (_mode == AuthMode.signIn) _privacyAgreed = false;
                                            });
                                          },
                                    child: Text(
                                      _mode == AuthMode.signIn
                                          ? 'Need an account? Sign up'
                                          : 'Already have an account? Sign in',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (Navigator.of(context).canPop())
                        Center(
                          child: TextButton.icon(
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: secondary,
                            ),
                            label: Text(
                              'Back',
                              style: TextStyle(
                                color: secondary,
                                fontWeight: FontWeight.w500,
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
                child: Image.asset(
                  'assets/images/skyline-2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
