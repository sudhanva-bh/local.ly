class ChatRoom {
  final String id;
  final String participant1;
  final String participant2;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCountP1;
  final int unreadCountP2;

  ChatRoom({
    required this.id,
    required this.participant1,
    required this.participant2,
    this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCountP1,
    required this.unreadCountP2,
  });

  // Helper: Get the unread count specifically for ME
  int getMyUnreadCount(String myId) {
    if (myId == participant1) return unreadCountP1;
    if (myId == participant2) return unreadCountP2;
    return 0;
  }

  // Helper: Get the ID of the person I am talking to
  String getOtherUserId(String myId) {
    return myId == participant1 ? participant2 : participant1;
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as String,
      participant1: map['participant_1'] as String,
      participant2: map['participant_2'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageTime: DateTime.parse(
        map['last_message_time'] ?? map['created_at'],
      ).toLocal(),
      // Safely parse the counts (default to 0 if null)
      unreadCountP1: map['unread_count_p1'] ?? 0,
      unreadCountP2: map['unread_count_p2'] ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at']).toLocal(),
    );
  }
}
