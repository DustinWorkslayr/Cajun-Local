import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/features/events/data/models/business_event.dart';
import 'package:cajun_local/features/events/data/models/event_rsvp.dart';
import 'package:cajun_local/features/events/data/repositories/business_events_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';

/// Local Events — redesigned with a premium editorial aesthetic.
class LocalEventsScreen extends ConsumerStatefulWidget {
  const LocalEventsScreen({super.key});

  @override
  ConsumerState<LocalEventsScreen> createState() => _LocalEventsScreenState();
}

class _LocalEventsScreenState extends ConsumerState<LocalEventsScreen> {
  Map<String, String> _myStatusByEventId = {};
  bool _myRsvpsLoaded = false;

  Future<void> _loadMyRsvps() async {
    final list = await ref.read(eventRsvpsRepositoryProvider).listMyRsvps();
    if (!mounted) return;
    setState(() {
      _myStatusByEventId = {for (var r in list) r.eventId: r.status};
      _myRsvpsLoaded = true;
    });
  }

  Future<void> _setRsvp(String eventId, String status) async {
    await ref.read(eventRsvpsRepositoryProvider).upsert(eventId: eventId, status: status);
    if (mounted) setState(() => _myStatusByEventId[eventId] = status);
  }

  static String formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(d.year, d.month, d.day);
    if (eventDay == today) return 'Today';
    final tomorrow = today.add(const Duration(days: 1));
    if (eventDay == tomorrow) return 'Tomorrow';
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
    if (!_myRsvpsLoaded && ref.watch(authControllerProvider).valueOrNull?.id != null) {
      _loadMyRsvps();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final isSignedIn = ref.watch(authControllerProvider).valueOrNull?.id != null;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBarWidget(
        title: 'Local Events',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: AppRefreshIndicator(
        onRefresh: () async {
          if (isSignedIn) await _loadMyRsvps();
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // --- Header & My RSVPs ---
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HAPPENINGS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.specGold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upcoming in Acadiana',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.specNavy,
                        fontFamily: 'Libre Baskerville',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (isSignedIn) ...[
                      _buildMyRsvpsSection(theme),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),

            // --- Main Events List ---
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: padding.left),
              sliver: FutureBuilder<List<BusinessEvent>>(
                future: BusinessEventsRepository().listApproved(),
                builder: (context, eventsSnapshot) {
                  if (eventsSnapshot.connectionState == ConnectionState.waiting && !eventsSnapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                      ),
                    );
                  }
                  
                  final events = eventsSnapshot.data ?? [];
                  if (events.isEmpty) return _buildEmptyState(theme);

                  final businessIds = events.map((e) => e.businessId).toSet().toList();
                  return FutureBuilder<Map<String, String>>(
                    future: _loadBusinessNames(businessIds),
                    builder: (context, namesSnapshot) {
                      final names = namesSnapshot.data ?? {};
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final event = events[index];
                            final businessName = names[event.businessId] ?? 'Local Business';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: AnimatedEntrance(
                                delay: Duration(milliseconds: 100 * (index % 5)),
                                child: _EventCard(
                                  event: event,
                                  businessName: businessName,
                                  myRsvpStatus: _myStatusByEventId[event.id],
                                  isSignedIn: isSignedIn,
                                  onRsvp: (status) => _setRsvp(event.id, status),
                                  onTap: () => context.push('/listing/${event.businessId}'),
                                ),
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
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRsvpsSection(ThemeData theme) {
    return FutureBuilder<List<EventRsvp>>(
      future: ref.read(eventRsvpsRepositoryProvider).listMyRsvps(),
      builder: (context, snapshot) {
        final rsvps = snapshot.data ?? [];
        if (rsvps.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, size: 18, color: AppTheme.specGold),
                const SizedBox(width: 8),
                Text(
                  'My RSVPs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, (BusinessEvent?, String)>>(
              future: _loadMyRsvpsWithDetails(rsvps),
              builder: (context, detailsSnapshot) {
                final details = detailsSnapshot.data ?? {};
                if (details.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: details.entries.map((e) {
                    final event = e.value.$1;
                    final businessName = e.value.$2;
                    if (event == null) return const SizedBox.shrink();
                    final status = _myStatusByEventId[event.id] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.specWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.specNavy.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => context.push('/listing/${event.businessId}'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            event.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            businessName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withOpacity(0.6),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'going'
                                  ? Colors.green.withOpacity(0.1)
                                  : status == 'interested'
                                      ? AppTheme.specGold.withOpacity(0.15)
                                      : AppTheme.specNavy.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status == 'going' ? 'Going' : status == 'interested' ? 'Interested' : 'RSVP',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: status == 'going'
                                    ? Colors.green[700]
                                    : status == 'interested'
                                        ? AppTheme.specGold
                                        : AppTheme.specNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.specNavy.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_rounded, size: 48, color: AppTheme.specNavy.withOpacity(0.3)),
              ),
              const SizedBox(height: 20),
              Text(
                'No upcoming events',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.specNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for local happenings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, (BusinessEvent?, String)>> _loadMyRsvpsWithDetails(List<EventRsvp> rsvps) async {
    final eventsRepo = BusinessEventsRepository();
    final businessRepo = BusinessRepository();
    final map = <String, (BusinessEvent?, String)>{};
    await Future.wait(
      rsvps.map((r) async {
        final event = await eventsRepo.getById(r.eventId);
        String name = 'Business';
        if (event != null) {
          final b = await businessRepo.getById(event.businessId);
          name = b?.name ?? name;
        }
        map[r.eventId] = (event, name);
      }),
    );
    return map;
  }

  static Future<Map<String, String>> _loadBusinessNames(List<String> businessIds) async {
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
    required this.onTap,
    this.myRsvpStatus,
    this.isSignedIn = false,
    this.onRsvp,
  });

  final BusinessEvent event;
  final String businessName;
  final VoidCallback onTap;
  final String? myRsvpStatus;
  final bool isSignedIn;
  final void Function(String status)? onRsvp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;
    final dateStr = _LocalEventsScreenState.formatDate(event.eventDate);
    final timeStr = _LocalEventsScreenState.formatTime(event.eventDate);
    final description = event.description?.trim() ?? '';
    final excerpt = description.length > 140 ? '${description.substring(0, 140).trim()}…' : description;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.specNavy.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppTheme.specNavy.withOpacity(0.05)),
                    errorWidget: (_, _, _) => Container(color: AppTheme.specNavy.withOpacity(0.05)),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dateStr.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.specNavy,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            businessName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.specGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (timeStr.isNotEmpty || (event.location != null && event.location!.isNotEmpty))
                  Row(
                    children: [
                      if (timeStr.isNotEmpty) ...[
                        Icon(Icons.access_time_filled_rounded, size: 16, color: AppTheme.specNavy.withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.specNavy.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        Icon(Icons.location_on_rounded, size: 16, color: AppTheme.specNavy.withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                if (excerpt.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    excerpt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (isSignedIn && onRsvp != null) ...[
                  Row(
                    children: [
                      _RsvpButton(
                        label: 'Going',
                        isSelected: myRsvpStatus == 'going',
                        onTap: () => onRsvp!('going'),
                        activeColor: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _RsvpButton(
                        label: 'Interested',
                        isSelected: myRsvpStatus == 'interested',
                        onTap: () => onRsvp!('interested'),
                        activeColor: AppTheme.specGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                InkWell(
                  onTap: onTap,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_alt_rounded, color: AppTheme.specGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'View Details',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.specGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? activeColor : AppTheme.specNavy.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? activeColor : AppTheme.specNavy.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.specNavy.withOpacity(0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
