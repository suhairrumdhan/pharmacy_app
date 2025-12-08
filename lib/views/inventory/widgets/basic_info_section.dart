import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import 'package:intl/intl.dart';

import '../add_medicine_dialog.dart';

class BasicInfoSection extends StatelessWidget {
  final AddMedicineController controller;

  const BasicInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      title: 'المعلومات الأساسية',
      icon: Icons.info,
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: InputDecoration(
            labelText: 'اسم الصنف التجاري',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.medication),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال اسم الصنف';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.scientificNameController,
          decoration: InputDecoration(
            labelText: 'الاسم العلمي (اختياري - سيتم استخدام الاسم التجاري إذا فارغ)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.science),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.descriptionController,
          decoration: InputDecoration(
            labelText: 'الوصف (اختياري)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.description),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Obx(() => controller.isLoadingCategories.value
            ? _buildLoadingWidget()
            : _buildCategoryDropdown(context)),
      ],
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'الفئة (اختياري)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedCategory.value,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('اختر التصنيف'),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('لا يوجد'),
              ),
            ),
            ...controller.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                ),
              );
            }).toList(),
            const DropdownMenuItem<String>(
              value: 'add_new',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('إضافة تصنيف جديد'),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue == 'add_new') {
              showAddCategoryDialog(context, controller);
            } else {
              controller.updateSelectedCategory(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Text('جاري تحميل التصنيفات...', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

Widget _buildSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}