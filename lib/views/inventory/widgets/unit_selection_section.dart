import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import '../../../models/inventory_model.dart';

class UnitSelectionSection extends StatelessWidget {
  final AddMedicineController controller;

  const UnitSelectionSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return buildSection(
        title: 'نوع الدواء',
        icon: Icons.medical_services,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'اختر نوع الدواء',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UnitType>(
                value: controller.selectedUnit.value,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: UnitType.values.map((unit) {
                  return DropdownMenuItem<UnitType>(
                    value: unit,
                    child: Text(controller.getUnitName(unit)),
                  );
                }).toList(),
                onChanged: (unit) {
                  controller.updateSelectedUnit(unit);
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ----------------------------------------------------------
// Section Template المعاد استخدامه
Widget buildSection({
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
