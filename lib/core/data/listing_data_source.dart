import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';

part 'listing_data_source.g.dart';

/// Bridge between legacy mock-based code and new repository-based data.
/// Eventually this should be deleted once all callers move to repositories directly.
class ListingDataSource {
  ListingDataSource({
    BusinessRepository? businessRepository,
    ParishRepository? parishRepository,
    CategoryRepository? categoryRepository,
  })  : _businessRepository = businessRepository ?? BusinessRepository(),
        _parishRepository = parishRepository ?? ParishRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository();

  final BusinessRepository _businessRepository;
  final ParishRepository _parishRepository;
  final CategoryRepository _categoryRepository;

  /// Placeholder for legacy compatibility.
  bool get useBackend => true;

  /// Returns current user from mock data (for legacy parts).
  Future<MockUser> getCurrentUser() async => MockData.currentUser;

  Future<List<MockParish>> getParishes() async {
    final list = await _parishRepository.listParishes();
    return list.map((p) => MockParish(id: p.id, name: p.name)).toList();
  }

  Future<List<MockCategory>> getCategories() async {
    final list = await _categoryRepository.listCategories();
    final result = <MockCategory>[];
    for (final c in list) {
        final subs = await _categoryRepository.listSubcategories(categoryId: c.id);
        result.add(MockCategory(
            id: c.id,
            name: c.name,
            iconName: c.icon ?? 'store',
            subcategories: subs.map((s) => MockSubcategory(id: s.id, name: s.name)).toList(),
        ));
    }
    return result;
  }

  Future<List<MockListing>> filterListings(ListingFilters filters) async {
    final list = await _businessRepository.listApproved(
      categoryId: filters.categoryId,
      parishIds: filters.parishIds,
    );
    
    // Convert Business to MockListing
    return list.map((b) => _toMock(b)).toList();
  }

  Future<MockListing?> getListingById(String id) async {
    final b = await _businessRepository.getById(id);
    if (b == null) return null;
    return _toMock(b);
  }

  MockListing _toMock(Business b) {
    return MockListing(
      id: b.id,
      name: b.name,
      tagline: b.tagline ?? '',
      description: b.description ?? '',
      categoryId: b.categoryId,
      categoryName: '', 
      address: b.address,
      phone: b.phone,
      website: b.website,
      parishId: b.parish,
      parishIds: b.parish != null ? [b.parish!] : [],
    );
  }
}

@riverpod
ListingDataSource listingDataSource(ListingDataSourceRef ref) {
  return ListingDataSource(
    businessRepository: ref.watch(businessRepositoryProvider),
    parishRepository: ref.watch(parishRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}
