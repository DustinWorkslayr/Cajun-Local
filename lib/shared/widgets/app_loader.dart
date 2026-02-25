import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Inline or full-page loading indicator with app-standard color and size.
/// Use instead of ad-hoc CircularProgressIndicator(color: AppTheme.specNavy).
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.color,
    this.size = 24,
    this.strokeWidth = 2,
  }) : _fullPage = false;

  /// Full-page loader: centered, larger size. Use when the whole body is loading.
  const AppLoader.page({
    super.key,
    this.color,
    this.size = 48,
    this.strokeWidth = 3,
  }) : _fullPage = true;

  final Color? color;
  final double size;
  final double strokeWidth;
  final bool _fullPage;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.specNavy;
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: effectiveColor,
      ),
    );
    if (_fullPage) {
      return Center(child: indicator);
    }
    return indicator;
  }
}
