import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/listing_data_source.dart';
import 'package:my_app/core/data/repositories/favorites_repository.dart';
import 'package:my_app/core/subscription/user_tier_service.dart';

/// Provides [ListingDataSource], [AuthRepository], [FavoritesRepository], and [UserTierService] to the widget tree.
class AppDataScope extends InheritedWidget {
  const AppDataScope({
    super.key,
    required this.dataSource,
    required this.authRepository,
    required this.favoritesRepository,
    required this.userTierService,
    required super.child,
  });

  final ListingDataSource dataSource;
  final AuthRepository authRepository;
  final FavoritesRepository favoritesRepository;
  final UserTierService userTierService;

  static AppDataScope of(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppDataScope>();
    assert(element != null, 'AppDataScope not found. Wrap app with AppDataScope.');
    context.dependOnInheritedElement(element!);
    return element.widget as AppDataScope;
  }

  @override
  bool updateShouldNotify(AppDataScope oldWidget) =>
      dataSource != oldWidget.dataSource ||
      authRepository != oldWidget.authRepository ||
      favoritesRepository != oldWidget.favoritesRepository ||
      userTierService != oldWidget.userTierService;
}
