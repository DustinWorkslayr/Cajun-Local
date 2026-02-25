import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/business_event.dart';
import 'package:my_app/core/data/repositories/business_events_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/event_rsvps_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Full event details + attendee/RSVP analytics for listing owner or admin.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.listingId,
  });

  final String eventId;
  final String listingId;

  static String _dateStr(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';
  static String _timeStr(DateTime d) {
    if (d.hour == 0 && d.minute == 0) return '';
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute == 0 ? '' : ':${d.minute.toString().padLeft(2, '0')}';
    return '$h$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        foregroundColor: nav,
        title: const Text('Event details'),
      ),
      body: FutureBuilder<BusinessEvent?>(
        future: SupabaseConfig.isConfigured
            ? BusinessEventsRepository().getById(eventId)
            : Future.value(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting &&
              !eventSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            );
          }
          final event = eventSnapshot.data;
          if (event == null) {
            return Center(
              child: Text(
                'Event not found',
                style: theme.textTheme.bodyLarge?.copyWith(color: nav),
              ),
            );
          }
          return FutureBuilder<(
            Business? business,
            EventRsvpCounts counts,
          )>(
            future: Future.wait([
              BusinessRepository().getById(listingId),
              EventRsvpsRepository().getCountsForEvent(eventId),
            ]).then((r) => (r[0] as Business?, r[1] as EventRsvpCounts)),
            builder: (context, dataSnapshot) {
              final business = dataSnapshot.data?.$1;
              final counts = dataSnapshot.data?.$2 ?? const EventRsvpCounts();

              return SingleChildScrollView(
                padding: padding,
                child: AppLayout.constrainSection(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (event.imageUrl != null &&
                          event.imageUrl!.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: event.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              height: 200,
                              color: nav.withValues(alpha: 0.08),
                              child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, _, _) => Container(
                              height: 200,
                              color: nav.withValues(alpha: 0.08),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: nav.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      if (event.imageUrl != null &&
                          event.imageUrl!.trim().isNotEmpty)
                        const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.specWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: nav,
                              ),
                            ),
                            if (business != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                business.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: sub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppTheme.specGold),
                                const SizedBox(width: 8),
                                Text(
                                  '${_dateStr(event.eventDate)}${_timeStr(event.eventDate).isNotEmpty ? ' · ${_timeStr(event.eventDate)}' : ''}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: nav,
                                  ),
                                ),
                              ],
                            ),
                            if (event.location != null &&
                                event.location!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 18, color: AppTheme.specGold),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location!,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: nav,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (event.description != null &&
                                event.description!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                event.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: nav,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: event.status == 'approved'
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : nav.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.status == 'approved'
                                    ? 'Approved'
                                    : 'Pending approval',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: event.status == 'approved'
                                      ? Colors.green.shade800
                                      : nav,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Attendees',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.specWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _CountRow(
                              label: 'Going',
                              count: counts.going,
                              color: Colors.green,
                            ),
                            const Divider(height: 24),
                            _CountRow(
                              label: 'Interested',
                              count: counts.interested,
                              color: AppTheme.specGold,
                            ),
                            const Divider(height: 24),
                            _CountRow(
                              label: 'Not going',
                              count: counts.notGoing,
                              color: sub,
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total responses',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: nav,
                                  ),
                                ),
                                Text(
                                  '${counts.total}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: nav,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: nav,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
