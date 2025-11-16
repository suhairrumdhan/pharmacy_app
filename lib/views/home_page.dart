import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/sales_controller.dart';
import '../widgets/sidebar.dart';
import 'chat/chat_page.dart';
import 'inventory/inventory_page.dart';
import 'sales/sales_page.dart';
import 'settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final AuthController authController = Get.find();

  final List<Widget> pages = [
    const DashboardPage(),
     SalesPage(),
     InventoryPage(),
     ChatPage(),
     SettingsPage(),
  ];

  final List<String> titles = [
    "لوحة التحكم",
    "المبيعات",
    "المخزون",
    "المراسلات",
    "الإعدادات"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (authController.pharmacyData.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          );
        }

        return Row(
          children: [
            // الشريط الجانبي
            SidebarWidget(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              pharmacyName: authController.pharmacyData["name"],
            ),

            // المحتوى الرئيسي
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    // شريط العنوان
                    Container(
                      padding: const EdgeInsets.all(24),
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
                          Text(
                            titles[selectedIndex],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const NotificationButton(),
                        ],
                      ),
                    ),

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
}

// لوحة التحكم
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
                "1,250 ريال",
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