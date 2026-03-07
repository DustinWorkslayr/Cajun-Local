import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/listing_data_source.dart';
import 'package:my_app/core/data/repositories/favorites_repository.dart';
import 'package:my_app/core/network/dio_client.dart';
import 'package:my_app/core/revenuecat/revenuecat_service.dart';
import 'package:my_app/core/subscription/user_tier_service.dart';

/// Provides [ListingDataSource], [AuthRepository], [FavoritesRepository], [UserTierService], and optional [RevenueCatService] to the widget tree.
class AppDataScope extends InheritedWidget {
  const AppDataScope({
    super.key,
    required this.dataSource,
    required this.dioClient,
    required this.authRepository,
    required this.favoritesRepository,
    required this.userTierService,
    required super.child,
    this.revenueCatService,
  });

  final ListingDataSource dataSource;
  final DioClient dioClient;
  final AuthRepository authRepository;
  final FavoritesRepository favoritesRepository;
  final UserTierService userTierService;
  final RevenueCatService? revenueCatService;

  static AppDataScope of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final element = context.getElementForInheritedWidgetOfExactType<AppDataScope>();
      assert(element != null, 'AppDataScope not found. Wrap app with AppDataScope.');
      context.dependOnInheritedElement(element!);
      return element.widget as AppDataScope;
    } else {
      final element = context.getElementForInheritedWidgetOfExactType<AppDataScope>();
      assert(element != null, 'AppDataScope not found. Wrap app with AppDataScope.');
      return element!.widget as AppDataScope;
    }
  }

  @override
  bool updateShouldNotify(AppDataScope oldWidget) =>
      dataSource != oldWidget.dataSource ||
      authRepository != oldWidget.authRepository ||
      favoritesRepository != oldWidget.favoritesRepository ||
      userTierService != oldWidget.userTierService ||
      revenueCatService != oldWidget.revenueCatService;
}
