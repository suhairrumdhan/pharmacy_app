import 'dart:io';

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
            const SizedBox(height: 24),
            Column(
              children: [
                // Name and Username
                Row(
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

                const SizedBox(height: 16),

                // Phone and Password
                Row(
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

                const SizedBox(height: 16),

                // Status and Hiring Date
                Row(
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
                                '${controller.hiringDate.value.month.toString().padLeft(2, '0')}/'
                                '${controller.hiringDate.value.day.toString().padLeft(2, '0')}'
                        ),
                        readOnly: true,
                        onTap: () => controller.selectDate(Get.context!),
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Role and Contract Type
                Row(
                  children: [
// في الويدجت الحالي (EmployeeFormSection) - عدل الـ CustomDropdownField للدور الوظيفي
                    Expanded(
                      child: Obx(() {
                        // التحقق: إذا القيمة غير موجودة في القائمة، استخدم null
                        final String? currentValue =
                        (controller.selectedRoleDisplay.value.isNotEmpty &&
                            ['ادمن', 'صيدلي', 'محاسب'].contains(controller.selectedRoleDisplay.value))
                            ? controller.selectedRoleDisplay.value
                            : null; // أو قيمة افتراضية: 'ادمن'

                        return CustomDropdownField(
                          label: 'الدور الوظيفي',
                          icon: Iconsax.briefcase,
                          value: currentValue, // هنا استخدم القيمة المؤكدة
                          items: const ['ادمن', 'صيدلي', 'محاسب'],
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedRoleDisplay.value = value;
                              controller.selectedRoleId.value = _getRoleId(value);
                              controller.roleError.value = null;
                            }
                          },
                          errorText: controller.roleError.value,
                        );
                      }),
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
              ],
            ),

            const SizedBox(height: 24),

            // Attachments Section
            _buildAttachmentsSection(),

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

            const SizedBox(height: 32),

            // Action Buttons
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

  Widget _buildAttachmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        color: Colors.blue.shade50.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.document_upload,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'المرفقات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // صورة الهوية - تستخدم الملفات المؤقتة الجديدة
          // صورة الهوية
          _buildAttachmentCard(
            title: 'صورة الهوية',
            icon: Iconsax.card,
            tempFile: controller.tempIdCardFile,
            storedUrl: controller.storedIdCardUrl,
            isLoading: controller.isUploadingIdCard,
            onAttach: controller.attachIdCard, // مباشرة بدون نقل الملفات
            onRemove: controller.removeIdCard,
            onView: (url) => controller.downloadAndOpenFile(url, 'id_card'),
          ),
          const SizedBox(height: 12),
          _buildAttachmentCard(
            title: 'الشهادة',
            icon: Iconsax.document,
            tempFile: controller.tempCertificateFile,
            storedUrl: controller.storedCertificateUrl,
            isLoading: controller.isUploadingCertificate,
            onAttach: controller.attachCertificate, // مباشرة بدون نقل الملفات
            onRemove: controller.removeCertificate,
            onView: (url) => controller.downloadAndOpenFile(url, 'certificate'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard({
    required String title,
    required IconData icon,
    required Rx<File?> tempFile,
    required RxString storedUrl,
    required RxBool isLoading,
    required VoidCallback onAttach,
    required VoidCallback onRemove,
    required Function(String) onView,
  }) {
    return Obx(() {
      final hasTempFile = tempFile.value != null;
      final hasStoredUrl = storedUrl.value.isNotEmpty;
      final hasAnyFile = hasTempFile || hasStoredUrl;
      final currentTempFile = tempFile.value;
      final currentStoredUrl = storedUrl.value;

      // تحديد نص الزر ونوع العملية
      final buttonText = hasAnyFile ? 'تغيير' : 'إرفاق';
      final buttonIcon = hasAnyFile ? Iconsax.edit : Iconsax.attach_square;
      final buttonColor = hasAnyFile ? Colors.orange : Colors.blue;

      // تحديد نص حالة الملف
      String statusText = '';
      Color statusColor = Colors.grey;

      if (hasTempFile) {
        statusText = 'ملف جديد (لم يحفظ بعد)';
        statusColor = Colors.orange.shade600;
      } else if (hasStoredUrl) {
        statusText = 'تم رفعها مسبقاً';
        statusColor = Colors.green.shade600;
      }

      // تحديد نص الأداة المساعدة لحذف
      final deleteTooltip = hasTempFile
          ? 'إزالة الملف الجديد'
          : hasStoredUrl
          ? 'حذف الملف المخزن'
          : '';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasAnyFile ? statusColor.withOpacity(0.3) : Colors.grey.shade300,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasAnyFile ? statusColor : Colors.blue.shade600,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (hasTempFile && currentTempFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        _getFileName(currentTempFile.path),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (statusText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (isLoading.value)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (hasAnyFile)
              Row(
                children: [
                  if (hasStoredUrl && !hasTempFile) // فقط عرض عين إذا كان هناك ملف مخزن ولا يوجد ملف جديد
                    IconButton(
                      onPressed: () => onView(currentStoredUrl),
                      icon: Icon(Iconsax.eye, color: Colors.blue.shade600, size: 18),
                      tooltip: 'معاينة الملف المخزن',
                    ),
                  IconButton(
                    onPressed: hasAnyFile ? onRemove : null,
                    icon: Icon(Iconsax.trash, color: Colors.red.shade600, size: 18),
                    tooltip: deleteTooltip,
                  ),
                ],
              ),

            ElevatedButton.icon(
              onPressed: isLoading.value ? null : onAttach,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor.shade50,
                foregroundColor: buttonColor.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(buttonIcon, size: 16),
              label: Text(buttonText),
            ),
          ],
        ),
      );
    });
  }

  String _getFileName(String path) {
    final parts = path.split('/');
    return parts.last;
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