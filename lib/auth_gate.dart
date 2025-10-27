import 'package:flutter/material.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/setup/setup_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/features/auth/pages/auth_page.dart';
import 'package:locally/features/home/presentation/pages/home_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the auth state
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // -------------------------------------------------
          // 🔒 User is NOT signed in → show login page
          // -------------------------------------------------
          return const AuthPage();
        } else {
          // -------------------------------------------------
          // ✅ User IS signed in → Check for a profile
          // -------------------------------------------------

          // 2. Watch the profile state *only if* the user is logged in
          final profileState = ref.watch(currentUserProfileProvider);

          return profileState.when(
            data: (seller) {
              if (seller == null) {
                // -------------------------------------------------
                // 👶 User is signed in but has NO PROFILE → show setup page
                // -------------------------------------------------
                return const SetupPage();
              } else {
                // -------------------------------------------------
                // 🏠 User is signed in AND has a PROFILE → show home page
                // -------------------------------------------------
                return const HomePage();
              }
            },
            loading: () {
              // Show a loading screen while we fetch the profile
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
            error: (error, _) {
              // This is a critical error (e.g., database connection failed)
              return Scaffold(
                body: Center(
                  child: Text('Error loading profile: $error'),
                ),
              );
            },
          );
        }
      },
      loading: () {
        // Show a loading screen while we check for a user session
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, _) {
        // This is an error with authentication itself
        return Scaffold(
          body: Center(child: Text('Auth Error: $error')),
        );
      },
    );
  }
}
