import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Themed dialog when a scanned punch QR code is already used or invalid.
/// Uses spec navy/gold/offWhite styling.
class PunchCodeInvalidDialog extends StatelessWidget {
  const PunchCodeInvalidDialog({
    super.key,
    this.message,
    this.title = 'This code is used or invalid',
  });

  final String? message;
  final String title;

  static const double _cardRadius = 24;

  /// Shows the dialog. [message] is optional (e.g. from punch-validate); defaults to a friendly explanation.
  static Future<void> show(
    BuildContext context, {
    String? message,
    String title = 'This code is used or invalid',
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => PunchCodeInvalidDialog(
        message: message,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final body = message?.trim().isNotEmpty == true
        ? message!
        : 'This QR code has already been used or is no longer valid. The customer will need to show a new code.';

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
                    Icons.qr_code_2_rounded,
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
                    body,
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
                      onPressed: () => Navigator.of(context).pop(),
                      expanded: false,
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
