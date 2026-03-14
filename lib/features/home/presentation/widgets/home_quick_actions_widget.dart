import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

class HomeQuickActionsWidget extends StatelessWidget {
  const HomeQuickActionsWidget({
    super.key,
    required this.isTablet,
    this.onDeals,
    this.onEvents,
    this.onChooseForMe,
  });

  final bool isTablet;
  final VoidCallback? onDeals;
  final VoidCallback? onEvents;
  final VoidCallback? onChooseForMe;

  static const double _cardGap = 16;
  static const double _cardRadius = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = AppTheme.specNavy.withValues(alpha: 0.4);

    if (isTablet) {
      Widget actionCard(String label, String description, IconData icon, VoidCallback? onTap) {
        final enabled = onTap != null;
        return Expanded(
          child: Material(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            elevation: 0,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_cardRadius),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(
                    color: enabled ? AppTheme.specGold.withValues(alpha: 0.5) : nav.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 28, color: enabled ? AppTheme.specGold : sub),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: enabled ? nav : sub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(color: nav.withValues(alpha: 0.65), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Row(
        children: [
          actionCard('Deals', 'Save at local spots', Icons.local_offer_rounded, onDeals),
          const SizedBox(width: _cardGap),
          actionCard('Events', 'What\'s happening in Acadiana', Icons.event_rounded, onEvents),
          const SizedBox(width: _cardGap),
          actionCard('Choose for Me', 'Get a random pick', Icons.shuffle_rounded, onChooseForMe),
        ],
      );
    }

    Widget chip(String label, IconData icon, VoidCallback? onTap) {
      final enabled = onTap != null;
      return Material(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled ? AppTheme.specGold.withValues(alpha: 0.5) : nav.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: enabled ? AppTheme.specGold : sub),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: enabled ? nav : sub,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useVertical = constraints.maxWidth < 360;
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: useVertical ? double.infinity : (constraints.maxWidth - 24) / 3,
              child: chip('Deals', Icons.local_offer_rounded, onDeals),
            ),
            SizedBox(
              width: useVertical ? double.infinity : (constraints.maxWidth - 24) / 3,
              child: chip('Events', Icons.event_rounded, onEvents),
            ),
            SizedBox(
              width: useVertical ? double.infinity : (constraints.maxWidth - 24) / 3,
              child: chip('Choose for Me', Icons.shuffle_rounded, onChooseForMe),
            ),
          ],
        );
      },
    );
  }
}
