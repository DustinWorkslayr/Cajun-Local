import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/revenuecat/present_subscription_paywall.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/core/data/deal_type_icons.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/listing/presentation/providers/listing_detail_provider.dart';
import 'package:cajun_local/features/listing/presentation/screens/claim_business_screen.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_shared.dart';
import 'package:cajun_local/features/messaging/presentation/screens/conversation_thread_screen.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/contact_form_widget.dart';
import 'package:cajun_local/shared/widgets/deal_detail_popup.dart';

class BdInfoTab extends StatelessWidget {
  const BdInfoTab({
    super.key,
    required this.listing,
    required this.data,
    required this.isSignedIn,
    required this.currentUserId,
    required this.onReload,
  });

  final Business listing;
  final ListingDetailData data;
  final bool isSignedIn;
  final String? currentUserId;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final hasContact = listing.address != null || listing.phone != null || listing.website != null;
    final hasHours = data.businessHours.isNotEmpty;
    final hasSocial = data.socialLinks.isNotEmpty;
    final hasMap = data.listingLatitude != null && data.listingLongitude != null;
    final hasPendingClaim = data.userClaim?.status == 'pending';
    final hasApprovedClaim = data.userClaim?.status == 'approved';
    final showClaim = listing.isClaimable == true && isSignedIn && !hasApprovedClaim;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── About / Description ──────────────────────────────────────
        if (listing.description?.isNotEmpty == true) ...[
          _InfoCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            child: Text(
              listing.description!,
              style: const TextStyle(color: AppTheme.specNavy, fontSize: 15, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Contact Information ──────────────────────────────────────
        if (hasContact) ...[
          _InfoCard(
            title: 'Contact',
            icon: Icons.contact_phone_rounded,
            child: BdContactBlock(listing: listing),
          ),
          const SizedBox(height: 16),
        ],

        // ── Business Hours ───────────────────────────────────────────
        if (hasHours) ...[
          _InfoCard(
            title: 'Hours',
            icon: Icons.schedule_outlined,
            padding: EdgeInsets.zero,
            child: BdHoursBlock(hours: data.businessHours),
          ),
          const SizedBox(height: 16),
        ],

        // ── Map Preview ──────────────────────────────────────────────
        if (hasMap) ...[
          _InfoCard(
            title: 'Location',
            icon: Icons.map_outlined,
            padding: EdgeInsets.zero,
            child: BdMapPlaceholder(lat: data.listingLatitude!, lng: data.listingLongitude!),
          ),
          const SizedBox(height: 16),
        ],

        // ── Social & Links ───────────────────────────────────────────
        if (hasSocial) ...[
          _InfoCard(
            title: 'Social & Links',
            icon: Icons.link_rounded,
            child: BdSocialLinks(links: data.socialLinks),
          ),
          const SizedBox(height: 16),
        ],

        // ── Contact Form (Directly on background or in card?) ────────
        ContactFormWidget(
          businessId: listing.id,
          businessName: listing.name,
          isSignedIn: isSignedIn,
          onConversationStarted: (id) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ConversationThreadScreen(conversationId: id, businessName: listing.name)),
            );
          },
        ),

        // ── Claim Section ────────────────────────────────────────────
        if (showClaim) ...[
          const SizedBox(height: 16),
          _ClaimSection(listing: listing, hasPendingClaim: hasPendingClaim, currentUserId: currentUserId, onReload: onReload),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.child, this.padding});
  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1D).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.specGold),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ClaimSection extends StatelessWidget {
  const _ClaimSection({required this.listing, required this.hasPendingClaim, required this.currentUserId, required this.onReload});
  final Business listing;
  final bool hasPendingClaim;
  final String? currentUserId;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.specSurfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.specSurfaceContainerHigh),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.business_center_rounded, size: 20, color: AppTheme.specNavy),
            const SizedBox(width: 8),
            const Text('Own this business?', style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
          const SizedBox(height: 8),
          Text(
            hasPendingClaim ? 'Your claim is under review — we\'ll reach out soon.' : 'Claim this listing to manage your business on Cajun Local.',
            style: TextStyle(color: AppTheme.specOnSurfaceVariant, fontSize: 13, height: 1.5),
          ),
          if (!hasPendingClaim && currentUserId != null) ...[
            const SizedBox(height: 14),
            AppSecondaryButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => ClaimBusinessScreen(businessId: listing.id, businessName: listing.name, userId: currentUserId!)),
                );
                if (ok == true) onReload();
              },
              child: const Text('Claim This Business'),
            ),
          ],
        ]),
      );
}

/// The "Deals" tab — list of deal cards.
class BdDealsTab extends ConsumerStatefulWidget {
  const BdDealsTab({super.key, required this.listingId, required this.listingName, required this.deals, required this.isSignedIn});
  final String listingId;
  final String listingName;
  final List<Deal> deals;
  final bool isSignedIn;

  @override
  ConsumerState<BdDealsTab> createState() => _BdDealsTabState();
}

class _BdDealsTabState extends ConsumerState<BdDealsTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.deals.isEmpty) return const BdEmptyState(icon: Icons.local_offer_outlined, message: 'No active deals');

    return Column(
      children: widget.deals.map((deal) {
        return Padding(
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
                child: Icon(DealTypeIcons.iconFor(deal.dealType), size: 20, color: AppTheme.specNavy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(deal.title, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 14)),
                  if (deal.description?.isNotEmpty == true)
                    Text(deal.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.specOutline, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => DealDetailPopup.show(
                  context,
                  deal: deal,
                  listingName: widget.listingName,
                  showViewBusinessButton: false,
                  isClaimed: false,
                  isUsed: false,
                  usedAt: null,
                  onClaim: widget.isSignedIn
                      ? () async {
                          final uid = ref.read(authControllerProvider).valueOrNull?.id;
                          if (uid == null) return;
                          final canClaim = ref.read(userTierServiceProvider).value?.canClaimDeals ?? false;
                          if (!canClaim) {
                            await presentSubscriptionPaywall(context, ref);
                            return;
                          }
                          await ref.read(userDealsRepositoryProvider).claim(uid, deal.id);
                        }
                      : null,
                  onClaimUpsell: widget.isSignedIn ? () => presentSubscriptionPaywall(context, ref) : null,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(10)),
                  child: const Text('View', style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
