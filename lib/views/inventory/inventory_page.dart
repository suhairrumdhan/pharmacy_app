import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/inventory_controller.dart';
import 'widgets/stats_card.dart';
import 'widgets/quick_alerts.dart';
import 'widgets/inventory_toolbar.dart';
import 'widgets/medicines_table.dart';

class InventoryPage extends StatelessWidget {
  InventoryPage({super.key});

  final InventoryController inventoryController = Get.put(InventoryController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // البطاقة الإحصائية
          const StatsCard(),
          const SizedBox(height: 20),

          // التنبيهات السريعة
          const QuickAlerts(),
          const SizedBox(height: 20),

          // شريط الأدوات
          const InventoryToolbar(),
          const SizedBox(height: 16),

          // قائمة الأدوية
          const Expanded(
            child: MedicinesTable(),
          ),
        ],
      ),
    );
  }
}