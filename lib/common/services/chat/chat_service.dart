import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locally/common/models/chat/chat_models.dart';

final chatServiceProvider = Provider((ref) {
  return ChatService(Supabase.instance.client);
});

final unreadChatCountProvider = StreamProvider.family<int, String>((ref, myId) {
  return ref.watch(chatServiceProvider)
      .getMyChatRoomsStream(myId)
      .map((rooms) {
        int total = 0;
        for (var room in rooms) {
          total += room.getMyUnreadCount(myId);
        }
        return total;
      });
});

class ChatService {
  final SupabaseClient _client;
  ChatService(this._client);

  // ---------------------------------------------------------------------------
  // 1. Create or Get existing chat room (supports seller/consumer types)
  // ---------------------------------------------------------------------------
  Future<String> createOrGetChatRoom(
    String myId,
    String otherId, {
    required String myType,       // "seller" or "consumer"
    required String otherType,    // "seller" or "consumer"
  }) async {
    // Check if room already exists
    final existing = await _client
        .from('chat_rooms')
        .select()
        .or(
          'and(participant_1.eq.$myId,participant_2.eq.$otherId),'
          'and(participant_1.eq.$otherId,participant_2.eq.$myId)'
        );

    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }

    // Create a new room
    final newRoom = await _client.from('chat_rooms').insert({
      'participant_1': myId,
      'participant_1_type': myType,
      'participant_2': otherId,
      'participant_2_type': otherType,
      'last_message_time': DateTime.now().toIso8601String(),
      'unread_count_p1': 0,
      'unread_count_p2': 0,
    }).select();

    return newRoom.first['id'] as String;
  }

  // ---------------------------------------------------------------------------
  // 2. Stream My Chat Rooms
  // ---------------------------------------------------------------------------
  Stream<List<ChatRoom>> getMyChatRoomsStream(String myId) {
    return _client
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map((data) {
          final myRooms = data.where((room) =>
              room['participant_1'] == myId ||
              room['participant_2'] == myId).toList();

          return myRooms.map((e) => ChatRoom.fromMap(e)).toList();
        });
  }

  // ---------------------------------------------------------------------------
  // 3. Stream messages in a room
  // ---------------------------------------------------------------------------
  Stream<List<ChatMessage>> getMessagesStream(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => ChatMessage.fromMap(e)).toList());
  }

  // ---------------------------------------------------------------------------
  // 4. Send message
  // ---------------------------------------------------------------------------
  Future<void> sendMessage(String roomId, String senderId, String content) async {
    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
    });
    // DB trigger updates last message + unread counts
  }

  // ---------------------------------------------------------------------------
  // 5. Mark room as read
  // ---------------------------------------------------------------------------
  Future<void> markRoomAsRead(String roomId, String myId) async {
    final roomData = await _client
        .from('chat_rooms')
        .select('participant_1, participant_2')
        .eq('id', roomId)
        .maybeSingle();

    if (roomData == null) return;

    final p1 = roomData['participant_1'];

    if (myId == p1) {
      await _client
          .from('chat_rooms')
          .update({'unread_count_p1': 0})
          .eq('id', roomId);
    } else {
      await _client
          .from('chat_rooms')
          .update({'unread_count_p2': 0})
          .eq('id', roomId);
    }
  }
}
