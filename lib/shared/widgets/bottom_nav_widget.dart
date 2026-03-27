import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Bottom nav — frosted glass, rounded top, gold pill active state.
/// Matches Stitch v2 "Cajun Local Redesigned" design exactly.
class BottomNavWidget extends StatelessWidget {
  const BottomNavWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.screenCount,
    required this.titles,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int screenCount;
  final List<String> titles;

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.article_rounded,
    Icons.explore_rounded,
    Icons.local_offer_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final barCount = screenCount.clamp(1, _icons.length);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF191C1D).withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,

            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(barCount, (index) {
                  final selected = index == currentIndex;
                  final label = index < titles.length ? titles[index] : '';
                  final iconData = index < _icons.length ? _icons[index] : Icons.circle_rounded;
                  return _BottomNavItem(icon: iconData, label: label, selected: selected, onTap: () => onTap(index));
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.specGold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : AppTheme.specOnSurfaceVariant),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: selected ? Colors.white : AppTheme.specOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
