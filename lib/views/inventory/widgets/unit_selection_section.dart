import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import '../../../models/inventory_model.dart';

class UnitSelectionSection extends StatelessWidget {
  final AddMedicineController controller;

  const UnitSelectionSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final bool compact = w < 520;
        final bool mid = w >= 520 && w < 800;

        final double pad = compact ? 14 : (mid ? 16 : 20);
        final double titleSize = compact ? 15.5 : 17.5;
        final double headerGap = compact ? 16 : 22;
        final double gap = compact ? 12 : 16;

        InputDecoration deco({
          required String label,
          IconData? icon,
        }) {
          return InputDecoration(
            labelText: label,
            prefixIcon: icon == null ? null : Icon(icon),
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

        return Obx(() {
          return _buildSection(
            title: 'نوع الدواء',
            icon: Icons.medical_services,
            pad: pad,
            titleSize: titleSize,
            headerGap: headerGap,
            children: [
              InputDecorator(
                decoration: deco(
                  label: 'اختر نوع الدواء',
                  icon: Icons.medical_services,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UnitType?>(
                    value: controller.selectedUnit.value, // ممكن تكون null
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),

                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('اختر'),
                    ),

                    items: [
                      const DropdownMenuItem<UnitType?>(
                        value: null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('بدون تحديد'),
                        ),
                      ),
                      ...UnitType.values.map((unit) {
                        return DropdownMenuItem<UnitType?>(
                          value: unit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              controller.getUnitName(unit),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (unit) => controller.updateSelectedUnit(unit),
                  ),
                ),
              ),

              SizedBox(height: gap),

              // (اختياري) سطر توضيحي صغير
              Text(
                'اختر شكل الدواء (قرص / شراب / بخاخ ...)',
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

// ✅ نفس نمط _buildSection اللي استخدمناه قبل (Responsive params)
Widget _buildSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
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
