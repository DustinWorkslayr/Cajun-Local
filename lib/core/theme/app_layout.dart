import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Responsive layout helpers: padding, max width, tablet breakpoint.
class AppLayout {
  AppLayout._();

  static const double _gutterPhone = 20;
  static const double _gutterTablet = 32;
  static const double _sectionSpacing = 28;

  static EdgeInsets horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width >= AppTheme.breakpointTablet ? _gutterTablet : _gutterPhone;
    return EdgeInsets.symmetric(horizontal: gutter);
  }

  static EdgeInsets padding(BuildContext context, {double top = 0, double bottom = 0}) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal.left, top, horizontal.right, bottom);
  }

  static double get sectionSpacing => _sectionSpacing;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
  }

  static Widget constrainSection(BuildContext context, Widget child) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= AppTheme.sectionMaxWidth) return child;
    return Center(
      child: SizedBox(width: AppTheme.sectionMaxWidth, child: child),
    );
  }
}
