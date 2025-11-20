// lib/common/providers/consumer_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/consumer_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/profile/consumer_profile_service.dart';

/// Provides the ConsumerProfileService instance
final consumerProfileServiceProvider = Provider<ConsumerProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return ConsumerProfileService(client);
});

/// Streams the currently logged-in user's CONSUMER profile
/// Returns null if not logged in or if the profile doesn't exist yet
final currentConsumerProfileProvider = StreamProvider<ConsumerModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  final user = authState.value;

  if (user != null) {
    final profileService = ref.watch(consumerProfileServiceProvider);
    return profileService.getProfileStream(user.id);
  } else {
    return Stream.value(null);
  }
});

/// Fetches a specific ConsumerModel profile by their UID
/// Useful for viewing other users' profiles (if your app logic allows)
final getConsumerProfileByIdProvider =
    FutureProvider.family<ConsumerModel, String>((
      ref,
      uid,
    ) async {
      final profileService = ref.watch(consumerProfileServiceProvider);

      final result = await profileService.getProfile(uid);

      return result.fold(
        (failure) =>
            throw failure, // The FutureProvider will expose this as an error
        (consumer) => consumer, // Success
      );
    });
