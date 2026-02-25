import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Dialog shown when a business owner hits a tier limit (deal limit or advanced feature).
/// Displays [message] and a "View plans" CTA. Reuses spec navy/gold styling.
class BusinessTierUpgradeDialog extends StatelessWidget {
  const BusinessTierUpgradeDialog({
    super.key,
    required this.message,
    this.title = 'Upgrade your plan',
    this.viewPlansLabel = 'View plans',
    this.onViewPlans,
  });

  final String message;
  final String title;
  final String viewPlansLabel;
  final VoidCallback? onViewPlans;

  static const double _cardRadius = 24;

  /// Shows the dialog. [message] is typically from
  /// [BusinessTierService.upgradeMessageForDealLimit] or
  /// [BusinessTierService.upgradeMessageForAdvancedFeatures].
  static Future<void> show(
    BuildContext context, {
    required String message,
    String title = 'Upgrade your plan',
    String viewPlansLabel = 'View plans',
    VoidCallback? onViewPlans,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => BusinessTierUpgradeDialog(
        message: message,
        title: title,
        viewPlansLabel: viewPlansLabel,
        onViewPlans: onViewPlans,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: AppTheme.specGold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: nav,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: sub,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewPlans?.call();
                      },
                      expanded: false,
                      child: Text(
                        viewPlansLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Maybe later',
                      style: TextStyle(
                        color: sub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: nav.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
