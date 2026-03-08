import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
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
      final isRefund = widget.salesController.refundMode.value;

      if (isRefund) {
        await widget.salesController.completeRefundAndPrint();
      } else {
        await widget.salesController.completeSaleAndPrint();
      }

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showSafeSnackbar(
        title: 'خطأ',
        message: e.toString(),
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
      final isRefund = widget.salesController.refundMode.value;

      final isDisabled = sale.items.isEmpty || isLoading || _isProcessing;

      final buttonColor = isDisabled
          ? Colors.grey[400]
          : isRefund
          ? Colors.orange[700]
          : Colors.green[700];

      final shadowColor = isDisabled
          ? Colors.grey.withOpacity(0.10)
          : isRefund
          ? Colors.orange.withOpacity(0.20)
          : Colors.green.withOpacity(0.20);

      final buttonText = sale.items.isEmpty
          ? 'أضف منتجات أولاً'
          : isRefund
          ? 'تنفيذ الترجيع وطباعة الإيصال'
          : 'إنهاء البيع وطباعة الفاتورة';

      final buttonIcon = isRefund
          ? Iconsax.arrow_left_2
          : Iconsax.receipt_discount;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : _processCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
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
                buttonIcon,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                buttonText,
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