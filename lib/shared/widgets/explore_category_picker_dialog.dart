import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/category_icons.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Sentinel for "Explore all" so we can tell it apart from dialog dismissed (null).
const String kExploreAllSentinel = '';

/// Shows a dialog asking how to explore: by category (cards) or explore all.
/// Returns [kExploreAllSentinel] for "Explore all", category id for a category, or null if dismissed.
Future<String?> showExploreCategoryPickerDialog({
  required BuildContext context,
  required List<MockCategory> categories,
}) async {
  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ExploreCategoryPickerDialog(categories: categories),
  );
}

class _ExploreCategoryPickerDialog extends StatelessWidget {
  const _ExploreCategoryPickerDialog({required this.categories});

  final List<MockCategory> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const crossAxisCount = 4;
    const spacing = 8.0;
    const runSpacing = 8.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How do you want to explore?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
              ),
              const SizedBox(height: 12),
              _ExploreAllCard(onTap: () => Navigator.of(context).pop(kExploreAllSentinel)),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'BY CATEGORY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: runSpacing,
                      alignment: WrapAlignment.center,
                      children: categories.map((cat) {
                        return SizedBox(
                          width: width,
                          child: _CategoryCard(category: cat, onTap: () => Navigator.of(context).pop(cat.id)),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreAllCard extends StatelessWidget {
  const _ExploreAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.specNavy, AppTheme.specNavy.withValues(alpha: 0.92)],
            ),
            boxShadow: [
              BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.explore_rounded, size: 22, color: AppTheme.specGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Explore all',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specWhite),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: AppTheme.specWhite.withValues(alpha: 0.9), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final MockCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(getCategoryIconData(category.iconName), size: 24, color: AppTheme.specNavy),
              const SizedBox(height: 4),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
