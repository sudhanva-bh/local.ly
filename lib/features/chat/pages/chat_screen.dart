import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:locally/common/models/chat/chat_models.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/services/chat/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Seller otherUser;
  final String myId;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUser,
    required this.myId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // We actually don't need a scroll controller if we rely on standard reverse:true behavior,
  // but keeping it allows for programmatic scrolling if needed.
  final ScrollController _scrollController = ScrollController();

  Future<void> makePhoneCall(String phoneNumber) async {
    // Use Uri.parse to construct the tel: URL
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    // Check if the application can launch the URL
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle the error if the launch fails (e.g., if running on a platform
      // without phone capabilities, like a web browser or desktop)
      throw 'Could not launch $launchUri';
    }
  }

  @override
  void initState() {
    super.initState();
    // Mark as read as soon as screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatServiceProvider).markRoomAsRead(widget.roomId, widget.myId);
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final content = _controller.text.trim();
    _controller.clear();

    ref
        .read(chatServiceProvider)
        .sendMessage(
          widget.roomId,
          widget.myId,
          content,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUser.profileImageUrl != null
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              backgroundColor: colors.surfaceContainerHighest,
              child: widget.otherUser.profileImageUrl == null
                  ? Text(widget.otherUser.shopName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.shopName,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.phone, color: colors.onSurface),
            onPressed: () {
              makePhoneCall(widget.otherUser.phoneNumber!);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ref
                    .watch(chatServiceProvider)
                    .getMessagesStream(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading chats"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  // Reverse the list because ListView is reversed
                  // Messages come in [Oldest ... Newest]
                  // Reversed List: [Newest ... Oldest]
                  // ListView(reverse:true) draws index 0 at bottom.
                  final reversedMessages = messages.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Starts at bottom
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: reversedMessages.length,
                    itemBuilder: (context, index) {
                      final msg = reversedMessages[index];
                      final isMe = msg.senderId == widget.myId;

                      // Calculate grouping logic
                      // Note: Because we are reversed, 'next' index is actually the older message (visually above)
                      // and 'prev' index is the newer message (visually below)

                      // Is the message visually ABOVE (index + 1) the same user?
                      final isPrevSame =
                          index < reversedMessages.length - 1 &&
                          reversedMessages[index + 1].senderId == msg.senderId;

                      // Is the message visually BELOW (index - 1) the same user?
                      final isNextSame =
                          index > 0 &&
                          reversedMessages[index - 1].senderId == msg.senderId;

                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        isNextSame: isNextSame, // Visually below
                        isPrevSame: isPrevSame, // Visually above
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 30),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceDim,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Message...",
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: colors.primary,
              radius: 22,
              child: Icon(
                LucideIcons.sendHorizontal,
                color: colors.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isNextSame; // Visually below
  final bool isPrevSame; // Visually above

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isNextSame,
    required this.isPrevSame,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Corner logic:
    // If the message visually below me (nextSame) is mine, square off bottom corner
    // If the message visually above me (prevSame) is mine, square off top corner
    final double topRadius = isPrevSame ? 4 : 20;
    final double bottomRadius = isNextSame ? 4 : 20;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: isNextSame ? 2 : 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? colors.primary : colors.surfaceDim,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 20 : topRadius),
            topRight: Radius.circular(isMe ? topRadius : 20),
            bottomLeft: Radius.circular(isMe ? 20 : bottomRadius),
            bottomRight: Radius.circular(isMe ? bottomRadius : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? colors.onPrimary : colors.onSurface,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            // Only show timestamp if it's the LAST message in a sequence (visually bottom)
            if (!isNextSame) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? colors.onPrimary.withOpacity(0.7)
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }
}
