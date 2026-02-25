// ignore_for_file: avoid_print
/// Seeds the Supabase database with fake data for testing.
///
/// Requires env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
/// Run: dart run scripts/seed_database.dart
///
/// Best run against a fresh or test DB; re-running may cause duplicate-key errors
/// unless your tables use upsert or you clear data first.
library;

import 'dart:io';

import 'package:supabase/supabase.dart';

const _cat1 = '11111111-1111-1111-1111-111111111101';
const _cat2 = '11111111-1111-1111-1111-111111111102';
const _cat3 = '11111111-1111-1111-1111-111111111103';
const _sub1 = '22222222-2222-2222-2222-222222222201';
const _sub2 = '22222222-2222-2222-2222-222222222202';
const _sub3 = '22222222-2222-2222-2222-222222222203';
const _sub4 = '22222222-2222-2222-2222-222222222204';
const _biz1 = '33333333-3333-3333-3333-333333333301';
const _biz2 = '33333333-3333-3333-3333-333333333302';
const _biz3 = '33333333-3333-3333-3333-333333333303';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    print('Error: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables.');
    exit(1);
  }

  final client = SupabaseClient(url, key);
  print('Seeding database...');

  try {
    await _seedCategories(client);
    await _seedSubcategories(client);
    await _seedBusinesses(client);
    await _seedBusinessParishes(client);
    await _seedBusinessSubcategories(client);
    await _seedBusinessHours(client);
    await _seedDeals(client);
    await _seedBlogPosts(client);
    await _seedNotificationBanners(client);
    print('Done.');
  } catch (e, st) {
    print('Seed failed: $e');
    print(st);
    exit(1);
  }
}

Future<void> _seedCategories(SupabaseClient client) async {
  await client.from('business_categories').upsert([
    {'id': _cat1, 'name': 'Restaurants', 'icon': 'restaurant', 'sort_order': 1},
    {'id': _cat2, 'name': 'Music & Events', 'icon': 'music_note', 'sort_order': 2},
    {'id': _cat3, 'name': 'Shopping', 'icon': 'store', 'sort_order': 3},
  ], onConflict: 'id');
  print('  business_categories');
}

Future<void> _seedSubcategories(SupabaseClient client) async {
  await client.from('subcategories').upsert([
    {'id': _sub1, 'name': 'Cajun', 'category_id': _cat1},
    {'id': _sub2, 'name': 'Seafood', 'category_id': _cat1},
    {'id': _sub3, 'name': 'Zydeco', 'category_id': _cat2},
    {'id': _sub4, 'name': 'Local crafts', 'category_id': _cat3},
  ], onConflict: 'id');
  print('  subcategories');
}

Future<void> _seedBusinesses(SupabaseClient client) async {
  await client.from('businesses').upsert([
    {
      'id': _biz1,
      'name': 'Bayou Bites',
      'status': 'approved',
      'category_id': _cat1,
      'city': 'Lafayette',
      'parish': 'lafayette',
      'state': 'LA',
      'address': '412 Bayou Teche Rd, Lafayette, LA 70501',
      'phone': '(337) 555-0142',
      'description': "Family-owned since 1982. Authentic gumbo and po'boys.",
      'tagline': "Authentic gumbo & po'boys",
    },
    {
      'id': _biz2,
      'name': 'Zydeco Hall',
      'status': 'approved',
      'category_id': _cat2,
      'city': 'Lafayette',
      'parish': 'lafayette',
      'state': 'LA',
      'address': '200 Festival Way, Lafayette, LA 70506',
      'phone': '(337) 555-0198',
      'description': 'Live Cajun and zydeco. Dance floor and full bar.',
      'tagline': 'Live music & dancing',
    },
    {
      'id': _biz3,
      'name': 'Cajun Spice Market',
      'status': 'approved',
      'category_id': _cat3,
      'city': 'Breaux Bridge',
      'parish': 'st_martin',
      'state': 'LA',
      'address': '101 Main St, Breaux Bridge, LA 70517',
      'phone': '(337) 555-0221',
      'description': 'Cajun spices, hot sauces, and local crafts.',
      'tagline': 'Local spices & crafts',
    },
  ], onConflict: 'id');
  print('  businesses');
}

Future<void> _seedBusinessParishes(SupabaseClient client) async {
  await client.from('business_parishes').upsert([
    {'business_id': _biz1, 'parish_id': 'lafayette'},
    {'business_id': _biz2, 'parish_id': 'lafayette'},
    {'business_id': _biz3, 'parish_id': 'st_martin'},
  ], onConflict: 'business_id,parish_id');
  print('  business_parishes');
}

Future<void> _seedBusinessSubcategories(SupabaseClient client) async {
  await client.from('business_subcategories').upsert([
    {'business_id': _biz1, 'subcategory_id': _sub1},
    {'business_id': _biz1, 'subcategory_id': _sub2},
    {'business_id': _biz2, 'subcategory_id': _sub3},
    {'business_id': _biz3, 'subcategory_id': _sub4},
  ], onConflict: 'business_id,subcategory_id');
  print('  business_subcategories');
}

Future<void> _seedBusinessHours(SupabaseClient client) async {
  final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final rows = <Map<String, dynamic>>[];
  for (final d in days) {
    if (d == 'sunday') {
      rows.add({'business_id': _biz1, 'day_of_week': d, 'open_time': '12:00', 'close_time': '20:00', 'is_closed': false});
    } else {
      rows.add({'business_id': _biz1, 'day_of_week': d, 'open_time': '11:00', 'close_time': d == 'friday' || d == 'saturday' ? '22:00' : '21:00', 'is_closed': false});
    }
  }
  rows.addAll([
    {'business_id': _biz2, 'day_of_week': 'thursday', 'open_time': '18:00', 'close_time': '02:00', 'is_closed': false},
    {'business_id': _biz2, 'day_of_week': 'friday', 'open_time': '18:00', 'close_time': '02:00', 'is_closed': false},
    {'business_id': _biz2, 'day_of_week': 'saturday', 'open_time': '18:00', 'close_time': '02:00', 'is_closed': false},
    {'business_id': _biz2, 'day_of_week': 'sunday', 'open_time': '16:00', 'close_time': '00:00', 'is_closed': false},
  ]);
  for (final d in days) {
    rows.add({
      'business_id': _biz3,
      'day_of_week': d,
      'open_time': d == 'sunday' ? '10:00' : '09:00',
      'close_time': d == 'sunday' ? '16:00' : '18:00',
      'is_closed': false,
    });
  }
  await client.from('business_hours').upsert(rows, onConflict: 'business_id,day_of_week');
  print('  business_hours');
}

Future<void> _seedDeals(SupabaseClient client) async {
  final now = DateTime.now().toUtc().toIso8601String();
  final end90 = DateTime.now().toUtc().add(const Duration(days: 90)).toIso8601String();
  final end60 = DateTime.now().toUtc().add(const Duration(days: 60)).toIso8601String();
  final end30 = DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String();
  await client.from('deals').insert([
    {'business_id': _biz1, 'title': '10% off lunch', 'deal_type': 'percentage', 'status': 'approved', 'description': 'Valid Mon–Fri 11am–2pm. Dine-in only.', 'is_active': true, 'start_date': now, 'end_date': end90},
    {'business_id': _biz1, 'title': 'Free dessert with entrée', 'deal_type': 'freebie', 'status': 'approved', 'description': 'Order any entrée, get bread pudding or pecan pie on the house.', 'is_active': true, 'start_date': now, 'end_date': end60},
    {'business_id': _biz2, 'title': 'Half-price cover on Thursday', 'deal_type': 'percentage', 'status': 'approved', 'description': 'Show this deal at the door for half-price cover.', 'is_active': true, 'start_date': now, 'end_date': end30},
  ]);
  print('  deals');
}

Future<void> _seedBlogPosts(SupabaseClient client) async {
  final now = DateTime.now().toUtc().toIso8601String();
  await client.from('blog_posts').upsert([
    {'id': '55555555-5555-5555-5555-555555555501', 'slug': 'welcome-to-cajun-local', 'title': 'Welcome to Cajun Local', 'body': '<p>Discover local businesses, deals, and events in Acadiana.</p><p>We’re here to connect you with the best of Louisiana.</p>', 'status': 'approved', 'published_at': now},
    {'id': '55555555-5555-5555-5555-555555555502', 'slug': 'best-gumbo-in-town', 'title': 'Best Gumbo in Town', 'body': '<p>Our roundup of top gumbo spots this season.</p><h2>Bayou favorites</h2><p>From classic chicken and andouille to seafood gumbo.</p>', 'status': 'approved', 'published_at': now},
  ], onConflict: 'slug');
  print('  blog_posts');
}

Future<void> _seedNotificationBanners(SupabaseClient client) async {
  await client.from('notification_banners').upsert([
    {'id': '44444444-4444-4444-4444-444444444401', 'title': 'Welcome', 'message': 'Thanks for using Cajun Local. Check out our latest deals and events!', 'is_active': true},
  ], onConflict: 'id');
  print('  notification_banners');
}
