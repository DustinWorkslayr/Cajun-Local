import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/categories/data/models/subcategory.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_listing_controller.freezed.dart';
part 'create_listing_controller.g.dart';

@freezed
abstract class CreateListingState with _$CreateListingState {
  const factory CreateListingState({
    @Default([]) List<BusinessCategory> categories,
    @Default([]) List<Parish> parishes,
    @Default([]) List<Subcategory> subcategories,
    @Default(true) bool categoriesLoading,
    @Default(true) bool parishesLoading,
    @Default(false) bool subcategoriesLoading,

    // Form State
    BusinessCategory? selectedCategory,
    Parish? selectedParish,
    @Default({}) Set<String> selectedSubcategoryIds,
    @Default(false) bool agreedToPrivacy,
    String? message,
    @Default(false) bool success,
    @Default(false) bool submitting,
    String? createdBusinessId,
  }) = _CreateListingState;
}

@riverpod
class CreateListingController extends _$CreateListingController {
  @override
  FutureOr<CreateListingState> build() async {
    final results = await Future.wait([
      CategoryRepository().listCategories(),
      ParishRepository().listParishes(),
    ]);

    return CreateListingState(
      categories: results[0] as List<BusinessCategory>,
      parishes: results[1] as List<Parish>,
      categoriesLoading: false,
      parishesLoading: false,
    );
  }

  void updateCategory(BusinessCategory? category) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      selectedCategory: category,
      selectedSubcategoryIds: {},
    ));

    if (category != null) {
      loadSubcategories(category.id);
    }
  }

  void updateParish(Parish? parish) {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(selectedParish: parish));
  }

  void toggleSubcategory(String id) {
    final currentState = state.value;
    if (currentState == null) return;

    final current = Set<String>.from(currentState.selectedSubcategoryIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = AsyncValue.data(currentState.copyWith(selectedSubcategoryIds: current));
  }

  void updateAgreedToPrivacy(bool value) {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(agreedToPrivacy: value));
  }

  Future<void> loadSubcategories(String categoryId) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(subcategoriesLoading: true));
    try {
      final subcategories = await CategoryRepository().listSubcategories(categoryId: categoryId);
      state = AsyncValue.data(state.value!.copyWith(
        subcategories: subcategories,
        subcategoriesLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        subcategories: [],
        subcategoriesLoading: false,
      ));
    }
  }

  Future<bool> submit({
    required String name,
    required String address,
    required String phone,
    required String website,
  }) async {
    final currentState = state.value;
    if (currentState == null) return false;

    if (currentState.selectedCategory == null) {
      state = AsyncValue.data(currentState.copyWith(message: 'Please select a category.', success: false));
      return false;
    }
    if (currentState.selectedParish == null) {
      state = AsyncValue.data(currentState.copyWith(message: 'Please select a parish.', success: false));
      return false;
    }
    if (!currentState.agreedToPrivacy) {
      state = AsyncValue.data(currentState.copyWith(message: 'Please agree to the Privacy Policy.', success: false));
      return false;
    }

    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (uid == null) {
      state = AsyncValue.data(currentState.copyWith(message: 'You must be signed in.', success: false));
      return false;
    }

    state = AsyncValue.data(currentState.copyWith(message: null, submitting: true));

    try {
      final businessRepo = BusinessRepository();
      final businessId = await businessRepo.insertBusiness(
        name: name,
        categoryId: currentState.selectedCategory!.id,
        createdBy: uid,
        address: address.isEmpty ? null : address,
        city: address.isEmpty ? currentState.selectedParish?.name : null,
        parish: currentState.selectedParish?.id,
        state: 'LA',
        phone: phone.isEmpty ? null : phone,
        website: website.isEmpty ? null : website,
      );

      await businessRepo.setBusinessSubcategories(businessId, currentState.selectedSubcategoryIds.toList());

      state = AsyncValue.data(state.value!.copyWith(
        message: 'Listing created.',
        success: true,
        submitting: false,
        createdBusinessId: businessId,
      ));
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        message: e.toString(),
        success: false,
        submitting: false,
      ));
      return false;
    }
  }
}
