import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/stripe/stripe_checkout_service.dart';
import 'package:my_app/core/stripe/stripe_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/my_listings/presentation/screens/create_listing_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/listing_edit_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/subscription_upsell_popup.dart';
import 'package:my_app/core/subscription/resolved_permissions.dart';
import 'package:url_launcher/url_launcher.dart';

/// List of businesses owned by the current user. Brand theme (specOffWhite, specNavy, specGold).
/// When [embeddedInShell] is true, only the list body is built (nav and app bar from MainShell).
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({
    super.key,
    this.embeddedInShell = false,
    this.onBack,
  });

  final bool embeddedInShell;
  final VoidCallback? onBack;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  static const double _cardRadius = 16;

  Future<(MockUser, List<MockListing>)> _loadListings() {
    final dataSource = AppDataScope.of(context).dataSource;
    return dataSource.getCurrentUser().then((user) => Future.wait(
          user.ownedListingIds.map((id) => dataSource.getListingById(id)),
        ).then((list) => (
              user,
              list.whereType<MockListing>().toList(),
            )));
  }

  late Future<(MockUser, List<MockListing>)> _listingsFuture = _loadListings();

  /// Add/request a listing — only for Cajun+ (canSubmitBusiness). Otherwise we show upsell.
  void _onAddBusiness() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const CreateListingScreen()))
        .then((_) {
      if (mounted) setState(() => _listingsFuture = _loadListings());
    });
  }

  /// Start Stripe checkout for Cajun+ (user subscription). Used by upsell CTA.
  Future<void> _startCajunPlusCheckout() async {
    if (!mounted) return;
    final scope = AppDataScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening checkout…')),
    );
    try {
      final plans = await UserPlansRepository().list();
      if (!mounted) return;
      final tier = StripeConfig.defaultUserTier;
      final matching = plans.where((p) => p.tier.toLowerCase() == tier).toList();
      final plan = matching.isEmpty ? null : matching.first;
      if (plan == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subscription plan available. Please try again later.')),
        );
        return;
      }
      final planId = plan.id;
      final useYearly = StripeConfig.defaultUserInterval == 'yearly';
      String? priceId = useYearly ? plan.stripePriceIdYearly : plan.stripePriceIdMonthly;
      if (priceId == null || priceId.isEmpty) {
        final fallback = StripeConfig.userPlans[tier];
        priceId = useYearly ? fallback?.yearly : fallback?.monthly;
      }
      if (priceId == null || priceId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription not configured. Add Stripe Price IDs in Admin → Plans.')),
        );
        return;
      }
      if (priceId.contains('placeholder')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription not configured. Add real Stripe Price IDs in Admin → Plans (replace placeholders).',
            ),
          ),
        );
        return;
      }
      final stripe = StripeCheckoutService();
      final url = await stripe.createCheckoutSession(
        priceId: priceId,
        mode: 'subscription',
        successUrl: StripeCheckoutService.successUrl(),
        cancelUrl: StripeCheckoutService.cancelUrl(),
        metadata: {
          'type': 'user_subscription',
          'reference_id': planId,
        },
      );
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        scope.userTierService.refresh();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open browser. URL: $url')),
        );
      }
    } on StripeCheckoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout: ${e.message}')),
      );
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Stripe checkout error: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }
  }

  void _showCajunPlusUpsell() {
    SubscriptionUpsellPopup.show(
      context,
      onSubscribe: () {
        Navigator.of(context).pop();
        _startCajunPlusCheckout();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final userTierService = AppDataScope.of(context).userTierService;

    Widget content = ValueListenableBuilder<ResolvedPermissions?>(
      valueListenable: userTierService.permissions,
      builder: (_, perms, _) {
        final canAddListing = perms?.canSubmitBusiness ?? false;

        return FutureBuilder<(MockUser, List<MockListing>)>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
              return Container(
                color: AppTheme.specOffWhite,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.specNavy),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your listings…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final listings = snapshot.data?.$2 ?? const <MockListing>[];

            if (listings.isEmpty) {
              if (canAddListing) {
                return _GetStartedView(padding: padding, onAddBusiness: _onAddBusiness);
              }
              return _GetStartedUpsellView(
                padding: padding,
                onGetCajunPlus: _showCajunPlusUpsell,
              );
            }

            return Container(
              color: AppTheme.specOffWhite,
              child: CustomScrollView(
                slivers: [
                  // ——— Header ———
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, widget.embeddedInShell ? 12 : 24, padding.right, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Listings',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.specNavy,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage your business listings. Tap one to edit details, menu, deals, and more.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.75),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 4,
                              width: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.specGold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (canAddListing)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AppSecondaryButton(
                                  onPressed: _onAddBusiness,
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text('Add new'),
                                ),
                              )
                            else
                              _CajunPlusUpsellCard(
                                onTap: _showCajunPlusUpsell,
                                compact: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              // ——— List of listing cards ———
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, padding.right),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = listings[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AnimatedEntrance(
                          delay: Duration(milliseconds: 50 + (index * 40)),
                          child: _ListingCard(
                            listing: listing,
                            cardRadius: _cardRadius,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ListingEditScreen(listingId: listing.id),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    childCount: listings.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
          },
        );
      },
    );

    if (widget.embeddedInShell) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(
          'My Listings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: content,
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.cardRadius,
    required this.onTap,
  });

  final MockListing listing;
  final double cardRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppTheme.specNavy,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing.address != null && listing.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        listing.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (listing.categoryName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.specNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.categoryName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specNavy,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.specNavy.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GetStartedView extends StatelessWidget {
  const _GetStartedView({required this.padding, required this.onAddBusiness});

  final EdgeInsets padding;
  final VoidCallback onAddBusiness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppTheme.specOffWhite,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding.left + 24, 32, padding.right + 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 64,
                  color: AppTheme.specNavy,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Get started with My Listings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.specNavy,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your business to the directory so customers can find you. You can then manage your listing, menu, deals, and events in one place.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                height: 4,
                width: 56,
                decoration: BoxDecoration(
                  color: AppTheme.specGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              AppSecondaryButton(
                onPressed: onAddBusiness,
                icon: const Icon(Icons.add_business_rounded, size: 22),
                label: const Text('Add your business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when user does not have Cajun+: advertise upgrade to add a listing.
class _GetStartedUpsellView extends StatelessWidget {
  const _GetStartedUpsellView({
    required this.padding,
    required this.onGetCajunPlus,
  });

  final EdgeInsets padding;
  final VoidCallback onGetCajunPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppTheme.specOffWhite,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding.left + 24, 32, padding.right + 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 64,
                  color: AppTheme.specNavy,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'My Listings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.specNavy,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your business to the directory so customers can find you. Request a listing and we’ll review it—then you can manage your listing, menu, deals, and events in one place.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _CajunPlusUpsellCard(onTap: onGetCajunPlus, compact: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cajun+ upsell card: tap to open subscription popup / checkout.
class _CajunPlusUpsellCard extends StatelessWidget {
  const _CajunPlusUpsellCard({
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: AppTheme.specGold, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Cajun+ to add another listing',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Request new businesses for approval. \$2.99/mo.',
                        style: theme.textTheme.bodySmall?.copyWith(color: sub),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sub),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: AppTheme.specNavy, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cajun+ Membership',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: nav,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add & request business listings',
                      style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'With Cajun+ you can submit new businesses for approval. Once approved, you’ll manage your listing, menu, deals, and events here. You also get exclusive deals, unlimited favorites, and Ask Local.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: sub,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            onPressed: onTap,
            icon: const Icon(Icons.workspace_premium_rounded, size: 20),
            label: const Text('Get Cajun+ · \$2.99/mo'),
          ),
        ],
      ),
    );
  }
}
