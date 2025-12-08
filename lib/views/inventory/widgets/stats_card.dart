import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/inventory_controller.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final inventoryController = Get.find<InventoryController>();
      final totalMedicines = inventoryController.medicines.length;
      final lowStockCount = inventoryController.lowStockMedicines.length;
      final expiredCount = inventoryController.expiredMedicines.length;
     // final totalValue = inventoryController.totalInventoryValue;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue.shade50, Colors.green.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            _buildStatItem(
              icon: Icons.medication,
              value: totalMedicines.toString(),
              label: 'إجمالي الأصناف',
              color: Colors.blue,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Icons.warning,
              value: lowStockCount.toString(),
              label: 'منخفضة المخزون',
              color: Colors.orange,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Icons.error,
              value: expiredCount.toString(),
              label: 'منتهية الصلاحية',
              color: Colors.red,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Icons.attach_money,
              value: '0 د.ل',
              label: 'xxxxxx',
              color: Colors.green,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.shade300,
    );
  }
}