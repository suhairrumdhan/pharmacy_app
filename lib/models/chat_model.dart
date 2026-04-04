import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String participantName;
  final String lastMessage;
  final String lastMessageType;
  final DateTime lastMessageTime;


  /// العداد الصحيح لكل طرف
  final int pharmacyUnreadCount;
  final int userUnreadCount;

  final String pharmacyId;
  final String userId;
  final String userName;

  final bool pharmacyIsOnline;
  final String? userImage;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.pharmacyId,
    required this.userId,
    required this.userName,
    required this.pharmacyUnreadCount,
    required this.userUnreadCount,
    this.pharmacyIsOnline = false,
    this.userImage,
  });

  /// ✅ العداد الذي يخص الصيدلية فقط
  int get unreadForPharmacy => pharmacyUnreadCount;

  bool get hasUnreadForPharmacy => pharmacyUnreadCount > 0;

  /// ✅ معاينة ذكية لآخر رسالة
  String get lastMessagePreview {
    switch (lastMessageType) {
      case 'image':
        return '📷 صورة';
      case 'file':
        return '📎 ملف';
      default:
        return lastMessage.isEmpty ? 'لا توجد رسائل' : lastMessage;
    }
  }

  factory ChatConversation.fromMap(String id, Map<String, dynamic> data) {
    return ChatConversation(
      id: id,
      participantName: data["userName"] ?? "مستخدم",
      lastMessage: data["lastMessage"] ?? "",
      lastMessageType: data["lastMessageType"] ?? "text",
      lastMessageTime:
      (data["lastMessageTime"] as Timestamp?)?.toDate() ?? DateTime.now(),
      pharmacyId: data["pharmacyId"] ?? "",
      userId: data["userId"] ?? "",
      userName: data["userName"] ?? "مستخدم",
      pharmacyUnreadCount: data["pharmacyUnreadCount"] ?? 0,
      userUnreadCount: data["userUnreadCount"] ?? 0,
      pharmacyIsOnline: data["pharmacyIsOnline"] ?? false,
      userImage: data["userImage"],
    );
  }

  ChatConversation copyWith({
    String? id,
    String? participantName,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageTime,
    int? pharmacyUnreadCount,
    int? userUnreadCount,
    String? pharmacyId,
    String? userId,
    String? userName,
    bool? pharmacyIsOnline,
    String? userImage,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      pharmacyUnreadCount: pharmacyUnreadCount ?? this.pharmacyUnreadCount,
      userUnreadCount: userUnreadCount ?? this.userUnreadCount,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      pharmacyIsOnline: pharmacyIsOnline ?? this.pharmacyIsOnline,
      userImage: userImage ?? this.userImage,
    );
  }
}

class ChatMessage {
  final String id;
  final String message;
  final String senderId;
  final bool isMe;
  final DateTime timestamp;

  /// إضافات احترافية
  final String type; // text / image / file
  final String status; // sent / delivered / read
  final bool isRead;
  final String? imageUrl;
  final String? senderName;
  final String? senderType;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.isMe,
    required this.timestamp,
    this.type = 'text',
    this.status = 'sent',
    this.isRead = false,
    this.imageUrl,
    this.senderName,
    this.senderType,
  });

  bool get isImage => type == 'image';
  bool get isText => type == 'text';

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      message: data["text"] ?? "",
      senderId: data["senderId"] ?? "",
      isMe: data["isMe"] ?? false,
      timestamp:
      (data["timestamp"] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data["type"] ?? "text",
      status: data["status"] ?? "sent",
      isRead: data["isRead"] ?? false,
      imageUrl: data["imageUrl"],
      senderName: data["senderName"],
      senderType: data["senderType"],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? message,
    String? senderId,
    bool? isMe,
    DateTime? timestamp,
    String? type,
    String? status,
    bool? isRead,
    String? imageUrl,
    String? senderName,
    String? senderType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      senderId: senderId ?? this.senderId,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
    );
  }
}