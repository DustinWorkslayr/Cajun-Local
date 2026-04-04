import 'dart:ui';

import 'package:cajun_local/features/listing/presentation/screens/business_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/deal_type_icons.dart';
import 'package:cajun_local/core/extensions/buildcontext_extension.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/core/theme/theme.dart';

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

  final Deal deal;
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
    required Deal deal,
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
    final isDark = theme.brightness == Brightness.dark;
    final isClaimed = widget.isClaimed;
    final onClaim = widget.onClaim;
    final onClaimUpsell = widget.onClaimUpsell;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppTheme.specWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
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
                    child: Icon(DealTypeIcons.iconFor(widget.deal.dealType), size: 20, color: AppTheme.specGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEAL DETAILS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'A local flavor favorite',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.paddingOf(context).bottom + 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.deal.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.specNavy,
                        fontFamily: 'Libre Baskerville',
                      ),
                    ),
                    if (widget.listingName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.store_rounded, size: 18, color: AppTheme.specGold),
                          const SizedBox(width: 8),
                          Text(
                            widget.listingName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _sectionLabel('DESCRIPTION'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.specOffWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        widget.deal.description ?? 'No description provided.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy, height: 1.6),
                      ),
                    ),
                    if (widget.deal.endDate != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.specRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 18, color: AppTheme.specRed),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Offer valid until ${_formatDate(widget.deal.endDate!)}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppTheme.specRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (onClaim != null || onClaimUpsell != null || isClaimed) ...[
                      if (isClaimed)
                        _buildClaimedStatus(theme)
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
                                      context.showSuccessSnackBar('Deal claimed successfully!');
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      context.showErrorSnackBar('Failed to claim deal. Please try again.');
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: AppTheme.specNavy,
                          ),
                          icon: _isClaiming
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                                )
                              : const Icon(Icons.local_offer_rounded, size: 20),
                          label: Text(_isClaiming ? 'Claiming...' : 'Grab this deal'),
                        ),
                      const SizedBox(height: 12),
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
                                builder: (_) => BusinessDetailScreen(listingId: widget.deal.businessId),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.store_rounded, size: 20),
                        label: const Text('Visit Business'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w800, letterSpacing: 1.0),
    );
  }

  Widget _buildClaimedStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 22, color: Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.isUsed
                  ? (widget.usedAt != null ? 'Redeemed on ${_formatDate(widget.usedAt!)}' : 'Redeemed')
                  : 'You claimed this deal',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
