
import 'package:cloud_firestore/cloud_firestore.dart';
class ChatConversation {
  final String id;
  final String participantName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String pharmacyId;
  final String userId;
  final String userName;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.pharmacyId,
    required this.userId,
    required this.userName,
  });

  factory ChatConversation.fromMap(String id, Map<String, dynamic> data) {
    return ChatConversation(
      id: id,
      participantName: data["userName"] ?? "مستخدم",
      lastMessage: data["lastMessage"] ?? "لا توجد رسائل",
      lastMessageTime: (data["lastMessageTime"] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data["unreadCount"] ?? 0,
      pharmacyId: data["pharmacyId"] ?? "",
      userId: data["userId"] ?? "",
      userName: data["userName"] ?? "مستخدم",
    );
  }
}

class ChatMessage {
  final String id;
  final String message;
  final String senderId;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.isMe,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      message: data["text"] ?? "",
      senderId: data["senderId"] ?? "",
      isMe: data["isMe"] ?? false,
      timestamp: (data["timestamp"] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}
