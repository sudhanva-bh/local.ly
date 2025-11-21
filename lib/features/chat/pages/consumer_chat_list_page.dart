import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:locally/common/models/chat/chat_models.dart';
import 'package:locally/common/services/chat/chat_service.dart';
import 'package:locally/features/chat/widgets/chat_list_tile.dart';

class ConsumerChatListPage extends ConsumerWidget {
  const ConsumerChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumer = ref.watch(currentConsumerProfileProvider).value;

    if (consumer == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final chatRoomsStream =
        ref.watch(chatServiceProvider).getMyChatRoomsStream(consumer.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: chatRoomsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (c, i) =>
                const Divider(height: 1, indent: 80, endIndent: 20),
            itemBuilder: (context, index) {
              return ChatListTile(
                room: rooms[index],
                currentUserId: consumer.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messageSquareOff, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No messages yet",
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}
