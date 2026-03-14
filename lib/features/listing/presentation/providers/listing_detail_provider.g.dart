// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$listingDetailControllerHash() =>
    r'ceb2259dd161dc2af9f568d04688b0ab133ae75a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ListingDetailController
    extends BuildlessAutoDisposeAsyncNotifier<ListingDetailData?> {
  late final String listingId;

  FutureOr<ListingDetailData?> build(String listingId);
}

/// See also [ListingDetailController].
@ProviderFor(ListingDetailController)
const listingDetailControllerProvider = ListingDetailControllerFamily();

/// See also [ListingDetailController].
class ListingDetailControllerFamily
    extends Family<AsyncValue<ListingDetailData?>> {
  /// See also [ListingDetailController].
  const ListingDetailControllerFamily();

  /// See also [ListingDetailController].
  ListingDetailControllerProvider call(String listingId) {
    return ListingDetailControllerProvider(listingId);
  }

  @override
  ListingDetailControllerProvider getProviderOverride(
    covariant ListingDetailControllerProvider provider,
  ) {
    return call(provider.listingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'listingDetailControllerProvider';
}

/// See also [ListingDetailController].
class ListingDetailControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ListingDetailController,
          ListingDetailData?
        > {
  /// See also [ListingDetailController].
  ListingDetailControllerProvider(String listingId)
    : this._internal(
        () => ListingDetailController()..listingId = listingId,
        from: listingDetailControllerProvider,
        name: r'listingDetailControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$listingDetailControllerHash,
        dependencies: ListingDetailControllerFamily._dependencies,
        allTransitiveDependencies:
            ListingDetailControllerFamily._allTransitiveDependencies,
        listingId: listingId,
      );

  ListingDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.listingId,
  }) : super.internal();

  final String listingId;

  @override
  FutureOr<ListingDetailData?> runNotifierBuild(
    covariant ListingDetailController notifier,
  ) {
    return notifier.build(listingId);
  }

  @override
  Override overrideWith(ListingDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ListingDetailControllerProvider._internal(
        () => create()..listingId = listingId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        listingId: listingId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ListingDetailController,
    ListingDetailData?
  >
  createElement() {
    return _ListingDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ListingDetailControllerProvider &&
        other.listingId == listingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, listingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ListingDetailControllerRef
    on AutoDisposeAsyncNotifierProviderRef<ListingDetailData?> {
  /// The parameter `listingId` of this provider.
  String get listingId;
}

class _ListingDetailControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ListingDetailController,
          ListingDetailData?
        >
    with ListingDetailControllerRef {
  _ListingDetailControllerProviderElement(super.provider);

  @override
  String get listingId => (origin as ListingDetailControllerProvider).listingId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
