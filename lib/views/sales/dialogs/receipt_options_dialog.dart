import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';

class ReceiptOptionsDialog extends StatelessWidget {
  final SalesController salesController;

  const ReceiptOptionsDialog({
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
              Iconsax.printer,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'فاتورة البيع',
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.tick_circle,
              size: 40,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'تم حفظ الفاتورة بنجاح.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'هل تريد طباعة الفاتورة؟',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'لاحقاً',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _printReceipt();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('نعم، اطبع'),
        ),
      ],
    );
  }

  void _printReceipt() {
    Get.snackbar(
      'طباعة الفاتورة',
      '✅ سيتم إرسال الفاتورة للطباعة',
      backgroundColor: Colors.green[700],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}