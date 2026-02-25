import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/punch_qr_sheet.dart';

/// Screen showing the current user's punch card enrollments (punches and redemption).
class MyPunchCardsScreen extends StatelessWidget {
  const MyPunchCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataSource = AppDataScope.of(context).dataSource;
    final padding = AppLayout.horizontalPadding(context);
    final auth = AppDataScope.of(context).authRepository;

    if (auth.currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My punch cards'),
          backgroundColor: AppTheme.specOffWhite,
          foregroundColor: AppTheme.specNavy,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sign in to see your punch cards.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('My punch cards'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
      ),
      body: FutureBuilder<List<MockPunchCard>>(
        future: dataSource.getMyPunchCards(),
        builder: (context, snapshot) {
          final cards = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting && cards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cards.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.loyalty_outlined, size: 56, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No punch cards yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enroll in a punch card at a business to see your progress here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 28),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return FutureBuilder<MockListing?>(
                future: dataSource.getListingById(card.listingId),
                builder: (context, listSnap) {
                  final listing = listSnap.data;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MyPunchCardTile(
                      card: card,
                      listingName: listing?.name,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ListingDetailScreen(listingId: card.listingId),
                          ),
                        );
                      },
                      onShowQr: card.userPunchCardId != null && !card.isRedeemed
                          ? () => showPunchQrSheet(context, userPunchCardId: card.userPunchCardId!, cardTitle: card.title)
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MyPunchCardTile extends StatelessWidget {
  const _MyPunchCardTile({
    required this.card,
    required this.onTap,
    this.listingName,
    this.onShowQr,
  });

  final MockPunchCard card;
  final VoidCallback onTap;
  final String? listingName;
  final VoidCallback? onShowQr;

  static const double _cardRadius = 14;

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
                      card.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                  if (card.isRedeemed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.specGold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Redeemed',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.specNavy,
                        ),
                      ),
                    )
                  else
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
                card.rewardDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (int i = 0; i < card.punchesRequired; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < card.punchesEarned
                              ? AppTheme.specGold
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          border: Border.all(
                            color: i < card.punchesEarned
                                ? AppTheme.specGold
                                : theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: i < card.punchesEarned
                            ? Icon(Icons.check_rounded, size: 16, color: AppTheme.specNavy)
                            : null,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${card.punchesEarned}/${card.punchesRequired} punches',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                ],
              ),
              if (onShowQr != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppOutlinedButton(
                    onPressed: onShowQr,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppTheme.specNavy),
                    label: Text(
                      'Show QR for punch',
                      style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
