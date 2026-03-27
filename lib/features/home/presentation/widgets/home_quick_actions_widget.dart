import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Horizontal-scroll quick-action pills.
/// Matches Stitch v2 spec:
///  • First pill (Deals) = secondary bg (#795900) + white text
///  • Remaining pills = surface-container-high bg + on-surface-variant text
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        children: [
          _QuickPill(
            label: 'Deals',
            icon: Icons.sell_rounded,
            onTap: onDeals,
            isPrimary: true,
          ),
          const SizedBox(width: 12),
          _QuickPill(
            label: 'Events',
            icon: Icons.calendar_today_rounded,
            onTap: onEvents,
          ),
          const SizedBox(width: 12),
          _QuickPill(
            label: 'Choose for me',
            icon: Icons.auto_awesome_rounded,
            onTap: onChooseForMe,
          ),
        ],
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  const _QuickPill({
    required this.label,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isPrimary ? AppTheme.specGold : AppTheme.specSurfaceContainerHigh;
    final fg = isPrimary ? Colors.white : AppTheme.specOnSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
