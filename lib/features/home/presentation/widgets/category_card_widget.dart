import 'package:flutter/material.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/utils/icon_mapper.dart';

/// Category card — matches Stitch v2 exactly:
/// White card, rounded-3xl (24px), icon in bg-surface-container rounded-2xl (16px),
/// bold navy name, grey count, gold underline bar.
class CategoryCardWidget extends StatelessWidget {
  const CategoryCardWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  final BusinessCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF191C1D).withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container: bg-surface-container rounded-2xl
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.specSurfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  IconMapper.getIcon(category.iconName, fallback: Icons.store_rounded),
                  size: 28,
                  color: AppTheme.specNavy, // text-primary
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Count
              if (category.businessCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${category.businessCount} spots',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specOutline,
                    fontSize: 11,
                  ),
                ),
              ],

              // Gold bar (Stitch: w-8 h-1 bg-secondary mx-auto mt-2 rounded-full)
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.specGold,
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
