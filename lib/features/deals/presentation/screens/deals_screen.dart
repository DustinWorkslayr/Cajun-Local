import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/deal_type_icons.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/deals/data/models/user_deal.dart';
import 'package:cajun_local/features/deals/data/repositories/deals_repository.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:cajun_local/features/profile/data/repositories/profiles_repository.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/deal_detail_popup.dart';
import 'package:cajun_local/core/revenuecat/present_subscription_paywall.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/features/deals/data/repositories/user_deals_repository.dart';

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
class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> with SingleTickerProviderStateMixin {
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
          Container(
            color: AppTheme.specOffWhite,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEALS & REWARDS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.specGold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Local Flavor, Better Price.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.specNavy,
                    fontFamily: 'Libre Baskerville',
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                // Pill segmented control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.specNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.45),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
                    indicator: BoxDecoration(
                      color: AppTheme.specGold,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.specGold.withValues(alpha: 0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(10),
                    tabs: const [
                      Tab(icon: Icon(Icons.local_offer_rounded, size: 18), text: 'Discounts', height: 48),
                      Tab(icon: Icon(Icons.loyalty_rounded, size: 18), text: 'Loyalty', height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [const _DiscountsTab(), const _LoyaltyTab()]),
          ),
        ],
      ),
    );
  }
}

const double _cardRadius = 14;

/// Section header with icon badge + title + optional subtitle.
class _SectionTitleBadge extends StatelessWidget {
  const _SectionTitleBadge({required this.icon, required this.label, this.subtitle});

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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.specGold, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.specNavy),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
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
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20)),
        ),
      ],
    ),
  );
}

class _DiscountsTab extends ConsumerStatefulWidget {
  const _DiscountsTab();

  @override
  ConsumerState<_DiscountsTab> createState() => _DiscountsTabState();
}

class _DiscountsTabState extends ConsumerState<_DiscountsTab> {
  List<Deal>? _deals;
  Map<String, UserDeal> _userDealsByDealId = {};
  bool _loading = true;
  Set<String> _parishIds = {};
  List<Parish> _parishes = [];
  String? _categoryId;
  String? _dealType;
  List<BusinessCategory> _categories = [];
  bool _parishIdsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_parishIdsInitialized) {
      _parishIdsInitialized = true;
      final parishRepo = ref.read(parishRepositoryProvider);
      Future.wait<dynamic>([UserParishPreferences.getPreferredParishIds(), parishRepo.listParishes()])
          .then((results) {
            if (mounted) {
              setState(() {
                _parishIds = results[0] as Set<String>;
                _parishes = results[1] as List<Parish>;
                _load();
              });
            }
          })
          .catchError((_) {
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
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final dealRepo = ref.read(dealsRepositoryProvider);
    final businessRepo = ref.read(businessRepositoryProvider);
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    final userDealRepo = ref.read(userDealsRepositoryProvider);

    final categories = await categoryRepo.listCategories();
    final results = await Future.wait<dynamic>([
      dealRepo.listApproved(),
      uid != null ? userDealRepo.listForUser(uid) : Future<List<UserDeal>>.value([]),
      // Fetch businesses filtered by selected parishes (empty = all)
      _parishIds.isEmpty
          ? Future<List<Business>>.value([])
          : businessRepo.listApproved(parishIds: _parishIds, limit: 5000),
    ]);

    if (mounted) {
      final list = results[1] as List<UserDeal>;
      final allApproved = results[0] as List<Deal>;
      final parishBusinesses = results[2] as List<Business>;

      // Build allowed businessId set when parishes are selected
      final allowedBusinessIds = _parishIds.isEmpty ? null : parishBusinesses.map((b) => b.id).toSet();

      final filtered = allApproved.where((d) {
        if (_dealType != null && d.dealType != _dealType) return false;
        if (allowedBusinessIds != null && !allowedBusinessIds.contains(d.businessId)) return false;
        return true;
      }).toList();

      setState(() {
        _categories = categories;
        _deals = filtered;
        _userDealsByDealId = {for (var e in list) e.dealId: e};
        _loading = false;
      });
    }
  }

  void _openParishFilter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        Set<String> selected = Set.from(_parishIds);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final allSelected = selected.length == _parishes.length && _parishes.isNotEmpty;
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.specNavy.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Navy Header Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    decoration: BoxDecoration(
                      color: AppTheme.specNavy,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.specNavy.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 20, color: AppTheme.specGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PARISH FILTER',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.specGold,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                selected.isEmpty
                                    ? 'Showing all parishes'
                                    : '${selected.length} area${selected.length > 1 ? 's' : ''} selected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Select All toggle
                        GestureDetector(
                          onTap: () => setModalState(() {
                            if (allSelected) {
                              selected = {};
                            } else {
                              selected = _parishes.map((p) => p.id).toSet();
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: allSelected ? AppTheme.specGold : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              allSelected ? 'Deselect all' : 'Select all',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Parish list
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: _parishes.map((p) {
                          final isSelected = selected.contains(p.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected ? AppTheme.specGold.withValues(alpha: 0.1) : AppTheme.specOffWhite,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selected.remove(p.id);
                                    } else {
                                      selected.add(p.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        size: 20,
                                        color: isSelected
                                            ? AppTheme.specGold
                                            : AppTheme.specNavy.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                        }).toList(),
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 100),
                    decoration: BoxDecoration(
                      color: AppTheme.specWhite,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: AppOutlinedButton(
                            onPressed: () => setModalState(() => selected = {}),
                            label: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppPrimaryButton(
                            onPressed: () {
                              UserParishPreferences.setPreferredParishIds(selected);
                              setState(() {
                                _parishIds = selected;
                                _load();
                              });
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: AppTheme.specNavy,
                            ),
                            label: Text(
                              selected.isEmpty
                                  ? 'Show all'
                                  : 'Apply ${selected.length} area${selected.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.specNavy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                decoration: BoxDecoration(color: AppTheme.specGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.local_offer_outlined, size: 56, color: AppTheme.specRed),
              ),
              const SizedBox(height: 24),
              Text(
                'No deals here — yet',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different category or parish, or check back soon. Don\'t leave money on the table.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    final uid = ref.watch(authControllerProvider).valueOrNull?.id;
    final userDealRepo = ref.watch(userDealsRepositoryProvider);
    final userTierService = ref.watch(userTierServiceProvider);
    // final canClaimDeals = uid != null && (userTierService.value?.canClaimDeals ?? false);
    final canClaimDeals = true;
    final canSeeExclusiveDeals = userTierService.value?.canSeeExclusiveDeals ?? false;
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
                const SizedBox(height: 12),
                // ── Unified Filter Panel ───────────────────────────────
                Builder(
                  builder: (context) {
                    final activeCount =
                        (_categoryId != null ? 1 : 0) + (_parishIds.isNotEmpty ? 1 : 0) + (_dealType != null ? 1 : 0);
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.specWhite,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 16, color: AppTheme.specNavy),
                                const SizedBox(width: 6),
                                Text(
                                  'Filter deals',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.specNavy,
                                  ),
                                ),
                                const Spacer(),
                                if (activeCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.specGold,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$activeCount active',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _categoryId = null;
                                        _dealType = null;
                                        _parishIds = {};
                                        UserParishPreferences.setPreferredParishIds({});
                                        _load();
                                      });
                                    },
                                    child: Text(
                                      'Clear all',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.specRed.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Row 1: Category chips
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 0, 0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [null, ..._categories.map((c) => c.id)].map((id) {
                                  final label = id == null
                                      ? 'All categories'
                                      : _categories.firstWhere((c) => c.id == id).name;
                                  final selected = _categoryId == id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _categoryId = id;
                                        _load();
                                      }),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: selected ? AppTheme.specNavy : AppTheme.specOffWhite,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selected ? AppTheme.specNavy : Colors.black.withValues(alpha: 0.08),
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                            color: selected ? Colors.white : AppTheme.specNavy.withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                          ),
                          // Row 2: Deal type + Parish
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Row(
                              children: [
                                // Deal type selector (scrollable)
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _dealTypeFilterOptions.map((opt) {
                                        final selected = _dealType == opt.value;
                                        final IconData icon = switch (opt.value) {
                                          'percentage' => Icons.percent_rounded,
                                          'fixed' => Icons.attach_money_rounded,
                                          'bogo' => Icons.control_point_duplicate_rounded,
                                          'freebie' => Icons.card_giftcard_rounded,
                                          'other' => Icons.more_horiz_rounded,
                                          _ => Icons.local_offer_rounded,
                                        };
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              _dealType = opt.value;
                                              _load();
                                            }),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? AppTheme.specGold.withValues(alpha: 0.15)
                                                    : AppTheme.specOffWhite,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: selected
                                                      ? AppTheme.specGold
                                                      : Colors.black.withValues(alpha: 0.08),
                                                  width: selected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    icon,
                                                    size: 14,
                                                    color: selected
                                                        ? AppTheme.specNavy
                                                        : AppTheme.specNavy.withValues(alpha: 0.45),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    opt.label,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                                      color: selected
                                                          ? AppTheme.specNavy
                                                          : AppTheme.specNavy.withValues(alpha: 0.65),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Parish pill button
                                GestureDetector(
                                  onTap: _openParishFilter,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _parishIds.isEmpty ? AppTheme.specOffWhite : AppTheme.specNavy,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _parishIds.isEmpty
                                            ? Colors.black.withValues(alpha: 0.08)
                                            : AppTheme.specNavy,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 14,
                                          color: _parishIds.isEmpty
                                              ? AppTheme.specNavy.withValues(alpha: 0.45)
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _parishIds.isEmpty ? 'Parish' : '${_parishIds.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _parishIds.isEmpty
                                                ? AppTheme.specNavy.withValues(alpha: 0.65)
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                      context.push('/my-deals');
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
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.specNavy.withValues(alpha: 0.5),
                          ),
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
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 110 + MediaQuery.paddingOf(context).bottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final deals = _deals!;
                if (!canSeeExclusiveDeals && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => presentSubscriptionPaywall(context, ref),
                        borderRadius: BorderRadius.circular(_cardRadius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.specNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(_cardRadius),
                            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5), width: 1.5),
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
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppTheme.specNavy.withValues(alpha: 0.5),
                              ),
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
                        ? _LockedDealCard(deal: deal, onTap: () => presentSubscriptionPaywall(context, ref))
                        : FutureBuilder<Business?>(
                            future: BusinessRepository().getById(deal.businessId),
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
                                            context.push('/listing/${deal.businessId}');
                                          }
                                        : null,
                                    isClaimed: isClaimed,
                                    isUsed: isUsed,
                                    usedAt: ud?.usedAt,
                                    onClaim: canClaimDeals && uid != null
                                        ? () async {
                                            await userDealRepo.claim(uid, deal.id);
                                            final authRepoInternal = ref.read(profilesRepositoryProvider);
                                            final ownerUserId =
                                                await BusinessManagersRepository().getFirstManagerUserId(
                                                  deal.businessId,
                                                ) ??
                                                await ref
                                                    .read(businessRepositoryProvider)
                                                    .getCreatedBy(deal.businessId);
                                            if (ownerUserId != null) {
                                              final ownerProfile = await authRepoInternal.getProfile(ownerUserId);
                                              final to = ownerProfile?.email?.trim();
                                              if (to != null && to.isNotEmpty) {}
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
                                        ? () => presentSubscriptionPaywall(context, ref)
                                        : null,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                );
              }, childCount: (canSeeExclusiveDeals ? 0 : 1) + (_deals!.length)),
            ),
          ),
      ],
    );
  }
}

/// Locked (member-only) deal card: tap to show Cajun+ upsell.
class _LockedDealCard extends StatelessWidget {
  const _LockedDealCard({required this.deal, required this.onTap});

  final Deal deal;
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(DealTypeIcons.iconFor(deal.dealType), size: 20, color: AppTheme.specNavy),
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
                      deal.description ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  decoration: BoxDecoration(color: AppTheme.specGold.withValues(alpha: 0.9), shape: BoxShape.circle),
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
  const _DealCard({required this.deal, required this.onTap, this.listingName, this.isUsed = false});

  final Deal deal;
  final String? listingName;
  final VoidCallback onTap;
  final bool isUsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUsed ? AppTheme.specWhite.withValues(alpha: 0.85) : AppTheme.specWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isUsed ? Colors.black.withValues(alpha: 0.04) : AppTheme.specGold.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.specGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(DealTypeIcons.iconFor(deal.dealType), size: 26, color: AppTheme.specGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                        ),
                      ),
                      if (listingName != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          listingName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        deal.description ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.55),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isUsed) _redeemedBadge(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoyaltyTab extends ConsumerStatefulWidget {
  const _LoyaltyTab();

  @override
  ConsumerState<_LoyaltyTab> createState() => _LoyaltyTabState();
}

class _LoyaltyTabState extends ConsumerState<_LoyaltyTab> {
  List<PunchCardProgram>? _programs;
  bool _loading = true;
  Set<String> _parishIds = {};
  List<Parish> _parishes = [];
  String? _categoryId;
  List<BusinessCategory> _categories = [];
  bool _parishIdsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_parishIdsInitialized) {
      _parishIdsInitialized = true;
      final parishRepo = ref.read(parishRepositoryProvider);
      Future.wait<dynamic>([UserParishPreferences.getPreferredParishIds(), parishRepo.listParishes()])
          .then((results) {
            if (mounted) {
              setState(() {
                _parishIds = results[0] as Set<String>;
                _parishes = results[1] as List<Parish>;
                _load();
              });
            }
          })
          .catchError((_) {
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
    if (_programs == null && _loading && _parishIdsInitialized) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final punchRepo = ref.read(punchCardProgramsRepositoryProvider);

    final categories = await categoryRepo.listCategories();
    final programs = await punchRepo.listActive();

    if (mounted) {
      setState(() {
        _categories = categories;
        _programs = programs;
        _loading = false;
      });
    }
  }

  void _openParishFilter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        Set<String> selected = Set.from(_parishIds);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final allSelected = selected.length == _parishes.length && _parishes.isNotEmpty;
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.specNavy.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Navy Header Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    decoration: BoxDecoration(
                      color: AppTheme.specNavy,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.specNavy.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 20, color: AppTheme.specGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PARISH FILTER',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.specGold,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                selected.isEmpty
                                    ? 'Showing all parishes'
                                    : '${selected.length} area${selected.length > 1 ? 's' : ''} selected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Select All toggle
                        GestureDetector(
                          onTap: () => setModalState(() {
                            if (allSelected) {
                              selected = {};
                            } else {
                              selected = _parishes.map((p) => p.id).toSet();
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: allSelected ? AppTheme.specGold : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              allSelected ? 'Deselect all' : 'Select all',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Parish list
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: _parishes.map((p) {
                          final isSelected = selected.contains(p.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected ? AppTheme.specGold.withValues(alpha: 0.1) : AppTheme.specOffWhite,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selected.remove(p.id);
                                    } else {
                                      selected.add(p.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        size: 20,
                                        color: isSelected
                                            ? AppTheme.specGold
                                            : AppTheme.specNavy.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                        }).toList(),
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 100),
                    decoration: BoxDecoration(
                      color: AppTheme.specWhite,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: AppOutlinedButton(
                            onPressed: () => setModalState(() => selected = {}),
                            label: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppPrimaryButton(
                            onPressed: () {
                              UserParishPreferences.setPreferredParishIds(selected);
                              setState(() {
                                _parishIds = selected;
                                _load();
                              });
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: AppTheme.specNavy,
                            ),
                            label: Text(
                              selected.isEmpty
                                  ? 'Show all'
                                  : 'Apply ${selected.length} area${selected.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.specNavy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                decoration: BoxDecoration(color: AppTheme.specGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.loyalty_outlined, size: 56, color: AppTheme.specRed),
              ),
              const SizedBox(height: 24),
              Text(
                'No loyalty cards here',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different category or parish, or check back soon. Earn punches at participating local spots.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    final padding = AppLayout.horizontalPadding(context);
    final programs = _programs ?? const [];

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
                const SizedBox(height: 12),
                // ── Unified Filter Panel ───────────────────────────────
                Builder(
                  builder: (context) {
                    final activeCount = (_categoryId != null ? 1 : 0) + (_parishIds.isNotEmpty ? 1 : 0);
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.specWhite,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 16, color: AppTheme.specNavy),
                                const SizedBox(width: 6),
                                Text(
                                  'Filter loyalty cards',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.specNavy,
                                  ),
                                ),
                                const Spacer(),
                                if (activeCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.specGold,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$activeCount active',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _categoryId = null;
                                        _parishIds = {};
                                        UserParishPreferences.setPreferredParishIds({});
                                        _load();
                                      });
                                    },
                                    child: Text(
                                      'Clear all',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.specRed.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Row 1: Category chips
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 0, 0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [null, ..._categories.map((c) => c.id)].map((id) {
                                  final label = id == null
                                      ? 'All categories'
                                      : _categories.firstWhere((c) => c.id == id).name;
                                  final selected = _categoryId == id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _categoryId = id;
                                        _load();
                                      }),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: selected ? AppTheme.specNavy : AppTheme.specOffWhite,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selected ? AppTheme.specNavy : Colors.black.withValues(alpha: 0.08),
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                            color: selected ? Colors.white : AppTheme.specNavy.withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                          ),
                          // Row 2: Parish filter
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Row(
                              children: [
                                const Icon(Icons.loyalty_rounded, size: 14, color: AppTheme.specNavy),
                                const SizedBox(width: 6),
                                Text(
                                  'Participating locals near you',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                // Parish pill
                                GestureDetector(
                                  onTap: _openParishFilter,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _parishIds.isEmpty ? AppTheme.specOffWhite : AppTheme.specNavy,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _parishIds.isEmpty
                                            ? Colors.black.withValues(alpha: 0.08)
                                            : AppTheme.specNavy,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 14,
                                          color: _parishIds.isEmpty
                                              ? AppTheme.specNavy.withValues(alpha: 0.45)
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _parishIds.isEmpty
                                              ? 'All parishes'
                                              : '${_parishIds.length} parish${_parishIds.length > 1 ? 'es' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _parishIds.isEmpty
                                                ? AppTheme.specNavy.withValues(alpha: 0.65)
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                      context.push('/my-punch-cards');
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
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.specNavy.withValues(alpha: 0.5),
                          ),
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
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
          )
        else if (programs.isEmpty)
          SliverFillRemaining(child: _emptyState(context, theme))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 110 + MediaQuery.paddingOf(context).bottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final program = programs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FutureBuilder<Business?>(
                    future: BusinessRepository().getById(program.businessId),
                    builder: (context, listSnap) {
                      final listing = listSnap.data;
                      return AnimatedEntrance(
                        delay: Duration(milliseconds: 60 * (index + 1)),
                        child: _LoyaltyCard(
                          program: program,
                          listingName: listing?.name,
                          onTap: () {
                            if (listing == null) return;
                            context.push('/listing/${program.businessId}');
                          },
                        ),
                      );
                    },
                  ),
                );
              }, childCount: programs.length),
            ),
          ),
      ],
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.program, required this.onTap, this.listingName});

  final PunchCardProgram program;
  final VoidCallback? onTap;
  final String? listingName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final punches = program.punchesRequired.clamp(1, 12);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Navy header band ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: const BoxDecoration(
                  color: AppTheme.specNavy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon circle
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: AppTheme.specGold, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.loyalty_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    // Title + business name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.title ?? 'Loyalty Program',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          if (listingName != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.store_rounded, size: 12, color: AppTheme.specSecondaryContainer),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    listingName!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.specSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Punch card badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppTheme.specGold, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        'Punch card',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── White body ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reward description
                    Text(
                      program.rewardDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.75),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PUNCH SLOTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            '$punches punches = 1 reward',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.specNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Punch slots
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: List.generate(punches, (i) {
                        return Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.specGold.withValues(alpha: 0.10),
                            border: Border.all(color: AppTheme.specGold, width: 1.5),
                          ),
                          child: Center(
                            child: Icon(Icons.star_rounded, size: 15, color: AppTheme.specGold.withValues(alpha: 0.6)),
                          ),
                        );
                      }),
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
