import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/ratings/rating_model.dart';

class ProductRatingCard extends StatelessWidget {
  final Rating rating;

  const ProductRatingCard({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Star Rating ---
        _buildStarRating(context, rating.stars),
        const SizedBox(height: 8),

        // --- Title ---
        Text(
          rating.title,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // --- Description (if it exists) ---
        if (rating.description != null && rating.description!.isNotEmpty)
          Text(
            rating.description!,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }

  /// Helper to build the star icons
  Widget _buildStarRating(BuildContext context, int starCount) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < starCount ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}