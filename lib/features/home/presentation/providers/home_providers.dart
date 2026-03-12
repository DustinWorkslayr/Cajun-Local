import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/admin/data/models/parish.dart';
import 'package:cajun_local/features/news/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/features/admin/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/events/data/repositories/business_events_repository.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';

part 'home_providers.g.dart';

@riverpod
Future<List<MockSpot>> homeFeaturedSpots(Ref ref) async {
  final businessRepo = ref.watch(businessRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);

  final businesses = await businessRepo.listApproved(limit: 10);
  final categories = await categoryRepo.listCategories();
  final catMap = {for (final c in categories) c.id: c.name};

  final spots = <MockSpot>[];
  for (final b in businesses) {
    final subIds = await categoryRepo.getSubcategoryIdsForBusiness(b.id);
    String? subLabel;
    if (subIds.isNotEmpty) {
      final subs = await categoryRepo.listSubcategories(categoryId: b.categoryId);
      final firstSub = subs.where((s) => s.id == subIds.first).firstOrNull;
      subLabel = firstSub?.name;
    }

    spots.add(MockSpot(
      id: b.id,
      name: b.name,
      subtitle: b.tagline ?? b.name,
      categoryId: b.categoryId,
      categoryName: catMap[b.categoryId],
      subcategoryName: subLabel,
      logoUrl: b.logoUrl,
      rating: null,
    ));
  }
  return spots;
}

@riverpod
Future<List<MockCategory>> homeCategories(Ref ref) async {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final businessRepo = ref.watch(businessRepositoryProvider);

  final rawCategories = await categoryRepo.listCategories();
  final categories = <MockCategory>[];
  for (final c in rawCategories) {
    final count = await businessRepo.listApprovedCount(categoryId: c.id);
    categories.add(MockCategory(
      id: c.id,
      name: c.name,
      iconName: c.icon ?? 'store',
      count: count,
      subcategories: c.subcategories.map((s) => MockSubcategory(id: s.id, name: s.name)).toList(),
      bucket: c.bucket,
    ));
  }
  return categories;
}

@riverpod
Future<List<BlogPost>> homeLatestPosts(Ref ref) async {
  final blogRepo = ref.watch(blogPostsRepositoryProvider);
  final parishIds = await UserParishPreferences.getPreferredParishIds();
  return blogRepo.listApproved(limit: 10, forParishIds: parishIds.isEmpty ? null : parishIds);
}

@riverpod
Future<List<(MockEvent, String)>> homeUpcomingEvents(Ref ref) async {
  final eventsRepo = ref.watch(businessEventsRepositoryProvider);
  final businessRepo = ref.watch(businessRepositoryProvider);

  final rawEvents = await eventsRepo.listApproved();
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  final filteredEvents = rawEvents.where((e) {
    final local = e.eventDate.isUtc ? e.eventDate.toLocal() : e.eventDate;
    final eventDay = DateTime(local.year, local.month, local.day);
    return !eventDay.isBefore(startOfToday);
  }).take(6).toList();

  final result = <(MockEvent, String)>[];
  for (final e in filteredEvents) {
    final business = await businessRepo.getById(e.businessId);
    result.add((
      MockEvent(
        id: e.id,
        listingId: e.businessId,
        title: e.title,
        eventDate: e.eventDate,
        description: e.description,
        endDate: e.endDate,
        location: e.location,
        imageUrl: e.imageUrl,
        status: e.status,
      ),
      business?.name ?? 'Local Business'
    ));
  }
  return result;
}

@riverpod
Future<List<String>> homePreferredParishNames(Ref ref) async {
  final parishRepo = ref.watch(parishRepositoryProvider);
  final parishIds = await UserParishPreferences.getPreferredParishIds();
  if (parishIds.isEmpty) return [];

  final parishes = await parishRepo.listParishes();
  final parishMap = {for (final p in parishes) p.id: p.name};
  return parishIds.map((id) => parishMap[id] ?? id).toList();
}

@riverpod
Future<List<Parish>> homeParishes(Ref ref) async {
  final parishRepo = ref.watch(parishRepositoryProvider);
  return parishRepo.listParishes();
}
