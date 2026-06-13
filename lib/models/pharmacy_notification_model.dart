import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyNotificationModel {
  final String id;
  final String pharmacyId;

  final String type;
  final String title;
  final String message;
  final String? body;

  final String? referenceType;
  final String? referenceId;
  final String? actionRoute;
  final String? actionId;

  final String? orderId;
  final String? chatId;
  final String? userId;
  final String? userName;

  final String? iconName;
  final String? imageUrl;

  final bool isRead;
  final bool isDeleted;
  final bool isActionable;

  final String priority;
  final DateTime createdAt;
  final DateTime? readAt;

  final Map<String, dynamic> extraData;

  const PharmacyNotificationModel({
    required this.id,
    required this.pharmacyId,
    required this.type,
    required this.title,
    required this.message,
    this.body,
    this.referenceType,
    this.referenceId,
    this.actionRoute,
    this.actionId,
    this.orderId,
    this.chatId,
    this.userId,
    this.userName,
    this.iconName,
    this.imageUrl,
    required this.isRead,
    required this.isDeleted,
    required this.isActionable,
    required this.priority,
    required this.createdAt,
    this.readAt,
    required this.extraData,
  });

  factory PharmacyNotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return PharmacyNotificationModel(
      id: doc.id,
      pharmacyId: _readString(data['pharmacyId']),
      type: _readString(data['type']),
      title: _readString(data['title']),
      message: _readString(data['message']),
      body: _readNullableString(data['body']),
      referenceType: _readNullableString(data['referenceType']),
      referenceId: _readNullableString(data['referenceId']),
      actionRoute: _readNullableString(data['actionRoute']),
      actionId: _readNullableString(data['actionId']),
      orderId: _readNullableString(data['orderId']),
      chatId: _readNullableString(data['chatId']),
      userId: _readNullableString(data['userId']),
      userName: _readNullableString(data['userName']),
      iconName: _readNullableString(data['iconName']),
      imageUrl: _readNullableString(data['imageUrl']),
      isRead: _readBool(data['isRead']),
      isDeleted: _readBool(data['isDeleted']),
      isActionable: data['isActionable'] is bool ? data['isActionable'] as bool : true,
      priority: _readString(data['priority'], fallback: 'normal'),
      createdAt: _readDateTime(data['createdAt']) ?? DateTime.now(),
      readAt: _readDateTime(data['readAt']),
      extraData: _readMap(data['extraData']),
    );
  }

  bool get isNewOrder => type == 'newOrder';
  bool get isChatMessage => type == 'chatMessage';
  bool get isAdminBroadcast => type == 'adminBroadcast';

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1';
    }
    return false;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }
}