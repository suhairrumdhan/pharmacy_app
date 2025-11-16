import 'package:get/get.dart';
import '../models/chat_model.dart';

class ChatController extends GetxController {
  var conversations = <ChatConversation>[].obs;
  var currentMessages = <ChatMessage>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
  }

  void loadConversations() {
    // TODO: جلب المحادثات من Firestore
    conversations.value = [
      ChatConversation(
        id: '1',
        participantId: 'user1',
        participantName: 'محمد أحمد',
        lastMessage: 'هل الدواء متوفر؟',
        lastMessageTime: DateTime.now(),
        unreadCount: 2,
      ),
      ChatConversation(
        id: '2',
        participantId: 'user2',
        participantName: 'عيادة الدكتور خالد',
        lastMessage: 'نحتاج كمية إضافية',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
    ];
  }

  void loadMessages(String conversationId) {
    // TODO: جلب الرسائل من Firestore
    currentMessages.value = [
      ChatMessage(
        id: '1',
        senderId: 'user1',
        senderName: 'محمد أحمد',
        message: 'مرحباً، هل الدواء متوفر؟',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: '2',
        senderId: 'pharmacy',
        senderName: 'صيدليتك',
        message: 'نعم متوفر، يمكنك الحضور في أي وقت',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  void sendMessage(String message, String conversationId) {
    // TODO: إرسال رسالة إلى Firestore
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'pharmacy',
      senderName: 'صيدليتك',
      message: message,
      timestamp: DateTime.now(),
    );

    currentMessages.add(newMessage);
  }
}