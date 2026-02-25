import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/user_deal.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/user_deals_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/core/preferences/user_parish_preferences.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/deals/presentation/screens/my_deals_screen.dart';
import 'package:my_app/features/deals/presentation/screens/my_punch_cards_screen.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/deal_detail_popup.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/subscription_upsell_popup.dart';

/// Deal type filter options: value (null = all) and label.
const List<({String? value, String label})> _dealTypeFilterOptions = [
  (value: null, label: 'All'),
  (value: 'percentage', label: 'Percentage off'),
  (value: 'fixed', label: 'Fixed off'),
  (value: 'bogo', label: 'BOGO'),
  (value: 'freebie', label: 'Freebie'),
  (value: 'other', label: 'Other'),
  (value: 'flash', label: 'Flash'),
  (value: 'member_only', label: 'Member only'),
];

/// Deals tab — Discounts and Loyalty. Uses new theme: specOffWhite, specNavy, specGold.
class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppTheme.specOffWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Material(
              color: AppTheme.specOffWhite,
              child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.specNavy,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: AppTheme.specGold,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.local_offer_rounded, size: 20), text: 'Discounts'),
                Tab(icon: Icon(Icons.loyalty_rounded, size: 20), text: 'Loyalty'),
              ],
            ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const _DiscountsTab(),
                const _LoyaltyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const double _cardRadius = 14;

/// Section header with icon badge + title + optional subtitle (e.g. "Deals", "My deals").
class _SectionTitleBadge extends StatelessWidget {
  const _SectionTitleBadge({
    required this.icon,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.specGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppTheme.specNavy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.specNavy,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Badge shown when a deal has been redeemed/used. Checkmark + "Redeemed" for clarity.
Widget _redeemedBadge(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9), // soft green
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.6)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        Text(
          'Redeemed',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ],
    ),
  );
}

class _DiscountsTab extends StatefulWidget {
  const _DiscountsTab();

  @override
  State<_DiscountsTab> createState() => _DiscountsTabState();
}

class _DiscountsTabState extends State<_DiscountsTab> {
  List<MockDeal>? _deals;
  Map<String, UserDeal> _userDealsByDealId = {};
  bool _loading = true;
  Set<String> _parishIds = {};
  List<MockParish> _parishes = [];
  String? _categoryId;
  String? _dealType;
  List<MockCategory> _categories = [];
  bool _parishIdsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_parishIdsInitialized) {
      _parishIdsInitialized = true;
      final ds = AppDataScope.of(context).dataSource;
      Future.wait([
        UserParishPreferences.getPreferredParishIds(),
        ds.getParishes(),
      ]).then((results) {
        if (mounted) {
          setState(() {
            _parishIds = Set.from(results[0] as List<String>);
            _parishes = results[1] as List<MockParish>;
            _load();
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _parishIds = {};
            _parishes = [];
            _load();
          });
        }
      });
      return;
    }
    if (_deals == null && _loading && _parishIdsInitialized) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dataSource = AppDataScope.of(context).dataSource;
    final auth = AppDataScope.of(context).authRepository;
    final repo = UserDealsRepository(authRepository: auth);
    final uid = auth.currentUserId;

    final categories = await dataSource.getCategories();
    final results = await Future.wait([
      dataSource.getActiveDealsFiltered(
        parishIds: _parishIds,
        categoryId: _categoryId,
        dealType: _dealType,
      ),
      uid != null ? repo.listForUser(uid) : Future<List<UserDeal>>.value([]),
    ]);
    if (mounted) {
      final list = results[1] as List<UserDeal>;
      setState(() {
        _categories = categories;
        _deals = results[0] as List<MockDeal>;
        _userDealsByDealId = {for (var e in list) e.dealId: e};
        _loading = false;
      });
    }
  }

  void _openParishFilter() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Set<String> selected = Set.from(_parishIds);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter by parish',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your deals default to your preferred parishes — change them here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _parishes.map((p) {
                      final isSelected = selected.contains(p.id);
                      return FilterChip(
                        label: Text(p.name),
                        selected: isSelected,
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              selected.add(p.id);
                            } else {
                              selected.remove(p.id);
                            }
                          });
                        },
                        selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                        checkmarkColor: AppTheme.specNavy,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(() => selected = {}),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppSecondaryButton(
                          onPressed: () {
                            setState(() {
                              _parishIds = selected;
                              _load();
                            });
                            Navigator.of(ctx).pop();
                          },
                          expanded: true,
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_offer_outlined, size: 56, color: AppTheme.specRed),
              ),
              const SizedBox(height: 24),
              Text(
                'No deals here — yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different category or parish, or check back soon. Don\'t leave money on the table.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppDataScope.of(context);
    final dataSource = scope.dataSource;
    final auth = scope.authRepository;
    final userDealsRepo = UserDealsRepository(authRepository: auth);
    final uid = auth.currentUserId;
    final canClaimDeals = uid != null && (scope.userTierService.value?.canClaimDeals ?? false);
    final canSeeExclusiveDeals = scope.userTierService.value?.canSeeExclusiveDeals ?? false;
    final padding = AppLayout.horizontalPadding(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitleBadge(
                  icon: Icons.local_offer_rounded,
                  label: 'Deals',
                  subtitle: 'Your parishes, your deals. Grab \'em before they\'re gone.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _categoryId,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text('All categories', style: theme.textTheme.bodyMedium)),
                          ..._categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name, style: theme.textTheme.bodyMedium))),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _categoryId = v;
                            _load();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppOutlinedButton(
                      onPressed: _openParishFilter,
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(_parishIds.isEmpty ? 'Parishes' : '${_parishIds.length}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dealTypeFilterOptions.map((opt) {
                      final selected = _dealType == opt.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(opt.label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _dealType = opt.value;
                              _load();
                            });
                          },
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                          checkmarkColor: AppTheme.specNavy,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: AppTheme.specWhite,
                  elevation: 0,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_cardRadius),
                    side: BorderSide(color: AppTheme.specGold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const MyDealsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(_cardRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.specGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.bookmark_rounded, size: 26, color: AppTheme.specGold),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.specGold.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'My deals',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.specNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'View your claimed deals and show at checkout',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (!_parishIdsInitialized || _loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if ((_deals ?? const []).isEmpty)
          SliverFillRemaining(child: _emptyState(context, theme))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final deals = _deals!;
                  if (!canSeeExclusiveDeals && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => SubscriptionUpsellPopup.show(context),
                          borderRadius: BorderRadius.circular(_cardRadius),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.specNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(_cardRadius),
                              border: Border.all(
                                color: AppTheme.specGold.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_rounded, size: 28, color: AppTheme.specGold),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Exclusive deals',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.specNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Get Cajun+ to unlock member-only & flash deals. Worth every penny.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.specNavy.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final dealIndex = canSeeExclusiveDeals ? index : index - 1;
                  final deal = deals[dealIndex];
                  final ud = _userDealsByDealId[deal.id];
                  final isClaimed = ud != null;
                  final isUsed = ud?.usedAt != null;
                  final isMemberOnlyLocked = deal.dealType == 'member_only' && !canSeeExclusiveDeals;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AnimatedEntrance(
                      delay: Duration(milliseconds: 60 * (index + 1)),
                      child: isMemberOnlyLocked
                          ? _LockedDealCard(
                              deal: deal,
                              onTap: () => SubscriptionUpsellPopup.show(context),
                            )
                          : FutureBuilder<MockListing?>(
                              future: dataSource.getListingById(deal.listingId),
                              builder: (context, listSnap) {
                                final listing = listSnap.data;
                                return _DealCard(
                                  deal: deal,
                                  listingName: listing?.name,
                                  isUsed: isUsed,
                                  onTap: () {
                                    DealDetailPopup.show(
                                      context,
                                      deal: deal,
                                      listingName: listing?.name,
                                      onGoToListing: listing != null
                                          ? () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => ListingDetailScreen(listingId: deal.listingId),
                                                ),
                                              );
                                            }
                                          : null,
                                      isClaimed: isClaimed,
                                      isUsed: isUsed,
                                      usedAt: ud?.usedAt,
                                      onClaim: canClaimDeals
                                          ? () async {
                                              await userDealsRepo.claim(uid, deal.id);
                                              final claimerProfile = await AuthRepository().getProfileForAdmin(uid);
                                              final ownerUserId = await BusinessManagersRepository().getFirstManagerUserId(deal.listingId) ??
                                                  await BusinessRepository().getCreatedBy(deal.listingId);
                                              if (ownerUserId != null) {
                                                final ownerProfile = await AuthRepository().getProfileForAdmin(ownerUserId);
                                                final to = ownerProfile?.email?.trim();
                                                if (to != null && to.isNotEmpty) {
                                                  await SendEmailService().send(
                                                    to: to,
                                                    template: 'deal_claimed',
                                                    variables: {
                                                      'display_name': claimerProfile?.displayName ?? 'A customer',
                                                      'deal_title': deal.title,
                                                      'business_name': listing?.name ?? deal.listingId,
                                                    },
                                                  );
                                                }
                                              }
                                              if (mounted) {
                                                setState(() {
                                                  _userDealsByDealId[deal.id] = UserDeal(
                                                    userId: uid,
                                                    dealId: deal.id,
                                                    claimedAt: DateTime.now(),
                                                    usedAt: null,
                                                  );
                                                });
                                              }
                                            }
                                          : null,
                                      onClaimUpsell: uid != null && !canClaimDeals
                                          ? () => SubscriptionUpsellPopup.show(context)
                                          : null,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  );
                },
                childCount: (canSeeExclusiveDeals ? 0 : 1) + (_deals!.length),
              ),
            ),
          ),
      ],
    );
  }
}

/// Locked (member-only) deal card: tap to show Cajun+ upsell.
class _LockedDealCard extends StatelessWidget {
  const _LockedDealCard({required this.deal, required this.onTap});

  final MockDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3), width: 1),
              ),
              child: Opacity(
                opacity: 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            deal.discount ?? 'Member only',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deal.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.specNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deal.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.specGold.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppTheme.specNavy, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({
    required this.deal,
    required this.onTap,
    this.listingName,
    this.isUsed = false,
  });

  final MockDeal deal;
  final String? listingName;
  final VoidCallback onTap;
  final bool isUsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUsed ? AppTheme.specWhite.withValues(alpha: 0.95) : AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: isUsed
                  ? AppTheme.specNavy.withValues(alpha: 0.12)
                  : AppTheme.specGold.withValues(alpha: 0.4),
              width: isUsed ? 1 : 1.5,
            ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.specGold.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      deal.discount ?? 'Deal',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                        ),
                        if (listingName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            listingName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isUsed) _redeemedBadge(context),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                deal.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (deal.code != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Code: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.specOffWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        deal.code!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppTheme.specNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltyTab extends StatefulWidget {
  const _LoyaltyTab();

  @override
  State<_LoyaltyTab> createState() => _LoyaltyTabState();
}

class _LoyaltyTabState extends State<_LoyaltyTab> {
  List<MockPunchCard>? _punchCards;
  bool _loading = true;
  Set<String> _parishIds = {};
  List<MockParish> _parishes = [];
  String? _categoryId;
  List<MockCategory> _categories = [];
  bool _parishIdsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_parishIdsInitialized) {
      _parishIdsInitialized = true;
      final ds = AppDataScope.of(context).dataSource;
      Future.wait([
        UserParishPreferences.getPreferredParishIds(),
        ds.getParishes(),
      ]).then((results) {
        if (mounted) {
          setState(() {
            _parishIds = Set.from(results[0] as List<String>);
            _parishes = results[1] as List<MockParish>;
            _load();
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _parishIds = {};
            _parishes = [];
            _load();
          });
        }
      });
      return;
    }
    if (_punchCards == null && _loading && _parishIdsInitialized) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dataSource = AppDataScope.of(context).dataSource;
    final categories = await dataSource.getCategories();
    final cards = await dataSource.getActivePunchCardsFiltered(
      parishIds: _parishIds,
      categoryId: _categoryId,
    );
    if (mounted) {
      setState(() {
        _categories = categories;
        _punchCards = cards;
        _loading = false;
      });
    }
  }

  void _openParishFilter() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Set<String> selected = Set.from(_parishIds);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter by parish',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show loyalty programs from businesses in these parishes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _parishes.map((p) {
                      final isSelected = selected.contains(p.id);
                      return FilterChip(
                        label: Text(p.name),
                        selected: isSelected,
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              selected.add(p.id);
                            } else {
                              selected.remove(p.id);
                            }
                          });
                        },
                        selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                        checkmarkColor: AppTheme.specNavy,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(() => selected = {}),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppSecondaryButton(
                          onPressed: () {
                            setState(() {
                              _parishIds = selected;
                              _load();
                            });
                            Navigator.of(ctx).pop();
                          },
                          expanded: true,
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.loyalty_outlined, size: 56, color: AppTheme.specRed),
              ),
              const SizedBox(height: 24),
              Text(
                'No loyalty cards here',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different category or parish, or check back soon. Earn punches at participating local spots.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataSource = AppDataScope.of(context).dataSource;
    final padding = AppLayout.horizontalPadding(context);
    final punchCards = _punchCards ?? const [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitleBadge(
                  icon: Icons.loyalty_rounded,
                  label: 'Loyalty punch cards',
                  subtitle: 'Earn punches and rewards at local businesses. Filter by parish or category.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _categoryId,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text('All categories', style: theme.textTheme.bodyMedium)),
                          ..._categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name, style: theme.textTheme.bodyMedium))),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _categoryId = v;
                            _load();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppOutlinedButton(
                      onPressed: _openParishFilter,
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(_parishIds.isEmpty ? 'Parishes' : '${_parishIds.length}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Material(
                  color: AppTheme.specWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_cardRadius),
                    side: BorderSide(color: AppTheme.specGold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const MyPunchCardsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(_cardRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.specGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.loyalty_rounded, size: 26, color: AppTheme.specGold),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.specGold.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'My loyalty cards',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.specNavy,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'View your enrolled punch cards and show QR',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (!_parishIdsInitialized || _loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)))
        else if (punchCards.isEmpty)
          SliverFillRemaining(child: _emptyState(context, theme))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final card = punchCards[index];
                  return FutureBuilder<MockListing?>(
                    future: dataSource.getListingById(card.listingId),
                    builder: (context, listSnap) {
                      final listing = listSnap.data;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AnimatedEntrance(
                          delay: Duration(milliseconds: 60 * (index + 1)),
                          child: _LoyaltyCard(
                            punchCard: card,
                            listingName: listing?.name,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ListingDetailScreen(listingId: card.listingId),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: punchCards.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({
    required this.punchCard,
    required this.onTap,
    this.listingName,
  });

  final MockPunchCard punchCard;
  final VoidCallback? onTap;
  final String? listingName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3), width: 1),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      punchCard.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                  Icon(Icons.loyalty_rounded, size: 24, color: AppTheme.specGold),
                ],
              ),
              if (listingName != null) ...[
                const SizedBox(height: 4),
                Text(
                  listingName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                punchCard.rewardDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (int i = 0; i < punchCard.punchesRequired; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < punchCard.punchesEarned
                              ? AppTheme.specGold
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          border: Border.all(
                            color: i < punchCard.punchesEarned
                                ? AppTheme.specGold
                                : theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: i < punchCard.punchesEarned
                            ? Icon(Icons.check_rounded, size: 16, color: AppTheme.specNavy)
                            : null,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${punchCard.punchesEarned}/${punchCard.punchesRequired}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
