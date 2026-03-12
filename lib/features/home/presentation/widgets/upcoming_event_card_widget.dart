import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/theme/theme.dart';

class UpcomingEventCardWidget extends StatelessWidget {
  const UpcomingEventCardWidget({
    super.key,
    required this.event,
    required this.businessName,
    required this.onTap,
  });

  final MockEvent event;
  final String businessName;
  final VoidCallback onTap;

  static const _cardWidth = 200.0;
  static const _radius = 14.0;

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
    final dateStr = _formatDate(event.eventDate);

    const double cardHeight = 112.0;
    return SizedBox(
      width: _cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.specGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  businessName,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
