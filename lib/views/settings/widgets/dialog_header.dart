import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/employee_controller.dart';

class DialogHeader extends StatelessWidget {
  final RxBool showForm;
  final EmployeeController controller;

  const DialogHeader({
    super.key,
    required this.showForm,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                      color: showForm.value
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  showForm.value
                      ? Iconsax.user_edit
                      : Iconsax.people,
                  color: showForm.value
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getHeaderTitle(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          )),
          _buildCloseButton(),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    if (showForm.value) {
      return controller.currentEmployee.value == null
          ? 'إضافة موظف جديد'
          : 'تعديل بيانات الموظف';
    }
    return 'إدارة الموظفين';
  }

  Widget _buildCloseButton() {
    return IconButton(
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
    );
  }
}