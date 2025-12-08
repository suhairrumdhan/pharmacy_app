import 'package:flutter/material.dart';
import '../../../controllers/add_medicine_controller.dart';

class AddCategoryDialog extends StatelessWidget {
  final AddMedicineController controller;

  const AddCategoryDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'إضافة تصنيف جديد',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          TextField(
            controller: controller.newCategoryController,
            decoration: InputDecoration(
              labelText: 'التصنيف الجديد',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.add),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (_) => _addCategoryAndClose(context),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addCategoryAndClose(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text('إضافة', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addCategoryAndClose(BuildContext context) async {
    await controller.addNewCategory();
    Navigator.of(context).pop();
  }
}