import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';

class AddQuantityDialog extends StatefulWidget {
  final Medicine medicine;
  final SalesController salesController;

  const AddQuantityDialog({
    super.key,
    required this.medicine,
    required this.salesController,
  });

  @override
  State<AddQuantityDialog> createState() => _AddQuantityDialogState();
}

class _AddQuantityDialogState extends State<AddQuantityDialog> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
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
                  Iconsax.add_circle,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إضافة ${widget.medicine.name}',
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
                'المخزون المتوفر: ${widget.medicine.quantity}',
                style: TextStyle(color: Colors.grey[600]),
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
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
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
                    onPressed: quantity < widget.medicine.quantity
                        ? () => setState(() => quantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.salesController.addMedicineToSale(
                  widget.medicine,
                  quantity: quantity,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }
}