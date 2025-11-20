import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/account_type.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/features/consumer/consumer_nav_page.dart';
import 'package:locally/features/retail_seller/retail_nav_page.dart';
import 'package:locally/features/setup/setup_page.dart';
import 'package:locally/features/welcome/pages/welcome_screen.dart';
import 'package:locally/features/wholesale_seller/wholesale_nav_page.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // No session → show welcome/auth flow
          return const WelcomeScreen();
        }

        // User logged in → read metadata
        final metadata = user.userMetadata ?? {};

        final onboarded = metadata["onboarded"] == true;
        final accountTypeRaw = metadata["accountType"] as String?;

        // If user hasn't onboarded → setup
        if (!onboarded) {
          return const SetupPage();
        }

        // User onboarded → route based on account type
        final accountType = AccountTypeX.fromValue(accountTypeRaw);

        switch (accountType) {
          case AccountType.wholesaleSeller:
            print("Wholesale");
            return const WholesaleNavPage();
          case AccountType.retailSeller:
            return const RetailNavPage();
          case AccountType.consumer:
            return const ConsumerNavPage();
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
