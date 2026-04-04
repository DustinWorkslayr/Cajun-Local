import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';
import 'package:cajun_local/features/messaging/data/repositories/form_submissions_repository.dart';
import 'package:cajun_local/core/stripe/stripe_checkout_service.dart';
import 'package:cajun_local/core/stripe/stripe_config.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/subscription/resolved_permissions.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/page_loader.dart';
import 'package:cajun_local/core/revenuecat/present_subscription_paywall.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cajun_local/features/profile/presentation/widgets/profile_header_widget.dart';
import 'package:cajun_local/features/profile/presentation/widgets/profile_sections.dart';
import 'package:cajun_local/features/profile/presentation/widgets/profile_preferences_section.dart';
import 'package:cajun_local/shared/widgets/app_confirmation_dialog.dart';
import 'package:cajun_local/core/extensions/buildcontext_extension.dart';

// --- Placeholder for failed loads ---
const _anonymousUser = MockUser(displayName: '', email: null, avatarUrl: null, ownedListingIds: []);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.onMyListings, this.onNavigateToHome, this.onHandleNotificationActionUrl});

  final VoidCallback? onMyListings;
  final VoidCallback? onNavigateToHome;
  final bool Function(String actionUrl)? onHandleNotificationActionUrl;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<_ProfilePageData>? _dataFuture;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _dataFuture = _loadProfileData();
    }
  }

  Future<_ProfilePageData> _loadProfileData() async {
    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      final mockUser = user != null
          ? MockUser(displayName: user.email.split('@').first, email: user.email, avatarUrl: null)
          : _anonymousUser;

      final uid = user?.id;
      final businessIdsFuture = (uid != null)
          ? BusinessManagersRepository().listBusinessIdsForUser(uid)
          : Future.value(<String>[]);

      final results = await Future.wait<dynamic>([
        Future.value(mockUser),
        businessIdsFuture,
      ]).timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException('Profile load timed out'));
      if (!mounted) return _ProfilePageData(user: _anonymousUser, isBusinessManager: false);
      final businessIds = results[1] as List<String>;
      final isBusinessManager = businessIds.isNotEmpty;
      int inboxUnreadCount = 0;
      if (businessIds.isNotEmpty) {
        inboxUnreadCount = await FormSubmissionsRepository().unreadCountForBusinesses(businessIds);
      }
      return _ProfilePageData(
        user: results[0] as MockUser,
        isBusinessManager: isBusinessManager,
        inboxUnreadCount: inboxUnreadCount,
      );
    } catch (e) {
      if (!mounted) return _ProfilePageData(user: _anonymousUser, isBusinessManager: false);
      return _ProfilePageData(user: _anonymousUser, isBusinessManager: false, loadError: 'Loading data failed.');
    }
  }

  // Stripe
  Future<void> _startStripeCheckout() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening checkout…')));
    try {
      final plans = await ref.read(userPlansRepositoryProvider).list();
      if (!mounted) return;
      final tier = StripeConfig.defaultUserTier;
      final plan = plans.where((p) => p.tier.toLowerCase() == tier).firstOrNull;
      if (plan == null) return;
      final useYearly = StripeConfig.defaultUserInterval == 'yearly';
      String? priceId = useYearly ? plan.stripePriceIdYearly : plan.stripePriceIdMonthly;
      if (priceId == null || priceId.isEmpty) {
        final fallback = StripeConfig.userPlans[tier];
        priceId = useYearly ? fallback?.yearly : fallback?.monthly;
      }
      if (priceId == null || priceId.isEmpty || priceId.contains('placeholder')) return;

      final stripe = StripeCheckoutService();
      final url = await stripe.createCheckoutSession(
        priceId: priceId,
        mode: 'subscription',
        successUrl: StripeCheckoutService.successUrl(),
        cancelUrl: StripeCheckoutService.cancelUrl(),
        metadata: {'type': 'user_subscription', 'reference_id': plan.id},
      );
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        final uid = ref.read(authControllerProvider).valueOrNull?.id;
        if (uid != null) ref.read(userTierServiceProvider).refresh(uid);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    }
  }

  Future<void> _openCustomerPortal() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening billing portal…')));
    try {
      final stripe = StripeCheckoutService();
      final url = await stripe.createCustomerPortalSession(returnUrl: StripeCheckoutService.portalReturnUrl());
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        final uid = ref.read(authControllerProvider).valueOrNull?.id;
        if (uid != null) ref.read(userTierServiceProvider).refresh(uid);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Portal failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfilePageData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Container(
            color: AppTheme.specOffWhite,
            child: const PageLoader(message: 'Loading profile…'),
          );
        }
        final data = snapshot.data!;
        return _ProfileUnifiedContent(
          user: data.user,
          isBusinessManager: data.isBusinessManager,
          inboxUnreadCount: data.inboxUnreadCount,
          onRefresh: () {
            setState(() {
              _dataFuture = _loadProfileData();
            });
          },
          onMyListings: widget.onMyListings,
          onHandleNotificationActionUrl: widget.onHandleNotificationActionUrl,
          onStartStripeCheckout: _startStripeCheckout,
          onOpenCustomerPortal: _openCustomerPortal,
        );
      },
    );
  }
}

class _ProfilePageData {
  const _ProfilePageData({
    required this.user,
    this.isBusinessManager = false,
    this.inboxUnreadCount = 0,
    this.loadError,
  });
  final MockUser user;
  final bool isBusinessManager;
  final int inboxUnreadCount;
  final String? loadError;
}

// -------------------------------------------------------------------------- //
// UNIFIED PROFILE CONTENT
// -------------------------------------------------------------------------- //

class _ProfileUnifiedContent extends ConsumerWidget {
  const _ProfileUnifiedContent({
    required this.user,
    required this.isBusinessManager,
    required this.inboxUnreadCount,
    required this.onRefresh,
    this.onMyListings,
    this.onHandleNotificationActionUrl,
    required this.onStartStripeCheckout,
    required this.onOpenCustomerPortal,
  });

  final MockUser user;
  final bool isBusinessManager;
  final int inboxUnreadCount;
  final VoidCallback onRefresh;
  final VoidCallback? onMyListings;
  final bool Function(String actionUrl)? onHandleNotificationActionUrl;
  final Future<void> Function() onStartStripeCheckout;
  final Future<void> Function() onOpenCustomerPortal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authControllerProvider).valueOrNull?.id;
    final signedIn = uid != null;
    final hasListings = user.ownedListingIds.isNotEmpty || isBusinessManager;
    final padding = AppLayout.horizontalPadding(context);

    // Main vertically scrollable master view.
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar(
          //   pinned: true,
          //   elevation: 0,
          //   scrolledUnderElevation: 2,
          //   backgroundColor: AppTheme.specOffWhite,
          //   surfaceTintColor: Colors.transparent,
          //   centerTitle: true,
          //   title: Text(
          //     'Profile',
          //     style: Theme.of(context).textTheme.titleLarge?.copyWith(
          //       fontWeight: FontWeight.w800,
          //       color: AppTheme.specNavy,
          //     ),
          //   ),
          // ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left == 0 ? 16.0 : padding.left,
              16.0,
              padding.right == 0 ? 16.0 : padding.right,
              110.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (signedIn) ProfileHeaderWidget(user: user, onRefresh: onRefresh) else _buildGuestHeader(context),

                QuickActionsRow(signedIn: signedIn, hasListings: hasListings, inboxUnreadCount: inboxUnreadCount),

                if (signedIn) ...[
                  _buildBillingSection(context, ref),
                  const SizedBox(height: 24),

                  _buildMyStuffSection(context),
                  const SizedBox(height: 24),

                  _buildBusinessSection(context, isBusinessManager),
                  const SizedBox(height: 24),

                  ProfilePreferencesSection(onHandleNotificationActionUrl: onHandleNotificationActionUrl),
                  const SizedBox(height: 24),
                ],

                _buildAboutSection(context),
                const SizedBox(height: 32),

                if (signedIn)
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.specRed,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      onPressed: () async {
                        final confirmed = await AppConfirmationDialog.show(
                          context,
                          title: 'Sign Out',
                          content: 'Are you sure you want to sign out of your account?',
                          confirmLabel: 'Sign Out',
                          isDanger: true,
                          icon: Icons.logout_rounded,
                        );

                        if (confirmed == true && context.mounted) {
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (context.mounted) {
                            context.showSuccessSnackBar('Signed out successfully');
                          }
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  Center(
                    child: AppPrimaryButton(
                      expanded: false,
                      onPressed: () => context.push('/auth/login'),
                      label: const Text('Sign In or Register'),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.specNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.account_circle_rounded, size: 64, color: AppTheme.specWhite),
          const SizedBox(height: 16),
          Text(
            'Welcome to Cajun Local',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.specWhite, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to save your favorite spots, get exclusive deals, and manage your account.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.specWhite.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSection(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<ResolvedPermissions?>(
      valueListenable: ref.read(userTierServiceProvider).permissions,
      builder: (context, perms, _) {
        final resolved = perms ?? ResolvedPermissions.free;
        final isPaid = resolved.tier == 'plus' || resolved.tier == 'pro';
        final planLabel = isPaid ? (resolved.planName ?? 'Cajun+ Membership') : 'Free';

        return ProfileSectionCard(
          title: 'SUBSCRIPTION',
          children: [
            ProfileListTile(
              icon: isPaid ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
              iconColor: isPaid ? AppTheme.specGold : null,
              title: isPaid ? planLabel : 'Upgrade to Cajun+',
              subtitle: isPaid ? 'Manage your subscription' : 'Unlock exclusive deals and Ask Local',
              onTap: () async {
                if (isPaid) {
                  final rc = ref.read(revenueCatServiceProvider);
                  if (rc != null) {
                    await rc.presentCustomerCenter(
                      onRestoreCompleted: (info) => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Purchases restored'))),
                      onRestoreFailed: (error) => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Restore failed: ${error.message}'))),
                    );
                  } else {
                    onOpenCustomerPortal();
                  }
                } else {
                  final rc = ref.read(revenueCatServiceProvider);
                  if (rc != null) {
                    await presentSubscriptionPaywall(context, ref);
                  } else {
                    onStartStripeCheckout();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyStuffSection(BuildContext context) {
    return ProfileSectionCard(
      title: 'MY STUFF',
      children: [
        ProfileListTile(
          icon: Icons.favorite_rounded,
          iconColor: AppTheme.specGold,
          title: 'My Favorites',
          subtitle: 'Businesses you have saved',
          onTap: () => context.push('/favorites'),
        ),
        ProfileListTile(
          icon: Icons.loyalty_rounded,
          title: 'My Punch Cards',
          subtitle: 'Punches and loyalty rewards',
          onTap: () => context.push('/my-punch-cards'),
        ),
        ProfileListTile(
          icon: Icons.local_offer_rounded,
          title: 'My Deals',
          subtitle: 'Redeemable offers and coupons',
          onTap: () => context.push('/my-deals'),
        ),
      ],
    );
  }

  Widget _buildBusinessSection(BuildContext context, bool isBusinessManager) {
    return ProfileSectionCard(
      title: 'BUSINESS TOOLS',
      children: [
        ProfileListTile(
          icon: Icons.store_rounded,
          title: 'My Listings & Dashboard',
          subtitle: 'Manage your profile, menu, and deals',
          onTap: () {
            if (onMyListings != null) {
              onMyListings!();
            } else {
              context.push('/my-listings');
            }
          },
        ),
        if (isBusinessManager)
          ProfileListTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan Punch Cards',
            subtitle: 'Redeem customer loyalty punches',
            onTap: () => context.push('/scan-punch-card'),
          ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return ProfileSectionCard(
      title: 'ABOUT & LEGAL',
      children: [
        ProfileListTile(
          icon: Icons.info_outline_rounded,
          title: 'About Cajun Local',
          onTap: () => context.push('/about'),
        ),
        ProfileListTile(
          icon: Icons.text_snippet_outlined,
          title: 'Privacy Policy',
          onTap: () => context.push('/privacy-policy'),
        ),
      ],
    );
  }
}
