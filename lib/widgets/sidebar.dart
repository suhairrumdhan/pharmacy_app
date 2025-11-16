import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String pharmacyName;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.pharmacyName,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // شعار الصيدلية
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services,
              size: 40,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            pharmacyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "صيدلية",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),

          // عناصر القائمة
          _buildSidebarItem(Icons.dashboard, "لوحة التحكم", 0),
          _buildSidebarItem(Icons.shopping_cart, "المبيعات", 1),
          _buildSidebarItem(Icons.medication, "المخزون", 2),
          _buildSidebarItem(Icons.chat, "المراسلات", 3),
          _buildSidebarItem(Icons.settings, "الإعدادات", 4),

          const Spacer(),

          // زر تسجيل الخروج
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "تسجيل الخروج",
                style: TextStyle(color: Colors.red),
              ),
              onTap: authController.logout,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool active = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
        border: active ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: active ? Colors.amber : Colors.white.withOpacity(0.8),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.amber : Colors.white.withOpacity(0.9),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }
}