import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/shared/widgets/section_divider.dart';

/// Section wrapper: consistent horizontal padding, optional max-width for tablet,
/// optional section header and festival-style divider.
class ResponsiveSection extends StatelessWidget {
  const ResponsiveSection({
    super.key,
    required this.child,
    this.title,
    this.actionLabel,
    this.onAction,
    this.showDivider = false,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final Widget child;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showDivider;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: AppLayout.padding(
        context,
        top: topPadding,
        bottom: bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (onAction != null && actionLabel != null)
                    TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ),
            ),
          if (showDivider) const SectionDivider(verticalPadding: 8),
          child,
        ],
      ),
    );
    return AppLayout.constrainSection(context, content);
  }
}
