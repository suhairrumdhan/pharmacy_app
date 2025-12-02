import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/inventory_model.dart';
import 'empty_inventory_state.dart';
import 'medicine_table_row.dart';

class MedicinesTable extends StatelessWidget {
  const MedicinesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryController = Get.find<InventoryController>();

    return Obx(() {
      if (inventoryController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (inventoryController.filteredMedicines.isEmpty) {
        return const EmptyInventoryState();
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _buildMedicinesList(),
            ),
            _buildTableFooter(),
          ],
        ),
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // اسم الدواء والمعلومات الأساسية
          Expanded(
            flex: 3,
            child: _HeaderText("الصنف"),
          ),

          // التصنيف
          Expanded(
            flex: 1,
            child: _HeaderText("التصنيف"),
          ),

          // الأسعار
          Expanded(
            flex: 1,
            child: _HeaderText("الأسعار"),
          ),

          // المخزون
          Expanded(
            flex: 1,
            child: _HeaderText("المخزون"),
          ),

          // المورد
          Expanded(
            flex: 2,
            child: _HeaderText("المورد"),
          ),

          // الصلاحية
          Expanded(
            flex: 2,
            child: _HeaderText("الصلاحية"),
          ),

          // الحالة
          Expanded(
            flex: 1,
            child: _HeaderText("الحالة"),
          ),

          // الإجراءات
          SizedBox(
            width: 120,
            child: _HeaderText("الإجراءات"),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList() {
    final inventoryController = Get.find<InventoryController>();

    return ListView.builder(
      itemCount: inventoryController.filteredMedicines.length,
      itemBuilder: (context, index) {
        final medicine = inventoryController.filteredMedicines[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
            ),
          ),
          child: MedicineTableRow(medicine: medicine),
        );
      },
    );
  }

  Widget _buildTableFooter() {
    final inventoryController = Get.find<InventoryController>();

    return Obx(() {
      final total = inventoryController.filteredMedicines.length;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            _FooterText('إجمالي النتائج: $total'),
            const Spacer(),
            _FooterText('آخر تحديث: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}'),
          ],
        ),
      );
    });
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.black87,
      ),
      textAlign: TextAlign.left,
    );
  }
}

class _FooterText extends StatelessWidget {
  final String text;
  const _FooterText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
      ),
    );
  }
}