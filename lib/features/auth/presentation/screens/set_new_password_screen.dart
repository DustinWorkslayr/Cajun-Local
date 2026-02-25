import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown when the user has opened the password reset link (recovery session).
/// They enter a new password; on success we clear recovery and they're signed in.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({
    super.key,
    required this.onPasswordUpdated,
  });

  final VoidCallback onPasswordUpdated;

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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

    final password = _passwordController.text;
    try {
      await auth.updatePassword(password);
      if (mounted) {
        widget.onPasswordUpdated();
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
                                        'Set new password',
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
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              TextFormField(
                                                controller: _passwordController,
                                                decoration: InputDecoration(
                                                  labelText: 'New password',
                                                  hintText: '••••••••',
                                                  prefixIcon: Icon(
                                                      Icons.lock_outline_rounded,
                                                      color: primary),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons
                                                              .visibility_off_outlined
                                                          : Icons
                                                              .visibility_outlined,
                                                      color: primary,
                                                    ),
                                                    onPressed: () => setState(
                                                        () => _obscurePassword =
                                                            !_obscurePassword),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    borderSide: BorderSide(
                                                        color: primary,
                                                        width: 1.5),
                                                  ),
                                                ),
                                                obscureText: _obscurePassword,
                                                textInputAction:
                                                    TextInputAction.next,
                                                onFieldSubmitted: (_) =>
                                                    FocusScope.of(context)
                                                        .nextFocus(),
                                                validator: (v) {
                                                  if (v == null ||
                                                      v.isEmpty) {
                                                    return 'Enter a password';
                                                  }
                                                  if (v.length < 6) {
                                                    return 'Use at least 6 characters';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 20),
                                              TextFormField(
                                                controller: _confirmController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Confirm new password',
                                                  hintText: '••••••••',
                                                  prefixIcon: Icon(
                                                      Icons.lock_outline_rounded,
                                                      color: primary),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscureConfirm
                                                          ? Icons
                                                              .visibility_off_outlined
                                                          : Icons
                                                              .visibility_outlined,
                                                      color: primary,
                                                    ),
                                                    onPressed: () => setState(
                                                        () => _obscureConfirm =
                                                            !_obscureConfirm),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    borderSide: BorderSide(
                                                        color: primary,
                                                        width: 1.5),
                                                  ),
                                                ),
                                                obscureText: _obscureConfirm,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _submit(),
                                                validator: (v) {
                                                  if (v == null ||
                                                      v.isEmpty) {
                                                    return 'Confirm your password';
                                                  }
                                                  if (v !=
                                                      _passwordController
                                                          .text) {
                                                    return 'Passwords do not match';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              if (_errorMessage != null) ...[
                                                const SizedBox(height: 20),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .all(12),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .errorContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colorScheme
                                                          .onErrorContainer,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 28),
                                              AppPrimaryButton(
                                                onPressed: _loading
                                                    ? null
                                                    : () {
                                                        if (!(_formKey
                                                                .currentState
                                                                ?.validate() ??
                                                            false)) return;
                                                        _submit();
                                                      },
                                                child: _loading
                                                    ? SizedBox(
                                                        height: 22,
                                                        width: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: colorScheme
                                                              .onPrimary,
                                                        ),
                                                      )
                                                    : const Text(
                                                        'Update password',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
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
