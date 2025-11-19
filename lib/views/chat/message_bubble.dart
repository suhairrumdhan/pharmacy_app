import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();
    final isMe = message.senderId == chatController.pharmacyId;

    // Your custom color
    const primaryColor = Color(0xFF5EABD6);
    const receivedMessageColor = Color(0xFFF5F5F5);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sender Avatar (for received messages)
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withAlpha(200),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Message Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : receivedMessageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Time and Status Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white.withAlpha(180) : Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sender Avatar (for sent messages)
          if (isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor,
                  child: Icon(
                    Icons.medical_services,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'أمس ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Optional: Animated version with smooth entrance
class AnimatedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final int index;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.index,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: MessageBubble(
        message: message,
        showAvatar: showAvatar,
      ),
    );
  }
}

// Optional: Grouped messages for consecutive messages from same sender
class GroupedMessageBubble extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isMe;

  const GroupedMessageBubble({
    super.key,
    required this.messages,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5EABD6);
    const receivedMessageColor = Color(0xFFF5F5F5);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar space for alignment (invisible)
          if (!isMe)
            const SizedBox(width: 46),

          // Grouped messages
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ...messages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final message = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == messages.length - 1;

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: isLast ? 0 : 2,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? primaryColor : receivedMessageColor,
                        borderRadius: _getBorderRadius(isMe, isFirst, isLast),
                        boxShadow: isLast
                            ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          if (isLast) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white.withAlpha(180) : Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Avatar space for alignment (invisible)
          if (isMe)
            const SizedBox(width: 46),
        ],
      ),
    );
  }

  BorderRadius _getBorderRadius(bool isMe, bool isFirst, bool isLast) {
    if (isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isLast ? 4 : 20),
        bottomRight: Radius.circular(isFirst ? 20 : 4),
      );
    } else {
      return BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isFirst ? 4 : 20),
        bottomRight: Radius.circular(isLast ? 20 : 4),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}