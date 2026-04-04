import 'package:cajun_local/features/listing/presentation/screens/business_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/features/deals/data/models/user_deal.dart';
import 'package:cajun_local/features/deals/data/repositories/deals_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/user_deals_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/deal_detail_popup.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';

/// Profile "My deals": list of deals the user has claimed (saved).
class MyDealsScreen extends ConsumerStatefulWidget {
  const MyDealsScreen({super.key});

  @override
  ConsumerState<MyDealsScreen> createState() => _MyDealsScreenState();
}

class _MyDealsScreenState extends ConsumerState<MyDealsScreen> {
  List<({UserDeal userDeal, Deal? deal, String? listingName})>? _items;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null && _loading) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _items = [];
        });
      }
      return;
    }
    try {
      final userDealsResponse = await ref.read(userDealsRepositoryProvider).listForUser(uid);
      // Sort by claimedAt descending
      final userDeals = userDealsResponse..sort((a, b) => b.claimedAt.compareTo(a.claimedAt));

      if (userDeals.isEmpty) {
        if (mounted) {
          setState(() {
            _items = [];
            _loading = false;
          });
        }
        return;
      }

      final dealRepo = ref.read(dealsRepositoryProvider);
      final bizRepo = BusinessRepository();

      final deals = await Future.wait(userDeals.map((ud) => dealRepo.getById(ud.dealId)));
      final listingIds = deals.whereType<Deal>().map((d) => d.businessId).toSet();
      final listings = await Future.wait(listingIds.map((id) => bizRepo.getById(id)));
      final nameById = {for (var biz in listings.whereType<Business>()) biz.id: biz.name};

      if (mounted) {
        setState(() {
          _items = [
            for (var i = 0; i < userDeals.length; i++)
              (
                userDeal: userDeals[i],
                deal: deals[i],
                listingName: deals[i] != null ? nameById[deals[i]!.businessId] : null,
              ),
          ];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _items = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: const AppBarWidget(title: 'MY SAVED DEALS', showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.specGold))
          : _error != null
          ? _buildErrorState(theme)
          : (_items ?? []).isEmpty
          ? _buildEmptyState(theme)
          : AppRefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 40),
                itemCount: _items!.length,
                itemBuilder: (context, index) {
                  final item = _items![index];
                  final deal = item.deal;

                  if (deal == null) return const SizedBox.shrink();

                  return AnimatedEntrance(
                    delay: Duration(milliseconds: 50 * index),
                    child: _MyDealCard(item: item, onRefresh: _load),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.specGold.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.bookmark_border_rounded, size: 48, color: AppTheme.specGold),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved deals yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.specNavy,
                fontFamily: 'Libre Baskerville',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Claim deals from the local discounts section to see them here for easy access.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.specRed),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppSecondaryButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MyDealCard extends StatelessWidget {
  const _MyDealCard({required this.item, required this.onRefresh});

  final ({UserDeal userDeal, Deal? deal, String? listingName}) item;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deal = item.deal!;
    final isUsed = item.userDeal.usedAt != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUsed ? AppTheme.specNavy.withValues(alpha: 0.08) : AppTheme.specGold.withValues(alpha: 0.3),
            width: isUsed ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              DealDetailPopup.show(
                context,
                deal: deal,
                listingName: item.listingName,
                isClaimed: true,
                isUsed: isUsed,
                usedAt: item.userDeal.usedAt,
                onGoToListing: deal.businessId.isNotEmpty
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => BusinessDetailScreen(listingId: deal.businessId)),
                        );
                      }
                    : null,
                onClaim: () async {
                  // Already claimed, but popup might show it
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.dealType.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.specGold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              deal.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppTheme.specNavy,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                fontFamily: 'Libre Baskerville',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isUsed)
                        _RedeemedBadge()
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.qr_code_2_rounded, color: AppTheme.specGold, size: 20),
                        ),
                    ],
                  ),
                  if (item.listingName != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 16, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                        const SizedBox(width: 8),
                        Text(
                          item.listingName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Claimed ${_formatRelative(item.userDeal.claimedAt)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isUsed)
                        Text(
                          'READY TO USE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specRed,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}/${d.year}';
  }
}

class _RedeemedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5E1A5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF558B2F)),
          const SizedBox(width: 4),
          Text(
            'REDEEMED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF33691E),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
