// lib/common/gates/app_gate.dart (or whatever you wish to call it)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/auth/pages/auth_page.dart';
import 'package:locally/features/retail_seller/home/presentation/pages/retail_home_page.dart';
import 'package:locally/features/setup/setup_page.dart';
import 'package:locally/features/wholesale_seller/wholesale_nav_page.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the authentication state first
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // 🔒 User is NOT signed in
          return const AuthPage();
        } else {
          // ✅ User IS signed in, now check their profile
          return const _ProfileGate();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Auth Error: $error')),
      ),
    );
  }
}

/// This internal widget is only rendered if the user is authenticated.
/// It handles the profile-checking logic.
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Watch the user's profile
    final profileState = ref.watch(currentUserProfileProvider);

    return profileState.when(
      data: (seller) {
        if (seller == null) {
          // 👶 User is signed in but has NO profile
          return const SetupPage();
        } else {
          // 🏠 User has a profile, route them by type
          switch (seller.sellerType) {
            case SellerType.wholesaleSeller:
              return const WholesaleNavPage();
            case SellerType.retailSeller:
              return const RetailHomePage();
          }
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error loading profile: $error')),
      ),
    );
  }
}