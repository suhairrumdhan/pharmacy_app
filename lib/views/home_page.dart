import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/sales_controller.dart';
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

  // قائمة الصفحات
  final List<Widget> pages = [
    const DashboardPage(),
    SalesPage(),
    InventoryPage(),
    OrdersPage(),
    SuppliersPage(),
    InsuranceCompaniesPage(),
    AccountsPage(),
    FinancePage(),
    ChatPage(),
    SettingsPage(),
  ];

  // عناصر القائمة الجانبية مع أيكونات Iconsax
  final List<SidebarItem> sidebarItems = [
    SidebarItem(
      icon: Iconsax.home_2,
      label: "لوحة التحكم",
      activeIcon: Iconsax.home_2,
    ),
    SidebarItem(
      icon: Iconsax.shopping_cart,
      label: "المبيعات",
      activeIcon: Iconsax.shopping_cart,
      hasNotification: true,
    ),
    SidebarItem(
      icon: Iconsax.box,
      label: "المخزون",
      activeIcon: Iconsax.box,
    ),
    SidebarItem(
      icon: Iconsax.receipt,
      label: "الطلبات",
      activeIcon: Iconsax.receipt,
      hasNotification: true,
    ),
    SidebarItem(
      icon: Iconsax.truck,
      label: "الموردين",
      activeIcon: Iconsax.truck,
    ),
    SidebarItem(
      icon: Iconsax.shield_tick,
      label: "شركات التأمين",
      activeIcon: Iconsax.shield_tick,
    ),
    SidebarItem(
      icon: Iconsax.wallet,
      label: "الحسابات",
      activeIcon: Iconsax.wallet,
    ),
    SidebarItem(
      icon: Iconsax.dollar_circle,
      label: "الشؤون المالية",
      activeIcon: Iconsax.dollar_circle,
    ),
    SidebarItem(
      icon: Iconsax.message,
      label: "المراسلات",
      activeIcon: Iconsax.message,
      hasNotification: true,
    ),
    SidebarItem(
      icon: Iconsax.setting_2,
      label: "الإعدادات",
      activeIcon: Iconsax.setting_2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (authController.pharmacyData.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          );
        }

        return Row(
          children: [
            // الشريط الجانبي الأزرق
            SidebarWidget(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              pharmacyName: authController.pharmacyData["name"],
              pharmacyAddress: authController.pharmacyData["address"] ?? "",
              sidebarItems: sidebarItems,
              backgroundColor: const Color(0xFF1E40AF),
              activeColor: const Color(0xFF3B82F6),
              textColor: Colors.white,
              activeTextColor: Colors.white,
            ),

            // المحتوى الرئيسي
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    // شريط العنوان مع زر تبديل الحسابات
                    _buildAppBar(),

                    // المحتوى
                    Expanded(
                      child: pages[selectedIndex],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // بناء شريط التطبيق مع زر تبديل الحسابات
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // العنوان مع أيقونة الصفحة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sidebarItems[selectedIndex].activeIcon ??
                      sidebarItems[selectedIndex].icon,
                  color: const Color(0xFF1E40AF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                sidebarItems[selectedIndex].label,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),

          // الأزرار في الشريط العلوي
          Row(
            children: [
                _buildAccountSwitchButton(),
              const SizedBox(width: 16),

              // زر الإشعارات
              _buildNotificationButton(),

              const SizedBox(width: 16),

              // معلومات المستخدم
              _buildUserProfile(),
            ],
          ),
        ],
      ),
    );
  }

  // زر تبديل الحسابات للموظفين
  Widget _buildAccountSwitchButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(Iconsax.profile_2user, color: const Color(0xFF1E40AF), size: 20),
              const SizedBox(width: 8),
              Text(
                "تبديل الحساب",
                style: TextStyle(
                  color: const Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        onSelected: (value) {
          _handleAccountSwitch(value);
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              value: 'employee1',
              child: Row(
                children: [
                  Icon(Iconsax.profile_circle, color: const Color(0xFF1E40AF), size: 20),
                  const SizedBox(width: 12),
                  const Text("محمد أحمد (موظف)"),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'employee2',
              child: Row(
                children: [
                  Icon(Iconsax.profile_circle, color: const Color(0xFF1E40AF), size: 20),
                  const SizedBox(width: 12),
                  const Text("فاطمة علي (صيدلاني)"),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'admin',
              child: Row(
                children: [
                  Icon(Iconsax.security_user, color: const Color(0xFF1E40AF), size: 20),
                  const SizedBox(width: 12),
                  const Text("حساب المدير"),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Iconsax.logout, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text("تسجيل الخروج", style: TextStyle(color: Colors.red.shade600)),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  // زر الإشعارات
  Widget _buildNotificationButton() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Iconsax.notification,
            color: const Color(0xFF1E40AF),
            size: 24,
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // معلومات المستخدم
  Widget _buildUserProfile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'المستخدم',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E40AF),
                ),
              ),
              Text(
                'role',
                style: TextStyle(
                  color: const Color(0xFF1E40AF).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
               'name',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // معالجة تبديل الحساب
  void _handleAccountSwitch(String value) {
    if (value == 'logout') {
      authController.logout();
      return;
    }

    Get.snackbar(
      'تبديل الحساب',
      'تم التبديل إلى حساب جديد',
      backgroundColor: const Color(0xFF1E40AF),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: Icon(Iconsax.profile_2user, color: Colors.white),
    );
  }

  // الحصول على اسم الدور
  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'owner':
        return 'صاحب الصيدلية';
      case 'pharmacist':
        return 'صيدلاني';
      case 'employee':
        return 'موظف';
      default:
        return 'مستخدم';
    }
  }

  // الحصول على الأحرف الأولى من الاسم
  String _getUserInitials(String name) {
    if (name.isEmpty) return 'م';
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0][0] + parts[1][0];
    }
    return name[0];
  }
}





class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesController salesController = Get.find();
    final InventoryController inventoryController = Get.find();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // بطاقات الإحصائيات
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            physics: const NeverScrollableScrollPhysics(),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChart(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            color: Colors.grey.shade100,
            child: Center(
              child: Text(
                "مخطط $title",
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// زر الإشعارات
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