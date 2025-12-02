import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../dialog/add_medicine_dialog.dart';
import 'filter_button.dart';
import 'csv_import_dialog.dart';

class InventoryToolbar extends StatelessWidget {
  const InventoryToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryController = Get.find<InventoryController>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // أزرار الإضافة والاستيراد
            _buildActionButton(
              icon: Icons.add,
              label: 'إضافة دواء',
              color: Colors.green,
              onPressed: () => _showAddMedicineDialog(context),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.upload_file,
              label: 'استيراد CSV',
              color: Colors.blue,
              onPressed: () => _importFromCSV(inventoryController),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.download,
              label: 'تصدير CSV',
              color: Colors.purple,
              onPressed: () => _exportData(inventoryController),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.inventory_2,
              label: 'جرد سريع',
              color: Colors.orange,
              onPressed: () => _showQuickInventory(inventoryController),
            ),

            const Spacer(),

            // البحث
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: inventoryController.searchMedicines,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم، التصنيف، أو الباركود...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // التصفية
            FilterButton(inventoryController: inventoryController),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      onPressed: onPressed,
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMedicineDialog(),
    );
  }

  Future<void> _importFromCSV(InventoryController controller) async {
    try {
      FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["csv"],
        dialogTitle: 'اختر ملف CSV للاستيراد',
        allowMultiple: false,
      );

      if (picked == null) return;

      final filePath = picked.files.single.path!;
      final csvString = await File(filePath).readAsString();

      final List<List<dynamic>> table =
      CsvToListConverter().convert(csvString);

      if (table.isEmpty) {
        Get.snackbar("فشل", "الملف فارغ أو غير صالح",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final csvHeaders = table.first;

      // فتح نافذة اختيار الأعمدة
      final mapping = await Get.dialog<Map<String, int>>(
        CSVImportDialog(headers: csvHeaders),
        barrierDismissible: false,
      );

      if (mapping == null || mapping.isEmpty) {
        Get.snackbar("ملاحظة", "تم إلغاء عملية الاستيراد",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      // تجهيز البيانات للاستيراد
      final List<Map<String, dynamic>> finalData = [];

      int skippedRows = 0;
      for (int i = 1; i < table.length; i++) {
        try {
          final row = table[i];
          final item = <String, dynamic>{};

          mapping.forEach((field, index) {
            if (index < row.length) {
              item[field] = row[index];
            }
          });

          // التحقق من وجود البيانات الأساسية
          final name = item['name']?.toString()?.trim() ?? '';
          final scientificName = item['scientificName']?.toString()?.trim() ?? '';

          if (name.isNotEmpty && scientificName.isNotEmpty) {
            finalData.add(item);
          } else {
            skippedRows++;
          }
        } catch (e) {
          skippedRows++;
          continue;
        }
      }

      if (finalData.isEmpty) {
        Get.snackbar("فشل", "لم يتم العثور على بيانات صالحة للاستيراد",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // استيراد البيانات
      await controller.importFromCSV(filePath, mapping);

      // عرض تقرير الاستيراد
      if (skippedRows > 0) {
        Get.snackbar(
          "استيراد جزئي",
          "تم استيراد ${finalData.length} عنصر، تم تخطي $skippedRows صف",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          "نجاح",
          "تم استيراد ${finalData.length} عنصر بنجاح",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('CSV Import Error: $e');
      Get.snackbar(
        "خطأ في الاستيراد",
        "حدث خطأ أثناء معالجة الملف: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _exportData(InventoryController controller) async {
    try {
      // يمكنك إضافة خيارات تصدير هنا
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          title: const Text('تصدير البيانات'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 48, color: Colors.purple),
              SizedBox(height: 16),
              Text('اختر نوع التصدير'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.exportToCSV();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('تصدير CSV', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ في التصدير",
        "حدث خطأ أثناء التصدير: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showQuickInventory(InventoryController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'جرد سريع',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final medicines = controller.medicines;
              final lowStock = controller.lowStockCount;
              final expired = controller.expiredCount;
              final totalValue = controller.totalInventoryValue;
              final totalItems = controller.totalItemsCount;

              return Column(
                children: [
                  _buildStatCard(
                    title: 'الأصناف المنخفضة',
                    value: lowStock.toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildStatCard(
                    title: 'الأصناف المنتهية',
                    value: expired.toString(),
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildStatCard(
                    title: 'إجمالي المخزون',
                    value: '$totalItems قطعة',
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildStatCard(
                    title: 'القيمة الإجمالية',
                    value: '${totalValue.toStringAsFixed(2)} د.ل',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}