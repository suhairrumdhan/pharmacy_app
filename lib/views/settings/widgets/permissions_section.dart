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
                // Toggle Custom Permissions
                Obx(() {
                  final hasCustomPermissions = controller.currentEmployee.value?.hasCustomPermissions ?? false;
                  final isEditing = controller.currentEmployee.value != null;

                  return Switch.adaptive(
                    value: hasCustomPermissions,
                    onChanged: isEditing ? (value) {
                      controller.toggleCustomPermissions(value);
                    } : null,
                    activeColor: Colors.blue.shade700,
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Obx(() {
              final hasCustomPermissions = controller.currentEmployee.value?.hasCustomPermissions ?? false;
              final isEditing = controller.currentEmployee.value != null;

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
                  if (hasCustomPermissions)
                    const SizedBox(height: 4),
                  if (hasCustomPermissions)
                    Text(
                      'الأزرق: صلاحية أصلية، الأخضر: مفعلة مخصصة، الأحمر: معطلة مخصصة',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  if (!isEditing)
                    const SizedBox(height: 4),
                  if (!isEditing)
                    Text(
                      'يجب حفظ الموظف أولاً لتفعيل الصلاحيات المخصصة',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
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

              if (!hasCustomPermissions || currentEmployee == null) {
                // عرض صلاحيات الدور فقط
                return _buildRolePermissionsGrid(rolePermissions);
              } else {
                // عرض الصلاحيات المخصصة مع checkboxes
                return _buildCustomPermissionsGridWithCheckboxes(
                  rolePermissions: rolePermissions,
                  currentEmployee: currentEmployee,
                );
              }
            }),
          ],
        ),
      );
    });
  }

  Widget _buildRolePermissionsGrid(Map<String, bool> rolePermissions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rolePermissions.entries.map((entry) {
        final permissionKey = entry.key;
        final hasPermission = entry.value;
        final permissionName = permissionTranslations[permissionKey] ?? permissionKey;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasPermission ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasPermission ? Colors.green.shade300 : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPermission ? Iconsax.tick_circle : Iconsax.close_circle,
                size: 16,
                color: hasPermission ? Colors.green.shade600 : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                permissionName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: hasPermission ? Colors.green.shade800 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomPermissionsGridWithCheckboxes({
    required Map<String, bool> rolePermissions,
    required Employee currentEmployee,
  }) {
    final currentOverrides = currentEmployee.permissionOverrides;

    return Column(
      children: [
        // بناء المجموعات
        ..._buildPermissionGroupsWithCheckboxes(
          rolePermissions: rolePermissions,
          currentOverrides: currentOverrides,
          employeeId: currentEmployee.id,
        ),

        // الإحصائيات
        const SizedBox(height: 16),
        _buildPermissionsStats(currentOverrides, rolePermissions),

        // أزرار التحكم
        const SizedBox(height: 16),
        _buildPermissionActionButtons(currentEmployee),
      ],
    );
  }

  List<Widget> _buildPermissionGroupsWithCheckboxes({
    required Map<String, bool> rolePermissions,
    required Map<String, bool> currentOverrides,
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
                onChanged: (value) {
                  print('تغيير صلاحية: $permissionKey -> $value');
                  controller.updatePermissionOverride(
                    employeeId: employeeId,
                    permissionKey: permissionKey,
                    value: value!,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  Widget _buildPermissionCheckbox({
    required String label,
    required bool value,
    required bool isOverride,
    required ValueChanged<bool?> onChanged,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isOverride) {
      backgroundColor = value
          ? Colors.green.shade50
          : Colors.red.shade50;
      borderColor = value
          ? Colors.green.shade300
          : Colors.red.shade300;
      textColor = value
          ? Colors.green.shade800
          : Colors.red.shade800;
    } else {
      backgroundColor = value
          ? Colors.blue.shade50
          : Colors.grey.shade100;
      borderColor = value
          ? Colors.blue.shade300
          : Colors.grey.shade300;
      textColor = value
          ? Colors.blue.shade800
          : Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value ? Colors.blue.shade700 : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: value
                  ? Icon(
                Icons.check,
                size: 16,
                color: Colors.blue.shade700,
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
  }

  Widget _buildPermissionActionButtons(Employee currentEmployee) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    controller.selectAllPermissions();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'تفعيل الكل',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    controller.clearAllPermissions();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'تعطيل الكل',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Reset to Default Button
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextButton(
            onPressed: () {
              controller.resetPermissionsToDefault();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.orange.shade200),
              ),
            ),
            child: Text(
              'إعادة التعيين للإفتراضي',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStats(
      Map<String, bool> currentOverrides,
      Map<String, bool> rolePermissions,
      ) {
    final totalPermissions = rolePermissions.length;
    final enabledByDefault = rolePermissions.values.where((v) => v).length;
    final customEnabled = currentOverrides.values.where((v) => v).length;
    final customDisabled = currentOverrides.values.where((v) => !v).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Iconsax.box,
            label: 'الإجمالي',
            value: '$totalPermissions',
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Iconsax.tick_circle,
            label: 'مفعلة افتراضياً',
            value: '$enabledByDefault',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Iconsax.add_circle,
            label: 'مخصصة مفعلة',
            value: '$customEnabled',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Iconsax.close_circle,
            label: 'مخصصة معطلة',
            value: '$customDisabled',
            color: Colors.red,
          ),
        ],
      ),
    );
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.tick_circle,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DefaultPermissions.adminPermissions.length} صلاحية مفعلة',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}