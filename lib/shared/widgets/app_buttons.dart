import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// Shared button styles: gold/navy spec colors, consistent padding and shape.
/// Use these across the app for a symmetrical, component-based UI.

const EdgeInsets _defaultPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
const double _defaultRadius = 12;
const Size _defaultMinSize = Size(88, 48);

// --- Primary (gold background, navy text) — main CTAs ---

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.label,
    this.style,
    this.padding = _defaultPadding,
    this.minimumSize = _defaultMinSize,
    this.expanded = true,
  }) : assert(child != null || label != null, 'Provide child or label');

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;
  final EdgeInsets padding;
  final Size minimumSize;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppTheme.specGold.withValues(alpha: 0.5);
        return AppTheme.specGold;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppTheme.specNavy.withValues(alpha: 0.5);
        return AppTheme.specNavy;
      }),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(minimumSize),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
      ),
    );
    if (icon != null && label != null) {
      final btn = FilledButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: effectiveStyle,
        icon: icon!,
        label: label!,
      );
      return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
    }
    final c = child ?? label!;
    final btn = FilledButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: effectiveStyle,
      child: c,
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// --- Secondary (navy background, white text) — secondary filled ---

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.label,
    this.style,
    this.padding = _defaultPadding,
    this.minimumSize = _defaultMinSize,
    this.expanded = false,
  }) : assert(child != null || label != null, 'Provide child or label');

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;
  final EdgeInsets padding;
  final Size minimumSize;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppTheme.specNavy.withValues(alpha: 0.4);
        return AppTheme.specNavy;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppTheme.specWhite.withValues(alpha: 0.6);
        return AppTheme.specWhite;
      }),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(minimumSize),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
      ),
    );
    if (icon != null && label != null) {
      final btn = FilledButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: effectiveStyle,
        icon: icon!,
        label: label!,
      );
      return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
    }
    final c = child ?? label!;
    final btn = FilledButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: effectiveStyle,
      child: c,
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// --- Outlined (navy border + text) ---

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.label,
    this.style,
    this.padding = _defaultPadding,
    this.minimumSize = _defaultMinSize,
    this.expanded = false,
  }) : assert(child != null || label != null, 'Provide child or label');

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;
  final EdgeInsets padding;
  final Size minimumSize;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      foregroundColor: WidgetStateProperty.all(AppTheme.specNavy),
      side: WidgetStateProperty.all(BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.6), width: 1.5)),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(minimumSize),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
      ),
    );
    if (icon != null && label != null) {
      final btn = OutlinedButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: effectiveStyle,
        icon: icon!,
        label: label!,
      );
      return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
    }
    final c = child ?? label!;
    final btn = OutlinedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: effectiveStyle,
      child: c,
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// --- Text (navy text, no fill) ---

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.label,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.useGold = false,
  }) : assert(child != null || label != null, 'Provide child or label');

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;
  final EdgeInsets padding;
  final bool useGold;

  @override
  Widget build(BuildContext context) {
    final color = useGold ? AppTheme.specGold : AppTheme.specNavy;
    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      foregroundColor: WidgetStateProperty.all(color),
      padding: WidgetStateProperty.all(padding),
    );
    if (icon != null && label != null) {
      return TextButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: effectiveStyle,
        icon: icon!,
        label: label!,
      );
    }
    return TextButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: effectiveStyle,
      child: child ?? label!,
    );
  }
}

// --- Danger (red filled) — delete, destructive confirm ---

class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.label,
    this.style,
    this.padding = _defaultPadding,
    this.minimumSize = _defaultMinSize,
  }) : assert(child != null || label != null, 'Provide child or label');

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;
  final EdgeInsets padding;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      backgroundColor: WidgetStateProperty.all(AppTheme.specRed),
      foregroundColor: WidgetStateProperty.all(AppTheme.specWhite),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(minimumSize),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
      ),
    );
    if (icon != null && label != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: effectiveStyle,
        icon: icon!,
        label: label!,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: effectiveStyle,
      child: child ?? label!,
    );
  }
}

// --- Danger outlined (red border + text) ---

class AppDangerOutlinedButton extends StatelessWidget {
  const AppDangerOutlinedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.label,
    this.style,
    this.padding = _defaultPadding,
    this.minimumSize = _defaultMinSize,
  }) : assert(child != null || label != null, 'Provide child or label');

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;
  final EdgeInsets padding;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      foregroundColor: WidgetStateProperty.all(AppTheme.specRed),
      side: WidgetStateProperty.all(const BorderSide(color: AppTheme.specRed, width: 1.5)),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(minimumSize),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
      ),
    );
    if (icon != null && label != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: effectiveStyle,
        icon: icon!,
        label: label!,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: effectiveStyle,
      child: child ?? label!,
    );
  }
}
