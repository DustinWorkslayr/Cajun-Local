import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';

class ExploreTopBar extends StatelessWidget {
  const ExploreTopBar({
    super.key,
    required this.openNowOnly,
    required this.onOpenNowChanged,
    required this.onFilterTap,
    required this.listMapTabController,
  });

  final bool openNowOnly;
  final ValueChanged<bool> onOpenNowChanged;
  final VoidCallback onFilterTap;
  final TabController listMapTabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Container(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 12),
      color: AppTheme.specOffWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCOVER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.specGold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Explore',
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
              // Open Now toggle pill
              GestureDetector(
                onTap: () => onOpenNowChanged(!openNowOnly),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: openNowOnly ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: openNowOnly ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: openNowOnly ? Colors.white : AppTheme.specNavy.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Open now',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: openNowOnly ? Colors.white : AppTheme.specNavy.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button
              Material(
                color: AppTheme.specNavy.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(Icons.tune_rounded, color: AppTheme.specNavy, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // List / Map segmented control
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.specNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListenableBuilder(
              listenable: listMapTabController,
              builder: (context, _) {
                return Row(
                  children: [
                    Expanded(
                      child: ExploreSegmentBtn(
                        icon: Icons.view_list_rounded,
                        label: 'List',
                        selected: listMapTabController.index == 0,
                        onTap: () => listMapTabController.animateTo(0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ExploreSegmentBtn(
                        icon: Icons.map_rounded,
                        label: 'Map',
                        selected: listMapTabController.index == 1,
                        onTap: () => listMapTabController.animateTo(1),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreSegmentBtn extends StatelessWidget {
  const ExploreSegmentBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.specGold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.specGold.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.specNavy.withValues(alpha: 0.40),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppTheme.specNavy.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
