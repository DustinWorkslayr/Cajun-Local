// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$listingEditControllerHash() =>
    r'732c3a30d3ba61b402bcafb8d5cb6ef8b79f4318';

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

abstract class _$ListingEditController
    extends BuildlessAutoDisposeAsyncNotifier<ListingEditState> {
  late final String listingId;

  FutureOr<ListingEditState> build(String listingId);
}

/// See also [ListingEditController].
@ProviderFor(ListingEditController)
const listingEditControllerProvider = ListingEditControllerFamily();

/// See also [ListingEditController].
class ListingEditControllerFamily extends Family<AsyncValue<ListingEditState>> {
  /// See also [ListingEditController].
  const ListingEditControllerFamily();

  /// See also [ListingEditController].
  ListingEditControllerProvider call(String listingId) {
    return ListingEditControllerProvider(listingId);
  }

  @override
  ListingEditControllerProvider getProviderOverride(
    covariant ListingEditControllerProvider provider,
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
  String? get name => r'listingEditControllerProvider';
}

/// See also [ListingEditController].
class ListingEditControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ListingEditController,
          ListingEditState
        > {
  /// See also [ListingEditController].
  ListingEditControllerProvider(String listingId)
    : this._internal(
        () => ListingEditController()..listingId = listingId,
        from: listingEditControllerProvider,
        name: r'listingEditControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$listingEditControllerHash,
        dependencies: ListingEditControllerFamily._dependencies,
        allTransitiveDependencies:
            ListingEditControllerFamily._allTransitiveDependencies,
        listingId: listingId,
      );

  ListingEditControllerProvider._internal(
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
  FutureOr<ListingEditState> runNotifierBuild(
    covariant ListingEditController notifier,
  ) {
    return notifier.build(listingId);
  }

  @override
  Override overrideWith(ListingEditController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ListingEditControllerProvider._internal(
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
    ListingEditController,
    ListingEditState
  >
  createElement() {
    return _ListingEditControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ListingEditControllerProvider &&
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
mixin ListingEditControllerRef
    on AutoDisposeAsyncNotifierProviderRef<ListingEditState> {
  /// The parameter `listingId` of this provider.
  String get listingId;
}

class _ListingEditControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ListingEditController,
          ListingEditState
        >
    with ListingEditControllerRef {
  _ListingEditControllerProviderElement(super.provider);

  @override
  String get listingId => (origin as ListingEditControllerProvider).listingId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
