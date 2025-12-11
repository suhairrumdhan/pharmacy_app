import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildEmployeesCard() {
  // قائمة الخيارات الستة
  final options = [
    {
      'title': 'إضافة/حذف/تعديل الموظفين',
      'icon': Icons.person_add_rounded,
    },
    {
      'title': 'الصلاحيات والأدوار',
      'icon': Icons.admin_panel_settings_rounded,
    },
    {
      'title': 'الحضور والشفتات',
      'icon': Icons.calendar_today_rounded,
    },
    {
      'title': 'الرواتب',
      'icon': Icons.payments_rounded,
    },
    {
      'title': 'سجل العمليات',
      'icon': Icons.history_rounded,
    },
    {
      'title': 'الأمن والصلاحيات',
      'icon': Icons.security_rounded,
    },
  ];

  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.group_rounded,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'إدارة الموظفين',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'إدارة موظفي الصيدلية، الأدوار والصلاحيات',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // تقسيم الأزرار إلى صفوف كل صف يحتوي على زرين
            Column(
              children: [
                // الصف الأول
                Row(
                  children: [
                    Expanded(
                      child: _buildManagementButton(
                        title: 'إضافة/حذف/تعديل الموظفين',
                        icon: Icons.person_add_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الصلاحيات والأدوار',
                        icon: Icons.admin_panel_settings_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // الصف الثاني
                Row(
                  children: [
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الحضور والشفتات',
                        icon: Icons.calendar_today_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الرواتب',
                        icon: Icons.payments_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // الصف الثالث
                Row(
                  children: [
                    Expanded(
                      child: _buildManagementButton(
                        title: 'سجل العمليات',
                        icon: Icons.history_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الأمن والصلاحيات',
                        icon: Icons.security_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// دالة لبناء زر الإدارة (بنفس تصميم الزر الأصلي)
Widget _buildManagementButton({
  required String title,
  required IconData icon,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click, // هذا يجعل الماوس يتحول ليد
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_left_rounded,
          color: Colors.blue.shade700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          Get.snackbar(
            'قيد التطوير',
            'صفحة "$title" قيد التطوير',
            backgroundColor: Colors.blue.shade50,
            colorText: Colors.blue.shade800,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: Icon(
              Icons.info_rounded,
              color: Colors.blue.shade700,
            ),
          );
        },
      ),
    ),
  );
}