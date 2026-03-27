import 'package:flutter/material.dart';

/// Maps material icon name strings (e.g. from the backend) to Material IconData.
/// Returns a default fallback icon if the name is not found or is null.
class IconMapper {
  static IconData getIcon(String? iconName, {IconData fallback = Icons.category_rounded}) {
    if (iconName == null || iconName.isEmpty) return fallback;

    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'local_play':
        return Icons.local_play_rounded;
      case 'design_services':
        return Icons.design_services_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'storefront':
        return Icons.storefront_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'local_bar':
        return Icons.local_bar_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'construction':
        return Icons.construction_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      default:
        // Try mapping the exact string dynamically just in case, but prefer the switch statement above.
        // It's safer to just return a fallback for unknown icons so we don't crash.
        return fallback;
    }
  }
}
