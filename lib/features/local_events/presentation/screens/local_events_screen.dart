import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business_event.dart';
import 'package:my_app/core/data/models/event_rsvp.dart';
import 'package:my_app/core/data/repositories/business_events_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/event_rsvps_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';

/// Local Events — approved events from all businesses. Theme aligned with home/news.
/// Shows "My RSVPs" when signed in and RSVP chips on each event card.
class LocalEventsScreen extends StatefulWidget {
  const LocalEventsScreen({super.key});

  @override
  State<LocalEventsScreen> createState() => _LocalEventsScreenState();
}

class _LocalEventsScreenState extends State<LocalEventsScreen> {
  final _rsvpRepo = EventRsvpsRepository();
  Map<String, String> _myStatusByEventId = {};
  bool _myRsvpsLoaded = false;

  Future<void> _loadMyRsvps() async {
    final list = await _rsvpRepo.listMyRsvps();
    if (!mounted) return;
    setState(() {
      _myStatusByEventId = {for (var r in list) r.eventId: r.status};
      _myRsvpsLoaded = true;
    });
  }

  Future<void> _setRsvp(String eventId, String status) async {
    await _rsvpRepo.upsert(eventId: eventId, status: status);
    if (mounted) setState(() => _myStatusByEventId[eventId] = status);
  }

  static String formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(d.year, d.month, d.day);
    if (eventDay == today) return 'Today';
    final tomorrow = today.add(const Duration(days: 1));
    if (eventDay == tomorrow) return 'Tomorrow';
    return '${d.month}/${d.day}/${d.year}';
  }

  static String formatTime(DateTime d) {
    final hour = d.hour;
    final minute = d.minute;
    if (hour == 0 && minute == 0) return '';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    final am = hour < 12 ? 'AM' : 'PM';
    return '$h$m $am';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_myRsvpsLoaded &&
        AppDataScope.of(context).authRepository.currentUserId != null) {
      _loadMyRsvps();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Events',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.specNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Happenings from businesses near you.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, padding.right),
            sliver: FutureBuilder<List<EventRsvp>>(
              future: AppDataScope.of(context).authRepository.currentUserId != null
                  ? _rsvpRepo.listMyRsvps()
                  : Future.value(<EventRsvp>[]),
              builder: (context, myRsvpsSnapshot) {
                final myRsvps = myRsvpsSnapshot.data ?? [];
                if (myRsvps.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: FutureBuilder<Map<String, (BusinessEvent?, String)>>(
                    future: _loadMyRsvpsWithDetails(myRsvps),
                    builder: (context, detailsSnapshot) {
                      if (detailsSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !detailsSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final details = detailsSnapshot.data ?? {};
                      if (details.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My RSVPs',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...details.entries.map((e) {
                            final eventId = e.key;
                            final event = e.value.$1;
                            final businessName = e.value.$2;
                            if (event == null) return const SizedBox.shrink();
                            final status = _myStatusByEventId[eventId] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: AppTheme.specWhite,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ListingDetailScreen(
                                          listingId: event.businessId,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.title,
                                                style: theme.textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.specNavy,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                businessName,
                                                style: theme.textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppTheme.specNavy
                                                          .withValues(alpha: 0.7),
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'going'
                                                ? Colors.green
                                                    .withValues(alpha: 0.2)
                                                : status == 'interested'
                                                    ? AppTheme.specGold
                                                        .withValues(alpha: 0.3)
                                                    : AppTheme.specNavy
                                                        .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            status == 'going'
                                                ? 'Going'
                                                : status == 'interested'
                                                    ? 'Interested'
                                                    : 'Not going',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.specNavy,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, padding.right),
            sliver: FutureBuilder<List<BusinessEvent>>(
              future: SupabaseConfig.isConfigured
                  ? BusinessEventsRepository().listApproved()
                  : Future.value(<BusinessEvent>[]),
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.connectionState == ConnectionState.waiting &&
                    !eventsSnapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.specNavy),
                      ),
                    ),
                  );
                }
                final events = eventsSnapshot.data ?? [];
                if (events.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: 56,
                              color: AppTheme.specNavy.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check back for local happenings.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final businessIds = events.map((e) => e.businessId).toSet().toList();
                return FutureBuilder<Map<String, String>>(
                  future: _loadBusinessNames(businessIds),
                  builder: (context, namesSnapshot) {
                    final names = namesSnapshot.data ?? {};
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = events[index];
                          final businessName =
                              names[event.businessId] ?? 'Local business';
                          final isFirst = index == 0;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isFirst ? 24 : 20,
                            ),
                            child: _EventCard(
                              event: event,
                              businessName: businessName,
                              featured: isFirst,
                              myRsvpStatus: _myStatusByEventId[event.id],
                              isSignedIn: AppDataScope.of(context)
                                      .authRepository
                                      .currentUserId !=
                                  null,
                              onRsvp: (status) => _setRsvp(event.id, status),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ListingDetailScreen(
                                      listingId: event.businessId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: events.length,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Future<Map<String, (BusinessEvent?, String)>> _loadMyRsvpsWithDetails(
    List<EventRsvp> rsvps,
  ) async {
    final eventsRepo = BusinessEventsRepository();
    final businessRepo = BusinessRepository();
    final map = <String, (BusinessEvent?, String)>{};
    await Future.wait(rsvps.map((r) async {
      final event = await eventsRepo.getById(r.eventId);
      String name = 'Business';
      if (event != null) {
        final b = await businessRepo.getById(event.businessId);
        name = b?.name ?? name;
      }
      map[r.eventId] = (event, name);
    }));
    return map;
  }

  static Future<Map<String, String>> _loadBusinessNames(
    List<String> businessIds,
  ) async {
    final repo = BusinessRepository();
    final map = <String, String>{};
    await Future.wait(
      businessIds.map((id) async {
        final b = await repo.getById(id);
        if (b != null) map[id] = b.name;
      }),
    );
    return map;
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.businessName,
    required this.featured,
    required this.onTap,
    this.myRsvpStatus,
    this.isSignedIn = false,
    this.onRsvp,
  });

  final BusinessEvent event;
  final String businessName;
  final bool featured;
  final VoidCallback onTap;
  final String? myRsvpStatus;
  final bool isSignedIn;
  final void Function(String status)? onRsvp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        event.imageUrl != null && event.imageUrl!.isNotEmpty;
    final dateStr = _LocalEventsScreenState.formatDate(event.eventDate);
    final timeStr = _LocalEventsScreenState.formatTime(event.eventDate);
    final dateTimeStr = timeStr.isEmpty ? dateStr : '$dateStr · $timeStr';
    final description = event.description?.trim() ?? '';
    final excerpt = description.length > 120
        ? '${description.substring(0, 120).trim()}…'
        : description;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                AspectRatio(
                  aspectRatio: featured ? 2.1 : 1.85,
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppTheme.specNavy.withValues(alpha: 0.08),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppTheme.specNavy.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.specNavy.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateTimeStr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.specGold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.location != null &&
                        event.location!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppTheme.specNavy.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.65),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        excerpt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.75),
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isSignedIn && onRsvp != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: const Text('Going'),
                            selected: myRsvpStatus == 'going',
                            onSelected: (_) => onRsvp!('going'),
                            selectedColor: Colors.green.withValues(alpha: 0.35),
                            checkmarkColor: AppTheme.specNavy,
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: myRsvpStatus == 'going'
                                  ? AppTheme.specNavy
                                  : AppTheme.specNavy.withValues(alpha: 0.8),
                              fontWeight:
                                  myRsvpStatus == 'going'
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                            ),
                          ),
                          FilterChip(
                            label: const Text('Interested'),
                            selected: myRsvpStatus == 'interested',
                            onSelected: (_) => onRsvp!('interested'),
                            selectedColor:
                                AppTheme.specGold.withValues(alpha: 0.35),
                            checkmarkColor: AppTheme.specNavy,
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: myRsvpStatus == 'interested'
                                  ? AppTheme.specNavy
                                  : AppTheme.specNavy.withValues(alpha: 0.8),
                              fontWeight:
                                  myRsvpStatus == 'interested'
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                            ),
                          ),
                          FilterChip(
                            label: const Text('Not going'),
                            selected: myRsvpStatus == 'not_going',
                            onSelected: (_) => onRsvp!('not_going'),
                            selectedColor:
                                AppTheme.specNavy.withValues(alpha: 0.15),
                            checkmarkColor: AppTheme.specNavy,
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: myRsvpStatus == 'not_going'
                                  ? AppTheme.specNavy
                                  : AppTheme.specNavy.withValues(alpha: 0.8),
                              fontWeight:
                                  myRsvpStatus == 'not_going'
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'View business',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppTheme.specGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
