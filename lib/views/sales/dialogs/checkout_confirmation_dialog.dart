import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../../../controllers/sales_controller.dart';
import '../utils/dialog_utils.dart';
import 'receipt_options_dialog.dart';

class CheckoutConfirmationDialog extends StatefulWidget {
  final SalesController salesController;

  const CheckoutConfirmationDialog({
    super.key,
    required this.salesController,
  });

  @override
  State<CheckoutConfirmationDialog> createState() => _CheckoutConfirmationDialogState();
}

class _CheckoutConfirmationDialogState extends State<CheckoutConfirmationDialog> {
  bool _isProcessing = false;

// في CheckoutConfirmationDialog، عدل دالة _confirmSale:
  Future<void> _confirmSale(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final success = await widget.salesController.saveSale();

      if (!mounted) return;

      if (success) {
        // إغلاق dialog التأكيد
        Navigator.of(context).pop(true);

        // عرض dialog خيارات الإيصال
        await Future.delayed(const Duration(milliseconds: 300));

        if (context.mounted) {
          await DialogUtils.showSafeDialog(
            context: context,
            builder: (_) => ReceiptOptionsDialog(
              salesController: widget.salesController,
              invoiceNumber: widget.salesController.currentSale.value.invoiceNumber,
            ),
            barrierDismissible: false,
          );
        }
      } else {
        DialogUtils.showSafeSnackbar(
          title: 'خطأ',
          message: 'فشل في حفظ الفاتورة',
        );
      }
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showSafeSnackbar(
        title: 'خطأ',
        message: 'حدث خطأ غير متوقع: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.salesController.currentSale.value;

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

          // مؤشر التحميل
          if (_isProcessing) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'جاري حفظ الفاتورة...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(
            'إلغاء',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () => _confirmSale(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('تأكيد وطباعة'),
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