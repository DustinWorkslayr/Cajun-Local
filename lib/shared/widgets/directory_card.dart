import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Directory-style card with image area, title, subtitle, gold accent bar; scale on tap.
class DirectoryCard extends StatefulWidget {
  const DirectoryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageWidget,
    this.onTap,
    this.accentColor,
    this.showAccentBar = true,
    this.badgeLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? imageWidget;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool showAccentBar;
  /// Optional badge (e.g. "Partner" for highest-tier businesses).
  final String? badgeLabel;

  @override
  State<DirectoryCard> createState() => _DirectoryCardState();
}

class _DirectoryCardState extends State<DirectoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = widget.accentColor ?? AppTheme.cajunRed;

    return MouseRegion(
      onEnter: (_) => setState(() => _pressed = true),
      onExit: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.imageWidget != null)
                  widget.imageWidget!
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.place_rounded,
                      size: 48,
                      color: accent.withValues(alpha: 0.9),
                    ),
                  ),
                if (widget.showAccentBar)
                  Container(
                    height: 3,
                    width: double.infinity,
                    color: AppTheme.accentGold.withValues(alpha: 0.6),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.badgeLabel != null && widget.badgeLabel!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.specGold.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                widget.badgeLabel!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (widget.onTap != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Discover',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
