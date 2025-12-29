import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../dialogs/checkout_confirmation_dialog.dart';

class CheckoutButton extends StatelessWidget {
  final SalesController salesController;

  const CheckoutButton({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sale = salesController.currentSale.value;
      final isLoading = salesController.isLoading.value;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: sale.items.isEmpty || isLoading
              ? null
              : () {
            showDialog(
              context: context,
              builder: (_) => CheckoutConfirmationDialog(salesController: salesController),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: isLoading
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
              const Text(
                'إنهاء البيع وطباعة الفاتورة',
                style: TextStyle(
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