import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/news/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/events/data/repositories/business_events_repository.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/businesses/data/models/featured_business.dart';
import '../../data/models/home_models.dart';

part 'home_providers.g.dart';

@riverpod
Future<List<FeaturedBusiness>> homeFeaturedSpots(Ref ref) async {
  final businessRepo = ref.watch(businessRepositoryProvider);
  return businessRepo.getFeaturedBusiness(limit: 10);
}

@riverpod
Future<List<BusinessCategory>> homeCategories(Ref ref) async {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  // Optimized: backend now returns business_count directly in listCategories
  return categoryRepo.listCategories();
}

@riverpod
Future<List<BlogPost>> homeLatestPosts(Ref ref) async {
  final blogRepo = ref.watch(blogPostsRepositoryProvider);
  final parishIds = await UserParishPreferences.getPreferredParishIds();
  return blogRepo.listApproved(limit: 10, forParishIds: parishIds.isEmpty ? null : parishIds);
}

@riverpod
Future<List<HomeEvent>> homeUpcomingEvents(Ref ref) async {
  final eventsRepo = ref.watch(businessEventsRepositoryProvider);
  final businessRepo = ref.watch(businessRepositoryProvider);

  final rawEvents = await eventsRepo.listApproved();
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  final filteredEvents = rawEvents
      .where((e) {
        final local = e.eventDate.isUtc ? e.eventDate.toLocal() : e.eventDate;
        final eventDay = DateTime(local.year, local.month, local.day);
        return !eventDay.isBefore(startOfToday);
      })
      .take(6)
      .toList();

  final result = <HomeEvent>[];
  for (final e in filteredEvents) {
    final business = await businessRepo.getById(e.businessId);
    result.add(
      HomeEvent(
        id: e.id,
        businessId: e.businessId,
        businessName: business?.name ?? 'Local Business',
        title: e.title,
        eventDate: e.eventDate,
        imageUrl: e.imageUrl,
        location: e.location,
      ),
    );
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
