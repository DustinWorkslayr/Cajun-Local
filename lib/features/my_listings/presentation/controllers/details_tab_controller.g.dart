// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'details_tab_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$detailsTabControllerHash() =>
    r'3d7d4db1d30fd9d84d5daf8a15a98ead53c4d036';

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

abstract class _$DetailsTabController
    extends BuildlessAutoDisposeAsyncNotifier<DetailsTabState> {
  late final String listingId;

  FutureOr<DetailsTabState> build(String listingId);
}

/// See also [DetailsTabController].
@ProviderFor(DetailsTabController)
const detailsTabControllerProvider = DetailsTabControllerFamily();

/// See also [DetailsTabController].
class DetailsTabControllerFamily extends Family<AsyncValue<DetailsTabState>> {
  /// See also [DetailsTabController].
  const DetailsTabControllerFamily();

  /// See also [DetailsTabController].
  DetailsTabControllerProvider call(String listingId) {
    return DetailsTabControllerProvider(listingId);
  }

  @override
  DetailsTabControllerProvider getProviderOverride(
    covariant DetailsTabControllerProvider provider,
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
  String? get name => r'detailsTabControllerProvider';
}

/// See also [DetailsTabController].
class DetailsTabControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          DetailsTabController,
          DetailsTabState
        > {
  /// See also [DetailsTabController].
  DetailsTabControllerProvider(String listingId)
    : this._internal(
        () => DetailsTabController()..listingId = listingId,
        from: detailsTabControllerProvider,
        name: r'detailsTabControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$detailsTabControllerHash,
        dependencies: DetailsTabControllerFamily._dependencies,
        allTransitiveDependencies:
            DetailsTabControllerFamily._allTransitiveDependencies,
        listingId: listingId,
      );

  DetailsTabControllerProvider._internal(
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
  FutureOr<DetailsTabState> runNotifierBuild(
    covariant DetailsTabController notifier,
  ) {
    return notifier.build(listingId);
  }

  @override
  Override overrideWith(DetailsTabController Function() create) {
    return ProviderOverride(
      origin: this,
      override: DetailsTabControllerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<DetailsTabController, DetailsTabState>
  createElement() {
    return _DetailsTabControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DetailsTabControllerProvider &&
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
mixin DetailsTabControllerRef
    on AutoDisposeAsyncNotifierProviderRef<DetailsTabState> {
  /// The parameter `listingId` of this provider.
  String get listingId;
}

class _DetailsTabControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          DetailsTabController,
          DetailsTabState
        >
    with DetailsTabControllerRef {
  _DetailsTabControllerProviderElement(super.provider);

  @override
  String get listingId => (origin as DetailsTabControllerProvider).listingId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
