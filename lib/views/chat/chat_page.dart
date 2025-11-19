import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import 'health_record_panel.dart';
import 'conversation_area.dart';
import 'conversation_tile.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Conversations List
        _buildConversationsList(),

        // Conversation Area
        Expanded(
          child: ConversationArea(messageController: messageController),
        ),

        // Health Record Panel
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: HealthRecordPanel(),
        ),
      ],
    );
  }

  Widget _buildConversationsList() {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Conversations List
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: chatController.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatController.conversations[index];
                return ConversationTile(conversation: conversation);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          // chatController.searchConversations(value);
        },
        decoration: InputDecoration(
          hintText: 'بحث في المحادثات...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}