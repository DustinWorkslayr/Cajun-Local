// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$newsPostsHash() => r'35b3fd03f060737ea44dffca04b04172d05d52f4';

/// See also [newsPosts].
@ProviderFor(newsPosts)
final newsPostsProvider = AutoDisposeFutureProvider<List<BlogPost>>.internal(
  newsPosts,
  name: r'newsPostsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$newsPostsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NewsPostsRef = AutoDisposeFutureProviderRef<List<BlogPost>>;
String _$newsParishesHash() => r'b1bbfcc7e2aff2ea276cd00ec17d7fcb5f258999';

/// See also [newsParishes].
@ProviderFor(newsParishes)
final newsParishesProvider = AutoDisposeFutureProvider<List<Parish>>.internal(
  newsParishes,
  name: r'newsParishesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$newsParishesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NewsParishesRef = AutoDisposeFutureProviderRef<List<Parish>>;
String _$newsPostHash() => r'148fc7da5b98db8868105bd157af59dbf7bee7e8';

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

/// See also [newsPost].
@ProviderFor(newsPost)
const newsPostProvider = NewsPostFamily();

/// See also [newsPost].
class NewsPostFamily extends Family<AsyncValue<BlogPost?>> {
  /// See also [newsPost].
  const NewsPostFamily();

  /// See also [newsPost].
  NewsPostProvider call(String postId) {
    return NewsPostProvider(postId);
  }

  @override
  NewsPostProvider getProviderOverride(covariant NewsPostProvider provider) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'newsPostProvider';
}

/// See also [newsPost].
class NewsPostProvider extends AutoDisposeFutureProvider<BlogPost?> {
  /// See also [newsPost].
  NewsPostProvider(String postId)
    : this._internal(
        (ref) => newsPost(ref as NewsPostRef, postId),
        from: newsPostProvider,
        name: r'newsPostProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$newsPostHash,
        dependencies: NewsPostFamily._dependencies,
        allTransitiveDependencies: NewsPostFamily._allTransitiveDependencies,
        postId: postId,
      );

  NewsPostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<BlogPost?> Function(NewsPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NewsPostProvider._internal(
        (ref) => create(ref as NewsPostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BlogPost?> createElement() {
    return _NewsPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NewsPostProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NewsPostRef on AutoDisposeFutureProviderRef<BlogPost?> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _NewsPostProviderElement
    extends AutoDisposeFutureProviderElement<BlogPost?>
    with NewsPostRef {
  _NewsPostProviderElement(super.provider);

  @override
  String get postId => (origin as NewsPostProvider).postId;
}

String _$newsRecentPostsHash() => r'd15dd89aa212202e6289da83fc21deab90533994';

/// See also [newsRecentPosts].
@ProviderFor(newsRecentPosts)
const newsRecentPostsProvider = NewsRecentPostsFamily();

/// See also [newsRecentPosts].
class NewsRecentPostsFamily extends Family<AsyncValue<List<BlogPost>>> {
  /// See also [newsRecentPosts].
  const NewsRecentPostsFamily();

  /// See also [newsRecentPosts].
  NewsRecentPostsProvider call({String? excludePostId}) {
    return NewsRecentPostsProvider(excludePostId: excludePostId);
  }

  @override
  NewsRecentPostsProvider getProviderOverride(
    covariant NewsRecentPostsProvider provider,
  ) {
    return call(excludePostId: provider.excludePostId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'newsRecentPostsProvider';
}

/// See also [newsRecentPosts].
class NewsRecentPostsProvider
    extends AutoDisposeFutureProvider<List<BlogPost>> {
  /// See also [newsRecentPosts].
  NewsRecentPostsProvider({String? excludePostId})
    : this._internal(
        (ref) => newsRecentPosts(
          ref as NewsRecentPostsRef,
          excludePostId: excludePostId,
        ),
        from: newsRecentPostsProvider,
        name: r'newsRecentPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$newsRecentPostsHash,
        dependencies: NewsRecentPostsFamily._dependencies,
        allTransitiveDependencies:
            NewsRecentPostsFamily._allTransitiveDependencies,
        excludePostId: excludePostId,
      );

  NewsRecentPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.excludePostId,
  }) : super.internal();

  final String? excludePostId;

  @override
  Override overrideWith(
    FutureOr<List<BlogPost>> Function(NewsRecentPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NewsRecentPostsProvider._internal(
        (ref) => create(ref as NewsRecentPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        excludePostId: excludePostId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BlogPost>> createElement() {
    return _NewsRecentPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NewsRecentPostsProvider &&
        other.excludePostId == excludePostId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, excludePostId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NewsRecentPostsRef on AutoDisposeFutureProviderRef<List<BlogPost>> {
  /// The parameter `excludePostId` of this provider.
  String? get excludePostId;
}

class _NewsRecentPostsProviderElement
    extends AutoDisposeFutureProviderElement<List<BlogPost>>
    with NewsRecentPostsRef {
  _NewsRecentPostsProviderElement(super.provider);

  @override
  String? get excludePostId =>
      (origin as NewsRecentPostsProvider).excludePostId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
