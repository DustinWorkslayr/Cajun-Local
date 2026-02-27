import 'package:flutter/material.dart';

/// Icon name (stored in DB) and display label for category icon picker.
class CategoryIconOption {
  const CategoryIconOption({required this.name, required this.label});
  final String name;
  final String label;
}

/// All category icon options for admin picker. Empty [name] = default (general).
const List<CategoryIconOption> kCategoryIconOptions = [
  CategoryIconOption(name: '', label: 'Default'),
  CategoryIconOption(name: 'restaurant', label: 'Restaurant'),
  CategoryIconOption(name: 'local_cafe', label: 'Cafe'),
  CategoryIconOption(name: 'bakery_dining', label: 'Bakery'),
  CategoryIconOption(name: 'lunch_dining', label: 'Lunch'),
  CategoryIconOption(name: 'dinner_dining', label: 'Dinner'),
  CategoryIconOption(name: 'brunch_dining', label: 'Brunch'),
  CategoryIconOption(name: 'restaurant_menu', label: 'Menu'),
  CategoryIconOption(name: 'local_dining', label: 'Dining'),
  CategoryIconOption(name: 'fastfood', label: 'Fast food'),
  CategoryIconOption(name: 'cake', label: 'Cake'),
  CategoryIconOption(name: 'icecream', label: 'Ice cream'),
  CategoryIconOption(name: 'local_bar', label: 'Bar'),
  CategoryIconOption(name: 'wine_bar', label: 'Wine bar'),
  CategoryIconOption(name: 'sports_bar', label: 'Sports bar'),
  CategoryIconOption(name: 'nightlife', label: 'Nightlife'),
  CategoryIconOption(name: 'music_note', label: 'Music'),
  CategoryIconOption(name: 'theater_comedy', label: 'Theater'),
  CategoryIconOption(name: 'store', label: 'Store'),
  CategoryIconOption(name: 'storefront', label: 'Storefront'),
  CategoryIconOption(name: 'shopping_bag', label: 'Shopping bag'),
  CategoryIconOption(name: 'shopping_cart', label: 'Shopping cart'),
  CategoryIconOption(name: 'terrain', label: 'Terrain'),
  CategoryIconOption(name: 'park', label: 'Park'),
  CategoryIconOption(name: 'nature_people', label: 'Nature'),
  CategoryIconOption(name: 'beach_access', label: 'Beach'),
  CategoryIconOption(name: 'museum', label: 'Museum'),
  CategoryIconOption(name: 'palette', label: 'Art'),
  CategoryIconOption(name: 'brush', label: 'Brush'),
  CategoryIconOption(name: 'camera_alt', label: 'Camera'),
  CategoryIconOption(name: 'auto_stories', label: 'Stories'),
  CategoryIconOption(name: 'menu_book', label: 'Book'),
  CategoryIconOption(name: 'fitness_center', label: 'Fitness'),
  CategoryIconOption(name: 'spa', label: 'Spa'),
  CategoryIconOption(name: 'local_hospital', label: 'Health'),
  CategoryIconOption(name: 'school', label: 'School'),
  CategoryIconOption(name: 'account_balance', label: 'Finance'),
  CategoryIconOption(name: 'work', label: 'Work'),
  CategoryIconOption(name: 'build', label: 'Build'),
  CategoryIconOption(name: 'plumbing', label: 'Plumbing'),
  CategoryIconOption(name: 'electrical_services', label: 'Electrical'),
  CategoryIconOption(name: 'cleaning_services', label: 'Cleaning'),
  CategoryIconOption(name: 'handyman', label: 'Handyman'),
  CategoryIconOption(name: 'category', label: 'General'),
];

/// Returns Material icon for category icon [name] (stored in DB). Empty/null => default.
IconData getCategoryIconData(String? name) {
  if (name == null || name.isEmpty) return Icons.category_rounded;
  switch (name) {
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'local_cafe':
      return Icons.local_cafe_rounded;
    case 'bakery_dining':
      return Icons.bakery_dining_rounded;
    case 'lunch_dining':
      return Icons.lunch_dining_rounded;
    case 'dinner_dining':
      return Icons.dinner_dining_rounded;
    case 'brunch_dining':
      return Icons.brunch_dining_rounded;
    case 'restaurant_menu':
      return Icons.restaurant_menu_rounded;
    case 'local_dining':
      return Icons.local_dining_rounded;
    case 'fastfood':
      return Icons.fastfood_rounded;
    case 'cake':
      return Icons.cake_rounded;
    case 'icecream':
      return Icons.icecream_rounded;
    case 'local_bar':
      return Icons.local_bar_rounded;
    case 'wine_bar':
      return Icons.wine_bar_rounded;
    case 'sports_bar':
      return Icons.sports_bar_rounded;
    case 'nightlife':
      return Icons.nightlife_rounded;
    case 'music_note':
      return Icons.music_note_rounded;
    case 'theater_comedy':
      return Icons.theater_comedy_rounded;
    case 'store':
      return Icons.store_rounded;
    case 'storefront':
      return Icons.storefront_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'shopping_cart':
      return Icons.shopping_cart_rounded;
    case 'terrain':
      return Icons.terrain_rounded;
    case 'park':
      return Icons.park_rounded;
    case 'nature_people':
      return Icons.nature_people_rounded;
    case 'beach_access':
      return Icons.beach_access_rounded;
    case 'museum':
      return Icons.museum_rounded;
    case 'palette':
      return Icons.palette_rounded;
    case 'brush':
      return Icons.brush_rounded;
    case 'camera_alt':
      return Icons.camera_alt_rounded;
    case 'auto_stories':
      return Icons.auto_stories_rounded;
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'fitness_center':
      return Icons.fitness_center_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'work':
      return Icons.work_rounded;
    case 'build':
      return Icons.build_rounded;
    case 'plumbing':
      return Icons.plumbing_rounded;
    case 'electrical_services':
      return Icons.electrical_services_rounded;
    case 'cleaning_services':
      return Icons.cleaning_services_rounded;
    case 'handyman':
      return Icons.handyman_rounded;
    case 'category':
      return Icons.category_rounded;
    default:
      return Icons.category_rounded;
  }
}
