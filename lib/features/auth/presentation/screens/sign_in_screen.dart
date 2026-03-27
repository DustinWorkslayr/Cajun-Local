import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/preferences/sign_in_preferences.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/screens/forgot_password_request_screen.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    setState(() { _errorMessage = null; _loading = true; });

    try {
      await ref.read(authControllerProvider.notifier).signIn(
        email: _emailController.text.trim(), 
        password: _passwordController.text
      );
      if (mounted) {
        if (_rememberMe) {
          await SignInPreferences.setRememberMe(true);
          await SignInPreferences.setLastEmail(_emailController.text.trim());
        } else {
          await SignInPreferences.setRememberMe(false);
          await SignInPreferences.clear();
        }
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
    setState(() { _errorMessage = null; _loading = true; });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _loading = false; });
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
            left: 0, right: 0, bottom: 0,
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
                          'SIGN IN',
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
                          'Experience your community through\na curated local lens.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            height: 1.4,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                              validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 20, width: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                  activeColor: AppTheme.specGold,
                                  checkColor: AppTheme.specNavy,
                                  side: BorderSide(color: textColor.withOpacity(0.3)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Remember Me', style: GoogleFonts.beVietnamPro(fontSize: 14, color: textColor.withOpacity(0.7))),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordRequestScreen())),
                            child: Text('Forgot Password?', style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppTheme.specRed, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.beVietnamPro(color: AppTheme.specRed, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                      
                      const SizedBox(height: 36),
                      AppPrimaryButton(
                        onPressed: _loading ? null : _submit,
                        label: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy))
                          : const Text(
                              'GET STARTED',
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: textColor.withOpacity(0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.3))),
                          ),
                          Expanded(child: Divider(color: textColor.withOpacity(0.1))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      _SocialButton(
                        onPressed: _loading ? null : _signInWithGoogle,
                        isDark: isDark,
                        label: 'Sign in with Google',
                      ),
                      
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("New to Cajun Local? ", style: GoogleFonts.beVietnamPro(color: textColor.withOpacity(0.5))),
                          GestureDetector(
                            onTap: () => context.go('/auth/register'),
                            child: Text('Create Account', style: GoogleFonts.beVietnamPro(color: AppTheme.specGold, fontWeight: FontWeight.bold)),
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
    String? Function(String?)? validator,
  }) {
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : AppTheme.specNavy.withOpacity(0.1);
    final focusColor = AppTheme.specGold;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: focusColor),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.beVietnamPro(color: isDark ? Colors.white : AppTheme.specNavy, fontWeight: FontWeight.bold),
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
          Image.asset('assets/images/googleicon.webp', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
