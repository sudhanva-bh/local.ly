// lib/common/controllers/profile_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';

/// Controller for handling all profile-related logic.
class ProfileController extends StateNotifier<AsyncValue<Seller?>> {
  final Ref ref;

  ProfileController(this.ref)
    // 1. Initialize state from the *current* value of the stream provider
    : super(ref.watch(currentUserProfileProvider)) {
    // 2. Listen for *future* updates to the stream provider
    ref.listen<AsyncValue<Seller?>>(
      currentUserProfileProvider,
      (_, next) {
        // Ensure we don't get stuck in a loop if the values are the same
        if (state != next) {
          state = next;
        }
      },
    );
  }

  /// Update the entire Seller object (generic update)
  Future<void> updateProfile(Seller updatedSeller) async {
    state = const AsyncValue.loading();

    final profileService = ref.read(profileServiceProvider);
    final result = await profileService.updateProfile(updatedSeller);

    result.match(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = AsyncValue.data(updatedSeller),
    );
  }

  /// 🔹 Update specific fields (convenience methods)

  Future<void> updateShopName(String newName) async {
    final seller = state.value;
    if (seller == null) return;

    final updatedSeller = seller.copyWith(
      shopName: newName,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updatedSeller);
  }

  Future<void> updatePhoneNumber(String newPhone) async {
    final seller = state.value;
    if (seller == null) return;

    final updatedSeller = seller.copyWith(
      phoneNumber: newPhone,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updatedSeller);
  }

  Future<void> updateShopLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final seller = state.value;
    if (seller == null) return;

    final updatedSeller = seller.copyWith(
      latitude: latitude,
      longitude: longitude,
      address: address,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updatedSeller);
  }

  /// 🔹 Refresh manually
  Future<void> refreshProfile() async {
    final auth = ref.read(authStateProvider);
    final user = auth.value;
    if (user != null) {
      final profileService = ref.read(profileServiceProvider);
      final result = await profileService.getProfile(user.id);
      result.match(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (seller) => state = AsyncValue.data(seller),
      );
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// 🔹 Delete profile completely
  Future<void> deleteProfile(String uid) async {
    state = const AsyncValue.loading();

    final profileService = ref.read(profileServiceProvider);
    final result = await profileService.deleteProfile(uid);

    result.match(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<Seller?>>((ref) {
      return ProfileController(ref);
    });
