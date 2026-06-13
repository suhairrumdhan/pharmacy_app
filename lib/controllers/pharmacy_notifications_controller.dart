import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/pharmacy_notification_model.dart';
import '../services/pharmacy_notifications_service.dart';

class PharmacyNotificationsController extends GetxController {
  final PharmacyNotificationsService _service =
      PharmacyNotificationsService.instance;

  StreamSubscription<List<PharmacyNotificationModel>>? _latestSub;
  StreamSubscription<int>? _unreadSub;
  StreamSubscription<int>? _ordersUnreadSub;
  StreamSubscription<int>? _systemUnreadSub;

  /// هذه القائمة خاصة بديالوج الإشعارات فقط
  /// لذلك سنضع فيها إشعارات الإدارة فقط adminBroadcast
  final RxList<PharmacyNotificationModel> notifications =
      <PharmacyNotificationModel>[].obs;

  /// عداد عام لكل الإشعارات غير المقروءة لو احتجتيه لاحقًا
  final RxInt unreadCount = 0.obs;

  /// عداد الطلبات الجديدة لزر الطلبات في السايدبار
  final RxInt orderUnreadCount = 0.obs;

  /// عداد إشعارات الإدارة لزر الجرس
  final RxInt systemUnreadCount = 0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString pharmacyId = ''.obs;

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  bool _initialLoadDone = false;
  final Set<String> _seenNotificationIds = {};

  void startListening(String currentPharmacyId) {
    if (currentPharmacyId.trim().isEmpty) {
      print('🔴 Notifications: pharmacyId is empty');
      return;
    }

    print('🟢 Notifications: startListening for $currentPharmacyId');

    pharmacyId.value = currentPharmacyId;

    _latestSub?.cancel();
    _unreadSub?.cancel();
    _ordersUnreadSub?.cancel();
    _systemUnreadSub?.cancel();

    _initialLoadDone = false;
    _seenNotificationIds.clear();

    /// تحميل إشعارات الإدارة فقط للديالوج
    loadFirstPage();

    /// Listener خفيف لآخر الإشعارات حتى نعرض Snackbar للطلبات/الرسائل/الإدارة
    _latestSub = _service
        .getLatestNotificationsStream(
      currentPharmacyId,
      limit: 20,
    )
        .listen(
          (latestItems) {
        print('📩 Latest notifications received: ${latestItems.length}');

        if (!_initialLoadDone) {
          _seenNotificationIds.addAll(latestItems.map((e) => e.id));
          _initialLoadDone = true;
          return;
        }

        for (final notification in latestItems) {
          if (!_seenNotificationIds.contains(notification.id)) {
            _seenNotificationIds.add(notification.id);

            /// إشعارات الإدارة فقط تدخل ديالوج الإشعارات
            if (notification.type == 'adminBroadcast') {
              _insertOrReplaceNotification(notification);
            }

            /// الكل يطلع كتنبيه داخلي: طلبات + رسائل + إدارة
            _showInternalAlert(notification);
          }
        }
      },
      onError: (error) {
        print('🔴 Pharmacy notifications stream error: $error');
      },
    );

    /// عداد كل الإشعارات غير المقروءة
    _unreadSub = _service.getUnreadCountStream(currentPharmacyId).listen(
          (count) {
        unreadCount.value = count;
      },
    );

    /// عداد الطلبات الجديدة لزر الطلبات
    _ordersUnreadSub = _service.getUnreadCountByTypeStream(
      pharmacyId: currentPharmacyId,
      type: 'newOrder',
    ).listen((count) {
      orderUnreadCount.value = count;
    });

    /// عداد إشعارات الإدارة لزر الجرس
    _systemUnreadSub = _service.getUnreadCountByTypeStream(
      pharmacyId: currentPharmacyId,
      type: 'adminBroadcast',
    ).listen((count) {
      systemUnreadCount.value = count;
    });
  }
  Future<void> markOrderAsRead(String orderId) async {
    final changed = await _service.markOrderNotificationAsRead(
      pharmacyId: pharmacyId.value,
      orderId: orderId,
    );

    if (changed && orderUnreadCount.value > 0) {
      orderUnreadCount.value--;
    }
  }
  Future<void> markAllSystemAsRead() async {
    await _service.markAllByTypeAsRead(
      pharmacyId: pharmacyId.value,
      type: 'adminBroadcast',
    );

    await loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    final id = pharmacyId.value.trim();
    if (id.isEmpty) return;

    try {
      isLoading.value = true;
      _lastDoc = null;
      hasMore.value = true;

      /// الديالوج يعرض إشعارات الإدارة فقط
      final result = await _service.fetchNotificationsPage(
        pharmacyId: id,
        limit: 20,
        type: 'adminBroadcast',
      );

      notifications.assignAll(result.notifications);
      _lastDoc = result.lastDoc;
      hasMore.value = result.hasMore;
      _seenNotificationIds.addAll(result.notifications.map((e) => e.id));
    } catch (e) {
      print('🔴 loadFirstPage error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    final id = pharmacyId.value.trim();
    if (id.isEmpty || isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;

      /// عرض المزيد للإدارة فقط
      final result = await _service.fetchNotificationsPage(
        pharmacyId: id,
        startAfter: _lastDoc,
        limit: 20,
        type: 'adminBroadcast',
      );

      for (final item in result.notifications) {
        _insertOrReplaceNotification(item, showOnTop: false);
      }

      _lastDoc = result.lastDoc ?? _lastDoc;
      hasMore.value = result.hasMore;
      _seenNotificationIds.addAll(result.notifications.map((e) => e.id));
    } catch (e) {
      print('🔴 loadMore error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _insertOrReplaceNotification(
      PharmacyNotificationModel notification, {
        bool showOnTop = true,
      }) {
    final index = notifications.indexWhere((n) => n.id == notification.id);

    if (index >= 0) {
      notifications[index] = notification;
      return;
    }

    if (showOnTop) {
      notifications.insert(0, notification);
    } else {
      notifications.add(notification);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(
      pharmacyId: pharmacyId.value,
      notificationId: notificationId,
    );

    /// طالما الموديل ما فيه copyWith، نخلي التحديث ينعكس من إعادة التحميل
    /// أو عند فتح الديالوج مرة ثانية.
  }

  Future<void> markAllAsRead() async {
    /// هذا سيعلّم كل إشعارات الصيدلية كمقروءة.
    /// لو تبي لاحقًا نخليها للإدارة فقط، ندير دالة markAllByTypeAsRead.
    await _service.markAllAsRead(pharmacyId.value);
    await loadFirstPage();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(
      pharmacyId: pharmacyId.value,
      notificationId: notificationId,
    );

    notifications.removeWhere((n) => n.id == notificationId);
  }

  Future<void> handleTap(PharmacyNotificationModel notification) async {
    if (!notification.isRead) {
      await markAsRead(notification.id);
    }
  }

  void _showInternalAlert(PharmacyNotificationModel notification) {
    print('🚨 showInternalAlert: ${notification.title}');

    SystemSound.play(SystemSoundType.alert);

    String title = notification.title;

    if (notification.type == 'newOrder') {
      title = 'طلب جديد';
    } else if (notification.type == 'chatMessage') {
      title = 'رسالة جديدة';
    } else if (notification.type == 'adminBroadcast') {
      title = 'إشعار من الإدارة';
    }

    Get.snackbar(
      title.isNotEmpty ? title : 'إشعار جديد',
      notification.message.isNotEmpty
          ? notification.message
          : 'لديك إشعار جديد',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      isDismissible: true,
      backgroundColor: const Color(0xFF1E40AF),
      colorText: Colors.white,
      onTap: (_) {
        handleTap(notification);
      },
    );
  }

  /// هذه القوائم الآن تخص إشعارات الإدارة فقط
  /// لأن notifications نفسها لا تحتوي إلا adminBroadcast

  List<PharmacyNotificationModel> get todayNotifications {
    final now = DateTime.now();

    return notifications.where((n) {
      final d = n.createdAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<PharmacyNotificationModel> get weekNotifications {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    return notifications.where((n) {
      final d = n.createdAt;
      final isToday =
          d.year == now.year && d.month == now.month && d.day == now.day;

      return !isToday && d.isAfter(startOfWeek);
    }).toList();
  }

  List<PharmacyNotificationModel> get olderNotifications {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    return notifications.where((n) {
      final d = n.createdAt;
      return d.isBefore(startOfWeek);
    }).toList();
  }

  @override
  void onClose() {
    _latestSub?.cancel();
    _unreadSub?.cancel();
    _ordersUnreadSub?.cancel();
    _systemUnreadSub?.cancel();
    super.onClose();
  }
}