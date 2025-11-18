// lib/features/view_seller/widgets/add_review_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/common/models/users/seller_model.dart';
// Import the profile controller to get the current user's name
import 'package:locally/features/retail_seller/profile_page/controllers/profile_controller.dart';
import 'package:locally/features/view_seller/controllers/review_controller.dart';

/// A simple star rating selection widget
class StarRating extends StatelessWidget {
  final int starCount;
  final double rating;
  final Function(double) onRatingChanged;
  final Color color;

  const StarRating({
    super.key,
    this.starCount = 5,
    this.rating = 0.0,
    required this.onRatingChanged,
    required this.color,
  });

  Widget buildStar(BuildContext context, int index) {
    Icon icon;
    if (index >= rating) {
      icon = Icon(Icons.star_border, color: color, size: 32);
    } else {
      icon = Icon(Icons.star, color: color, size: 32);
    }
    return InkResponse(
      onTap: () => onRatingChanged(index + 1.0),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          List.generate(starCount, (index) => buildStar(context, index)),
    );
  }
}

/// The Bottom Sheet widget for adding a review
class AddReviewSheet extends ConsumerStatefulWidget {
  final Seller seller;
  const AddReviewSheet({super.key, required this.seller});

  @override
  ConsumerState<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<AddReviewSheet> {
  double _stars = 0.0;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a star rating.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Get the current user's profile to find their name
      final currentUserProfile = ref.read(profileControllerProvider);
      final reviewerName = currentUserProfile.value?.shopName ?? 'Anonymous';

      final newRating = Rating(
        // Generate a new unique ID for the rating
        ratingId: ref.read(uuidProvider).v4(),
        stars: _stars.toInt(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        reviewerName: reviewerName, // Attach the user's name
      );

      try {
        await ref
            .read(reviewControllerProvider)
            .addReview(widget.seller, newRating);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Review submitted!'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Close the bottom sheet
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to submit review: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate ${widget.seller.shopName}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StarRating(
              rating: _stars,
              onRatingChanged: (rating) => setState(() => _stars = rating),
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Review Title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty)
                      ? 'Please enter a title'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Share your experience...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    label: const Text("Submit Review"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitReview,
                  ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}