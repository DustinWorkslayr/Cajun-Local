import 'package:flutter/material.dart';

/// Cajun Local app theme using Material 3.
/// Navy, red, gold — warm, community-driven, regionally proud.
class AppTheme {
  AppTheme._();

  /// Tablet breakpoint (width): use multi-column layouts above this.
  static const double breakpointTablet = 600;
  /// Max content width for centered sections on large screens.
  static const double sectionMaxWidth = 800;

  // Brand palette (UI spec: navy primary, gold accent, red limited)
  static const Color _cajunRed = Color(0xFFBF0A30);   // Cajun / primary
  static const Color _localBlue = Color(0xFF002868);  // Navy / secondary
  static const Color _accentGold = Color(0xFFF4C430); // Gold accent
  static const Color _black = Color(0xFF1A1A1A);
  static const Color _white = Color(0xFFFFFFFF);

  /// Spec colors: navy primary, gold highlight, red accent (limited), off-white background.
  static const Color specNavy = Color(0xFF0B2A55);
  static const Color specGold = Color(0xFFF4B400);
  static const Color specRed = Color(0xFFC62828);
  static const Color specOffWhite = Color(0xFFF8F6F2);
  static const Color specWhite = Color(0xFFFFFFFF);

  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: onSurface, height: 1.15),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: onSurface, height: 1.2),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: onSurface, height: 1.25),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface, height: 1.25),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, height: 1.35),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant, height: 1.3),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant, height: 1.3, letterSpacing: 0.5),
    );
  }

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: _cajunRed,
      onPrimary: _white,
      primaryContainer: Color(0xFFFFDAD6),
      onPrimaryContainer: Color(0xFF410008),
      secondary: _localBlue,
      onSecondary: _white,
      secondaryContainer: Color(0xFFD6E3FF),
      onSecondaryContainer: Color(0xFF001B3D),
      tertiary: _accentGold,
      onTertiary: _black,
      tertiaryContainer: Color(0xFFFFE08C),
      onTertiaryContainer: Color(0xFF261900),
      surface: Color(0xFFFFFBFF),
      onSurface: _black,
      surfaceContainerHighest: Color(0xFFE6E1E5),
      onSurfaceVariant: Color(0xFF524344),
      outline: Color(0xFF857374),
      error: Color(0xFFBA1A1A),
      onError: _white,
      outlineVariant: Color(0xFFD8C2C4),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme.onSurface, colorScheme.onSurfaceVariant),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: _cajunRed,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _cajunRed,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: _cajunRed,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: specGold,
          foregroundColor: specNavy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: specNavy,
          side: BorderSide(color: specNavy.withValues(alpha: 0.6), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: specNavy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFFFFB3AE),
      onPrimary: Color(0xFF670018),
      primaryContainer: Color(0xFF8F0025),
      onPrimaryContainer: Color(0xFFFFDAD6),
      secondary: Color(0xFFA8C7FF),
      onSecondary: Color(0xFF122F5A),
      secondaryContainer: Color(0xFF284572),
      onSecondaryContainer: Color(0xFFD6E3FF),
      tertiary: _accentGold,
      onTertiary: _black,
      tertiaryContainer: Color(0xFF5C4A00),
      onTertiaryContainer: Color(0xFFFFE08C),
      surface: _black,
      onSurface: Color(0xFFE6E1E5),
      surfaceContainerHighest: Color(0xFF2D2B2C),
      onSurfaceVariant: Color(0xFFD8C2C4),
      outline: Color(0xFFA08C8E),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      outlineVariant: Color(0xFF524344),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme.onSurface, colorScheme.onSurfaceVariant),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: _accentGold,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _accentGold,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: _accentGold,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// Brand colors for use in widgets (e.g. logo background).
  static const Color cajunRed = _cajunRed;
  static const Color localBlue = _localBlue;
  static const Color accentGold = _accentGold;
}
