import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/user_deal.dart';
import 'package:my_app/core/data/repositories/user_deals_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/deal_detail_popup.dart';

/// Badge shown when a deal has been redeemed/used. Checkmark + "Redeemed" for clarity.
Widget _redeemedBadge(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
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

/// Profile "My deals": list of deals the user has claimed (saved). Tap to view details.
class MyDealsScreen extends StatefulWidget {
  const MyDealsScreen({super.key});

  @override
  State<MyDealsScreen> createState() => _MyDealsScreenState();
}

class _MyDealsScreenState extends State<MyDealsScreen> {
  List<({UserDeal userDeal, MockDeal? deal, String? listingName})>? _items;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null && _loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AppDataScope.of(context).authRepository;
    final dataSource = AppDataScope.of(context).dataSource;
    final uid = auth.currentUserId;
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
      final userDeals = await UserDealsRepository(authRepository: auth).listForUser(uid);
      if (userDeals.isEmpty) {
        if (mounted) {
          setState(() {
            _items = [];
            _loading = false;
          });
        }
        return;
      }
      final deals = await Future.wait(
        userDeals.map((ud) => dataSource.getDealById(ud.dealId)),
      );
      final listingIds = deals.whereType<MockDeal>().map((d) => d.listingId).toSet();
      final listings = await Future.wait(
        listingIds.map((id) => dataSource.getListingById(id)),
      );
      final nameById = {for (var i = 0; i < listingIds.length; i++) listingIds.elementAt(i): listings[i]?.name};

      if (mounted) {
        setState(() {
          _items = [
            for (var i = 0; i < userDeals.length; i++)
              (
                userDeal: userDeals[i],
                deal: deals[i],
                listingName: deals[i] != null ? nameById[deals[i]!.listingId] : null,
              ),
          ];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
        _items = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.specGold.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_rounded, size: 20, color: AppTheme.specNavy),
                  const SizedBox(width: 8),
                  Text(
                    'My deals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Couldn\'t load your deals',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.specNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppSecondaryButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : (_items ?? []).isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_border_rounded,
                              size: 64,
                              color: AppTheme.specGold.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved deals yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.specNavy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Claim deals from the Deals tab and they\'ll show up here.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 28),
                        itemCount: _items!.length,
                        itemBuilder: (context, index) {
                          final item = _items![index];
                          final deal = item.deal;
                          if (deal == null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.specWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Deal no longer available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }
                          final isUsed = item.userDeal.usedAt != null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                    onGoToListing: deal.listingId.isNotEmpty
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) => ListingDetailScreen(listingId: deal.listingId),
                                              ),
                                            );
                                          }
                                        : null,
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isUsed ? AppTheme.specWhite.withValues(alpha: 0.96) : AppTheme.specWhite,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isUsed
                                          ? AppTheme.specNavy.withValues(alpha: 0.12)
                                          : AppTheme.specGold.withValues(alpha: 0.45),
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
                                                if (item.listingName != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.listingName!,
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
                                        'Claimed ${_formatDate(item.userDeal.claimedAt)}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.month}/${d.day}/${d.year}';
  }
}
