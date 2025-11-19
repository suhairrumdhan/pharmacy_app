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
  String get pharmacyId => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    print('🔍 Current User UID: ${_auth.currentUser?.uid}');
    print('🔍 Pharmacy ID from getter: $pharmacyId');
    print('🔍 Expected Pharmacy ID in Firestore: 2ZE0QgVFl1Wtk2b84bUKqqYl8UM2');

    // تحقق إذا كان هناك تطابق
    if (pharmacyId == '2ZE0QgVFl1Wtk2b84bUKqqYl8UM2') {
      print('✅ Pharmacy ID matches!');
    } else {
      print('❌ Pharmacy ID does not match!');
    }

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

      if (snapshot.docs.isEmpty) {
        print('⚠️ No conversations found! Checking all chats...');
        // جلب جميع المحادثات للتحقق
        _firestore.collection("chats").get().then((allChats) {
          print('📊 All chats in database: ${allChats.docs.length}');
          allChats.docs.forEach((doc) {
            final data = doc.data();
            print('💬 Chat ${doc.id}: pharmacyId=${data['pharmacyId']}, userName=${data['userName']}');
          });
        });
      }

      conversations.value = snapshot.docs.map((doc) {
        final data = doc.data();
        print('✅ Loaded chat: ${doc.id} - ${data['userName']}');
        return ChatConversation.fromMap(doc.id, data);
      }).toList();
    }, onError: (error) {
      print('❌ Error listening to conversations: $error');
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

    // تحديث unreadCount إلى صفر
    _firestore.collection("chats").doc(chatId).update({
      "unreadCount": 0,
    });
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
    };

    try {
      // إضافة الرسالة إلى مجموعة messages الفرعية
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .add(newMessage);

      // تحديث المحادثة الرئيسية
      await _firestore.collection("chats").doc(chatId).update({
        "lastMessage": text,
        "lastMessageTime": FieldValue.serverTimestamp(),
        "unreadCount": 0,
        "pharmacyIsOnline": true,
      });

      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}