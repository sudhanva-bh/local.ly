import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/gates/token_updater_wrapper.dart';
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
        if (user == null) return const WelcomeScreen();

        final metadata = user.userMetadata ?? {};
        final onboarded = metadata["onboarded"] == true;
        final accountTypeRaw = metadata["accountType"] as String?;

        if (!onboarded) return const SetupPage();

        final accountType = AccountTypeX.fromValue(accountTypeRaw);

        // NOTE: We do not call the service here anymore.
        // We let the Wrapper handle it.

        switch (accountType) {
          case AccountType.wholesaleSeller:
            return const TokenUpdaterWrapper(
              isConsumer: false,
              child: WholesaleNavPage(),
            );
          case AccountType.retailSeller:
            return const TokenUpdaterWrapper(
              isConsumer: false,
              child: RetailNavPage(),
            );
          case AccountType.consumer:
            return const TokenUpdaterWrapper(
              isConsumer: true,
              child: ConsumerNavPage(),
            );
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