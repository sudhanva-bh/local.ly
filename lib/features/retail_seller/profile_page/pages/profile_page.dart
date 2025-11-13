// lib/features/profile/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/retail_seller/profile_page/controllers/profile_controller.dart';
import 'package:locally/features/retail_seller/profile_page/widgets/profile_body.dart'; // New import

class ProfilePage extends ConsumerWidget {
  final String? sellerId;

  const ProfilePage({super.key, this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = sellerId == null;

    // Use the controller for the current user, as we fixed
    final profileAsync = isCurrentUser
        ? ref.watch(profileControllerProvider)
        : ref.watch(getProfileByIdProvider(sellerId!));

    return Scaffold(
      // Moved Scaffold here to provide a consistent page structure
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (seller) {
          if (seller == null) {
            // This case should primarily happen if a non-current user's profile
            // isn't found or if the current user's stream is empty.
            return const Center(child: Text('No profile found'));
          }
          // Delegate to the new ProfileBody widget
          return ProfileBody(seller: seller, isCurrentUser: isCurrentUser);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }
}
