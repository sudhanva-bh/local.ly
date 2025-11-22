import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/features/consumer/view_product/widgets/add_reviews_modal_sheet.dart';

class ConsumerProductRatingsSection extends ConsumerWidget {
  final String productId;
  final List<Rating> ratings;
  final double averageRating;

  const ConsumerProductRatingsSection({
    super.key,
    required this.productId,
    required this.ratings,
    required this.averageRating,
  });

  void _showAddReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddReviewSheet(productId: productId),
    );
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for DraggableScrollableSheet
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => AllReviewsSheet(
        ratings: ratings,
        averageRating: averageRating,
        productId: productId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.text;

    final visibleReviews = ratings.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Row ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reviews (${ratings.length})",
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStarBar(averageRating, colors.primary, 18),
                  ],
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddReviewSheet(context),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text("Write Review"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: colors.outlineVariant.withOpacity(0.5)),

        // --- Review List ---
        if (ratings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "No reviews yet. Be the first!",
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < visibleReviews.length; i++) ...[
                _ReviewCard(review: visibleReviews[i]),
                if (i < visibleReviews.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),

        if (ratings.length > 3)
          Center(
            child: TextButton(
              onPressed: () => _showAllReviews(context),
              child: const Text("View all reviews"),
            ),
          ),
      ],
    );
  }

  Widget _buildStarBar(double rating, Color color, double size) {
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
// 🃏 Internal: Single Review Card
// -----------------------------------------------------------------------------
class _ReviewCard extends StatelessWidget {
  final Rating review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  (review.reviewerName ?? "A")[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName ?? "Anonymous",
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: i < review.stars ? Colors.amber : colors.outline,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (review.title.isNotEmpty)
            Text(
              review.title,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (review.description != null && review.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.description!,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📝 Internal: Add Review Sheet
// -----------------------------------------------------------------------------
class _AddReviewSheet extends ConsumerStatefulWidget {
  final String productId;

  const _AddReviewSheet({required this.productId});

  @override
  ConsumerState<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<_AddReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  int _rating = 5;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get User Info
      final userProfile = ref.read(currentConsumerProfileProvider).value;
      final userName = userProfile != null
          ? userProfile.fullName
          : "Local Shopper";

      // 2. Create Rating Object
      final newRating = Rating(
        ratingId: DateTime.now().millisecondsSinceEpoch
            .toString(), // Simple ID gen
        stars: _rating,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        reviewerName: userName,
      );

      // 3. Call Service
      final service = ref.read(retailProductServiceProvider);
      await service.addProductRating(widget.productId, newRating);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Write a Review", style: text.headlineSmall),
              const SizedBox(height: 20),

              // Star Rating Input
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 40,
                        color: index < _rating ? Colors.amber : colors.outline,
                      ),
                    );
                  }),
                ),
              ),
              Center(
                child: Text(
                  _rating == 5
                      ? "Excellent!"
                      : _rating == 4
                      ? "Good"
                      : _rating == 3
                      ? "Fair"
                      : _rating == 2
                      ? "Bad"
                      : "Poor",
                  style: text.labelLarge?.copyWith(color: colors.primary),
                ),
              ),
              const SizedBox(height: 20),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title (e.g. Great Quality!)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Review (Optional)",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Submit Review"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
