import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Label + TextField with app-standard decoration (filled, specWhite, radius 12).
/// Use for form fields across the app.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label!.isNotEmpty) ...[
            Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            obscureText: obscureText,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: theme.textTheme.bodyLarge?.copyWith(color: nav),
            decoration: InputDecoration(
              hintText: hint ?? (label != null ? 'Enter $label' : null),
              errorText: errorText,
              filled: true,
              fillColor: AppTheme.specWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nav.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nav.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.specGold, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
