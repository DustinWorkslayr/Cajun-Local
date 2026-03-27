import 'package:flutter/material.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/reviews/data/models/review.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_shared.dart';

/// "Reviews" tab — average rating row + list of review cards.
class BusinessDetailReviewsTab extends StatelessWidget {
  const BusinessDetailReviewsTab({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.reviewCount,
  });

  final List<Review> reviews;
  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const BdEmptyState(icon: Icons.rate_review_outlined, message: 'No reviews yet');
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Average rating row
      Row(children: [
        ...List.generate(5, (i) => Icon(
          i < averageRating.round().clamp(0, 5) ? Icons.star_rounded : Icons.star_border_rounded,
          size: 22,
          color: AppTheme.specGold,
        )),
        const SizedBox(width: 8),
        Text(
          '${averageRating.toStringAsFixed(1)} ($reviewCount)',
          style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ]),
      const SizedBox(height: 14),

      // Review cards
      ...reviews.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF191C1D).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: List.generate(5, (i) => Icon(
                i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 14,
                color: AppTheme.specGold,
              ))),
              if (r.createdAt != null)
                Text('${r.createdAt!.month}/${r.createdAt!.day}/${r.createdAt!.year}', style: const TextStyle(color: AppTheme.specOutline, fontSize: 12)),
            ]),
            if (r.body?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(r.body!, style: const TextStyle(color: AppTheme.specNavy, fontSize: 14, height: 1.5)),
            ],
          ]),
        ),
      )),
    ]);
  }
}
