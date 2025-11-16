import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/all_rating_sheet.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/rating_card.dart';

class ProductRatingsSection extends StatelessWidget {
  final List<Rating> ratings;
  final double averageRating;

  const ProductRatingsSection({
    super.key,
    required this.ratings,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final topThreeRatings = ratings.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colors.outline.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(
          "Ratings & Reviews",
          style: text.titleMedium!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // --- Average Rating Summary ---
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              "${averageRating.toStringAsFixed(1)} out of 5",
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              "(${ratings.length} ratings)",
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),

        const SizedBox(height: 20),
        // --- List of Top 3 Ratings ---
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < topThreeRatings.length; i++) ...[
              ProductRatingCard(rating: topThreeRatings[i]),
              // Add a separator unless it's the last item
              if (i < topThreeRatings.length - 1)
                Divider(color: colors.outline.withOpacity(0.2), height: 24),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // --- "See All" Button ---
        if (ratings.length > 3)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => showAllRatingsSheet(context, ratings),
              child: Text("See all ${ratings.length} reviews"),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
