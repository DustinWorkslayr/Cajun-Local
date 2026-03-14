import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/businesses/data/models/business_image.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_images_repository.dart';
import 'package:cajun_local/core/data/services/business_images_storage_service.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'dart:typed_data';

part 'details_tab_controller.freezed.dart';
part 'details_tab_controller.g.dart';

@freezed
abstract class DetailsTabState with _$DetailsTabState {
  const factory DetailsTabState({
    @Default([]) List<BusinessCategory> categories,
    @Default([]) List<Parish> parishes,
    @Default([]) List<String> initialSubcategoryIds,
    @Default([]) List<BusinessImage> galleryImages,
    @Default(false) bool galleryLoading,
    @Default(false) bool uploadingGallery,
    @Default(false) bool saving,
    String? error,
    @Default(false) bool success,
    Business? businessRaw,
  }) = _DetailsTabState;
}

@riverpod
class DetailsTabController extends _$DetailsTabController {
  @override
  FutureOr<DetailsTabState> build(String listingId) async {
    final results = await Future.wait([
      CategoryRepository().listCategories(),
      ParishRepository().listParishes(),
      CategoryRepository().getSubcategoryIdsForBusiness(listingId),
      BusinessRepository().getByIdForManager(listingId),
      BusinessImagesRepository().listForBusiness(listingId),
    ]);

    return DetailsTabState(
      categories: results[0] as List<BusinessCategory>,
      parishes: results[1] as List<Parish>,
      initialSubcategoryIds: results[2] as List<String>,
      businessRaw: results[3] as Business?,
      galleryImages: results[4] as List<BusinessImage>,
    );
  }

  Future<void> save({
    required String name,
    required String tagline,
    required String? categoryId,
    required String address,
    required String phone,
    required String website,
    required String description,
    required String? parishId,
    required List<String> serviceParishIds,
    required List<String> subcategoryIds,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(saving: true, success: false, error: null));

    try {
      final repo = BusinessRepository();

      await repo.updateBusiness(
        listingId,
        name: name,
        tagline: tagline,
        categoryId: categoryId,
        address: address,
        phone: phone,
        website: website,
        description: description,
        parish: parishId,
      );

      await repo.setBusinessParishes(listingId, serviceParishIds);
      await repo.setBusinessSubcategories(listingId, subcategoryIds);

      final updatedBusiness = await BusinessRepository().getByIdForManager(listingId);

      state = AsyncValue.data(currentState.copyWith(businessRaw: updatedBusiness, success: true, saving: false));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> uploadImage({
    required Uint8List bytes,
    required String extension,
    required String type, // 'gallery', 'logo', 'banner'
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (type == 'gallery') {
      state = AsyncValue.data(currentState.copyWith(uploadingGallery: true));
    } else {
      state = AsyncValue.data(currentState.copyWith(saving: true));
    }

    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: listingId,
        type: type,
        bytes: bytes,
        extension: extension,
      );

      final uid = ref.read(authControllerProvider).valueOrNull?.id;
      final isAdmin = uid != null && await ref.read(authControllerProvider.notifier).isAdmin();

      if (type == 'gallery') {
        await BusinessImagesRepository().insert(
          businessId: listingId,
          url: url,
          sortOrder: currentState.galleryImages.length,
          approvedBy: isAdmin ? uid : null,
        );
        final updatedGallery = await BusinessImagesRepository().listForBusiness(listingId);
        state = AsyncValue.data(currentState.copyWith(galleryImages: updatedGallery, uploadingGallery: false));
      } else {
        await BusinessRepository().updateBusiness(
          listingId,
          logoUrl: type == 'logo' ? url : null,
          bannerUrl: type == 'banner' ? url : null,
        );
        final updatedBusiness = await BusinessRepository().getByIdForManager(listingId);
        state = AsyncValue.data(currentState.copyWith(businessRaw: updatedBusiness, saving: false));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(uploadingGallery: false, saving: false, error: e.toString()));
    }
  }

  Future<void> deleteGalleryImage(String imageId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      await BusinessImagesRepository().delete(imageId);
      final updatedGallery = await BusinessImagesRepository().listForBusiness(listingId);
      state = AsyncValue.data(currentState.copyWith(galleryImages: updatedGallery));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
    }
  }

  Future<void> reorderGallery(int oldIndex, int newIndex) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final images = List<BusinessImage>.from(currentState.galleryImages);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);

    state = AsyncValue.data(currentState.copyWith(galleryImages: images));

    try {
      final ids = images.map((img) => img.id).toList();
      await BusinessImagesRepository().reorder(listingId, ids);
    } catch (e) {
      // Revert if failed?
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
      final originalGallery = await BusinessImagesRepository().listForBusiness(listingId);
      state = AsyncValue.data(currentState.copyWith(galleryImages: originalGallery));
    }
  }
}
