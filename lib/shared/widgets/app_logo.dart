import 'package:flutter/material.dart';

/// Cajun Local logo for app bar. Place logo at assets/images/logo.png.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 44,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  static const String _assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => Text(
        'Cajun Local',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
