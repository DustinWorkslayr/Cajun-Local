import 'package:flutter/material.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/shared/utils/icon_mapper.dart';

import 'package:cajun_local/core/theme/theme.dart';

/// Sentinel for "Explore all" — distinguishable from dialog dismissed (null).
const String kExploreAllSentinel = '';

/// Shows a bottom-sheet asking how to explore: by category or explore all.
/// Returns [kExploreAllSentinel] for "Explore all", a category id for a
/// specific category, or null if the user dismisses without choosing.
Future<String?> showExploreCategoryPickerDialog({
  required BuildContext context,
  required List<BusinessCategory> categories,
}) async {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _ExploreCategoryPickerSheet(categories: categories),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreCategoryPickerSheet extends StatelessWidget {
  const _ExploreCategoryPickerSheet({required this.categories});

  final List<BusinessCategory> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── drag handle ────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.specNavy.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── editorial heading ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT ARE YOU LOOKING FOR?',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.specGold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start exploring',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.specNavy,
                    fontFamily: 'Libre Baskerville',
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── "Explore all" hero card ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ExploreAllCard(
              onTap: () => Navigator.of(context).pop(kExploreAllSentinel),
            ),
          ),

          // ── category grid ──────────────────────────────────────────────────
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'BY CATEGORY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 28),
                child: _CategoryGrid(
                  categories: categories,
                  onSelect: (id) => Navigator.of(context).pop(id),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: bottomPadding + 28),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Explore all" hero card
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreAllCard extends StatelessWidget {
  const _ExploreAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.specNavy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.specNavy.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gold icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.explore_rounded, size: 24, color: AppTheme.specGold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore everything',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse all local businesses',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category grid
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid({required this.categories, required this.onSelect});

  final List<BusinessCategory> categories;
  final ValueChanged<String> onSelect;

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  String? _hovered;

  @override
  Widget build(BuildContext context) {
    const crossCount = 3;
    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
        final tileHeight = tileWidth * 0.9; // slightly shorter than square

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: widget.categories.map((cat) {
            final isPressed = _hovered == cat.id;
            return SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: _CategoryTile(
                category: cat,
                isPressed: isPressed,
                onTapDown: () => setState(() => _hovered = cat.id),
                onTapUp: () {
                  setState(() => _hovered = null);
                  widget.onSelect(cat.id);
                },
                onTapCancel: () => setState(() => _hovered = null),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual category tile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final BusinessCategory category;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: isPressed
              ? AppTheme.specNavy.withValues(alpha: 0.90)
              : AppTheme.specWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPressed
                ? AppTheme.specNavy
                : AppTheme.specNavy.withValues(alpha: 0.10),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.specNavy.withValues(alpha: isPressed ? 0.18 : 0.06),
              blurRadius: isPressed ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon square
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPressed
                    ? AppTheme.specGold.withValues(alpha: 0.20)
                    : AppTheme.specNavy.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconMapper.getIcon(category.iconName),
                size: 22,
                color: isPressed ? AppTheme.specGold : AppTheme.specNavy,
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPressed ? Colors.white : AppTheme.specNavy,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
