import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Bottom nav: 6 icons only (no labels), rounded floating bar.
/// Filename: bottom_nav_widget.dart
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
    Icons.favorite_rounded,
    Icons.local_offer_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final barCount = screenCount.clamp(1, _icons.length);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(barCount, (index) {
            final selected = index == currentIndex;
            final label = index < titles.length ? titles[index] : '';
            final iconData = index < _icons.length ? _icons[index] : Icons.circle_rounded;
            return Expanded(
              child: BottomNavItemWidget(icon: iconData, selected: selected, label: label, onTap: () => onTap(index)),
            );
          }),
        ),
      ),
    );
  }
}

class BottomNavItemWidget extends StatefulWidget {
  const BottomNavItemWidget({
    super.key,
    required this.icon,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  State<BottomNavItemWidget> createState() => _BottomNavItemWidgetState();
}

class _BottomNavItemWidgetState extends State<BottomNavItemWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: AppTheme.specGold.withValues(alpha: 0.14),
          focusColor: AppTheme.specGold.withValues(alpha: 0.2),
          highlightColor: AppTheme.specGold.withValues(alpha: 0.22),
          splashColor: AppTheme.specGold.withValues(alpha: 0.35),
          child: Tooltip(
            message: widget.label,
            child: Center(
              child: AnimatedScale(
                scale: _hovered ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: widget.selected
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppTheme.specGold.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 0),
                            BoxShadow(
                              color: AppTheme.specGold.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, size: 26, color: AppTheme.specNavy),
                      )
                    : Icon(widget.icon, size: 26, color: AppTheme.specNavy.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
