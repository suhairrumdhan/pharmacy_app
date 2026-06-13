import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pharmacy_notification_model.dart';

class PharmacyNotificationsPageResult {
  final List<PharmacyNotificationModel> notifications;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const PharmacyNotificationsPageResult({
    required this.notifications,
    required this.lastDoc,
    required this.hasMore,
  });
}

class PharmacyNotificationsService {
  PharmacyNotificationsService._();

  static final PharmacyNotificationsService instance =
  PharmacyNotificationsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notificationsRef(
      String pharmacyId,
      ) {
    return _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('notifications');
  }

  /// عداد كل الإشعارات غير المقروءة
  Stream<int> getUnreadCountStream(String pharmacyId) {
    if (pharmacyId.trim().isEmpty) {
      return Stream.value(0);
    }

    return _notificationsRef(pharmacyId)
        .where('isRead', isEqualTo: false)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// عداد حسب نوع الإشعار
  /// مثال:
  /// newOrder -> عداد زر الطلبات
  /// adminBroadcast -> عداد زر الجرس
  Stream<int> getUnreadCountByTypeStream({
    required String pharmacyId,
    required String type,
  }) {
    if (pharmacyId.trim().isEmpty || type.trim().isEmpty) {
      return Stream.value(0);
    }

    return _notificationsRef(pharmacyId)
        .where('type', isEqualTo: type)
        .where('isRead', isEqualTo: false)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Listener خفيف لآخر إشعارات فقط
  /// يستخدم للتنبيه الداخلي Snackbar + Sound
  Stream<List<PharmacyNotificationModel>> getLatestNotificationsStream(
      String pharmacyId, {
        int limit = 20,
      }) {
    if (pharmacyId.trim().isEmpty) {
      return Stream.value([]);
    }

    return _notificationsRef(pharmacyId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PharmacyNotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// تحميل صفحة إشعارات مع دعم الفلترة حسب النوع
  /// نستخدم type = adminBroadcast لعرض إشعارات الإدارة فقط داخل Dialog
  Future<PharmacyNotificationsPageResult> fetchNotificationsPage({
    required String pharmacyId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    String? type,
  }) async {
    if (pharmacyId.trim().isEmpty) {
      return const PharmacyNotificationsPageResult(
        notifications: [],
        lastDoc: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = _notificationsRef(pharmacyId)
        .where('isDeleted', isEqualTo: false);

    if (type != null && type.trim().isNotEmpty) {
      query = query.where('type', isEqualTo: type.trim());
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    final items = snapshot.docs
        .map((doc) => PharmacyNotificationModel.fromFirestore(doc))
        .toList();

    return PharmacyNotificationsPageResult(
      notifications: items,
      lastDoc: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<void> markAsRead({
    required String pharmacyId,
    required String notificationId,
  }) async {
    if (pharmacyId.trim().isEmpty || notificationId.trim().isEmpty) return;

    await _notificationsRef(pharmacyId).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// تعيين كل الإشعارات كمقروءة
  Future<void> markAllAsRead(String pharmacyId) async {
    if (pharmacyId.trim().isEmpty) return;

    final snapshot = await _notificationsRef(pharmacyId)
        .where('isRead', isEqualTo: false)
        .where('isDeleted', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// تعيين إشعارات نوع معين كمقروءة
  /// مفيدة لو تبي مثلاً:
  /// markAllByTypeAsRead(type: 'newOrder')
  Future<void> markAllByTypeAsRead({
    required String pharmacyId,
    required String type,
  }) async {
    if (pharmacyId.trim().isEmpty || type.trim().isEmpty) return;

    final snapshot = await _notificationsRef(pharmacyId)
        .where('type', isEqualTo: type.trim())
        .where('isRead', isEqualTo: false)
        .where('isDeleted', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
  Future<bool> markOrderNotificationAsRead({
    required String pharmacyId,
    required String orderId,
  }) async {
    if (pharmacyId.trim().isEmpty || orderId.trim().isEmpty) return false;

    final docRef = _notificationsRef(pharmacyId).doc('new_order_$orderId');

    final doc = await docRef.get();

    if (!doc.exists) return false;

    final data = doc.data();
    final isRead = data?['isRead'] == true;
    final isDeleted = data?['isDeleted'] == true;

    if (isRead || isDeleted) return false;

    await docRef.update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });

    return true;
  }
  Future<void> deleteNotification({
    required String pharmacyId,
    required String notificationId,
  }) async {
    if (pharmacyId.trim().isEmpty || notificationId.trim().isEmpty) return;

    await _notificationsRef(pharmacyId).doc(notificationId).update({
      'isDeleted': true,
    });
  }
}