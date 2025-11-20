// lib/features/consumer/profile/controllers/consumer_profile_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/users/consumer_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';

class ConsumerProfileController extends StateNotifier<AsyncValue<ConsumerModel?>> {
  final Ref ref;

  ConsumerProfileController(this.ref)
      : super(ref.watch(currentConsumerProfileProvider)) {
    ref.listen<AsyncValue<ConsumerModel?>>(
      currentConsumerProfileProvider,
      (_, next) {
        if (state != next) {
          state = next;
        }
      },
    );
  }

  /// Update the entire ConsumerModel object
  Future<void> updateProfile(ConsumerModel updatedConsumer) async {
    state = const AsyncValue.loading();
    final profileService = ref.read(consumerProfileServiceProvider);
    final result = await profileService.updateProfile(updatedConsumer);
    result.match(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = AsyncValue.data(updatedConsumer),
    );
  }

  /// Update Full Name
  Future<void> updateFullName(String newName) async {
    final consumer = state.value;
    if (consumer == null) return;
    final updated = consumer.copyWith(
      fullName: newName,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }

  /// Update Phone Number
  Future<void> updatePhoneNumber(String newPhone) async {
    final consumer = state.value;
    if (consumer == null) return;
    final updated = consumer.copyWith(
      phoneNumber: newPhone,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }

  /// Update Location & Address
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final consumer = state.value;
    if (consumer == null) return;
    final updated = consumer.copyWith(
      latitude: latitude,
      longitude: longitude,
      address: address,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }

  /// Refresh manually
  Future<void> refreshProfile() async {
    final auth = ref.read(authStateProvider);
    final user = auth.value;
    if (user != null) {
      final profileService = ref.read(consumerProfileServiceProvider);
      final result = await profileService.getProfile(user.id);
      result.match(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (consumer) => state = AsyncValue.data(consumer),
      );
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Delete profile completely
  Future<void> deleteProfile() async {
    state = const AsyncValue.loading();
    final profileService = ref.read(consumerProfileServiceProvider);
    // No products to delete for consumers, just the profile/auth
    final result = await profileService.deleteProfile();
    result.match(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}

final consumerProfileControllerProvider =
    StateNotifierProvider<ConsumerProfileController, AsyncValue<ConsumerModel?>>(
        (ref) {
  return ConsumerProfileController(ref);
});