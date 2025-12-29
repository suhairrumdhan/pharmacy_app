import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import 'receipt_options_dialog.dart';

class CheckoutConfirmationDialog extends StatelessWidget {
  final SalesController salesController;

  const CheckoutConfirmationDialog({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
    final sale = salesController.currentSale.value;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.tick_circle,
              color: Colors.green[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'تأكيد عملية البيع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الفاتورة:',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildConfirmationRow('📊 عدد الأصناف', '${sale.items.length}'),
          _buildConfirmationRow('💰 المجموع', '${sale.total.toStringAsFixed(2)} ر.س'),
          _buildConfirmationRow('💳 طريقة الدفع', sale.paymentMethod.arabicName),
          if (sale.insuranceCompanyName != null)
            _buildConfirmationRow('🏥 شركة التأمين', sale.insuranceCompanyName!),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  color: Colors.blue[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هل أنت متأكد من إنهاء البيع؟',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
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
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final success = await salesController.saveSale();
            if (success) {
              showDialog(
                context: context,
                builder: (_) => ReceiptOptionsDialog(salesController: salesController),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('تأكيد وطباعة'),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}