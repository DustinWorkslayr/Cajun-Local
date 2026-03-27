import 'package:flutter/material.dart';
import 'package:cajun_local/features/home/data/models/home_models.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// "This week in Acadiana" hot-offer card — matches Stitch v2 grid card exactly:
/// Icon in secondary-container rounded-xl, discount badge, bold title, subtitle.
/// Two variants: light (white bg) and featured (navy bg).
class UpcomingEventCardWidget extends StatelessWidget {
  const UpcomingEventCardWidget({
    super.key,
    required this.event,
    required this.onTap,
    this.featured = false,
  });

  final HomeEvent event;
  final VoidCallback onTap;
  final bool featured;

  static const _radius = 24.0;

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = d.isUtc ? d.toLocal() : d;
    final eventDay = DateTime(local.year, local.month, local.day);
    if (eventDay == today) return 'Today';
    final tomorrow = today.add(const Duration(days: 1));
    if (eventDay == tomorrow) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final w = weekdays[eventDay.weekday - 1];
    final m = months[eventDay.month - 1];
    return '$w, $m ${eventDay.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = featured ? AppTheme.specNavy : AppTheme.specWhite;
    final titleColor = featured ? Colors.white : AppTheme.specNavy;
    final subtitleColor = featured ? AppTheme.specOnPrimaryContainer : AppTheme.specOutline;
    final iconBg = featured ? AppTheme.specNavyContainer : AppTheme.specSecondaryContainer;
    final iconColor = featured ? AppTheme.specOnPrimaryContainer : AppTheme.specNavy;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1D).withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_rounded,
                    size: 22,
                    color: iconColor,
                  ),
                ),
                if (!featured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDate(event.eventDate),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF93000A),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  event.businessName,
                  style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
