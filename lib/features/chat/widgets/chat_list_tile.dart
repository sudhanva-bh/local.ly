import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/chat/chat_models.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/services/chat/chat_service.dart';
import 'package:locally/features/chat/pages/chat_screen.dart';

class ChatListTile extends ConsumerWidget {
  final ChatRoom room;
  final String currentUserId;

  const ChatListTile({
    super.key,
    required this.room,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final otherUserId = room.getOtherUserId(currentUserId);

    // This provider watches only the specific user needed for this tile
    final otherUserProfile = ref.watch(getProfileByIdProvider(otherUserId));

    // Logic: Get unread count specifically for ME
    final int unreadCount = room.getMyUnreadCount(currentUserId);
    final bool hasUnread = unreadCount > 0;

    return otherUserProfile.when(
      data: (seller) {
        return InkWell(
          onTap: () {
            ref
                .read(chatServiceProvider)
                .markRoomAsRead(room.id, currentUserId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: room.id,
                  otherUser: seller,
                  myId: currentUserId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // 1. Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.surfaceContainerHighest,
                  backgroundImage: seller.profileImageUrl != null
                      ? NetworkImage(seller.profileImageUrl!)
                      : null,
                  child: seller.profileImageUrl == null
                      ? Text(
                          seller.shopName.isNotEmpty
                              ? seller.shopName[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // 2. Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Name
                          Expanded(
                            child: Text(
                              seller.shopName,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Time
                          Text(
                            _formatTime(room.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Message Preview
                          Expanded(
                            child: Text(
                              room.lastMessage ?? "Start the conversation",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: hasUnread
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Unread Badge
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      // Loading Skeleton
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.surfaceContainerHighest,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    color: colors.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      return "${time.day}/${time.month}";
    }
  }
}
