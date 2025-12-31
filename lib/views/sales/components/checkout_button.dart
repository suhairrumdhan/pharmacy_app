import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../dialogs/checkout_confirmation_dialog.dart';

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
  bool _isOpeningDialog = false;

  Future<void> _openCheckoutDialog(BuildContext context) async {
    if (!context.mounted) return;

    setState(() => _isOpeningDialog = true);

    try {
      await DialogUtils.showSafeDialog(
        context: context,
        builder: (_) => CheckoutConfirmationDialog(
          salesController: widget.salesController,
        ),
        barrierDismissible: false,
      );
    } catch (e, stackTrace) {
      print('❌ خطأ في فتح dialog: $e');
      print('📜 Stack trace: $stackTrace');

      DialogUtils.showSafeSnackbar(
        title: 'خطأ',
        message: 'فشل في فتح نافذة التأكيد',
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningDialog = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sale = widget.salesController.currentSale.value;
      final isLoading = widget.salesController.isLoading.value;
      final isDisabled = sale.items.isEmpty || isLoading || _isOpeningDialog;

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
          onPressed: isDisabled
              ? null
              : () => _openCheckoutDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled
                ? Colors.grey[400]
                : Colors.green[700],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: isLoading || _isOpeningDialog
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