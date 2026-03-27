import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/theme/theme.dart';
// import 'package:shared_widgets/app_buttons.dart';
// import 'package:shared_widgets/app_logo.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordRequestScreen extends ConsumerStatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  ConsumerState<ForgotPasswordRequestScreen> createState() => _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState extends ConsumerState<ForgotPasswordRequestScreen> {
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

    try {
      await ref.read(authControllerProvider.notifier).recoverPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _sent = true;
          _loading = false;
          _errorMessage = null;
        });
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
                          _sent ? 'CHECK EMAIL' : 'RECOVER',
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
                          _sent
                              ? 'Instructions sent to your curated inbox.'
                              : 'Securely restore your community access.',
                          style: GoogleFonts.beVietnamPro(fontSize: 15, height: 1.4, color: textColor.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_sent)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'If an account for this email exists, you will receive a recovery link shortly.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: textColor.withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        )
                      else
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
                                        'SEND RECOVERY LINK',
                                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                      ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 36),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back_rounded, size: 20, color: textColor),
                          label: Text(
                            'Back to Sign In',
                            style: GoogleFonts.beVietnamPro(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
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
          validator: validator,
          keyboardType: keyboardType,
          style: GoogleFonts.beVietnamPro(
            color: isDark ? Colors.white : AppTheme.specNavy,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 10),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: focusColor, width: 2)),
          ),
        ),
      ],
    );
  }
}
