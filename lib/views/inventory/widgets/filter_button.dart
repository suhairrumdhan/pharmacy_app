import 'package:flutter/material.dart';
import '../../../controllers/inventory_controller.dart';

class FilterButton extends StatelessWidget {
  final InventoryController inventoryController;

  const FilterButton({super.key, required this.inventoryController});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        inventoryController.filterMedicines(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('جميع الأدوية')),
        const PopupMenuItem(value: 'low_stock', child: Text('منخفضة المخزون')),
        const PopupMenuItem(value: 'expired', child: Text('منتهية الصلاحية')),
        const PopupMenuItem(value: 'good', child: Text('حالة جيدة')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.filter_list, size: 18),
            SizedBox(width: 8),
            Text('تصفية'),
          ],
        ),
      ),
    );
  }
}