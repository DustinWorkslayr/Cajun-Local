import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';

class CajunSplashScreen extends StatefulWidget {
  const CajunSplashScreen({super.key});

  @override
  State<CajunSplashScreen> createState() => _CajunSplashScreenState();
}

class _CajunSplashScreenState extends State<CajunSplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  late Animation<double> _shimmerMove; // For the custom "light sweep"

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 1. Logo Entrance (0-1500ms)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Light Sweep (600-2000ms)
    _shimmerMove = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOutSine),
      ),
    );

    // 3. Tagline & Dots (1200-2500ms)
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Premium Midnight
      body: Stack(
        alignment: Alignment.center,
        children: [
          // A. Dynamic Background Aura (Ensures contrast part 1)
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.3 + (_glowController.value * 0.2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        AppTheme.specNavy.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // B. Main Content Column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // B1. The Logo with Light-Reveal Shader
              AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Underlying glow for visibility (Ensures contrast part 2)
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.specGold.withValues(alpha: 0.1 * _logoOpacity.value),
                                  blurRadius: 64,
                                  spreadRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          // The actual Logo with subtle "light sweep"
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  AppTheme.specGold.withValues(alpha: 0.8),
                                  Colors.white,
                                ],
                                stops: [
                                  _shimmerMove.value - 0.4,
                                  _shimmerMove.value,
                                  _shimmerMove.value + 0.4,
                                ],
                              ).createShader(bounds);
                            },
                            child: const AppLogo(height: 150),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // B2. Staggered Tagline & Dot
              FadeTransition(
                opacity: _contentOpacity,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      Text(
                        'DISCOVER YOUR LOCAL SPIRIT',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _PremiumPulsar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumPulsar extends StatefulWidget {
  const _PremiumPulsar();

  @override
  State<_PremiumPulsar> createState() => _PremiumPulsarState();
}

class _PremiumPulsarState extends State<_PremiumPulsar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppTheme.specGold, shape: BoxShape.circle),
            ),
            Opacity(
              opacity: 1.0 - _controller.value,
              child: Transform.scale(
                scale: 1.0 + (3.0 * _controller.value),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5), width: 1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
