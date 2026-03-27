import 'package:flutter/material.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/features/events/data/models/business_event.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:cajun_local/features/listing/presentation/providers/listing_detail_provider.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_shared.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_tabs.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_menu_tab.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_reviews_tab.dart';

/// Stateful tab switcher + body. Sits below the floating info card.
class BusinessDetailBody extends StatefulWidget {
  const BusinessDetailBody({
    super.key,
    required this.data,
    required this.currentUserId,
    required this.isTablet,
    required this.onReload,
  });

  final ListingDetailData data;
  final String? currentUserId;
  final bool isTablet;
  final VoidCallback onReload;

  @override
  State<BusinessDetailBody> createState() => _BusinessDetailBodyState();
}

class _BusinessDetailBodyState extends State<BusinessDetailBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final listing = data.listing;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── Featured deal teaser ───────────────────────────────────────
      if (data.deals.isNotEmpty) _FeaturedDealBanner(deal: data.deals.first),
      if (data.deals.isNotEmpty) const SizedBox(height: 16),

      // ── Tab strip ─────────────────────────────────────────────────
      _TabStrip(selected: _tab, onChanged: (i) => setState(() => _tab = i)),
      const SizedBox(height: 20),

      // ── Tab body ──────────────────────────────────────────────────
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_tab),
          child: switch (_tab) {
            0 => BdInfoTab(
                listing: listing,
                data: data,
                isSignedIn: widget.currentUserId != null,
                currentUserId: widget.currentUserId,
                onReload: widget.onReload,
              ),
            1 => BdDealsTab(
                listingId: listing.id,
                listingName: listing.name,
                deals: data.deals,
                isSignedIn: widget.currentUserId != null,
              ),
            2 => BusinessDetailMenuTab(menuItems: data.menuItems),
            _ => BusinessDetailReviewsTab(
                reviews: data.reviews,
                averageRating: data.averageRating,
                reviewCount: data.reviewCount,
              ),
          },
        ),
      ),

      // ── Punch cards ───────────────────────────────────────────────
      if (data.punchCards.isNotEmpty) ...[
        const SizedBox(height: 28),
        BdSection(
          title: 'Punch Cards',
          icon: Icons.loyalty_rounded,
          child: _PunchCardList(cards: data.punchCards),
        ),
      ],

      // ── Events ────────────────────────────────────────────────────
      if (data.events.isNotEmpty) ...[
        const SizedBox(height: 28),
        BdSection(
          title: 'Events',
          icon: Icons.event_rounded,
          child: _EventList(events: data.events),
        ),
      ],
    ]);
  }
}

// ── Featured deal banner ──────────────────────────────────────────────────────
class _FeaturedDealBanner extends StatelessWidget {
  const _FeaturedDealBanner({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.specGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.40)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.specNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.local_offer_rounded, size: 18, color: AppTheme.specNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deal.title, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 14)),
              if (deal.description?.isNotEmpty == true)
                Text(deal.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.specOutline, fontSize: 12)),
            ]),
          ),
        ]),
      );
}

// ── Tab strip ─────────────────────────────────────────────────────────────────
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Info', 'Deals', 'Menu', 'Reviews'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.specSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppTheme.specGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.specOutline,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Punch card list ───────────────────────────────────────────────────────────
class _PunchCardList extends StatelessWidget {
  const _PunchCardList({required this.cards});
  final List<PunchCardProgram> cards;

  @override
  Widget build(BuildContext context) => Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF191C1D).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Icon(Icons.loyalty_rounded, size: 28, color: AppTheme.specGold),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title ?? 'Punch Card', style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 14)),
                Text('${c.punchesRequired} punches to get: ${c.rewardDescription}', style: const TextStyle(color: AppTheme.specOutline, fontSize: 12)),
              ])),
            ]),
          ),
        )).toList(),
      );
}

// ── Event list ────────────────────────────────────────────────────────────────
class _EventList extends StatelessWidget {
  const _EventList({required this.events});
  final List<BusinessEvent> events;

  @override
  Widget build(BuildContext context) => Column(
        children: events.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF191C1D).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.event_rounded, size: 22, color: AppTheme.specNavy),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 14)),
                Text('${e.eventDate.month}/${e.eventDate.day}/${e.eventDate.year}', style: const TextStyle(color: AppTheme.specOutline, fontSize: 12)),
              ])),
            ]),
          ),
        )).toList(),
      );
}
