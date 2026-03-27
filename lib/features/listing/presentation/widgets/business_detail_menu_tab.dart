import 'package:flutter/material.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/menu_item.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_shared.dart';

/// "Menu" tab — grouped by section with price pills.
class BusinessDetailMenuTab extends StatelessWidget {
  const BusinessDetailMenuTab({super.key, required this.menuItems});
  final List<MenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    if (menuItems.isEmpty) {
      return const BdEmptyState(icon: Icons.restaurant_menu_rounded, message: 'No menu or services listed yet');
    }

    final cs = Theme.of(context).colorScheme;

    // Group by section
    final bySection = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      bySection.putIfAbsent(item.sectionId, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bySection.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF191C1D).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(children: [
                  Icon(Icons.restaurant_menu_rounded, size: 16, color: AppTheme.specGold),
                  const SizedBox(width: 8),
                  Text(entry.key, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              ),
              Divider(height: 1, color: AppTheme.specSurfaceContainerHigh),
              ...entry.value.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700, fontSize: 14)),
                      if (item.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(item.description!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ])),
                    if (item.price?.isNotEmpty == true)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(item.price!, style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                  ]),
                )),
              const SizedBox(height: 4),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
