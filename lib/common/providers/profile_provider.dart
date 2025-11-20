// lib/common/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/auth_providers.dart'; // Your auth providers
import 'package:locally/common/services/profile/profile_service.dart';

/// Provides the ProfileService instance, depends on SupabaseClient
final profileServiceProvider = Provider<ProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return ProfileService(client);
});

final currentUserProfileProvider = StreamProvider<Seller?>((ref) {
  final authState = ref.watch(authStateProvider);

  final user = authState.value;

  if (user != null) {
    final profileService = ref.watch(profileServiceProvider);
    return profileService.getProfileStream(user.id);
  } else {
    return Stream.value(null);
  }
});

final getProfileByIdProvider = FutureProvider.family<Seller, String>((
  ref,
  uid,
) async {
  final profileService = ref.watch(profileServiceProvider);

  final result = await profileService.getProfile(uid);

  return result.fold(
    (failure) =>
        throw failure, // The FutureProvider will expose this as an error
    (seller) => seller, // Success
  );
});
