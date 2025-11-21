// lib/features/view_seller/pages/view_seller_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/consumer_model.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
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
    final currentConsumerAsync = ref.watch(currentConsumerProfileProvider);
    final currentUser = currentUserAsync.value;
    final currentConsumer = currentConsumerAsync.value;

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
        currentConsumer,
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

  // lib/features/view_seller/pages/view_seller_page.dart
  Widget? _buildChatFab(
    BuildContext context,
    WidgetRef ref,
    Seller? currentUser,
    ConsumerModel? currentConsumer,
    AsyncValue<dynamic> profileAsync,
  ) {
    // No login → no FAB
    if (currentUser == null && currentConsumer == null) {
      return null;
    }

    // Profile not loaded yet
    if (!profileAsync.hasValue) return null;

    final viewedProfile = profileAsync.value;

    // ----- Detect the viewed profile type -----
    final bool isSellerViewed = viewedProfile is Seller;

    // ----- Your own profile? hide FAB -----
    final myId = currentUser?.uid ?? currentConsumer?.uid;
    final viewedId = isSellerViewed
        ? (viewedProfile).uid
        : (viewedProfile as ConsumerModel).uid;

    if (myId == viewedId) return null;

    return FloatingActionButton.extended(
      heroTag: 'chat_fab',
      label: const Text("Message"),
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () async {
        try {
          final chatService = ref.read(chatServiceProvider);

          // -------------------------------
          // 💬 CHAT ROOM CREATION DECISION
          // -------------------------------
          String roomId;

          if (currentUser != null) {
            // Logged in as SELLER (retail)
            // → Can chat with wholesale OR consumer
            roomId = await chatService.createOrGetChatRoom(
              currentUser.uid,
              viewedId,
              myType: "seller",
              otherType: "seller",
            );
          } else {
            // Logged in as CONSUMER
            // → Can chat only with retail sellers
            roomId = await chatService.createOrGetChatRoom(
              currentConsumer!.uid,
              viewedId,
              myType: "consumer",
              otherType: "seller",
            );
          }

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: roomId,
                  otherUser: viewedProfile,
                  myId: myId!,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error starting chat: $e")),
            );
          }
        }
      },
    );
  }
}
