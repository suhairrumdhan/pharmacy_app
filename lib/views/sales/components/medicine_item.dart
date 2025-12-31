import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';

class MedicineItem extends StatefulWidget {
  final Medicine medicine;
  final SalesController salesController;
  final bool autoSelect;
  final VoidCallback? onSelected;
  final bool showPieceToggle;

  const MedicineItem({
    super.key,
    required this.medicine,
    required this.salesController,
    this.autoSelect = false,
    this.onSelected,
    this.showPieceToggle = true,
  });

  @override
  State<MedicineItem> createState() => _MedicineItemState();
}

class _MedicineItemState extends State<MedicineItem> {
  bool sellAsPiece = false;

  @override
  void initState() {
    super.initState();

    // إذا كان البحث بالباركود وautoSelect = true، أضف المنتج تلقائياً
    if (widget.autoSelect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addMedicine(quantity: 1);

        // إشعار بصري
        Get.snackbar(
          'تمت الإضافة',
          'تم إضافة ${widget.medicine.name} للفاتورة',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      });
    }
  }

  void _addMedicine({required int quantity}) {
    if (widget.medicine.quantity < quantity) {
      Get.snackbar(
        'مخزون غير كافي',
        'المخزون المتوفر: ${widget.medicine.quantity} فقط',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    widget.salesController.addMedicineToSale(
      widget.medicine,
      quantity: quantity,
      sellAsPiece: sellAsPiece,
    );

    if (widget.onSelected != null) {
      widget.onSelected!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicine = widget.medicine;
    final isAvailable = medicine.quantity > 0;
    final showPieceToggle = widget.showPieceToggle && medicine.sellByPiece;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _addMedicine(quantity: 1),
      onDoubleTap: () => _addMedicine(quantity: 2),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAvailable ? Colors.grey.shade200 : Colors.grey.shade300,
          ),
          boxShadow: isAvailable ? [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// صورة أو أيقونة الدواء
            _LeadingIcon(
              imageUrl: medicine.imageUrl,
              isAvailable: isAvailable,
            ),

            const SizedBox(width: 10),

            /// العمود الأساسي (اسم + الاسم العلمي + badges)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الدواء
                  Text(
                    medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? Colors.grey[800] : Colors.grey[500],
                    ),
                  ),

                  // الاسم العلمي
                  Text(
                    medicine.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // الباركود (محسوب في موقع مختلف)
                  if (medicine.barcode != null && medicine.barcode!.isNotEmpty)
                    Text(
                      'الباركود: ${medicine.barcode}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),

                  // badges للمخزون والصلاحية
                  _buildBadgesRow(medicine),
                ],
              ),
            ),

            const SizedBox(width: 10),

            /// السعر والمعلومات الجانبية
            _PriceAndStockColumn(
              price: medicine.sellingPrice,
              piecePrice: medicine.sellByPiece ? medicine.piecePrice : null,
              stockQuantity: medicine.quantity,
              isAvailable: isAvailable,
            ),

            /// Toggle للبيع بالقطعة (فقط إذا كان مسموحًا)
            if (showPieceToggle)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _PieceToggleSwitch(
                  value: sellAsPiece,
                  onChanged: isAvailable ? (v) => setState(() => sellAsPiece = v) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesRow(Medicine medicine) {
    final badges = <Widget>[];

    if (medicine.isLowStock) {
      badges.add(
        _Badge(
          label: 'مخزون منخفض',
          color: Colors.orange.shade100,
          textColor: Colors.orange.shade800,
          icon: Iconsax.alarm,
        ),
      );
    }

    if (medicine.isExpired) {
      badges.add(
        _Badge(
          label: 'منتهي الصلاحية',
          color: Colors.red.shade100,
          textColor: Colors.red.shade800,
          icon: Iconsax.danger,
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }
}

/// صورة الدواء مع تحسينات
class _LeadingIcon extends StatelessWidget {
  final String? imageUrl;
  final bool isAvailable;

  const _LeadingIcon({
    this.imageUrl,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isAvailable ? Colors.blue.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.blue.shade100 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIcon(),
        )
            : _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: Icon(
        Iconsax.health,
        color: isAvailable ? Colors.blue.shade700 : Colors.grey.shade500,
        size: 28,
      ),
    );
  }
}

/// السعر والمخزون
class _PriceAndStockColumn extends StatelessWidget {
  final double? price;
  final double? piecePrice;
  final int stockQuantity;
  final bool isAvailable;

  const _PriceAndStockColumn({
    this.price,
    this.piecePrice,
    required this.stockQuantity,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // السعر الأساسي
          Text(
            price != null ? '${price!.toStringAsFixed(1)} د.ل' : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.green.shade700 : Colors.grey.shade500,
            ),
          ),

          // سعر القطعة (إن وجد)
          if (piecePrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${piecePrice!.toStringAsFixed(1)} / قطعة',
                style: TextStyle(
                  fontSize: 11,
                  color: isAvailable ? Colors.purple.shade700 : Colors.grey.shade500,
                ),
              ),
            ),

          // المخزون
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$stockQuantity متوفر',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isAvailable
                    ? (stockQuantity > 10 ? Colors.green : Colors.orange)
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle للبيع بالقطعة
class _PieceToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PieceToggleSwitch({
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.purple.shade700,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade300,
        ),
        Text(
          'قطعة',
          style: TextStyle(
            fontSize: 10,
            color: onChanged != null ? Colors.purple.shade700 : Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Badges للمخزون/الصلاحية
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}