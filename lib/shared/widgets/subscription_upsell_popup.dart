import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/revenuecat/revenuecat_service.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_logo.dart';

/// Cajun+ Membership subscription upsell popup. Matches the design:
/// logo, title, tagline, feature list with gold checkmarks, gold CTAs, footer.
/// When [onSubscribe] / [onStartFreeTrial] are null, presents RevenueCat Paywall if available.
class SubscriptionUpsellPopup extends StatelessWidget {
  const SubscriptionUpsellPopup({
    super.key,
    this.onSubscribe,
    this.onStartFreeTrial,
  });

  final VoidCallback? onSubscribe;
  final VoidCallback? onStartFreeTrial;

  static const double _cardRadius = 24;
  static const String _price = '\$2.99';

  /// Shows the upsell as a centered dialog. When callbacks are null, presents RevenueCat Paywall (Cajun+).
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSubscribe,
    VoidCallback? onStartFreeTrial,
  }) {
    final scope = AppDataScope.of(context);
    void defaultSubscribe() {
      Navigator.of(context).pop();
      scope.revenueCatService?.presentPaywall().then((result) {
        if (context.mounted &&
            (result == PaywallPresentationResult.purchased ||
                result == PaywallPresentationResult.restored)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Cajun+!')),
          );
        }
      });
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => SubscriptionUpsellPopup(
        onSubscribe: onSubscribe ?? defaultSubscribe,
        onStartFreeTrial: onStartFreeTrial ?? defaultSubscribe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.specOffWhite,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: AppLogo(height: 88)),
                  const SizedBox(height: 20),
                  // Title: Cajun+ Membership
                  Text(
                    'Cajun+ Membership',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: nav,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Support Local. Stay Cajun.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: sub,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get full access for $_price/month',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: nav,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _FeatureRow(
                    label: 'Submit / request new businesses',
                    iconColor: AppTheme.specGold,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    label: 'Save unlimited favorites',
                    iconColor: AppTheme.specGold,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    label: 'Exclusive local deals',
                    iconColor: AppTheme.specGold,
                    showNewBadge: true,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    label: 'Early access to new features',
                    iconColor: AppTheme.specGold,
                  ),
                  const SizedBox(height: 28),
                  _GoldButton(
                    label: '$_price/mo · Cancel anytime',
                    onPressed: onSubscribe ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                  _GoldButton(
                    label: 'Start Free Trial',
                    onPressed: onStartFreeTrial ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Secure payment via App Store / Google Play.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: sub,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cancel anytime.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: sub,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.specWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: nav.withValues(alpha: 0.6),
                  ),
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.iconColor,
    this.showNewBadge = false,
  });

  final String label;
  final Color iconColor;
  final bool showNewBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: nav,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: nav.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ),
              if (showNewBadge)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.specRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NEW',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.specWhite,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.specGold,
                  AppTheme.specGold.withValues(alpha: 0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.specGold.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: nav,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
