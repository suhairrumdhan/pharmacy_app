import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<ChatConversation> conversations = <ChatConversation>[].obs;
  RxList<ChatMessage> currentMessages = <ChatMessage>[].obs;

  RxString selectedChatId = ''.obs;

  /// ✅ العداد الكلي Reactive
  RxInt totalUnreadCount = 0.obs;

  String get pharmacyId => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    print('🔍 Current User UID: ${_auth.currentUser?.uid}');
    print('🔍 Pharmacy ID from getter: $pharmacyId');
    listenToConversations();
  }

  /// 🔥 الاستماع لقائمة المحادثات الخاصة بالصيدلية
  void listenToConversations() {
    print('🎯 Listening for pharmacy: $pharmacyId');

    _firestore
        .collection("chats")
        .where("pharmacyId", isEqualTo: pharmacyId)
        .orderBy("lastMessageTime", descending: true)
        .snapshots()
        .listen((snapshot) {
      print('📨 Received ${snapshot.docs.length} conversations');

      conversations.value = snapshot.docs.map((doc) {
        final data = doc.data();
        print('✅ Loaded chat: ${doc.id} - ${data['userName']}');
        return ChatConversation.fromMap(doc.id, data);
      }).toList();

      /// ✅ تحديث العداد الكلي
      totalUnreadCount.value = conversations.fold(
        0,
            (sum, chat) => sum + chat.unreadForPharmacy,
      );
    }, onError: (error) {
      print('❌ Error listening to conversations: $error');
    });
  }

  /// 🔥 Stream للعداد الكلي لو احتجتيه في مكان ثاني
  Stream<int> getUnreadCountStream() {
    return _firestore
        .collection("chats")
        .where("pharmacyId", isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()["pharmacyUnreadCount"] ?? 0) as int;
      }
      return total;
    });
  }

  /// 🔥 تحميل الرسائل لمحادثة معينة
  void loadMessages(String chatId) {
    selectedChatId.value = chatId;
    print('Loading messages for chat: $chatId');

    _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      print('Received ${snapshot.docs.length} messages');
      currentMessages.value = snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.id, doc.data());
      }).toList();
    }, onError: (error) {
      print('Error loading messages: $error');
    });

    /// ✅ تصفير العداد الخاص بالصيدلية فقط
    _firestore.collection("chats").doc(chatId).update({
      "pharmacyUnreadCount": 0,
    });

    /// ✅ تحديث العداد المحلي مباشرة
    final index = conversations.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      conversations[index] = conversations[index].copyWith(
        pharmacyUnreadCount: 0,
      );

      totalUnreadCount.value = conversations.fold(
        0,
            (sum, chat) => sum + chat.unreadForPharmacy,
      );
    }
  }

  /// ✉ إرسال رسالة من الصيدلية
  Future<void> sendMessage(String text) async {
    if (selectedChatId.value.isEmpty) {
      print('No chat selected');
      return;
    }

    final chatId = selectedChatId.value;
    print('Sending message to chat: $chatId');

    final newMessage = {
      "senderId": pharmacyId,
      "senderName": "Pharmacy",
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "type": "text",
      "isMe": false,
      "status": "sent",
      "isRead": false,
      "senderType": "pharmacy",
    };

    try {
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .add(newMessage);

      await _firestore.collection("chats").doc(chatId).update({
        "lastMessage": text,
        "lastMessageType": "text",
        "lastMessageTime": FieldValue.serverTimestamp(),
        "userUnreadCount": FieldValue.increment(1),
        "pharmacyUnreadCount": 0,
        "pharmacyIsOnline": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}