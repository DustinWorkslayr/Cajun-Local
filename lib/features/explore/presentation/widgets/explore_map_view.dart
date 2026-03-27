import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

// Baton Rouge area — used as map center and base for synthetic marker positions.
const _mapCenter = LatLng(30.4515, -91.1871);

class ExploreMapView extends StatefulWidget {
  const ExploreMapView({super.key, required this.list, this.subcategoryNames = const {}});

  final List<Business> list;
  final Map<String, String> subcategoryNames;

  @override
  State<ExploreMapView> createState() => _ExploreMapViewState();
}

class _ExploreMapViewState extends State<ExploreMapView> {
  int? _selectedIndex;

  static LatLng _positionForIndex(int index) {
    const radius = 0.012;
    final angle = index * 0.7;
    return LatLng(_mapCenter.latitude + radius * cos(angle), _mapCenter.longitude + radius * sin(angle));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = widget.list;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: 13.5,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            onTap: (_, _) {
              if (_selectedIndex != null) setState(() => _selectedIndex = null);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sitesnapps.cajunlocal',
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < list.length; i++)
                  Marker(
                    point: _positionForIndex(i),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = _selectedIndex == i ? null : i),
                      child: SvgPicture.asset(
                        'assets/images/map pin icon.svg',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_selectedIndex != null && _selectedIndex! < list.length)
          DraggableScrollableSheet(
            initialChildSize: 0.36,
            minChildSize: 0.14,
            maxChildSize: 0.58,
            builder: (context, scrollController) {
              final listing = list[_selectedIndex!];
              const double? rating = null; // Business model doesn't have rating yet
              const String? ratingStr = null;
              const String categorySubLine = 'Business';

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.specNavy.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (listing.tagline != null && listing.tagline!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  listing.tagline!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.specNavy.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  categorySubLine,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) {
                                      final filled = rating != null && i < (rating).floor().clamp(0, 5);
                                      return Icon(
                                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 20,
                                        color: AppTheme.specGold,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ratingStr ?? 'No reviews',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: ratingStr != null ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _selectedIndex = null),
                          color: AppTheme.specNavy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      onPressed: () {
                        final id = listing.id;
                        setState(() => _selectedIndex = null);
                        context.push('/listing/$id');
                      },
                      expanded: false,
                      child: const Text('View listing'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
