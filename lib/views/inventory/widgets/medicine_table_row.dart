import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/inventory_model.dart';

class MedicineTableRow extends StatelessWidget {
  final Medicine medicine;
  final InventoryController inventoryController = Get.find();

  MedicineTableRow({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: _getRowColor(),
      child: Row(
        children: [
          // اسم الدواء والمعلومات الأساسية
          Expanded(
            flex: 3,
            child: _buildMedicineInfo(),
          ),

          // التصنيف
          Expanded(
            flex: 2,
            child: _buildCategory(),
          ),

          // الأسعار
          Expanded(
            flex: 2,
            child: _buildPricing(),
          ),

          // المخزون
          Expanded(
            flex: 1,
            child: _buildStockInfo(),
          ),

          // المورد
          Expanded(
            flex: 2,
            child: _buildSupplier(),
          ),

          // تاريخ الانتهاء
          Expanded(
            flex: 2,
            child: _buildExpiryDate(),
          ),

          // الحالة
          Expanded(
            flex: 1,
            child: _buildStatusBadge(),
          ),

          // الإجراءات
          SizedBox(
            width: 120,
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الاسم التجاري
        Row(
          children: [
            Expanded(
              child: Text(
                medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (medicine.barcode != null && medicine.barcode!.isNotEmpty)
              Icon(Icons.qr_code_2, size: 16, color: Colors.blue.shade600),
          ],
        ),

        // الاسم العلمي
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            medicine.scientificName,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // الوصف (إن وجد)
        if (medicine.description != null && medicine.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              medicine.description!,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildCategory() {
    return Text(
      medicine.category ?? 'غير مصنف',
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // سعر البيع
        _PriceRow(
          label: 'بيع',
          price: medicine.sellingPrice,
          isMain: true,
        ),

        // سعر الشراء
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _PriceRow(
            label: 'شراء',
            price: medicine.purchasePrice,
            color: Colors.blue.shade700,
          ),
        ),

        // سعر الشريط (إن وجد)
        if (medicine.sellByStrip == true && medicine.stripPrice != null && medicine.stripPrice! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _PriceRow(
              label: 'شريط',
              price: medicine.stripPrice!,
              color: Colors.green.shade700,
              isSmall: true,
            ),
          ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الكمية الحالية
        Row(
          children: [
            Text(
              medicine.quantity.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: medicine.isLowStock ? Colors.orange.shade700 : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            if (medicine.isLowStock)
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade600, size: 16),
          ],
        ),

        // وحدة القياس
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            medicine.unit != null ? _getUnitName(medicine.unit!) : 'قطعة',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ),

        // الحد الأدنى إن وجد
        if (medicine.minStockLevel != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'الحد الأدنى: ${medicine.minStockLevel}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSupplier() {
    return Text(
      medicine.supplier ?? 'غير محدد',
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExpiryDate() {
    if (medicine.expiryDate == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              'لا يوجد',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    final isExpired = medicine.isExpired;
    final daysRemaining = medicine.expiryDate!.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isExpired ? Colors.red : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(medicine.expiryDate!),
                style: TextStyle(
                  fontSize: 12,
                  color: isExpired ? Colors.red : Colors.grey.shade700,
                  fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (!isExpired && daysRemaining <= 30)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 20),
              child: Text(
                'متبقي: $daysRemaining يوم',
                style: TextStyle(
                  fontSize: 10,
                  color: daysRemaining <= 7 ? Colors.orange : Colors.green.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData? icon;

    if (medicine.isExpired) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      statusText = 'منتهي';
      icon = Icons.error_outline;
    } else if (medicine.isLowStock) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      statusText = 'منخفض';
      icon = Icons.warning_amber_outlined;
    } else {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      statusText = 'جيد';
      icon = Icons.check_circle_outline;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          icon: Icons.edit_note,
          color: Colors.blue.shade600,
          tooltip: 'تعديل',
          onPressed: () => _showEditDialog(),
        ),
        _buildActionButton(
          icon: Icons.inventory_2,
          color: Colors.orange.shade600,
          tooltip: 'المخزون',
          onPressed: () => _showStockUpdateDialog(),
        ),
        _buildActionButton(
          icon: Icons.delete_outline,
          color: Colors.red.shade600,
          tooltip: 'حذف',
          onPressed: () => _showDeleteDialog(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  Color _getRowColor() {
    if (medicine.isExpired) return Colors.red.shade50.withOpacity(0.3);
    if (medicine.isLowStock) return Colors.orange.shade50.withOpacity(0.3);
    return Colors.transparent;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _getUnitName(UnitType unit) {
    switch (unit) {
      case UnitType.piece:
        return 'قطعة';
      case UnitType.strip:
        return 'شريط';
      case UnitType.box:
        return 'صندوق';
      case UnitType.bottle:
        return 'زجاجة';
      case UnitType.ml:
        return 'مل';
    }
  }

  void _showEditDialog() {
    // Here you should open the actual edit dialog
    // For now, show a confirmation message
    Get.defaultDialog(
      title: 'تعديل الدواء',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اسم الدواء: ${medicine.name}'),
            Text('الاسم العلمي: ${medicine.scientificName}'),
            const SizedBox(height: 8),
            Text('سعر البيع: ${medicine.sellingPrice?.toStringAsFixed(2) ?? '0'} د.ل'),
            Text('سعر الشراء: ${medicine.purchasePrice?.toStringAsFixed(2) ?? '0'} د.ل'),
          ],
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          // TODO: Open actual edit dialog with AddMedicineDialog
        },
        child: const Text('تعديل'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('إلغاء'),
      ),
    );
  }

  void _showStockUpdateDialog() {
    final quantityController = TextEditingController(text: medicine.quantity.toString());

    Get.dialog(
      AlertDialog(
        title: const Text('تحديث المخزون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.medication),
              title: Text(medicine.name),
              subtitle: Text('الكمية الحالية: ${medicine.quantity}'),
            ),
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
              Get.snackbar(
                'نجاح',
                'تم تحديث المخزون بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل أنت متأكد من حذف ${medicine.name}؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              inventoryController.deleteMedicine(medicine.id);
              Get.back();
              Get.snackbar(
                'تم الحذف',
                'تم حذف ${medicine.name} بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// مكون مساعد لعرض الأسعار
class _PriceRow extends StatelessWidget {
  final String label;
  final double? price;
  final Color? color;
  final bool isMain;
  final bool isSmall;

  const _PriceRow({
    required this.label,
    required this.price,
    this.color,
    this.isMain = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmall ? 10 : (isMain ? 12 : 11),
          ),
        ),
        Text(
          price != null ? price!.toStringAsFixed(2) : '0.00',
          style: TextStyle(
            fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
            fontSize: isSmall ? 11 : (isMain ? 13 : 12),
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}