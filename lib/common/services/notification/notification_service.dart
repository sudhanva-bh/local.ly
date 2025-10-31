// lib/common/services/notification_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  NotificationService(this._ref);

  /// Requests notification permission and returns the FCM token.
  /// Use this during the initial setup.
  Future<String?> requestPermissionAndGetToken() async {
    // 1. Request permissions (mainly for iOS and Web)
    if (Platform.isIOS || Platform.isAndroid) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    // 2. Get the token
    return await _fcm.getToken();
  }

  /// Sets up the listener to automatically update the token in the database
  /// if FCM issues a new one. Call this after profile creation.
  void initTokenRefreshListener() {
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  /// [LEGACY OR FOR EXISTING USERS]
  /// This method is now used for existing users who already have a profile.
  Future<void> init() async {
    final token = await requestPermissionAndGetToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
    initTokenRefreshListener();
  }

  /// Saves the new FCM token to the user's profile in Supabase.
  Future<void> _saveTokenToDatabase(String newFCMToken) async {
    try {
      // ... (This method remains unchanged)
      final user = _ref.read(authStateProvider).value;
      if (user == null) {
        return;
      }
      final profileAsyncValue = _ref.read(currentUserProfileProvider);
      final currentProfile = profileAsyncValue.value;
      if (currentProfile == null) {
        return;
      }
      if (currentProfile.fcmToken == newFCMToken) {
        return;
      }
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