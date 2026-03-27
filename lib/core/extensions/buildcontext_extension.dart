import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Context extensions for cleaner UI code and consistent global helpers (Snackbars, theme access).
extension BuildContextExtension on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Premium Success Snackbar (Navy + Gold)
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.specNavy,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Premium Error Snackbar (Navy + Red)
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.specRed.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: AppTheme.specRed, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.specNavy,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.specRed.withValues(alpha: 0.3), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
