import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cajun Local app theme using FlexColorScheme for a premium Material 3 look.
/// Navy, red, gold — warm, community-driven, regionally proud.
class AppTheme {
  AppTheme._();

  /// Tablet breakpoint (width): use multi-column layouts above this.
  static const double breakpointTablet = 600;

  /// Large tablet / dashboard breakpoint: more columns, compact card height.
  static const double breakpointLargeTablet = 900;

  /// Max content width for centered sections on large screens.
  static const double sectionMaxWidth = 800;

  // Spec colors (from Stitch v2 design system namedColors)
  // static const Color primaryColor = Color(0xFFEAB308); // secondary (brand) - updated to darker yellow/gold

  static const Color specNavy = Color(0xFF002045); // primary
  static const Color specGold = Color(0xFF795900); // secondary (brand)
  static const Color specRed = Color(0xFFBA1A1A); // error
  static const Color specOffWhite = Color(0xFFF8F9FA); // background / surface
  static const Color specWhite = Color(0xFFFFFFFF); // surface_container_lowest
  static const Color specSurface = Color(0xFFFFFFFF);
  static const Color specSurfaceContainer = Color(0xFFEDEEEF); // surface_container
  static const Color specSurfaceContainerHigh = Color(0xFFE7E8E9); // surface_container_high
  static const Color specSurfaceContainerLow = Color(0xFFF3F4F5); // surface_container_low
  static const Color specOnSurface = Color(0xFF191C1D); // on_surface (ink-on-paper)
  static const Color specOnSurfaceVariant = Color(0xFF44474E); // on_surface_variant
  static const Color specOutline = Color(0xFF74777F); // outline
  static const Color specNavyContainer = Color(0xFF1A365D); // primary_container
  static const Color specSecondaryContainer = Color(0xFFFFC329); // secondary_container
  static const Color specOnPrimaryContainer = Color(0xFFADC7F7); // on_primary_container (used in hero subtitle)

  // Legacy brand color aliases (maintained for compatibility)
  static const Color cajunRed = specRed;
  static const Color localBlue = specNavy;
  static const Color accentGold = specGold;

  static ThemeData get light {
    final textTheme = GoogleFonts.beVietnamProTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
    );

    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: const Color(0xFFEAB308),
        primaryContainer: const Color(0xFFFFDDB3),
        secondary: specNavy,
        secondaryContainer: Color(0xFFD6E3FF),
        tertiary: specRed,
        tertiaryContainer: Color(0xFFFFDAD6),
        appBarColor: specWhite,
        error: Color(0xFFBA1A1A),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 2,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 8,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        adaptiveRemoveElevationTint: FlexAdaptive.all(),
        adaptiveElevationShadowsBack: FlexAdaptive.all(),
        adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
        defaultRadius: 8.0, // Per Stitch v2 spec
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsBorderSchemeColor: SchemeColor.primary,
        segmentedButtonSchemeColor: SchemeColor.primary,
        segmentedButtonBorderSchemeColor: SchemeColor.primary,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBackgroundAlpha: 15,
        inputDecoratorUnfocusedHasBorder: false,
        inputDecoratorFocusedBorderWidth: 1.0,
        inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
        fabUseShape: true,
        fabAlwaysCircular: true,
        fabSchemeColor: SchemeColor.primary,
        cardRadius: 8.0,
        popupMenuRadius: 8.0,
        popupMenuElevation: 3.0,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        appBarScrolledUnderElevation: 1.0,
        drawerRadius: 12.0,
        drawerIndicatorSchemeColor: SchemeColor.primary,
        bottomNavigationBarElevation: 4.0,
        bottomNavigationBarShowUnselectedLabels: true,
        navigationBarElevation: 0.0,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        navigationBarIndicatorSchemeColor: SchemeColor.primary,
        navigationRailIndicatorSchemeColor: SchemeColor.primary,
      ),
      keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true, keepPrimary: true),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      textTheme: textTheme,
      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
      scaffoldBackground: specOffWhite,
    );
  }

  static ThemeData get dark {
    final textTheme = GoogleFonts.beVietnamProTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
      displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
      displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
      headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
      headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
    );

    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFFADC7F7),
        primaryContainer: specNavy,
        secondary: Color(0xFFF9BD22),
        secondaryContainer: specGold,
        tertiary: Color(0xFFFFB3B1),
        tertiaryContainer: Color(0xFF720014),
        appBarColor: specNavy,
        error: Color(0xFFFFB4AB),
      ).defaultError.toDark(10, false),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        adaptiveRemoveElevationTint: FlexAdaptive.all(),
        adaptiveElevationShadowsBack: FlexAdaptive.all(),
        adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
        defaultRadius: 16.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsBorderSchemeColor: SchemeColor.primary,
        segmentedButtonSchemeColor: SchemeColor.primary,
        segmentedButtonBorderSchemeColor: SchemeColor.primary,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBackgroundAlpha: 31,
        inputDecoratorUnfocusedHasBorder: false,
        inputDecoratorFocusedBorderWidth: 1.0,
        inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
        fabUseShape: true,
        fabAlwaysCircular: true,
        fabSchemeColor: SchemeColor.secondary,
        cardRadius: 24.0,
        popupMenuRadius: 12.0,
        popupMenuElevation: 2.0,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        appBarScrolledUnderElevation: 1.0,
        drawerRadius: 24.0,
        drawerIndicatorSchemeColor: SchemeColor.primary,
        bottomNavigationBarElevation: 0.0,
        bottomNavigationBarShowUnselectedLabels: true,
        navigationBarElevation: 0.0,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        navigationBarIndicatorSchemeColor: SchemeColor.primary,
        navigationRailIndicatorSchemeColor: SchemeColor.primary,
      ),
      keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      textTheme: textTheme,
      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
    );
  }
}
