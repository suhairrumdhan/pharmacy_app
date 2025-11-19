import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import 'message_bubble.dart';

class ConversationArea extends StatelessWidget {
  final TextEditingController messageController;

  const ConversationArea({super.key, required this.messageController});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();

    return Obx(() => Column(
      children: [
        _buildChatHeader(chatController),
        _buildMessagesArea(chatController),
        _buildMessageInput(chatController),
      ],
    ));
  }

  Widget _buildChatHeader(ChatController chatController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: chatController.selectedChatId.value.isEmpty
                ? Colors.grey
                : Colors.blue,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: chatController.selectedChatId.value.isEmpty
                ? const Text(
              'اختر محادثة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
                : FutureBuilder<Map<String, dynamic>?>(
              future: _getChatData(chatController.selectedChatId.value),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final userName = snapshot.data!['userName'] ?? 'مستخدم';
                  return Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(ChatController chatController) {
    return Expanded(
      child: chatController.selectedChatId.value.isEmpty
          ? _buildEmptyChatState()
          : Obx(() => ListView.builder(
        padding: const EdgeInsets.all(16),
        reverse: true,
        itemCount: chatController.currentMessages.length,
        itemBuilder: (context, index) {
          final message = chatController.currentMessages[index];
          return MessageBubble(message: message);
        },
      )),
    );
  }

  Widget _buildEmptyChatState() {
    return const Center(
      child: Text(
        'اختر محادثة لبدء المحادثة',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatController chatController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              enabled: chatController.selectedChatId.value.isNotEmpty,
              decoration: InputDecoration(
                hintText: chatController.selectedChatId.value.isEmpty
                    ? 'اختر محادثة أولاً'
                    : 'اكتب رسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: chatController.selectedChatId.value.isEmpty
                    ? Colors.grey.shade300
                    : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: chatController.selectedChatId.value.isEmpty
                ? Colors.grey
                : Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: chatController.selectedChatId.value.isEmpty
                  ? null
                  : () {
                final text = messageController.text.trim();
                if (text.isNotEmpty) {
                  chatController.sendMessage(text);
                  messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getChatData(String chatId) async {
    try {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching chat data: $e');
      return null;
    }
  }
}