import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Festival/storefront-style section divider: gold line with optional map-pin accent.
class SectionDivider extends StatelessWidget {
  const SectionDivider({
    super.key,
    this.showAccent = true,
    this.thickness = 2,
    this.verticalPadding = 16,
  });

  final bool showAccent;
  final double thickness;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: thickness,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.accentGold.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          if (showAccent) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.place_rounded,
                size: 18,
                color: AppTheme.accentGold.withValues(alpha: 0.9),
              ),
            ),
            Expanded(
              child: Container(
                height: thickness,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ] else
            Expanded(
              child: Container(
                height: thickness,
                color: AppTheme.accentGold.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }
}
