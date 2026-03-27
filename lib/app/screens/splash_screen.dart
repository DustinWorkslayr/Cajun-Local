import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';

class CajunSplashScreen extends StatelessWidget {
  const CajunSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.specNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(height: 120),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppTheme.specGold,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
