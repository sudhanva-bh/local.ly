import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/setup/setup_page.dart';
import 'package:locally/common/gates/seller_type_gate.dart';

class SetupGate extends ConsumerWidget {
  const SetupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);

    return profileState.when(
      data: (seller) {
        if (seller == null) {
          // 👶 No profile → show setup page
          return const SetupPage();
        } else {
          // 🏠 Profile exists → go to SellerTypeGate
          return const SellerTypeGate();
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
