import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/inventory_controller.dart';
// models/quick_alert_model.dart
class QuickAlert {
  final String type; // 'low_stock' أو 'expired'
  final String message;
  final DateTime date;
  bool isRead;

  QuickAlert({
    required this.type,
    required this.message,
    required this.date,
    this.isRead = false,
  });
}
class QuickAlerts extends StatelessWidget {
  const QuickAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final inventoryController = Get.find<InventoryController>();
      final alerts = inventoryController.recentAlerts;
      if (alerts.isEmpty) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final alert in alerts.take(2))
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (alerts.length > 2)
              TextButton(
                onPressed: _showAllAlerts,
                child: Text('عرض الكل (${alerts.length})'),
              ),
          ],
        ),
      );
    });
  }

  void _showAllAlerts() {
    final inventoryController = Get.find<InventoryController>();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'جميع التنبيهات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final alerts = inventoryController.recentAlerts;
                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return ListTile(
                      leading: Icon(
                        alert.type == 'expired' ? Icons.error : Icons.warning,
                        color: alert.type == 'expired' ? Colors.red : Colors.orange,
                      ),
                      title: Text(alert.message),
                      subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(alert.date)),
                      trailing: alert.isRead ? null : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}