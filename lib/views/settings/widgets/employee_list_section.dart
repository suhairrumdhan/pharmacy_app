import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/employee_controller.dart';
import '../../../models/employee_model.dart';
import 'employee_card.dart';

class EmployeeListSection extends StatelessWidget {
  final EmployeeController controller;
  final RxBool showForm;

  const EmployeeListSection({
    super.key,
    required this.controller,
    required this.showForm,
  });

  @override
  Widget build(BuildContext context) {
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
                    showForm.value = true;
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
                    return _buildLoadingState();
                  }

                  if (controller.employees.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (controller.filteredEmployees.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return _buildEmployeesList();
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
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

  Widget _buildEmptyState() {
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
                showForm.value = true;
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

  Widget _buildNoResultsState() {
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

  Widget _buildEmployeesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = controller.filteredEmployees[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EmployeeCard(
            employee: employee,
            controller: controller,
            showForm: showForm,
          ),
        );
      },
    );
  }
}