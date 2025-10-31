// lib/common/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/auth_providers.dart'; // Your auth providers
import 'package:locally/common/services/profile/profile_service.dart';

/// Provides the ProfileService instance, depends on SupabaseClient
final profileServiceProvider = Provider<ProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  
  // The ProfileService constructor is now simpler
  return ProfileService(client);

  /* === OLD CODE TO DELETE ===
  return ProfileService(
    client,
    wholesaleService: ref.watch(wholesaleProductServiceProvider),
    retailService: ref.watch(retailProductServiceProvider),
  );
  */
});

/// == This is the main provider you'll use in the UI ==
///
/// Provides a real-time stream of the *currently logged-in* user's profile.
///
/// It watches the `authStateProvider`.
/// - If the user is **logged out** (auth user is null), it returns a stream of `null`.
/// - If the user is **logged in** (auth user is not null), it switches to the
///   `getProfileStream` from the `ProfileService` using the user's ID.
final currentUserProfileProvider = StreamProvider<Seller?>((ref) {
  // Watch the auth state
  final authState = ref.watch(authStateProvider);

  // Get the User? from the AsyncValue<User?>
  final user = authState.value;

  if (user != null) {
    // User is logged in, get their profile stream
    final profileService = ref.watch(profileServiceProvider);
    return profileService.getProfileStream(user.id);
  } else {
    // User is logged out, return a stream that emits a single null value
    return Stream.value(null);
  }
});

/// Provides a simple [Future] to get a profile by any UID.
///
/// This is useful for viewing *other* sellers' profiles.
/// Use `ref.watch(getProfileByIdProvider('some-user-id'))`
final getProfileByIdProvider = FutureProvider.family<Seller, String>((
  ref,
  uid,
) async {
  final profileService = ref.watch(profileServiceProvider);

  // Call the service
  final result = await profileService.getProfile(uid);

  // Handle the Either result
  return result.fold(
    (failure) =>
        throw failure, // The FutureProvider will expose this as an error
    (seller) => seller, // Success
  );
});