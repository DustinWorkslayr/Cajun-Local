import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'app_buttons.dart';

/// Reusable premium confirmation dialog following the "Digital Curator" design system.
class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDanger = false,
    this.icon,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final IconData? icon;

  /// Static helper to show the dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.specWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDanger ? AppTheme.specRed : AppTheme.specGold).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDanger ? AppTheme.specRed : AppTheme.specGold,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              textAlign: icon != null ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: icon != null ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    label: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isDanger
                      ? AppDangerButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          label: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        )
                      : AppPrimaryButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          label: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
