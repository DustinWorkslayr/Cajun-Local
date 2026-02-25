import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';

/// Glassy popup showing full deal details. Use [DealDetailPopup.show] to present.
class DealDetailPopup extends StatefulWidget {
  const DealDetailPopup({
    super.key,
    required this.deal,
    this.listingName,
    this.onGoToListing,
    this.showViewBusinessButton = true,
    this.isClaimed = false,
    this.isUsed = false,
    this.usedAt,
    this.onClaim,
    this.onClaimUpsell,
  });

  final MockDeal deal;
  final String? listingName;
  final VoidCallback? onGoToListing;
  final bool showViewBusinessButton;
  /// True when the current user has already claimed this deal.
  final bool isClaimed;
  /// True when the deal has been redeemed (used_at set).
  final bool isUsed;
  /// When [isUsed], optional date to show "Redeemed on ...".
  final DateTime? usedAt;
  /// Called when user taps "Claim deal". If null, claim button is hidden (e.g. not signed in).
  /// Can be async; popup shows "Claiming..." until it completes, then closes.
  final Future<void> Function()? onClaim;
  /// When set (signed in but tier does not allow claim), tapping "Claim deal" calls this (e.g. show upsell).
  final VoidCallback? onClaimUpsell;

  /// Shows a glassy bottom sheet with full deal details.
  static Future<void> show(
    BuildContext context, {
    required MockDeal deal,
    String? listingName,
    VoidCallback? onGoToListing,
    bool showViewBusinessButton = true,
    bool isClaimed = false,
    bool isUsed = false,
    DateTime? usedAt,
    Future<void> Function()? onClaim,
    VoidCallback? onClaimUpsell,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DealDetailPopup(
        deal: deal,
        listingName: listingName,
        onGoToListing: onGoToListing,
        showViewBusinessButton: showViewBusinessButton,
        isClaimed: isClaimed,
        isUsed: isUsed,
        usedAt: usedAt,
        onClaim: onClaim,
        onClaimUpsell: onClaimUpsell,
      ),
    );
  }

  @override
  State<DealDetailPopup> createState() => _DealDetailPopupState();
}

class _DealDetailPopupState extends State<DealDetailPopup> {
  bool _isClaiming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClaimed = widget.isClaimed;
    final onClaim = widget.onClaim;
    final onClaimUpsell = widget.onClaimUpsell;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          decoration: BoxDecoration(
            color: (isDark ? colorScheme.surface : AppTheme.specOffWhite)
                .withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.specGold.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.specNavy.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.specNavy.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Hero: navy band with discount + urgency
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.specNavy,
                          AppTheme.specNavy.withValues(alpha: 0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.specNavy.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A deal worth grabbing',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.specGold.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.deal.discount ?? 'Special offer',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.specWhite,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (widget.deal.expiry != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 16, color: AppTheme.specGold.withValues(alpha: 0.9)),
                              const SizedBox(width: 6),
                              Text(
                                'Valid until ${_formatDate(widget.deal.expiry!)} — don\'t miss out',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.specWhite.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.deal.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                        ),
                        if (widget.listingName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.store_rounded, size: 18, color: AppTheme.specRed),
                              const SizedBox(width: 6),
                              Text(
                                widget.listingName!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.specRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.specWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.deal.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.specNavy,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (widget.deal.code != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Your promo code',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.specGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.specGold, width: 2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.deal.code!,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      fontFamily: 'monospace',
                                      color: AppTheme.specNavy,
                                    ),
                                  ),
                                ),
                                Icon(Icons.copy_rounded, size: 20, color: AppTheme.specNavy.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (onClaim != null || onClaimUpsell != null || isClaimed) ...[
                          if (isClaimed)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.isUsed ? Icons.check_circle_rounded : Icons.check_circle_rounded,
                                  size: 22,
                                  color: widget.isUsed ? colorScheme.tertiary : colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.isUsed
                                        ? (widget.usedAt != null
                                            ? 'Redeemed on ${_formatDate(widget.usedAt!)}'
                                            : 'Redeemed')
                                        : 'You claimed this deal',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          else
                            AppPrimaryButton(
                            onPressed: _isClaiming
                                ? null
                                : () async {
                                    if (onClaim != null) {
                                      setState(() => _isClaiming = true);
                                      try {
                                        await onClaim();
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop();
                                      } finally {
                                        if (mounted) setState(() => _isClaiming = false);
                                      }
                                      return;
                                    }
                                    if (onClaimUpsell != null) {
                                      onClaimUpsell();
                                      return;
                                    }
                                  },
                            expanded: false,
                            icon: _isClaiming
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                                  )
                                : const Icon(Icons.local_offer_rounded, size: 22),
                            label: Text(_isClaiming ? 'Claiming...' : 'Grab this deal'),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (widget.showViewBusinessButton)
                            AppOutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (widget.onGoToListing != null) {
                                widget.onGoToListing!();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ListingDetailScreen(
                                      listingId: widget.deal.listingId,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.store_rounded, size: 20),
                            label: const Text('View business'),
                            ),
                          const SizedBox(height: 8),
                          TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Close',
                            style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
