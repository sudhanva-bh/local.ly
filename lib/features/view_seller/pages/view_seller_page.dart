// lib/features/view_seller/pages/view_seller_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/services/chat/chat_service.dart';
import 'package:locally/features/view_seller/widgets/view_seller_body.dart';
import 'package:locally/features/chat/pages/chat_screen.dart';

class ViewSellerPage extends ConsumerWidget {
  final String sellerId;

  const ViewSellerPage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the profile of the seller we are viewing
    final profileAsync = ref.watch(getProfileByIdProvider(sellerId));

    // --- 2. Watch the current user to get their ID ---
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final currentUser = currentUserAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // --- 3. Add the Floating Action Button ---
      floatingActionButton: _buildChatFab(
        context,
        ref,
        currentUser,
        profileAsync,
      ),

      body: profileAsync.when(
        data: (seller) {
          return ViewSellerBody(seller: seller);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }

  Widget? _buildChatFab(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    AsyncValue<dynamic>
    profileAsync, // dynamic to handle the Seller type generic
  ) {
    // Logic to hide the button:
    // 1. User is not logged in (currentUser == null)
    // 2. User is viewing their own profile (currentUser.uid == sellerId)
    // 3. The seller profile hasn't loaded yet (profileAsync.value == null)
    if (currentUser == null ||
        currentUser.uid == sellerId ||
        !profileAsync.hasValue) {
      return null;
    }

    return FloatingActionButton.extended(
      heroTag:
          'chat_fab', // Good practice if you have multiple FABs on different screens
      label: const Text("Message"),
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () async {
        // Get the loaded seller object
        final seller = profileAsync.value!;

        try {
          // 1. Create or Get the Chat Room ID from Supabase
          // We use ref.read here because we are inside a callback
          final chatService = ref.read(chatServiceProvider);
          final roomId = await chatService.createOrGetChatRoom(
            currentUser.uid,
            sellerId,
          );

          // 2. Navigate to the Chat Screen
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: roomId,
                  otherUser:
                      seller, // Pass the seller object for name/avatar in header
                  myId: currentUser.uid,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error starting chat: $e")));
          }
        }
      },
    );
  }
}
