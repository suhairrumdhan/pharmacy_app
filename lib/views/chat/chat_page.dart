import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import 'health_record_panel.dart';
import 'conversation_area.dart';
import 'conversation_tile.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool showHealthPanel = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildConversationsList(),

        Expanded(
          child: ConversationArea(messageController: messageController),
        ),

        if (showHealthPanel)
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: HealthRecordPanel(
              onClose: () {
                setState(() {
                  showHealthPanel = false;
                });
              },
            ),
          )
        else
          _collapsedHealthButton(),
      ],
    );
  }
  Widget _collapsedHealthButton() {
    return Container(
      width: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Center(
        child: Tooltip(
          message: 'عرض الملف الصحي',
          child: IconButton(
            onPressed: () {
              setState(() {
                showHealthPanel = true;
              });
            },
            icon: const Icon(Icons.health_and_safety_outlined),
            color: const Color(0xFF2563A9),
          ),
        ),
      ),
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