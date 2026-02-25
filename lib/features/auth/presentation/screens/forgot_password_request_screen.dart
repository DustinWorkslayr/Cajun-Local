import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen to request a password reset email. User enters email and we call
/// [AuthRepository.resetPasswordForEmail]. Success shows a message; user can go back to sign in.
class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState extends State<ForgotPasswordRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sent) return;
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
    try {
      await auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() {
          _sent = true;
          _loading = false;
          _errorMessage = null;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;

    final isTablet =
        MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 40),
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
                                    Center(child: AppLogo(height: 200)),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Container(
                                        width: 48,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentGold,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: Text(
                                        _sent
                                            ? 'Check your email'
                                            : 'Reset your password',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: isTablet
                                              ? 420
                                              : double.infinity,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(28),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: colorScheme.outlineVariant
                                                  .withValues(alpha: 0.8),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: secondary
                                                    .withValues(alpha: 0.06),
                                                blurRadius: 20,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: _sent
                                              ? _buildSuccessContent(theme,
                                                  colorScheme, primary)
                                              : _buildFormContent(theme,
                                                  colorScheme, primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    if (Navigator.of(context).canPop())
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: _loading
                                              ? null
                                              : () =>
                                                  Navigator.of(context).pop(),
                                          icon: Icon(
                                            Icons.arrow_back_rounded,
                                            size: 20,
                                            color: secondary,
                                          ),
                                          label: Text(
                                            'Back to sign in',
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

  Widget _buildFormContent(
      ThemeData theme, ColorScheme colorScheme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the email for your account and we\'ll send you a link to reset your password.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your email';
            return null;
          },
        ),
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
              : () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
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
              : const Text(
                  'Send reset link',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(
      ThemeData theme, ColorScheme colorScheme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 48, color: primary.withValues(alpha: 0.8)),
        const SizedBox(height: 16),
        Text(
          'If an account exists for ${_emailController.text.trim()}, you\'ll receive an email with a link to set a new password. Open the link on this device to continue.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
