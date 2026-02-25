import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Section card: title + icon + children in a white card.
/// Use for "Basic info", "Category", etc. sections in forms and detail views.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.padding,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ?? const EdgeInsets.all(20);

    return Container(
      width: double.infinity,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.specGold),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
