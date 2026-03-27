import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/notifications/data/repositories/user_notification_preferences_repository.dart';
import 'package:cajun_local/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cajun_local/features/profile/presentation/widgets/profile_sections.dart';

class ProfilePreferencesSection extends ConsumerStatefulWidget {
  const ProfilePreferencesSection({super.key, this.onHandleNotificationActionUrl});

  final bool Function(String actionUrl)? onHandleNotificationActionUrl;

  @override
  ConsumerState<ProfilePreferencesSection> createState() => _ProfilePreferencesSectionState();
}

class _ProfilePreferencesSectionState extends ConsumerState<ProfilePreferencesSection> {
  bool _notificationsDeals = true;
  bool _notificationsListings = true;
  bool _notificationsReminders = false;
  bool _notificationsNews = true;
  bool _notificationsEvents = true;
  bool _loaded = false;

  final _repo = UserNotificationPreferencesRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final uid = ref.watch(authControllerProvider).valueOrNull?.id;
      if (uid != null) {
        _loaded = true;
        _loadPrefs(uid);
      }
    }
  }

  Future<void> _loadPrefs(String uid) async {
    final prefs = await _repo.get(uid);
    if (mounted) {
      setState(() {
        _notificationsDeals = prefs.dealsEnabled;
        _notificationsListings = prefs.listingsEnabled;
        _notificationsReminders = prefs.remindersEnabled;
        _notificationsNews = prefs.newsEnabled;
        _notificationsEvents = prefs.eventsEnabled;
      });
    }
  }

  Future<void> _savePrefs() async {
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (uid == null) return;
    await _repo.save(
      uid,
      UserNotificationPreferences(
        dealsEnabled: _notificationsDeals,
        listingsEnabled: _notificationsListings,
        remindersEnabled: _notificationsReminders,
        newsEnabled: _notificationsNews,
        eventsEnabled: _notificationsEvents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    return ProfileSectionCard(
      title: 'NOTIFICATIONS',
      children: [
        _NotificationToggleListTile(
          title: 'Deals & Promotions',
          subtitle: 'Offers at saved businesses',
          value: _notificationsDeals,
          onChanged: (v) {
            setState(() => _notificationsDeals = v);
            _savePrefs();
          },
        ),
        _NotificationToggleListTile(
          title: 'Events & News',
          subtitle: 'Local articles and happening',
          value: _notificationsEvents,
          onChanged: (v) {
            setState(() => _notificationsEvents = v);
            setState(() => _notificationsNews = v);
            _savePrefs();
          },
        ),
        _NotificationToggleListTile(
          title: 'Reminders',
          subtitle: 'Punch card and favorite updates',
          value: _notificationsReminders,
          onChanged: (v) {
            setState(() => _notificationsReminders = v);
            _savePrefs();
          },
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NotificationsScreen(onHandleActionUrl: widget.onHandleNotificationActionUrl),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 20, color: AppTheme.specNavy.withValues(alpha: 0.7)),
                  const SizedBox(width: 12),
                  Text(
                    'Manage all notifications',
                    style: TextStyle(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationToggleListTile extends StatelessWidget {
  const _NotificationToggleListTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.specNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.specGold,
            activeTrackColor: AppTheme.specGold.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
