import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../controllers/employee_controller.dart';
import '../../../../../core/security/default_permissions.dart';
import '../../../../../models/employee_model.dart';

class PermissionsSection extends StatelessWidget {
  final EmployeeController controller;

  const PermissionsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedRoleId = controller.selectedRoleId.value;
      final currentEmployee = controller.currentEmployee.value;

      // إذا كان الدور admin، كل الصلاحيات مفعلة ولا يمكن التعديل
      if (selectedRoleId == 'admin') {
        return _buildAdminPermissionsSection();
      }

      // الحصول على صلاحيات الدور الحالي من DefaultPermissions
      final rolePermissions = DefaultPermissionsHelper.getPermissionsForRole(selectedRoleId);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header مع التبديل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.security,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الصلاحيات المخصصة',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          DefaultPermissionsHelper.getRoleDisplayName(selectedRoleId),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Obx(() {
                  final currentEmployee = controller.currentEmployee.value;
                  final hasCustomPermissions = currentEmployee?.hasCustomPermissions ?? false;

                  return Switch.adaptive(
                    value: hasCustomPermissions,
                    onChanged: (value) {
                      // للموظفين الجدد: تحديث القيمة مباشرة في الكنترولر
                      if (currentEmployee?.id?.isEmpty ?? true) {
                        controller.toggleCustomPermissions(value);
                      } else {
                        // للموظفين الموجودين: عرض تأكيد قبل التغيير
                        _showToggleConfirmationDialog(context, value);
                      }
                    },
                    activeColor: Colors.blue.shade700,
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Obx(() {
              final currentEmployee = controller.currentEmployee.value;
              final hasCustomPermissions = currentEmployee?.hasCustomPermissions ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCustomPermissions
                        ? 'يمكنك الآن تخصيص الصلاحيات للموظف'
                        : 'يتم تطبيق صلاحيات الدور الأساسية',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasCustomPermissions ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 16),

            // بناء العرض بناءً على الحالة
            Obx(() {
              final currentEmployee = controller.currentEmployee.value;
              final hasCustomPermissions = currentEmployee?.hasCustomPermissions ?? false;

              if (!hasCustomPermissions) {
                // لا تظهر الصلاحيات عندما تكون معطلة - فقط رسالة
                return _buildPermissionsDisabledMessage();
              } else {
                // عرض الصلاحيات المخصصة مع checkboxes
                return _buildCustomPermissionsGridWithCheckboxes(
                  rolePermissions: rolePermissions,
                  currentEmployee: currentEmployee!,
                );
              }
            }),
          ],
        ),
      );
    });
  }

  Widget _buildPermissionsDisabledMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.info_circle,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'تمكين الصلاحيات المخصصة لعرض وتعديل الصلاحيات',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showToggleConfirmationDialog(BuildContext context, bool newValue) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              newValue ? Iconsax.security : Iconsax.security_safe,
              color: newValue ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              newValue ? 'تفعيل الصلاحيات المخصصة' : 'تعطيل الصلاحيات المخصصة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: newValue ? Colors.blue.shade800 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Text(
          newValue
              ? 'سيتم تفعيل وضع الصلاحيات المخصصة. يمكنك الآن تعديل صلاحيات هذا الموظف بشكل فردي.'
              : 'سيتم تعطيل الصلاحيات المخصصة والعودة إلى صلاحيات الدور الأساسية. جميع التعديلات المخصصة سيتم حفظها.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.toggleCustomPermissions(newValue);
            },
            style: TextButton.styleFrom(
              backgroundColor: newValue ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            child: Text(
              newValue ? 'تفعيل' : 'تعطيل',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPermissionsGridWithCheckboxes({
    required Map<String, bool> rolePermissions,
    required Employee currentEmployee,
  }) {
    return Obx(() {
      // الحصول على أحدث البيانات من الـ controller
      final updatedEmployee = controller.currentEmployee.value ?? currentEmployee;
      final currentOverrides = updatedEmployee.permissionOverrides;

      return Column(
        children: [
          // بناء المجموعات
          ..._buildPermissionGroupsWithCheckboxes(
            rolePermissions: rolePermissions,
            employeeId: updatedEmployee.id,
          ),
        ],
      );
    });
  }

  List<Widget> _buildPermissionGroupsWithCheckboxes({
    required Map<String, bool> rolePermissions,
    required String employeeId,
  }) {
    // الحصول على الصلاحيات الفعلية الموجودة في rolePermissions
    final actualPermissions = rolePermissions.keys.toList();

    return permissionGroups.entries.map((group) {
      // تصفية الصلاحيات الموجودة فعلاً في الدور
      final validPermissions = group.value.where(
              (permission) => actualPermissions.contains(permission)
      ).toList();

      if (validPermissions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Obx(() {
        // الحصول على أحدث بيانات الموظف
        final currentEmployee = controller.currentEmployee.value;
        if (currentEmployee == null) return const SizedBox.shrink();

        final currentOverrides = currentEmployee.permissionOverrides;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: validPermissions.map((permissionKey) {
                final permissionName = permissionTranslations[permissionKey] ?? permissionKey;
                final hasBasePermission = rolePermissions[permissionKey] ?? false;
                final hasOverride = currentOverrides.containsKey(permissionKey);
                final overrideValue = currentOverrides[permissionKey] ?? false;
                final effectivePermission = hasOverride ? overrideValue : hasBasePermission;

                return _buildPermissionCheckbox(
                  label: permissionName,
                  value: effectivePermission,
                  isOverride: hasOverride,
                  permissionKey: permissionKey,
                  employeeId: employeeId,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      });
    }).toList();
  }

  Widget _buildPermissionCheckbox({
    required String label,
    required bool value,
    required bool isOverride,
    required String permissionKey,
    required String employeeId,
  }) {
    return Obx(() {
      final currentEmployee = controller.currentEmployee.value;
      final currentOverrides = currentEmployee?.permissionOverrides ?? {};


      final currentHasOverride = currentOverrides.containsKey(permissionKey);
      final currentValue = currentHasOverride
          ? (currentOverrides[permissionKey] ?? value)
          : value;

      final hasCustomStyle = currentHasOverride;
      
      final backgroundColor =
      currentValue ? Colors.blue.shade50 : Colors.grey.shade100;
      final borderColor =
      currentValue ? Colors.blue.shade300 : Colors.grey.shade300;
      final textColor =
      currentValue ? Colors.blue.shade800 : Colors.grey.shade600;
      final checkColor =
      currentValue ? Colors.blue.shade700 : Colors.grey.shade400;

      return GestureDetector(
        onTap: () async {
          await controller.updatePermissionOverride(
            employeeId: employeeId,
            permissionKey: permissionKey,
            value: !currentValue,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasCustomStyle
                  ? Colors.orange.shade300
                  : borderColor,
              width: hasCustomStyle ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: currentValue ? checkColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: currentValue ? checkColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: currentValue
                    ? Icon(
                  Icons.check,
                  size: 18,
                  color: checkColor,
                )
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAdminPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.security_safe,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'صلاحيات المدير',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يتمتع المدير بجميع الصلاحيات ولا يمكن تعديلها',
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}