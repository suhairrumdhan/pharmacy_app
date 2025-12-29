import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';

class BarcodeScannerDialog extends StatelessWidget {
  final SalesController salesController;

  const BarcodeScannerDialog({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
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
              Iconsax.scan_barcode,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'مسح الباركود',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.scan,
              size: 48,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'اضغط لبدء مسح الباركود',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'أو أدخل الباركود يدوياً',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  Iconsax.keyboard,
                  color: Colors.grey[500],
                  size: 20,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  salesController.searchByBarcode(value);
                  Navigator.pop(context);
                }
              },
            ),
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
      ],
    );
  }
}