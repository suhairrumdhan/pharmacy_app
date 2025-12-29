import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';

class EditItemDialog extends StatefulWidget {
  final int index;
  final SalesController salesController;

  const EditItemDialog({
    super.key,
    required this.index,
    required this.salesController,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    final item = widget.salesController.currentSale.value.items[widget.index];
    quantity = item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.salesController.currentSale.value.items[widget.index];

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.edit_2,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'تعديل ${item.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'السعر: ${item.unitPrice.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Iconsax.minus,
                  color: Colors.red[700],
                  size: 32,
                ),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                },
              ),
              const SizedBox(width: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  Iconsax.add_circle,
                  color: Colors.green[700],
                  size: 32,
                ),
                onPressed: () {
                  setState(() => quantity++);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'إلغاء',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.salesController.updateQuantity(widget.index, quantity);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('تحديث'),
        ),
      ],
    );
  }
}