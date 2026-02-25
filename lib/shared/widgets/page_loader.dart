import 'package:flutter/material.dart';

/// Full-page loading animation. Use while initial data is loading to avoid
/// showing mock or stale content.
class PageLoader extends StatelessWidget {
  const PageLoader({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
