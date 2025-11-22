import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/ratings/rating_model.dart';

// Ensure you import the AddReviewSheet if you want the button to work here too
// import 'package:locally/.../product_ratings_section.dart'; 

class AllReviewsSheet extends ConsumerWidget {
  final List<Rating> ratings;
  final double averageRating;
  final String productId;

  const AllReviewsSheet({
    super.key,
    required this.ratings,
    required this.averageRating,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.text;

    return DraggableScrollableSheet(
      initialChildSize: 0.6, // Starts at 60% height
      minChildSize: 0.4,
      maxChildSize: 0.95, // Expands to almost full screen
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // --- Handle Bar ---
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // --- Fixed Header (Summary) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    // Big Number
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: text.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Star Summary
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStaticStarBar(averageRating, colors.primary, 20),
                        const SizedBox(height: 4),
                        Text(
                          "${ratings.length} Reviews",
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceContainerLow,
                      ),
                    )
                  ],
                ),
              ),
              Divider(color: colors.outlineVariant.withOpacity(0.2)),

              // --- Scrollable List ---
              Expanded(
                child: ratings.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: ratings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          // Reverse list to show newest first
                          final review = ratings.reversed.toList()[index];
                          return ReviewCard(review: review);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: context.colors.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No reviews yet",
            style: context.text.titleMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStarBar(double rating, Color color, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon = Icons.star_border_rounded;
        if (index < rating.floor()) {
          icon = Icons.star_rounded;
        } else if (index < rating && (rating - index) >= 0.5) {
          icon = Icons.star_half_rounded;
        }
        return Icon(icon, color: color, size: size);
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// 🃏 Reusable Review Card (Moved to public class for reuse)
// -----------------------------------------------------------------------------
class ReviewCard extends StatelessWidget {
  final Rating review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _generateAvatarColor(review.reviewerName ?? "A"),
                child: Text(
                  (review.reviewerName ?? "A")[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? "Anonymous",
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.stars ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14,
                          color: i < review.stars ? Colors.amber : colors.outline,
                        );
                      }),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (review.title.isNotEmpty)
            Text(
              review.title,
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (review.description != null && review.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.description!,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to generate consistent colors for avatars based on name
  Color _generateAvatarColor(String name) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}