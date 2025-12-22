import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_controller.dart';
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
}