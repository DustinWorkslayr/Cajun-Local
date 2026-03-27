import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/screens/privacy_policy_agreement_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      final agreed = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(builder: (_) => const PrivacyPolicyAgreementScreen()));
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

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created.')));
        context.go('/');
      }
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
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= AppTheme.breakpointTablet;

    final bgColor = isDark ? AppTheme.specNavy : AppTheme.specWhite;
    final textColor = isDark ? Colors.white : AppTheme.specNavy;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Baseline Image - Enhanced Visibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/skyline-2.png',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                color: isDark ? Colors.white : AppTheme.specNavy,
                colorBlendMode: BlendMode.dstATop,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 500 : 400),
                  child: Column(
                    children: [
                      const AppLogo(height: 70),
                      const SizedBox(height: 12),
                      Container(height: 2, width: 20, color: AppTheme.specGold),
                      const SizedBox(height: 32),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SIGN UP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Join our exclusive network of community curators.',
                          style: GoogleFonts.beVietnamPro(fontSize: 15, height: 1.4, color: textColor.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInput(
                              controller: _displayNameController,
                              label: 'Full Name',
                              isDark: isDark,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 20),
                            _buildInput(
                              controller: _emailController,
                              label: 'Email Address',
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Invalid email format';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildInput(
                              controller: _passwordController,
                              label: 'Password',
                              isDark: isDark,
                              obscureText: true,
                              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              value: _privacyAgreed,
                              onChanged: (v) => setState(() => _privacyAgreed = v ?? false),
                              activeColor: AppTheme.specGold,
                              checkColor: AppTheme.specNavy,
                              side: BorderSide(color: textColor.withOpacity(0.3)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _privacyAgreed = !_privacyAgreed),
                              child: Text(
                                'Agreement with Terms & Privacy Policy',
                                style: GoogleFonts.beVietnamPro(fontSize: 13, color: textColor.withOpacity(0.7)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.specRed,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      const SizedBox(height: 36),
                      AppPrimaryButton(
                        onPressed: _loading ? null : _submit,
                        label: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                              )
                            : const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                      ),

                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: textColor.withOpacity(0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: textColor.withOpacity(0.1))),
                        ],
                      ),
                      const SizedBox(height: 32),

                      _SocialButton(
                        onPressed: _loading ? null : _signInWithGoogle,
                        isDark: isDark,
                        label: 'Sign up with Google',
                      ),

                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already a member? ",
                            style: GoogleFonts.beVietnamPro(color: textColor.withOpacity(0.5)),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/auth/login'),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.beVietnamPro(color: AppTheme.specGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : AppTheme.specNavy.withOpacity(0.1);
    final focusColor = AppTheme.specGold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: focusColor,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: GoogleFonts.beVietnamPro(
            color: isDark ? Colors.white : AppTheme.specNavy,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 10),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: focusColor, width: 2)),
            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.specRed)),
            focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.specRed, width: 2)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDark;
  final String label;

  const _SocialButton({required this.onPressed, required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.specNavy.withOpacity(0.1);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: isDark ? Colors.white : AppTheme.specNavy,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/googleicon.webp',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
          ),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
