import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_controller.dart';
import '../../../core/security/default_permissions.dart';
import '../../../models/employee_model.dart';
import '../widgets/employee_form_section.dart';
import '../widgets/employee_list_section.dart';
import '../widgets/dialog_header.dart';

class EmployeeManagementDialog extends StatelessWidget {
  final EmployeeController controller = Get.put(EmployeeController());
  final RxBool _showForm = false.obs;

  EmployeeManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
            maxHeight: 900,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),

                // Main Content
                Expanded(
                  child: Obx(() => Row(
                    children: [
                      // Left Section - Form (تظهر فقط عند الإضافة أو التعديل)
                      if (_showForm.value) ...[
                        Expanded(
                          flex: 5,
                          child: _buildLeftSection(),
                        ),
                        // Divider
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.blue.shade100,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Right Section - Employees List (دائمًا موجود)
                      Expanded(
                        flex: _showForm.value ? 5 : 10,
                        child: _buildRightSection(),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DialogHeader(
      showForm: _showForm,
      controller: controller,
    );
  }

  Widget _buildLeftSection() {
    return EmployeeFormSection(
      controller: controller,
      showForm: _showForm,
    );
  }

  Widget _buildRightSection() {
    return EmployeeListSection(
      controller: controller,
      showForm: _showForm,
    );
  }

  void _showDeleteConfirmation(Employee employee) {
    Get.defaultDialog(
      title: "تأكيد الحذف",
      titleStyle: TextStyle(
        color: Colors.red.shade700,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      middleText: "هل أنت متأكد من حذف الموظف ${employee.name}؟",
      middleTextStyle: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 16,
      ),
      textConfirm: "نعم، احذف",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.grey.shade700,
      buttonColor: Colors.red.shade700,
      onConfirm: () {
        controller.deleteEmployee(employee.id);
        Get.back();
      },
      onCancel: () {
        Get.back();
      },
    );
  }

  void _debugCheckPermissions() {
    print('=== تحقق من الصلاحيات ===');

    // تحقق من admin permissions
    print('Admin Permissions:');
    DefaultPermissions.adminPermissions.forEach((key, value) {
      print('  $key: $value');
    });

    // تحقق من الصلاحيات في المجموعات
    print('\n=== الصلاحيات في المجموعات ===');
    permissionGroups.forEach((group, permissions) {
      print('$group:');
      for (var permission in permissions) {
        final inAdmin = DefaultPermissions.adminPermissions.containsKey(permission);
        final inPharmacist = DefaultPermissions.pharmacistPermissions.containsKey(permission);
        final inCashier = DefaultPermissions.cashierPermissions.containsKey(permission);
        print('  $permission - موجود في: Admin:$inAdmin, Pharmacist:$inPharmacist, Cashier:$inCashier');
      }
    });
  }
}