import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Added iconsax import
import '../dialogs/audit_logs_dialog.dart';
import '../dialogs/employee_management_dialog.dart';

Widget buildEmployeesCard() {
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Iconsax.profile_2user, // Changed from Icons.group_rounded
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'إدارة الموظفين',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // تقسيم الأزرار إلى صفوف كل صف يحتوي على زرين
            Column(
              children: [
                // الصف الأول
                Row(
                  children: [
                    Expanded(
                      child: _buildManagementButton(
                        title: 'إضافة/حذف/تعديل الموظفين',
                        icon: Iconsax.profile_add, // Changed from Icons.person_add_rounded
                        onTap: () => _showEmployeeDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الصلاحيات والأدوار',
                        icon: Iconsax.security_user, // Changed from Icons.admin_panel_settings_rounded
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
                        icon: Iconsax.calendar, // Changed from Icons.calendar_today_rounded

                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الرواتب',
                        icon: Iconsax.dollar_circle, // Changed from Icons.payments_rounded
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
                        icon: Iconsax.note_1,
                        onTap: () => _showAuditLogsDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagementButton(
                        title: 'الأمن والصلاحيات',
                        icon: Iconsax.shield_security, // Changed from Icons.security_rounded
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

Widget _buildManagementButton({
  required String title,
  required IconData icon,
  VoidCallback? onTap,
  Color? iconColor,
  Color? backgroundColor,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor ?? Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blue.shade700).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: iconColor ?? Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
              ),
            ),
            Transform.rotate(
              angle: 3.14,
              child: Icon(
                Iconsax.arrow_left_2, // Changed from Icons.chevron_left_rounded
                color: (iconColor ?? Colors.blue.shade700).withOpacity(0.8),
                size: 24, // Slightly reduced size for better proportion
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper function to show the dialog
void _showEmployeeDialog() {
  Get.dialog(
    EmployeeManagementDialog(),
    barrierDismissible: true,
  );

}
void _showAuditLogsDialog() {
  Get.dialog(
    AuditLogsDialog(),
    barrierDismissible: true,
  );
}
// Helper function to show attendance dialog
