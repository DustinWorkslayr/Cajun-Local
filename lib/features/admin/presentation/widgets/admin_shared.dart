import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Reusable admin UI: search bar, pagination, slide-out detail panel.
/// Uses app theme (navy, gold, off-white) for consistency.

const double _panelWidthTablet = 420;
const int _defaultPageSize = 10;

/// Search field with hint and optional onChanged.
class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    this.hint = 'Search…',
    this.controller,
    this.onChanged,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      autofocus: autofocus,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}

/// Pagination footer: "Showing X–Y of Z" and prev/next.
class AdminPaginationFooter extends StatelessWidget {
  const AdminPaginationFooter({
    super.key,
    required this.totalCount,
    required this.pageIndex,
    required this.pageSize,
    required this.onPageChanged,
    this.onPageSizeChanged,
  });

  final int totalCount;
  final int pageIndex;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;

  int get totalPages => totalCount <= 0 ? 1 : (totalCount / pageSize).ceil();
  int get startItem => totalCount == 0 ? 0 : pageIndex * pageSize + 1;
  int get endItem => totalCount == 0 ? 0 : (pageIndex + 1) * pageSize.clamp(0, totalCount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPrev = pageIndex > 0;
    final canNext = pageIndex < totalPages - 1 && totalCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Text(
            '${totalCount == 0 ? 0 : startItem}–$endItem of $totalCount',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: canPrev ? () => onPageChanged(pageIndex - 1) : null,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Page ${pageIndex + 1} of $totalPages',
              style: theme.textTheme.labelMedium,
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: canNext ? () => onPageChanged(pageIndex + 1) : null,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          if (onPageSizeChanged != null) ...[
            const SizedBox(width: 24),
            Text(
              'Per page',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: pageSize.clamp(10, 100),
              items: [10, 25, 50].map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
              onChanged: (v) {
                if (v != null) onPageSizeChanged!(v);
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Slide-out panel from the right for detail view / approve actions.
/// On tablet: fixed width. On phone: can be full width or 90%.
class AdminDetailPanel extends StatelessWidget {
  const AdminDetailPanel({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.actions,
    this.width,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final List<Widget>? actions;
  final double? width;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    double? width,
  }) {
    final isTablet = MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
    final panelWidth = width ?? (isTablet ? _panelWidthTablet : MediaQuery.sizeOf(context).width * 0.92);
    final panelContent = child;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              elevation: 24,
              shadowColor: Colors.black38,
              child: Container(
                width: panelWidth,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: AdminDetailPanel(
                  title: title,
                  onClose: () => Navigator.of(context).pop(),
                  actions: actions,
                  child: panelContent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 8,
            top: MediaQuery.paddingOf(context).top + 8,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions!,
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Section label in admin lists (e.g. "Status", "Details").
class AdminDetailLabel extends StatelessWidget {
  const AdminDetailLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Data for a single badge chip (label + optional color).
class AdminBadgeData {
  const AdminBadgeData(this.label, {this.color});
  final String label;
  final Color? color;
}

/// Small chip for status, count, or category in admin list items.
class AdminBadge extends StatelessWidget {
  const AdminBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fg = color ?? colorScheme.onSurfaceVariant;
    final bg = backgroundColor ?? fg.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Card for list items: title, subtitle, optional leading, and multiple badges.
/// Use for data-focused admin lists.
class AdminListCard extends StatelessWidget {
  const AdminListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.statusLabel,
    this.statusColor,
    this.badges,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final String? statusLabel;
  final Color? statusColor;
  /// Multiple badges (e.g. status, category, date). Shown in a row; overrides statusLabel if non-null.
  final List<AdminBadgeData>? badges;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeList = badges ?? (statusLabel != null ? [AdminBadgeData(statusLabel!, color: statusColor)] : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (badgeList != null && badgeList.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: badgeList.map((b) => AdminBadge(
                          label: b.label,
                          color: b.color,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

int get defaultAdminPageSize => _defaultPageSize;

/// Returns a paginated slice of [list] for [pageIndex] and [pageSize].
List<T> paginate<T>(List<T> list, int pageIndex, int pageSize) {
  if (list.isEmpty) return [];
  final start = (pageIndex * pageSize).clamp(0, list.length);
  final end = (start + pageSize).clamp(0, list.length);
  return list.sublist(start, end);
}
