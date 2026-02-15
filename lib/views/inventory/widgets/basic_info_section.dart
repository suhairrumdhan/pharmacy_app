import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import '../add_category_dialog.dart';
import '../add_medicine_dialog.dart';

class BasicInfoSection extends StatelessWidget {
  final AddMedicineController controller;

  const BasicInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final bool compact = w < 520;       // ضيق
        final bool mid = w >= 520 && w < 800;

        final double pad = compact ? 14 : (mid ? 16 : 20);
        final double titleSize = compact ? 15.5 : 17.5;
        final double gap = compact ? 12 : 16;
        final double headerGap = compact ? 16 : 22;

        InputDecoration deco({
          required String label,
          required IconData icon,
        }) {
          return InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey[50],
            isDense: compact,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 12 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        return _buildSection(
          title: 'المعلومات الأساسية',
          icon: Icons.info,
          pad: pad,
          titleSize: titleSize,
          headerGap: headerGap,
          children: [
            TextFormField(
              controller: controller.nameController,
              decoration: deco(label: 'اسم الصنف التجاري', icon: Icons.medication),
              validator: (value) {
                if (value == null || value.isEmpty) return 'يرجى إدخال اسم الصنف';
                return null;
              },
            ),
            SizedBox(height: gap),
            TextFormField(
              controller: controller.scientificNameController,
              decoration: deco(
                label: 'الاسم العلمي (اختياري - سيتم استخدام الاسم التجاري إذا فارغ)',
                icon: Icons.science,
              ),
            ),
            SizedBox(height: gap),
            TextFormField(
              controller: controller.descriptionController,
              decoration: deco(label: 'الوصف (اختياري)', icon: Icons.description),
              maxLines: compact ? 2 : 3,
            ),
            SizedBox(height: gap),

            // ✅ Loading / Dropdown
            Obx(() => controller.isLoadingCategories.value
                ? _buildLoadingWidget(compact: compact)
                : _buildCategoryDropdown(context, compact: compact)),
          ],
        );
      },
    );
  }

  // ✅ Dropdown صار String? بالكامل (لأنه فيه null و add_new)
  Widget _buildCategoryDropdown(BuildContext context, {required bool compact}) {
    final String? current = controller.selectedCategory.value;
    final String? safeValue = (current == null || current == 'add_new') ? null : current;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'الفئة (اختياري)',
        filled: true,
        fillColor: Colors.grey[50],
        isDense: compact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 12 : 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('اختر التصنيف'),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('لا يوجد'),
              ),
            ),
            ...controller.categories.map((category) {
              return DropdownMenuItem<String?>(
                value: category,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const DropdownMenuItem<String?>(
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
              controller.updateSelectedCategory(newValue); // يقبل null
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'جاري تحميل التصنيفات...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: compact ? 12.5 : 13.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSection({
  required String title,
  required IconData icon,
  required List<Widget> children,

  // ✅ Responsive params
  double pad = 20,
  double titleSize = 18,
  double headerGap = 22,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: EdgeInsets.all(pad),
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: headerGap),
          ...children,
        ],
      ),
    ),
  );
}
