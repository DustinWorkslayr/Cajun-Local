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
    final element = context.getElementForInheritedWidgetOfExactType<FavoritesScope>();
    assert(element != null, 'FavoritesScope not found. Wrap app with FavoritesScope.');
    context.dependOnInheritedElement(element!);
    return (element.widget as FavoritesScope).favoriteIds;
  }

  @override
  bool updateShouldNotify(FavoritesScope oldWidget) =>
      oldWidget.favoriteIds != favoriteIds;
}
