// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteListingsHash() => r'209946d37c057128717db446527101e9b90a8e1c';

/// See also [favoriteListings].
@ProviderFor(favoriteListings)
final favoriteListingsProvider =
    AutoDisposeFutureProvider<List<MockListing>>.internal(
      favoriteListings,
      name: r'favoriteListingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteListingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteListingsRef = AutoDisposeFutureProviderRef<List<MockListing>>;
String _$userFavoriteIdsHash() => r'd83cbedd98f3e6886c116fcaa8def7b7528bd71f';

/// See also [UserFavoriteIds].
@ProviderFor(UserFavoriteIds)
final userFavoriteIdsProvider =
    AutoDisposeAsyncNotifierProvider<UserFavoriteIds, Set<String>>.internal(
      UserFavoriteIds.new,
      name: r'userFavoriteIdsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userFavoriteIdsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserFavoriteIds = AutoDisposeAsyncNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
