import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/employee_controller.dart';
import '../../../models/employee_model.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final EmployeeController controller;
  final RxBool showForm;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.controller,
    required this.showForm,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(employee);

    return Container(
      decoration: BoxDecoration(
        color: controller.currentEmployee.value?.id == employee.id
            ? Colors.blue.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.currentEmployee.value?.id == employee.id
              ? Colors.blue.shade300
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            controller.loadEmployeeForEdit(employee);
            showForm.value = true;
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Icon(
                    Iconsax.user,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.briefcase,
                            size: 12,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.roleId,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Iconsax.call,
                            size: 12,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    // Edit Button
                    _buildActionButton(
                      icon: Iconsax.edit_2,
                      color: Colors.blue,
                      onPressed: () {
                        controller.loadEmployeeForEdit(employee);
                        showForm.value = true;
                      },
                    ),
                    const SizedBox(width: 8),

                    // Delete Button
                    _buildActionButton(
                      icon: Iconsax.trash,
                      color: Colors.red,
                      onPressed: () => _showDeleteConfirmation(employee),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusInfo.color, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            statusInfo.icon,
                            size: 14,
                            color: statusInfo.color,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color,
          size: 18,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  _StatusInfo _getStatusInfo(Employee employee) {
    if (employee.isActive == true) {
      return _StatusInfo(
        color: Colors.green.shade600,
        icon: Iconsax.pause_circle,
      );
    } else if (employee.isActive == false) {
      return _StatusInfo(
        color: Colors.red.shade600,
        icon: Iconsax.close_circle,
      );
    }
    return _StatusInfo(
      color: Colors.orange.shade600,
      icon: Iconsax.info_circle,
    );
  }


  // ===== بديل أبسط للدالة السابقة =====
  void _showDeleteConfirmation(Employee employee) {
    // استخدام Get.dialog مع Navigator.pop للتحكم الدقيق
    Get.dialog(
      AlertDialog(
        title: Text(
          "تأكيد الحذف",
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text("هل أنت متأكد من حذف الموظف ${employee.name}؟"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!); // إغلاق هذا الديالوج فقط
            },
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!); // إغلاق هذا الديالوج فقط
              controller.deleteEmployee(employee.id);
            },
            child: Text(
              "نعم، احذف",
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}

class _StatusInfo {
  final Color color;
  final IconData icon;

  _StatusInfo({required this.color, required this.icon});
}