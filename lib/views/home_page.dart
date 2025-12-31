import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/sidebar.dart';
import 'chat/chat_page.dart';
import 'inventory/inventory_page.dart';
import 'orders/orders_page.dart';
import 'sales/sales_page.dart';
import 'settings/settings_page.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'accounts_page.dart';
import 'suppliers_page.dart';
import 'insurance_companies_page.dart';
import 'finance_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final AuthController authController = Get.find();
  late List<Widget> pages;
  late List<SidebarItem> sidebarItems;
  @override
  void initState() {
    super.initState();
    // تحديث اسم المستخدم والدور عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUserInfo();
    });
  }

  void _updateUserInfo() {
    final employee = authController.currentEmployee.value;
    if (employee != null) {
      authController.currentUserName.value = employee['username'] ?? '';
    }
  }

  // قائمة العناوين
  final List<String> pageTitles = [
    'لوحة التحكم',
    'المبيعات',
    'المخزون',
    'الطلبات',
    'الموردين',
    'شركات التأمين',
    'الحسابات',
    'الشؤون المالية',
    'المراسلات',
    'الإعدادات',
  ];

  final List<Map<String, dynamic>> allPages = [
    {'widget': DashboardPage(), 'permission': 'dashboard.view', 'titleIndex': 0},
    {'widget': SalesPage(), 'permission': 'sales.view', 'titleIndex': 1},
    {'widget': InventoryPage(), 'permission': 'inventory.view', 'titleIndex': 2},
    {'widget': OrdersPage(), 'permission': 'orders.view', 'titleIndex': 3},
    {'widget': SuppliersPage(), 'permission': 'suppliers.view', 'titleIndex': 4},
    {'widget': InsuranceCompaniesPage(), 'permission': 'insurance.view', 'titleIndex': 5},
    {'widget': AccountsPage(), 'permission': 'accounts.view', 'titleIndex': 6},
    {'widget': FinancePage(), 'permission': 'finance.view', 'titleIndex': 7},
    {'widget': ChatPage(), 'permission': 'messages.view', 'titleIndex': 8},
    {'widget': SettingsPage(), 'permission': 'settings.view', 'titleIndex': 9},
  ];

  final List<Map<String, dynamic>> allSidebarItems = [
    {'item': SidebarItem(icon: Iconsax.home_2, label: "لوحة التحكم", activeIcon: Iconsax.home_2), 'permission': 'dashboard.view'},
    {'item': SidebarItem(icon: Iconsax.shopping_cart, label: "المبيعات", activeIcon: Iconsax.shopping_cart), 'permission': 'sales.view'},
    {'item': SidebarItem(icon: Iconsax.box, label: "المخزون", activeIcon: Iconsax.box), 'permission': 'inventory.view'},
    {'item': SidebarItem(icon: Iconsax.receipt, label: "الطلبات", activeIcon: Iconsax.receipt), 'permission': 'orders.view'},
    {'item': SidebarItem(icon: Iconsax.truck, label: "الموردين", activeIcon: Iconsax.truck), 'permission': 'suppliers.view'},
    {'item': SidebarItem(icon: Iconsax.shield_tick, label: "شركات التأمين", activeIcon: Iconsax.shield_tick), 'permission': 'insurance.view'},
    {'item': SidebarItem(icon: Iconsax.wallet, label: "الحسابات", activeIcon: Iconsax.wallet), 'permission': 'accounts.view'},
    {'item': SidebarItem(icon: Iconsax.dollar_circle, label: "الشؤون المالية", activeIcon: Iconsax.dollar_circle), 'permission': 'finance.view'},
    {'item': SidebarItem(icon: Iconsax.message, label: "المراسلات", activeIcon: Iconsax.message), 'permission': 'messages.view'},
    {'item': SidebarItem(icon: Iconsax.setting_2, label: "الإعدادات", activeIcon: Iconsax.setting_2), 'permission': 'settings.view'},
  ];

  void _buildUiFromPermissions() {
    pages = allPages
        .where((p) => authController.can(p['permission']))
        .map((p) {
      final titleIndex = p['titleIndex'] as int;
      return PageWrapper(
        title: pageTitles[titleIndex],
        child: p['widget'] as Widget,
      );
    })
        .toList();

    sidebarItems = allSidebarItems
        .where((i) => authController.can(i['permission']))
        .map((i) => i['item'] as SidebarItem)
        .toList();

    if (selectedIndex >= pages.length) selectedIndex = 0;
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

        if (selectedIndex >= pages.length) {
          selectedIndex = 0;
        }

        final String pharmacyName =
            authController.pharmacyData['pharmacyName'] as String? ?? '';

        return Row(
          children: [
            SidebarWidget(
              selectedIndex: selectedIndex,
              sidebarItems: sidebarItems,
              onItemSelected: (index) {
                setState(() => selectedIndex = index);
              },
              pharmacyName: pharmacyName,
              backgroundColor: const Color(0xFF1E40AF),
              activeColor: const Color(0xFF3B82F6),
              textColor: Colors.white,
              activeTextColor: Colors.white,
            ),
            Expanded(
              child: pages[selectedIndex],
            ),
          ],
        );
      }),
    );
  }
}





class PageWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const PageWrapper({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // AppBar مخصص
          Container(
            height: 70,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
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

          // محتوى الصفحة - بدون SingleChildScrollView
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // بطاقات الإحصائيات
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildStatCard(
                Icons.medication,
                "إجمالي الأدوية",
                "120",
                const Color(0xFF2E7D32),
                Icons.trending_up,
              ),
              _buildStatCard(
                Icons.shopping_cart,
                "المبيعات اليوم",
                "1,250 ",
                const Color(0xFF1976D2),
                Icons.trending_up,
              ),
              _buildStatCard(
                Icons.pending_actions,
                "طلبات قيد الانتظار",
                "8",
                const Color(0xFFF57C00),
                Icons.schedule,
              ),
              _buildStatCard(
                Icons.warning,
                "منخفضة المخزون",
                "5",
                const Color(0xFFD32F2F),
                Icons.inventory_2,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // مخططات سريعة
          Row(
            children: [
              Expanded(
                child: _buildQuickChart("المبيعات الأسبوعية", Colors.blue),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildQuickChart("الأدوية الأكثر مبيعاً", Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color, IconData trendIcon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Icon(trendIcon, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildQuickChart(String title, Color color) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              color: color.withOpacity(0.2),
              child: const Center(child: Text("Chart Placeholder")),
            ),
          ),
        ],
      ),
    );
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
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
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
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}