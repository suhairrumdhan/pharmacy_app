import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/inventory_controller.dart';
import '../../dialog/add_medicine_dialog.dart';
import '../../models/inventory_model.dart';

class InventoryPage extends StatelessWidget {
  InventoryPage({super.key});
  final InventoryController inventoryController = Get.put(InventoryController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // التنبيهات والإحصائيات
          _buildAlertsSection(),
          const SizedBox(height: 24),

          // شريط الأدوات
          _buildToolbar(context),
          const SizedBox(height: 24),

          // قائمة الأدوية
          Expanded(
            child: _buildMedicinesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Obx(() {
      final lowStockCount = inventoryController.lowStockMedicines.length;
      final expiredCount = inventoryController.expiredMedicines.length;

      if (lowStockCount == 0 && expiredCount == 0) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lowStockCount > 0)
                    Text('$lowStockCount دواء منخفض المخزون', style: const TextStyle(color: Colors.orange)),
                  if (expiredCount > 0)
                    Text('$expiredCount دواء منتهي الصلاحية', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            if (lowStockCount > 0 || expiredCount > 0)
              TextButton(
                onPressed: _showAlertsDetails,
                child: const Text('عرض التفاصيل'),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("إضافة دواء"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddMedicineDialog(),
            );
          },
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text("تصدير"),
          onPressed: () {},
        ),
        const Spacer(),
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: inventoryController.searchMedicines,
            decoration: InputDecoration(
              hintText: 'بحث في الأدوية...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesList() {
    return Obx(() {
      if (inventoryController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // رأس الجدول
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text("الدواء", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("الفئة", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("السعر", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("الكمية", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("الحالة", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("الصلاحية", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 100), // مساحة للأزرار
                ],
              ),
            ),

            // قائمة الأدوية
            Expanded(
              child: ListView.builder(
                itemCount: inventoryController.filteredMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = inventoryController.filteredMedicines[index];
                  return MedicineListItem(medicine: medicine);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showAlertsDetails() {
    Get.dialog(
      AlertDialog(
        title: const Text('التنبيهات'),
        content: SizedBox(
          width: 500,
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (inventoryController.lowStockMedicines.isNotEmpty) ...[
                  const Text('أدوية منخفضة المخزون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ...inventoryController.lowStockMedicines.map((medicine) =>
                      ListTile(
                        leading: const Icon(Icons.inventory_2, color: Colors.orange),
                        title: Text(medicine.name),
                        subtitle: Text('المخزون: ${medicine.quantity} - الحد الأدنى: ${medicine.minStockLevel}'),
                      )
                  ),
                ],
                if (inventoryController.expiredMedicines.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('أدوية منتهية الصلاحية:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ...inventoryController.expiredMedicines.map((medicine) =>
                      ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(medicine.name),
                        subtitle: Text('انتهت في: ${_formatDate(medicine.expiryDate)}'),
                      )
                  ),
                ],
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class MedicineListItem extends StatelessWidget {
  final Medicine medicine;
  final InventoryController inventoryController = Get.find();

  MedicineListItem({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        color: _getRowColor(),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  medicine.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(medicine.category),
          ),
          Expanded(
            child: Text("${medicine.price.toStringAsFixed(2)} ريال"),
          ),
          Expanded(
            child: Row(
              children: [
                Text(medicine.quantity.toString()),
                const SizedBox(width: 8),
                if (medicine.isLowStock)
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
              ],
            ),
          ),
          Expanded(
            child: _buildStatusIndicator(),
          ),
          Expanded(
            child: Text(
              _formatDate(medicine.expiryDate),
              style: TextStyle(
                color: medicine.isExpired ? Colors.red : Colors.black,
                fontWeight: medicine.isExpired ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    _showEditDialog(context, medicine);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.inventory_2, size: 18),
                  onPressed: () {
                    _showStockUpdateDialog(context, medicine);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    inventoryController.deleteMedicine(medicine.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _getRowColor() {
    if (medicine.isExpired) return Colors.red.shade50;
    if (medicine.isLowStock) return Colors.orange.shade50;
    return null;
  }

  Widget _buildStatusIndicator() {
    if (medicine.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'منتهي',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else if (medicine.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'منخفض',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'جيد',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(BuildContext context, Medicine medicine) {
    // TODO: تنفيذ نافذة تعديل الدواء
    Get.snackbar('تعديل', 'سيتم تنفيذ نافذة تعديل ${medicine.name}');
  }

  void _showStockUpdateDialog(BuildContext context, Medicine medicine) {
    final quantityController = TextEditingController(text: medicine.quantity.toString());

    Get.dialog(
      AlertDialog(
        title: const Text('تحديث المخزون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الدواء: ${medicine.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية الجديدة',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text) ?? medicine.quantity;
              inventoryController.updateStock(medicine.id, newQuantity);
              Get.back();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}