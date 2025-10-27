import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  NotificationService(this._ref);

  /// Initializes FCM, requests permissions, and sets up token listeners.
  Future<void> init() async {
    // 1. Request permissions (mainly for iOS and Web)
    if (Platform.isIOS || Platform.isAndroid) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 2. Get the initial token and save it
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // 3. Listen for token refreshes (FCM can change the token)
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  /// Saves the new FCM token to the user's profile in Supabase.
  Future<void> _saveTokenToDatabase(String newFCMToken) async {
    try {
      // Get the current user's ID
      final user = _ref.read(authStateProvider).value;
      if (user == null) {
        // Not logged in, nothing to save
        return;
      }

      // Get the current user's profile
      // We use `read` on the FutureProvider to get the AsyncValue
      final profileAsyncValue = _ref.read(currentUserProfileProvider);

      final currentProfile = profileAsyncValue.value;
      if (currentProfile == null) {
        // User is logged in, but their profile hasn't been created yet.
        // Or it's still loading.
        // You might want to retry this logic once the profile is available.
        return;
      }

      // 4. Check if the token is new before updating
      if (currentProfile.fcmToken == newFCMToken) {
        // Token is already up-to-date
        return;
      }

      // 5. Save the new token
      final profileService = _ref.read(profileServiceProvider);
      await profileService.updateProfile(
        currentProfile.copyWith(fcmToken: newFCMToken),
      );

      print('FCM Token updated successfully.');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
