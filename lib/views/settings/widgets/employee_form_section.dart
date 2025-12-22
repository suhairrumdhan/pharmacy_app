import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/employee_controller.dart';
import 'custom_form_field.dart';
import 'custom_dropdown_field.dart';
import 'permissions_section.dart';

class EmployeeFormSection extends StatelessWidget {
  final EmployeeController controller;
  final RxBool showForm;

  const EmployeeFormSection({
    super.key,
    required this.controller,
    required this.showForm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Fields in Grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Name and Username
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomFormField(
                          label: 'الاسم الكامل',
                          icon: Iconsax.user,
                          controller: controller.nameCtrl,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => CustomFormField(
                          label: 'اسم المستخدم',
                          icon: Iconsax.user_tag,
                          controller: controller.usernameCtrl,
                          errorText: controller.usernameError.value,
                        )),
                      ),
                    ],
                  ),
                ),

                // Code and Password
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomFormField(
                          label: 'رقم الهاتف',
                          icon: Iconsax.call,
                          controller: controller.phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => CustomFormField(
                          label: 'كلمة المرور',
                          icon: Iconsax.lock,
                          controller: controller.passwordCtrl,
                          isPassword: true,
                          errorText: controller.passwordError.value,
                        )),
                      ),
                    ],
                  ),
                ),

                // Status and Hiring Date
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          String currentStatus = controller.isActive.value ? 'نشط' : 'موقوف';
                          return CustomDropdownField(
                            label: 'الحالة الوظيفية',
                            icon: Iconsax.status,
                            value: currentStatus,
                            items: const ['نشط', 'موقوف'],
                            onChanged: (value) {
                              if (value != null) {
                                controller.isActive.value = value == 'نشط';
                              }
                            },
                          );
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => CustomFormField(
                          label: 'تاريخ التوظيف',
                          icon: Iconsax.calendar,
                          controller: TextEditingController(
                              text: '${controller.hiringDate.value.year}/'
                                  '${controller.hiringDate.value.month}/'
                                  '${controller.hiringDate.value.day}'
                          ),
                          readOnly: true,
                          onTap: () => controller.selectDate(Get.context!),
                        )),
                      ),
                    ],
                  ),
                ),

                // Role and Contract Type
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(() => CustomDropdownField(
                          label: 'الدور الوظيفي',
                          icon: Iconsax.briefcase,
                          value: controller.selectedRoleDisplay.value,
                          items: const ['ادمن', 'صيدلي', 'محاسب'],
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedRoleDisplay.value = value;
                              controller.selectedRoleId.value = _getRoleId(value);
                              controller.roleError.value = null;
                            }
                          },
                          errorText: controller.roleError.value,
                        )),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => CustomDropdownField(
                          label: 'نوع العقد',
                          icon: Iconsax.document,
                          value: controller.contractType.value,
                          items: const ['دوام كامل', 'دوام جزئي', 'متعاون'],
                          onChanged: (value) {
                            if (value != null) controller.contractType.value = value;
                          },
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Attachments Section (معلق حالياً)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'المرفقات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  // يمكنك إضافة المرفقات هنا عندما تحتاجها
                ],
              ),
            ),

            // Permissions Section - تظهر فقط في حالة التعديل
            Obx(() {
              if (controller.currentEmployee.value != null) {
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    PermissionsSection(controller: controller),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            }),

            const SizedBox(height: 24),

            // أزرار الحفظ/الإضافة والرجوع
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  String _getRoleId(String displayName) {
    const roleMapping = {
      'ادمن': 'admin',
      'صيدلي': 'pharmacist',
      'محاسب': 'cashier',
    };
    return roleMapping[displayName] ?? displayName;
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // زر الرجوع
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                controller.cancelPermissionChanges();
                showForm.value = false;
                controller.clearForm();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.arrow_right_2,
                    color: Colors.grey.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'رجوع للقائمة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // زر الحفظ/الإضافة - يتغير حسب الحالة
        Expanded(
          child: Obx(() {
            final isAdding = controller.currentEmployee.value == null;

            return Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isAdding
                        ? Colors.green.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () async {
                  if (isAdding) {
                    // حالة إضافة موظف جديد
                    final success = await controller.addEmployee();
                    if (success) {
                      showForm.value = false;
                    }
                  } else {
                    // حالة تحديث موظف موجود
                    final success = await controller.updateEmployee(
                        controller.currentEmployee.value!.id
                    );
                    if (success) {
                      showForm.value = false;
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: isAdding
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAdding ? Iconsax.add : Iconsax.save_2,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAdding ? 'إضافة موظف' : 'حفظ التعديلات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}