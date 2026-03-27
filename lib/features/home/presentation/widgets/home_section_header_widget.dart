import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

class HomeSectionHeaderWidget extends StatelessWidget {
  const HomeSectionHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          softWrap: true,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.specOnSurfaceVariant.withValues(alpha: 0.8),
            ),
            softWrap: true,
          ),
        ],
      ],
    );
  }
}
