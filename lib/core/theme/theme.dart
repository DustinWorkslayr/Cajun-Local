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

  // Spec colors (from UI design)
  static const Color specNavy = Color(0xFF0B2A55);
  static const Color specGold = Color(0xFFF4B400);
  static const Color specRed = Color(0xFFC62828);
  static const Color specOffWhite = Color(0xFFF8F6F2);
  static const Color specWhite = Color(0xFFFFFFFF);

  // Legacy brand color aliases (maintained for compatibility)
  static const Color cajunRed = specRed;
  static const Color localBlue = specNavy;
  static const Color accentGold = specGold;

  static ThemeData get light {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: specNavy,
        primaryContainer: Color(0xFFD0E4FF),
        secondary: specRed,
        secondaryContainer: Color(0xFFFFDAD6),
        tertiary: specGold,
        tertiaryContainer: Color(0xFFFFE08C),
        appBarColor: specWhite,
        error: Color(0xFFBA1A1A),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        adaptiveRemoveElevationTint: FlexAdaptive.all(),
        adaptiveElevationShadowsBack: FlexAdaptive.all(),
        adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
        defaultRadius: 12.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
        elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
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
        fabSchemeColor: SchemeColor.tertiary,
        cardRadius: 16.0,
        popupMenuRadius: 8.0,
        popupMenuElevation: 3.0,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        appBarScrolledUnderElevation: 1.0,
        drawerRadius: 16.0,
        drawerIndicatorSchemeColor: SchemeColor.primary,
        bottomNavigationBarElevation: 8.0,
        bottomNavigationBarShowUnselectedLabels: true,
        navigationBarElevation: 8.0,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        navigationBarIndicatorSchemeColor: SchemeColor.primary,
        navigationRailIndicatorSchemeColor: SchemeColor.primary,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
      scaffoldBackground: specOffWhite,
    );
  }

  static ThemeData get dark {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFFD0E4FF),
        primaryContainer: specNavy,
        secondary: Color(0xFFFFDAD6),
        secondaryContainer: specRed,
        tertiary: Color(0xFFFFE08C),
        tertiaryContainer: specGold,
        appBarColor: specNavy,
        error: Color(0xFFFFB4AB),
      ).defaultError.toDark(10, false),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        adaptiveRemoveElevationTint: FlexAdaptive.all(),
        adaptiveElevationShadowsBack: FlexAdaptive.all(),
        adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
        defaultRadius: 12.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
        elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
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
        fabSchemeColor: SchemeColor.tertiary,
        cardRadius: 16.0,
        popupMenuRadius: 8.0,
        popupMenuElevation: 3.0,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        appBarScrolledUnderElevation: 1.0,
        drawerRadius: 16.0,
        drawerIndicatorSchemeColor: SchemeColor.primary,
        bottomNavigationBarElevation: 8.0,
        bottomNavigationBarShowUnselectedLabels: true,
        navigationBarElevation: 8.0,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        navigationBarIndicatorSchemeColor: SchemeColor.primary,
        navigationRailIndicatorSchemeColor: SchemeColor.primary,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );
  }
}
