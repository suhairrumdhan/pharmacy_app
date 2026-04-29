import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_type.dart';
import 'package:flutter/foundation.dart';

class PharmacyOrderNotificationsService {
  PharmacyOrderNotificationsService._();

  static final PharmacyOrderNotificationsService instance =
  PharmacyOrderNotificationsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> notifyOrderStatusChanged({
    required String userId,
    required String orderId,
    required String pharmacyId,
    required String pharmacyName,
    String? imageUrl,
    required String status,
    required String statusLabel,
    required String beneficiaryId,
    required String beneficiaryName,
    required String beneficiaryType,
    String? beneficiaryRelationLabel,
    String? note,
    List<Map<String, dynamic>> deliveredMedicines = const [],
  }) async {
    final content = _buildStatusContent(
      status: status,
      statusLabel: statusLabel,
      beneficiaryName: beneficiaryName,
      pharmacyName: pharmacyName,
      note: note,
    );

    final isCompleted = status == 'completed';
    final notificationStatus = isCompleted ? 'delivered' : status;
    final notificationStatusLabel = isCompleted ? 'تم الاستلام' : statusLabel;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'userId': userId,
      'title': content.title,
      'message': content.message,
      'type': AppNotificationType.orderUpdate.value,
      'priority': NotificationPriority.high.value,
      'referenceType': NotificationReferenceType.order.value,
      'isRead': false,
      'isDeleted': false,
      'isActionable': true,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'expiresAt': null,
      'referenceId': orderId,
      'actionRoute': '/orders',
      'actionId': orderId,
      'imageUrl': imageUrl,
      'iconName': _iconNameForStatus(status),
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'orderId': orderId,
      'chatId': null,
      'prescriptionId': null,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'beneficiaryType': beneficiaryType,
      'extraData': {
        'status': notificationStatus,
        'statusLabel': notificationStatusLabel,

        // الأصل الحقيقي للطلب
        'orderStatus': status,
        'orderStatusLabel': statusLabel,

        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),

        if (beneficiaryRelationLabel != null &&
            beneficiaryRelationLabel.trim().isNotEmpty)
          'beneficiaryRelationLabel': beneficiaryRelationLabel.trim(),

        if (isCompleted) 'canAddToMedicationHistory': true,
        if (isCompleted) 'showAddToMedicationHistoryPrompt': true,
        if (isCompleted) 'deliveredMedicines': deliveredMedicines,
      },
    });

    debugPrint('✅ Firestore notification saved');
  }

  Future<void> notifyPharmacyNoteAdded({
    required String userId,
    required String orderId,
    required String pharmacyId,
    required String pharmacyName,
    String? imageUrl,
    required String beneficiaryId,
    required String beneficiaryName,
    required String beneficiaryType,
    required String note,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'userId': userId,
      'title': 'ملاحظة جديدة من الصيدلية',
      'message': 'أضافت $pharmacyName ملاحظة على طلب $beneficiaryName: $note',
      'type': AppNotificationType.orderUpdate.value,
      'priority': NotificationPriority.normal.value,
      'referenceType': NotificationReferenceType.order.value,
      'isRead': false,
      'isDeleted': false,
      'isActionable': true,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'expiresAt': null,
      'referenceId': orderId,
      'actionRoute': '/orders',
      'actionId': orderId,
      'imageUrl': imageUrl,
      'iconName': 'order_note',
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'orderId': orderId,
      'chatId': null,
      'prescriptionId': null,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'beneficiaryType': beneficiaryType,
      'extraData': {
        'note': note,
      },
    });
  }

  _NotificationContent _buildStatusContent({
    required String status,
    required String statusLabel,
    required String beneficiaryName,
    required String pharmacyName,
    String? note,
  }) {
    switch (status) {
      case 'reviewing':
        return _NotificationContent(
          title: 'الطلب قيد المراجعة',
          message: 'بدأت $pharmacyName مراجعة طلب $beneficiaryName.',
        );

      case 'confirmed':
        return _NotificationContent(
          title: 'تم تأكيد الطلب',
          message: 'تم تأكيد طلب $beneficiaryName من $pharmacyName.',
        );

      case 'partiallyConfirmed':
        return _NotificationContent(
          title: 'الطلب متوفر جزئيًا',
          message: note != null && note.trim().isNotEmpty
              ? 'بعض عناصر طلب $beneficiaryName متوفرة من $pharmacyName. ملاحظة: ${note.trim()}'
              : 'بعض عناصر طلب $beneficiaryName متوفرة من $pharmacyName.',
        );

      case 'rejected':
        return _NotificationContent(
          title: 'تم رفض الطلب',
          message: note != null && note.trim().isNotEmpty
              ? 'تم رفض طلب $beneficiaryName من $pharmacyName. السبب: ${note.trim()}'
              : 'تم رفض طلب $beneficiaryName من $pharmacyName.',
        );

      case 'ready':
        return _NotificationContent(
          title: 'الطلب جاهز للاستلام',
          message: 'طلب $beneficiaryName أصبح جاهزًا في $pharmacyName.',
        );

      case 'completed':
        return _NotificationContent(
          title: 'تم تسليم الطلب',
          message: 'تم تسليم طلب $beneficiaryName بنجاح.',
        );

      case 'cancelled':
        return _NotificationContent(
          title: 'تم إلغاء الطلب',
          message: note != null && note.trim().isNotEmpty
              ? 'تم إلغاء طلب $beneficiaryName. السبب: ${note.trim()}'
              : 'تم إلغاء طلب $beneficiaryName.',
        );

      default:
        return _NotificationContent(
          title: 'تم تحديث الطلب',
          message: 'تم تحديث حالة طلب $beneficiaryName إلى $statusLabel.',
        );
    }
  }

  String _iconNameForStatus(String status) {
    switch (status) {
      case 'reviewing':
        return 'order_reviewing';
      case 'confirmed':
        return 'order_confirmed';
      case 'partiallyConfirmed':
        return 'order_partial';
      case 'rejected':
        return 'order_rejected';
      case 'ready':
        return 'order_ready';
      case 'completed':
        return 'order_completed';
      case 'cancelled':
        return 'order_cancelled';
      default:
        return 'order_update';
    }
  }
}

class _NotificationContent {
  final String title;
  final String message;

  const _NotificationContent({
    required this.title,
    required this.message,
  });
}