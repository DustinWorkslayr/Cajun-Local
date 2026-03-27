import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/business_hours.dart';
import 'package:cajun_local/features/businesses/data/models/business_link.dart';

/// Reusable section header used across business detail tabs.
class BdSection extends StatelessWidget {
  const BdSection({super.key, required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppTheme.specNavy),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
      ]),
      const SizedBox(height: 12),
      child,
    ]);
  }
}

/// Contact info block: address, phone, website rows, each tappable.
class BdContactBlock extends StatelessWidget {
  const BdContactBlock({super.key, required this.listing});
  final Business listing;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (listing.address != null)
        _Row(icon: Icons.location_on_rounded, text: listing.address!, onTap: () => _open('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(listing.address!)}')),
      if (listing.phone != null)
        _Row(icon: Icons.phone_rounded, text: listing.phone!, onTap: () => _open('tel:${listing.phone}')),
      if (listing.website != null)
        _Row(icon: Icons.language_rounded, text: listing.website!, onTap: () => _open(listing.website!)),
    ]);
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text, this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: AppTheme.specNavy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.specOutline.withValues(alpha: 0.5)),
          ]),
        ),
      );
}

/// Business hours list — highlights today's row.
class BdHoursBlock extends StatelessWidget {
  const BdHoursBlock({super.key, required this.hours});
  final List<BusinessHours> hours;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final today = _days[DateTime.now().weekday - 1];
    final sorted = [...hours]..sort((a, b) => _days.indexOf(a.dayOfWeek) - _days.indexOf(b.dayOfWeek));

    return Column(
      children: [
        const SizedBox(height: 8),
        ...sorted.map((h) {
          final isToday = h.dayOfWeek.toLowerCase() == today.toLowerCase();
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isToday
                ? BoxDecoration(
                    color: AppTheme.specSurfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Row(children: [
              SizedBox(
                width: 90,
                child: Text(
                  h.dayOfWeek.toUpperCase(),
                  style: TextStyle(
                    color: isToday ? AppTheme.specNavy : AppTheme.specOutline,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  h.isClosed == true ? 'CLOSED' : '${_f(h.openTime)} – ${_f(h.closeTime)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: h.isClosed == true ? AppTheme.specRed : AppTheme.specNavy,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.specNavy, borderRadius: BorderRadius.circular(6)),
                  child: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                ),
              ],
            ]),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  String _f(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $ampm';
    } catch (_) {
      return time;
    }
  }
}

/// Tap-to-open-maps placeholder. Used when lat/lng is available.
class BdMapPlaceholder extends StatelessWidget {
  const BdMapPlaceholder({super.key, required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppTheme.specSurfaceContainer,
            border: Border.all(color: AppTheme.specSurfaceContainerHigh),
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.map_rounded, size: 36, color: AppTheme.specOutline),
              const SizedBox(height: 6),
              const Text('Open in Maps', style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
      );
}

/// Social & external links as wrap of pill chips.
class BdSocialLinks extends StatelessWidget {
  const BdSocialLinks({super.key, required this.links});
  final List<BusinessLink> links;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: links.map((l) {
          final label = l.label?.isNotEmpty == true ? l.label! : l.url;
          return InkWell(
            onTap: () async {
              final uri = Uri.parse(l.url);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.specSurfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.link_rounded, size: 14, color: AppTheme.specOutline),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          );
        }).toList(),
      );
}

/// Reusable empty-state for tabs with no data.
class BdEmptyState extends StatelessWidget {
  const BdEmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 44, color: AppTheme.specOutline.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: AppTheme.specOutline, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
}
