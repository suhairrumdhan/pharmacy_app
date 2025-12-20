import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/employee_controller.dart';
import '../../../core/security/default_permissions.dart';
import '../../../models/employee_model.dart';


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
          constraints: BoxConstraints(
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

  // بناء الهيدر حسب الحالة
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _showForm.value
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _showForm.value
                      ? Iconsax.user_edit
                      : Iconsax.people,
                  color: _showForm.value
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _showForm.value
                    ? controller.currentEmployee.value == null
                    ? 'إضافة موظف جديد'
                    : 'تعديل بيانات الموظف'
                    : 'إدارة الموظفين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          )),
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSection() {
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
                        child: _buildEditField(
                          label: 'الاسم الكامل',
                          icon: Iconsax.user,
                          controller: controller.nameCtrl,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => _buildEditField(
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
                        child: _buildEditField(
                          label: 'رقم الهاتف',
                          icon: Iconsax.call,
                          controller: controller.phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => _buildEditField(
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

                // Phone and Hiring Date
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          String currentStatus = controller.isActive.value ? 'نشط' : 'موقوف';

                          return _buildDropdownField(
                            label: 'الحالة الوظيفية',
                            icon: Iconsax.status,
                            value: currentStatus,
                            items: ['نشط', 'موقوف'], // ← List<String> كما يتطلب
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
                        child: Obx(() => _buildEditField(
                          label: 'تاريخ التوظيف',
                          icon: Iconsax.calendar,
                          controller: TextEditingController(
                              text: '${controller.hiringDate.value.year}/${controller.hiringDate.value.month}/${controller.hiringDate.value.day}'
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
                        child: Obx(() => _buildDropdownField(
                          label: 'الدور الوظيفي',
                          icon: Iconsax.briefcase,
                          value: controller.selectedRoleDisplay.value, // استخدم Display value
                          items: roleMapping.keys.toList(), // القائمة بالعربي
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedRoleDisplay.value = value; // تعيين القيمة المعروضة
                              controller.selectedRoleId.value = roleMapping[value]!; // تعيين roleId المقابل
                              controller.roleError.value = null; // مسح رسالة الخطأ إن وجدت
                            }
                          },
                          errorText: controller.roleError.value,
                        )),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => _buildDropdownField(
                          label: 'نوع العقد',
                          icon: Iconsax.document,
                          value: controller.contractType.value,
                          items: ['دوام كامل', 'دوام جزئي', 'متعاون'],
                          onChanged: (value) {
                            if (value != null) controller.contractType.value = value;
                          },
                        )),
                      ),
                    ],
                  ),
                ),

                // Status
              ],
            ),

            const SizedBox(height: 24),

            // Attachments Section
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
                  Row(
                    children: [
                      // Expanded(
                      //   child: _buildAttachmentButton(
                      //     icon: Iconsax.card,
                      //     text: 'صورة البطاقة',
                      //     onPressed: controller.uploadIdCard,
                      //   ),
                      // ),
                      // const SizedBox(width: 12),
                      // Expanded(
                      //   child: _buildAttachmentButton(
                      //     icon: Iconsax.document_upload,
                      //     text: 'الشهادات',
                      //     onPressed: controller.uploadCertificate,
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildPermissionsSection(),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                // Cancel/Back Button
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
                        _showForm.value = false;
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

                // Update Button (يظهر فقط عند التعديل)
                if (controller.currentEmployee.value != null) ...[
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          controller.updateEmployee(controller.currentEmployee.value!.id);
                          _showForm.value = false;
                          Get.back();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تحديث',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Save/Add Button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: controller.currentEmployee.value == null
                              ? Colors.green.withOpacity(0.3)
                              : Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        if (controller.currentEmployee.value == null) {
                          controller.addEmployee();
                        } else {
                          controller.updateEmployee(controller.currentEmployee.value!.id);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: controller.currentEmployee.value == null
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
                            controller.currentEmployee.value == null
                                ? Iconsax.add
                                : Iconsax.save_2,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.currentEmployee.value == null
                                ? 'إضافة موظف'
                                : 'حفظ التعديلات',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSection() {
    // Create a TextEditingController for the search field
    final searchController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Search Bar with Add Button
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.4),
                        border: Border.all(
                          color: Colors.blue.shade100.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Iconsax.search_normal,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن موظف...',
                                hintStyle: TextStyle(
                                  color: Colors.blue.shade400,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: (value) => controller.searchText.value = value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add Employee Button
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    controller.clearForm();
                    _showForm.value = true;
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.user_add,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إضافة موظف جديد',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Employees List
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Obx(() {
                  // Show loading state when employees are being loaded
                  if (controller.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل البيانات...',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.employees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.people,
                            size: 60,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد موظفين',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () {
                                controller.clearForm();
                                _showForm.value = true;
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.user_add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'إضافة أول موظف',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.filteredEmployees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.search_normal,
                            size: 60,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.searchText.value.isEmpty
                                ? 'لا يوجد موظفين'
                                : 'لا توجد نتائج للبحث',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (controller.searchText.value.isNotEmpty)
                            const SizedBox(height: 8),
                          if (controller.searchText.value.isNotEmpty)
                            Text(
                              'بحث: "${controller.searchText.value}"',
                              style: TextStyle(
                                color: Colors.blue.shade400,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = controller.filteredEmployees[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEmployeeCard(employee),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? errorText,
    bool isPassword = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasError ? Colors.red.shade700 : Colors.blue.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasError
                        ? Colors.red.shade100.withOpacity(0.4)
                        : Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: isPassword,
                readOnly: readOnly,
                keyboardType: keyboardType,
                maxLines: maxLines,
                onTap: onTap,
                cursorColor: Colors.blue.shade600,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    icon,
                    color: hasError
                        ? Colors.red.shade400
                        : Colors.blue.shade600,
                    size: 20,
                  ),
                  hintText: 'أدخل هنا...',
                  hintStyle: TextStyle(
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  suffixIcon: isPassword
                      ? IconButton(
                    icon: Icon(
                      Iconsax.eye,
                      color: Colors.blue.shade600.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () {},
                  )
                      : null,
                ),
              ),
            ),
          ),
        ),

        // 🔴 رسالة الخطأ
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasError ? Colors.red.shade700 : Colors.blue.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasError
                        ? Colors.red.shade100.withOpacity(0.4)
                        : Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: value,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      icon,
                      color: hasError
                          ? Colors.red.shade400
                          : Colors.blue.shade600,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  icon: Icon(
                    Iconsax.arrow_down_1,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  items: items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),

        // 🔴 رسالة الخطأ
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildPermissionsSection() {
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

// دالة لعرض صلاحيات الدور فقط (بدون checkboxes)
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

// دالة لعرض الصلاحيات المخصصة مع checkboxes
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

// استبدل _buildPermissionGroupsWithCheckboxes بهذا الكود:
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

// دالة لبناء checkbox لكل صلاحية
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

// دالة لبناء أزرار الإجراءات (نفسها)
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

// دالة لبناء إحصائيات الصلاحيات (نفسها)
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

// دالة منفصلة لبناء قسم صلاحيات المدير (نفسها)
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

  Widget _buildEmployeeCard(Employee employee) {
    Color statusColor = Colors.green.shade600;
    IconData statusIcon = Iconsax.tick_circle;
    if (employee.isActive == true) {
      statusColor = Colors.green.shade600;
      statusIcon = Iconsax.pause_circle;
    }
    if (employee.isActive == false) {
      statusColor = Colors.red.shade600;
      statusIcon = Iconsax.close_circle;
    }

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
            // عند الضغط على الموظف لتحميل بياناته للتعديل
            controller.loadEmployeeForEdit(employee);
            _showForm.value = true;
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: IconButton(
                        onPressed: () {
                          controller.loadEmployeeForEdit(employee);
                          _showForm.value = true;
                        },
                        icon: Icon(
                          Iconsax.edit_2,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Delete Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200, width: 1),
                      ),
                      child: IconButton(
                        onPressed: () => _showDeleteConfirmation(employee),
                        icon: Icon(
                          Iconsax.trash,
                          color: Colors.red.shade700,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          // Text(
                          //   employee.status,
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     fontWeight: FontWeight.bold,
                          //     color: statusColor,
                          //   ),
                          // ),
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

  Widget _buildAttachmentButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.blue.shade100,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.blue.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterMenu() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
            color: Colors.blue.shade100,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blue.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'فلترة الموظفين',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...['الجميع', 'نشط', 'موقوف', 'مستقيل', 'صيدلي', 'محاسب', 'إداري']
                .map((filter) => ListTile(
              title: Text(
                filter,
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                // controller.selectedFilter.value = filter;
                Get.back();
              },
            ))
                .toList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  final Map<String, String> roleMapping = {
    'إداري': 'admin',
    'صيدلي': 'pharmacist',
    'محاسب': 'cashier',
  };


// دالة لبناء عنصر إحصائي
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

  // دالة عرض تأكيد الحذف
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
// أضف هذه الدالة في EmployeeManagementDialog
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




// القائمة الكاملة للصلاحيات (بالإنجليزية)
const List<String> ALL_PERMISSIONS = [
  // Dashboard
  'dashboard.view',
  'dashboard.analytics.view',
  'dashboard.reports.view',

  // Sales
  'sales.view',
  'sales.create',
  'sales.edit',
  'sales.delete',
  'sales.refund',
  'sales.override_price',
  'sales.view_history',

  // Inventory
  'inventory.view',
  'inventory.create',
  'inventory.update',
  'inventory.delete',
  'inventory.adjust_quantity',
  'inventory.view_cost',
  'inventory.expiry.manage',

  // Orders
  'orders.view',
  'orders.create',
  'orders.update_status',
  'orders.cancel',
  'orders.assign',
  'orders.external_sync',

  // Employees & Roles
  'employees.view',
  'employees.create',
  'employees.update',
  'employees.delete',
  'roles.manage',

  // Settings
  'settings.view',
  'settings.update',
  'settings.edit_image',
  'settings.delete_image',
  'settings.update_online',
  'settings.update_24h',
];

// Map لتحويل أسماء الصلاحيات من الإنجليزية إلى العربية
final Map<String, String> permissionTranslations = {
  // Dashboard
  'dashboard.view': 'عرض لوحة التحكم',
  'dashboard.analytics.view': 'عرض التحليلات',
  'dashboard.reports.view': 'عرض التقارير',

  // Sales
  'sales.view': 'عرض المبيعات',
  'sales.create': 'إنشاء مبيعات',
  'sales.edit': 'تعديل المبيعات',
  'sales.delete': 'حذف المبيعات',
  'sales.refund': 'إرجاع المبيعات',
  'sales.override_price': 'تجاوز السعر',
  'sales.view_history': 'عرض تاريخ المبيعات',

  // Inventory
  'inventory.view': 'عرض المخزون',
  'inventory.create': 'إضافة منتجات',
  'inventory.update': 'تعديل المنتجات',
  'inventory.delete': 'حذف المنتجات',
  'inventory.adjust_quantity': 'ضبط الكميات',
  'inventory.view_cost': 'عرض التكلفة',
  'inventory.expiry.manage': 'إدارة تاريخ الصلاحية',

  // Orders
  'orders.view': 'عرض الطلبات',
  'orders.create': 'إنشاء طلبات',
  'orders.update_status': 'تحديث حالة الطلبات',
  'orders.cancel': 'إلغاء الطلبات',
  'orders.assign': 'تعيين الطلبات',
  'orders.external_sync': 'مزامنة خارجية',

  // Employees & Roles
  'employees.view': 'عرض الموظفين',
  'employees.create': 'إضافة موظفين',
  'employees.update': 'تعديل الموظفين',
  'employees.delete': 'حذف الموظفين',
  'roles.manage': 'إدارة الأدوار',

  // Settings
  'settings.view': 'عرض الإعدادات',
  'settings.update': 'تحديث الإعدادات',
  'settings.edit_image': 'تعديل الصورة',
  'settings.delete_image': 'حذف الصورة',
  'settings.update_online': 'تحديث حالة الاتصال',
  'settings.update_24h': 'تحديث حالة العمل 24 ساعة',
};

// Map لتجميع الصلاحيات حسب الفئة (للعرض في مجموعات)
// استبدل permissionGroups بالكود التالي:
final Map<String, List<String>> permissionGroups = {
  'لوحة التحكم': [
    'dashboard.view',
    'dashboard.analytics.view',
    'dashboard.reports.view',
  ],
  'المبيعات': [
    'sales.view',
    'sales.create',
    'sales.edit',
    'sales.delete',
    'sales.refund',
    'sales.override_price',
    'sales.view_history',
  ],
  'المخزون': [
    'inventory.view',
    'inventory.create',
    'inventory.update',
    'inventory.delete',
    'inventory.adjust_quantity',
    'inventory.view_cost',
    'inventory.expiry.manage',
  ],
  'الطلبات': [
    'orders.view',
    'orders.create',
    'orders.update_status',
    'orders.cancel',
    'orders.assign',
    'orders.external_sync',
  ],
  'الموظفين والأدوار': [
    'employees.view',
    'employees.create',
    'employees.update',
    'employees.delete',
    'roles.manage',
  ],
  'الإعدادات': [
    'settings.view',
    'settings.update',
    'settings.edit_image',
    'settings.delete_image',
    'settings.update_online',
    'settings.update_24h',
  ],
};

// دالة مساعدة للحصول على الصلاحيات الفعلية بناءً على الدور
List<String> _getActualPermissionsForRole(Map<String, bool> rolePermissions) {
  final allPermissions = rolePermissions.keys.toList();
  final actualPermissions = <String>[];

  for (final group in permissionGroups.values) {
    for (final permission in group) {
      if (allPermissions.contains(permission)) {
        actualPermissions.add(permission);
      }
    }
  }

  return actualPermissions;
}
