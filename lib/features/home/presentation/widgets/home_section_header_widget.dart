import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

class HomeSectionHeaderWidget extends StatelessWidget {
  const HomeSectionHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;

  static const double _barHeight = 3;
  static const double _barWidth = 40;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.65)),
          ),
        ],
        const SizedBox(height: 6),
        Container(
          height: _barHeight,
          width: _barWidth,
          decoration: BoxDecoration(
            color: AppTheme.specGold.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
