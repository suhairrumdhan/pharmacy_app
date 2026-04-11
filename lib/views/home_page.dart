import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pharmacy_desktop/views/purchases/purchases_page.dart';
import 'package:pharmacy_desktop/views/shifts/shifts_page.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
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
    });
  }

  void _updateUserInfo() {
    final employee = authController.currentEmployee.value;
    if (employee != null) {
      authController.currentUserName.value = employee['username'] ?? '';
    } else {
      authController.currentUserName.value = authController.userName;
    }
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

  const PageWrapper({
    super.key,
    required this.child,
    this.actions,
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
                    const NotificationButton(),
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
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () {},
            color: Colors.grey.shade700,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}
