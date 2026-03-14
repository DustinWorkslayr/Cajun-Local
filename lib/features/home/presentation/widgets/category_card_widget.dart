import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/data/category_icons.dart';
import 'package:cajun_local/core/theme/theme.dart';

class CategoryCardWidget extends StatelessWidget {
  const CategoryCardWidget({super.key, required this.category, required this.onTap});

  final MockCategory category;
  final VoidCallback onTap;

  static const double _cardRadius = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added
            children: [
              Icon(getCategoryIconData(category.iconName), size: 36, color: AppTheme.specNavy), // Reduced from 40
              const SizedBox(height: 10), // Reduced from 14
              Flexible( // Added Wrap
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, 
                    color: AppTheme.specNavy,
                    fontSize: 13, // Slightly smaller
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (category.count > 0) ...[
                const SizedBox(height: 4), // Reduced from 6
                Text(
                  '${category.count} spots',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11, // Slightly smaller
                  ),
                ),
              ],
              const SizedBox(height: 8), // Reduced from 10
              Container(
                height: 2.5, // Reduced from 3
                width: 28, // Reduced from 32
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
