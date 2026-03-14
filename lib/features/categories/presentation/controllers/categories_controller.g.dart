// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$approvedCategoryBannersHash() =>
    r'df3494c6736923548a7a171fd42bafe7c914306c';

/// See also [approvedCategoryBanners].
@ProviderFor(approvedCategoryBanners)
final approvedCategoryBannersProvider =
    AutoDisposeFutureProvider<List<CategoryBanner>>.internal(
      approvedCategoryBanners,
      name: r'approvedCategoryBannersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$approvedCategoryBannersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApprovedCategoryBannersRef =
    AutoDisposeFutureProviderRef<List<CategoryBanner>>;
String _$filterPanelDataHash() => r'80c5b6811f5ccb5a853c3b230b29d04ce23ec271';

/// See also [filterPanelData].
@ProviderFor(filterPanelData)
final filterPanelDataProvider =
    AutoDisposeFutureProvider<
      (int, List<BusinessCategory>, List<Parish>)
    >.internal(
      filterPanelData,
      name: r'filterPanelDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filterPanelDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilterPanelDataRef =
    AutoDisposeFutureProviderRef<(int, List<BusinessCategory>, List<Parish>)>;
String _$categoriesControllerHash() =>
    r'297ad2f3b7f14dde83e35ab1ce93bb23da18e758';

/// See also [CategoriesController].
@ProviderFor(CategoriesController)
final categoriesControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      CategoriesController,
      CategoriesState
    >.internal(
      CategoriesController.new,
      name: r'categoriesControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoriesControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CategoriesController = AutoDisposeAsyncNotifier<CategoriesState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
