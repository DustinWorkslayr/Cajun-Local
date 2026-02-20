import 'package:flutter/material.dart';

/// Provides favorite listing IDs to the widget tree.
class FavoritesScope extends InheritedWidget {
  const FavoritesScope({
    super.key,
    required this.favoriteIds,
    required super.child,
  });

  final ValueNotifier<Set<String>> favoriteIds;

  static ValueNotifier<Set<String>> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'FavoritesScope not found. Wrap app with FavoritesScope.');
    return scope!.favoriteIds;
  }

  @override
  bool updateShouldNotify(FavoritesScope oldWidget) =>
      oldWidget.favoriteIds != favoriteIds;
}
