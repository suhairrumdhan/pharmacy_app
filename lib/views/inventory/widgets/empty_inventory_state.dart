import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../dialog/add_medicine_dialog.dart';

class EmptyInventoryState extends StatelessWidget {
  const EmptyInventoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أدوية في المخزون',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإضافة أدوية جديدة إلى مخزونك',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة أول دواء'),
              onPressed: () => _showAddMedicineDialog(Get.context!),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMedicineDialog(),
    );
  }
}