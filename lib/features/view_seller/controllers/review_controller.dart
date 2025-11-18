// lib/features/reviews/controllers/review_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/auth_providers.dart'; // For supabaseClientProvider
import 'package:locally/common/providers/profile_provider.dart';
import 'package:uuid/uuid.dart';

class ReviewController {
  final Ref ref;
  ReviewController(this.ref);

  /// Adds a new rating to a seller's profile by calling an RPC
  Future<void> addReview(Seller seller, Rating newRating) async {
    // 1. Get the Supabase client
    final client = ref.read(supabaseClientProvider);

    // 2. Convert the Dart object to a Map (which serializes to JSON)
    final newReviewMap = newRating.toMap();

    try {
      // 3. Call the RPC function by its name
      await client.rpc(
        'add_review_to_profile',
        params: {
          'seller_id': seller.uid,
          // The new_review parameter must be a single JSON object,
          // not an array. The SQL function handles adding it to the array.
          'new_review': newReviewMap,
        },
      );

      // 4. Success! Refresh the FutureProvider to show the new data.
      // ignore: unused_result
      ref.refresh(getProfileByIdProvider(seller.uid));
    } catch (e) {
      // Let the UI (add_review_sheet) handle this error
      throw Exception('Failed to submit review via RPC: $e');
    }
  }
}

/// Provider for the new ReviewController
final reviewControllerProvider = Provider<ReviewController>((ref) {
  return ReviewController(ref);
});

/// Provider for generating unique IDs
final uuidProvider = Provider<Uuid>((ref) => const Uuid());
