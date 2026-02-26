import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../dialogs/receipt_options_dialog.dart';
import '../utils/dialog_utils.dart';

class CheckoutButton extends StatefulWidget {
  final SalesController salesController;

  const CheckoutButton({
    super.key,
    required this.salesController,
  });

  @override
  State<CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<CheckoutButton> {
  bool _isProcessing = false;

  Future<void> _processCheckout() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // ✅ يحفظ + يحدّث الشيفت + يرجع الفاتورة المحفوظة
      final savedSale = await widget.salesController.completeSaleAndPrint();
      if (!mounted) return;
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
    return Obx(() {
      final sale = widget.salesController.currentSale.value;
      final isLoading = widget.salesController.isLoading.value;

      final isDisabled = sale.items.isEmpty || isLoading || _isProcessing;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : _processCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? Colors.grey[400] : Colors.green[700],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: isLoading || _isProcessing
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.receipt_discount,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                sale.items.isEmpty
                    ? 'أضف منتجات أولاً'
                    : 'إنهاء البيع وطباعة الفاتورة',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
