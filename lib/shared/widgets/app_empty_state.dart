import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Standardized empty state: icon, message, optional action.
/// Use for "no items", "no data", "no results" blocks.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.padding,
  });

  final String message;
  final IconData? icon;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(vertical: 32, horizontal: 20);

    return Padding(
      padding: effectivePadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
