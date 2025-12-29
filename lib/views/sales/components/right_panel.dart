import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/sales_controller.dart';
import 'invoice_header_card.dart';
import 'payment_card.dart';
import 'checkout_button.dart';

class RightPanel extends StatelessWidget {
  final SalesController salesController;

  const RightPanel({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // معلومات الفاتورة
        InvoiceHeaderCard(salesController: salesController),

        const SizedBox(height: 12),

        // تفاصيل الدفع
        Expanded(
          child: PaymentCard(salesController: salesController),
        ),

        const SizedBox(height: 12),

        // زر إنهاء البيع
        CheckoutButton(salesController: salesController),
      ],
    );
  }
}