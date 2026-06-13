import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pharmacy_desktop/views/purchases/purchases_page.dart';
import 'package:pharmacy_desktop/views/shifts/shifts_page.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/pharmacy_notifications_controller.dart';
import '../controllers/pharmacy_orders_controller.dart';
import '../models/pharmacy_notification_model.dart';
import '../widgets/sidebar.dart';

// صفحاتك الحالية
import 'chat/chat_page.dart';
import 'dashboard_page.dart';
import 'inventory/inventory_page.dart';
import 'orders/orders_page.dart';
import 'sales/sales_page.dart';
import 'settings/settings_page.dart';
import 'suppliers_page.dart';
import 'insurance_companies_page.dart';
import 'finance_page.dart';
//import 'shifts/shifts_page.dart';

/// ✅ صفحات جديدة (Placeholder) - تقدر تنقلها لملفات منفصلة لاحقا
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NavigationController navController = Get.put(NavigationController());
  final ChatController chatController = Get.find<ChatController>(); // ✅ أضف هذ
  final AuthController authController = Get.find<AuthController>();
  late List<Widget> pages;
  late List<SidebarItem> sidebarItems;

  // ✅ مصدر واحد يولّد الاثنين بنفس الترتيب
  late List<Map<String, dynamic>> visibleRoutes;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUserInfo();
      _initPharmacyNotifications();
    });
  }
  Future<void> _handleNotificationTap(
      PharmacyNotificationModel notification,
      ) async {
    final notificationsController =
    Get.find<PharmacyNotificationsController>();

    if (!notification.isRead) {
      await notificationsController.markAsRead(notification.id);
    }

    if (notification.type == 'chatMessage' &&
        notification.chatId != null &&
        notification.chatId!.trim().isNotEmpty) {
      final chatIndex = _findVisiblePageIndex('المراسلات');

      if (chatIndex != null) {
        navController.goToPage(chatIndex);
      }

      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().loadMessages(notification.chatId!);
      }

      return;
    }

    if (notification.type == 'newOrder' &&
        notification.orderId != null &&
        notification.orderId!.trim().isNotEmpty) {
      final ordersIndex = _findVisiblePageIndex('الطلبات');

      if (ordersIndex != null) {
        navController.goToPage(ordersIndex);
      }

      if (Get.isRegistered<PharmacyOrdersController>()) {
        final ordersController = Get.find<PharmacyOrdersController>();

        final order = ordersController.allOrders.firstWhereOrNull(
              (o) => o.id == notification.orderId,
        );

        if (order != null) {
          ordersController.selectOrder(order);
        }
      }

      return;
    }

    if (notification.type == 'adminBroadcast') {
      Get.defaultDialog(
        title: notification.title,
        middleText: notification.message,
        textConfirm: 'حسنًا',
        onConfirm: Get.back,
      );
    }
  }

  int? _findVisiblePageIndex(String label) {
    final index = sidebarItems.indexWhere((item) => item.label == label);
    return index == -1 ? null : index;
  }

  void _updateUserInfo() {
    final employee = authController.currentEmployee.value;
    if (employee != null) {
      authController.currentUserName.value = employee['username'] ?? '';
    } else {
      authController.currentUserName.value = authController.userName;
    }
  }
  void _initPharmacyNotifications() {
    final pharmacyId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (pharmacyId.trim().isEmpty) {
      debugPrint('⚠️ pharmacyId is empty. Notifications not initialized.');
      return;
    }

    final controller = Get.isRegistered<PharmacyNotificationsController>()
        ? Get.find<PharmacyNotificationsController>()
        : Get.put(
      PharmacyNotificationsController(),
      permanent: true,
    );

    controller.startListening(pharmacyId);
  }
  // عناوين الصفحات (الترتيب هنا يتطابق مع allPages titleIndex)
  final List<String> pageTitles = [
    'لوحة التحكم',
    'الطلبات',
    'المبيعات',
    'الورديات',
    'المخزون',
    'المشتريات',
    'الموردين',
    'شركات التأمين',
    'الشؤون المالية',
    'المراسلات',
    'الإعدادات',
  ];

  /// ✅ الترتيب الجديد (MVP صيدلية قوي)
  final List<Map<String, dynamic>> allPages = [
    {'widget':  DashboardPage(), 'permission': 'dashboard.view', 'titleIndex': 0},
    {'widget': OrdersPage(), 'permission': 'orders.view', 'titleIndex': 1},
    {'widget': SalesPage(), 'permission': 'sales.view', 'titleIndex': 2},
    {'widget': ShiftsPage(), 'permission': 'shifts.view', 'titleIndex': 3},
    {'widget': InventoryPage(), 'permission': 'inventory.view', 'titleIndex': 4},
    {'widget': PurchasesPage(), 'permission': 'purchases.view', 'titleIndex': 5},
    {'widget': SuppliersPage(), 'permission': 'suppliers.view', 'titleIndex': 6},
    {'widget': InsuranceCompaniesPage(), 'permission': 'insurance.view', 'titleIndex': 7},
    {'widget': FinancePage(), 'permission': 'finance.view', 'titleIndex': 8},
    {'widget': ChatPage(), 'permission': 'messages.view', 'titleIndex': 9},
    {'widget': SettingsPage(), 'permission': 'settings.view', 'titleIndex': 10},
  ];

  final List<Map<String, dynamic>> allSidebarItems = [
    {'item': SidebarItem(icon: Iconsax.home_2, label: "لوحة التحكم", activeIcon: Iconsax.home_2), 'permission': 'dashboard.view'},
    {'item': SidebarItem(icon: Iconsax.receipt, label: "الطلبات", activeIcon: Iconsax.receipt), 'permission': 'orders.view'},
    {'item': SidebarItem(icon: Iconsax.shopping_cart, label: "المبيعات", activeIcon: Iconsax.shopping_cart), 'permission': 'sales.view'},
    {'item': SidebarItem(icon: Iconsax.clock, label: "الورديات", activeIcon: Iconsax.clock), 'permission': 'shifts.view'},
    {'item': SidebarItem(icon: Iconsax.box, label: "المخزون", activeIcon: Iconsax.box), 'permission': 'inventory.view'},
    {'item': SidebarItem(icon: Iconsax.shopping_bag, label: "المشتريات", activeIcon: Iconsax.shopping_bag), 'permission': 'purchases.view'},
    {'item': SidebarItem(icon: Iconsax.truck, label: "الموردين", activeIcon: Iconsax.truck), 'permission': 'suppliers.view'},
    {'item': SidebarItem(icon: Iconsax.shield_tick, label: "شركات التأمين", activeIcon: Iconsax.shield_tick), 'permission': 'insurance.view'},
    {'item': SidebarItem(icon: Iconsax.dollar_circle, label: "الشؤون المالية", activeIcon: Iconsax.dollar_circle), 'permission': 'finance.view'},
    {
      'item': SidebarItem(
        icon: Iconsax.message,
        label: "المراسلات",
        activeIcon: Iconsax.message,
        notificationCount: 0, // ✅ خليها 0 مؤقتاً
      ),
      'permission': 'messages.view'
    },
    {'item': SidebarItem(icon: Iconsax.setting_2, label: "الإعدادات", activeIcon: Iconsax.setting_2), 'permission': 'settings.view'},
  ];

  void _buildUiFromPermissions() {
    visibleRoutes = [];

    // ✅ فلترة واحدة: نفس الترتيب ونفس الـ index
    final len = (allPages.length < allSidebarItems.length)
        ? allPages.length
        : allSidebarItems.length;

    for (int i = 0; i < len; i++) {
      final pagePerm = allPages[i]['permission'] as String;
      // نستخدم permission من الصفحة (أو تقدر تستعمل من السايدبار نفس الشي)
      if (authController.can(pagePerm)) {
        visibleRoutes.add({
          'page': allPages[i],
          'sidebar': allSidebarItems[i],
        });
      }
    }

    pages = visibleRoutes.map((r) {
      final p = r['page'] as Map<String, dynamic>;
      final titleIndex = p['titleIndex'] as int;
      return PageWrapper(
        child: p['widget'] as Widget,
        onNotificationTap: _handleNotificationTap,
      );
    }).toList();

    sidebarItems = visibleRoutes
        .map((r) => (r['sidebar'] as Map<String, dynamic>)['item'] as SidebarItem)
        .toList();

    if (navController.selectedIndex.value >= pages.length) navController.selectedIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (!authController.isPharmacyLoaded.value ||
            !authController.isPermissionsLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        _buildUiFromPermissions();

        if (pages.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد صلاحيات لعرض أي صفحة',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        if (navController.selectedIndex.value >= pages.length) navController.selectedIndex.value = 0;

        final String pharmacyName =
            authController.pharmacyData['pharmacyName'] as String? ?? '';

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // ✅ Responsive breakpoints للابتوبات
            final bool collapsed = w < 1150;
            final double sidebarWidth = collapsed ? 86 : 260;

            return Row(
              children: [
                SizedBox(
                  width: sidebarWidth,
                  child: SidebarWidget(
                    collapsed: collapsed,
                    selectedIndex: navController.selectedIndex.value,
                    sidebarItems: sidebarItems,
                    onItemSelected: navController.goToPage,
                    pharmacyName: pharmacyName,
                    backgroundColor: const Color(0xFF1E40AF),
                    activeColor: const Color(0xFF3B82F6),
                    textColor: Colors.white,
                    activeTextColor: Colors.white,
                  ),
                ),
                Expanded(child: pages[navController.selectedIndex.value]),
              ],
            );
          },
        );
      }),
    );
  }
}

class PageWrapper extends StatelessWidget {
  final Widget child;
  final List<Widget>? actions;
  final Future<void> Function(PharmacyNotificationModel notification)?
  onNotificationTap;

  const PageWrapper({
    super.key,
    required this.child,
    this.actions,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 70,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    ...?actions,
                    const SizedBox(width: 8),
                    NotificationButton(
                      onNotificationTap: onNotificationTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void goToPage(int index) {
    selectedIndex.value = index;
  }
}

class NotificationButton extends StatelessWidget {
  final Future<void> Function(PharmacyNotificationModel notification)?
  onNotificationTap;

  const NotificationButton({
    super.key,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PharmacyNotificationsController>();

    return Obx(() {
      // ✅ زر الجرس يحسب إشعارات الإدارة فقط
      final count = controller.systemUnreadCount.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, size: 28),
              color: count > 0 ? const Color(0xFF1E40AF) : Colors.grey.shade700,
              tooltip: 'إشعارات الإدارة',
              onPressed: () {
                Get.dialog(
                  PharmacyNotificationsDialog(
                    controller: controller,
                    onNotificationTap: onNotificationTap,
                  ),
                );
              },
            ),
          ),
          if (count > 0)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class PharmacyNotificationsDialog extends StatelessWidget {
  final PharmacyNotificationsController controller;
  final Future<void> Function(PharmacyNotificationModel notification)?
  onNotificationTap;

  const PharmacyNotificationsDialog({
    super.key,
    required this.controller,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد إشعارات حالياً',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _buildSection(
                      title: 'اليوم',
                      items: controller.todayNotifications,
                    ),
                    _buildSection(
                      title: 'هذا الأسبوع',
                      items: controller.weekNotifications,
                    ),
                    _buildSection(
                      title: 'الأقدم',
                      items: controller.olderNotifications,
                    ),
                    if (controller.hasMore.value) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Obx(() {
                          return OutlinedButton.icon(
                            onPressed: controller.isLoadingMore.value
                                ? null
                                : controller.loadMore,
                            icon: controller.isLoadingMore.value
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Iconsax.arrow_down_1, size: 18),
                            label: Text(
                              controller.isLoadingMore.value
                                  ? 'جاري التحميل...'
                                  : 'عرض المزيد',
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSection({
    required String title,
    required List<PharmacyNotificationModel> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 8,
            right: 4,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        ...items.map((notification) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationTile(
              notification: notification,
              onTap: () async {
                Get.back();

                if (onNotificationTap != null) {
                  await onNotificationTap!(notification);
                } else {
                  await controller.markAsRead(notification.id);
                }
              },
              onDelete: () {
                controller.deleteNotification(notification.id);
              },
            ),
          );
        }),
      ],
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Iconsax.notification,
              color: Color(0xFF1E40AF),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إشعارات الإدارة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'التنبيهات والإعلانات المرسلة من الإدارة المركزية',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.systemUnreadCount.value == 0) {
              return const SizedBox.shrink();
            }

            return TextButton.icon(
              onPressed: controller.markAllSystemAsRead,
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: const Text('تعيين الكل كمقروء'),
            );
          }),
          const SizedBox(width: 8),
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PharmacyNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? const Color(0xFFBFDBFE) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                            unread ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _typeLabel(notification.type),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'حذف',
                        onPressed: onDelete,
                        icon: Icon(
                          Iconsax.trash,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon() {
    IconData icon;
    Color color;
    Color bg;

    switch (notification.type) {
      case 'newOrder':
        icon = Iconsax.box;
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
        break;
      case 'chatMessage':
        icon = Iconsax.message;
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFDBEAFE);
        break;
      case 'adminBroadcast':
        icon = Iconsax.info_circle;
        color = const Color(0xFF9333EA);
        bg = const Color(0xFFF3E8FF);
        break;
      default:
        icon = Iconsax.notification;
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'adminBroadcast':
        return 'إدارة';
      default:
        return 'إشعار إداري';
    }
  }
}