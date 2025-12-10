import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import 'package:intl/intl.dart';

class AdditionalInfoSection extends StatelessWidget {
  final AddMedicineController controller;

  const AdditionalInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      title: 'المعلومات الإضافية',
      icon: Icons.more_horiz,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.minStockController,
                decoration: InputDecoration(
                  labelText: 'الحد الأدنى للمخزون (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.warning),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.supplierController,
                decoration: InputDecoration(
                  labelText: 'المورد (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.business),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.barcodeController,
          decoration: InputDecoration(
            labelText: 'الباركود (اختياري)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.qr_code),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Text('تاريخ انتهاء الصلاحية:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _selectExpiryDate(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
                icon: Icon(Icons.calendar_month, color: Colors.orange.shade700),
                label: Text(
                  formatDate(controller.expiryDate.value),
                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.expiryDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != controller.expiryDate.value) {
      controller.updateExpiryDate(picked);
    }
  }
}

String formatDate(DateTime date) {
  return DateFormat('yyyy/MM/dd').format(date);
}

Widget _buildSection({
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
          const SizedBox(height: 26),

        ],

      ),
    ),
  );
}