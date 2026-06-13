import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../controllers/sales_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/sales_model.dart';
import '../../../services/receipt_service.dart';
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
  bool _isPrinting = false;

  String _lyd(double v) => '${v.toStringAsFixed(2)} د.ل';

  bool _isPaymentValid() {
    final controller = widget.salesController;
    final sale = controller.currentSale.value.recalculate();
    final isRefund = controller.refundMode.value;

    if (sale.items.isEmpty) return false;

    if (isRefund) {
      final refundTotal = sale.items.fold<double>(
        0.0,
            (sum, item) => sum + item.total,
      );

      final paidOut =
          controller.refundCashOut.value + controller.refundCardOut.value;

      return refundTotal > 0 &&
          paidOut > 0 &&
          paidOut <= refundTotal &&
          (refundTotal - paidOut).abs() < 0.01;
    }

    final customerDue = sale.customerPaidAmount;

    if (sale.customerPaymentMethod == PaymentMethod.cash) {
      return controller.cashReceived.value >= customerDue;
    }

    return customerDue >= 0;
  }

  String _paymentErrorMessage() {
    final controller = widget.salesController;
    final sale = controller.currentSale.value.recalculate();
    final isRefund = controller.refundMode.value;

    if (sale.items.isEmpty) {
      return 'أضف منتجات أولاً';
    }

    if (isRefund) {
      final refundTotal = sale.items.fold<double>(
        0.0,
            (sum, item) => sum + item.total,
      );

      final paidOut =
          controller.refundCashOut.value + controller.refundCardOut.value;

      if (paidOut <= 0) {
        return 'أدخل مبلغ الترجيع الخارج';
      }

      if (paidOut > refundTotal) {
        return 'مبلغ الترجيع أكبر من قيمة الأصناف';
      }

      if ((refundTotal - paidOut).abs() >= 0.01) {
        return 'مبلغ الترجيع غير مطابق. المتبقي: ${_lyd(refundTotal - paidOut)}';
      }

      return 'بيانات الترجيع غير صحيحة';
    }

    final customerDue = sale.customerPaidAmount;

    if (sale.customerPaymentMethod == PaymentMethod.cash &&
        controller.cashReceived.value < customerDue) {
      return 'المبلغ المستلم ناقص: ${_lyd(customerDue - controller.cashReceived.value)}';
    }

    return 'بيانات الدفع غير مكتملة';
  }

  Future<void> _processCheckout({required bool printReceipt}) async {
    if (_isProcessing) return;

    final sale = widget.salesController.currentSale.value.recalculate();
    final isSavedInvoice =
        sale.isSaved || sale.status == InvoiceStatus.completed;

    if (!isSavedInvoice && !_isPaymentValid()) {
      DialogUtils.showSafeSnackbar(
        title: 'تنبيه',
        message: _paymentErrorMessage(),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _isPrinting = printReceipt;
    });

    try {
      final authController = Get.find<AuthController>();
      final pharmacyData = authController.pharmacyData;

      // ✅ فاتورة محفوظة مسبقًا: لا حفظ جديد، فقط معاينة أو طباعة
      if (isSavedInvoice) {
        if (printReceipt) {
          await ReceiptService.previewReceipt(
            context: context,
            sale: sale,
            pharmacyName:
            pharmacyData['pharmacyName']?.toString() ?? 'الصيدلية',
            pharmacyPhone: pharmacyData['phone']?.toString() ?? '',
            pharmacyAddress: pharmacyData['address']?.toString() ?? '',
            cashierName: sale.employeeName ?? authController.userName,
          );
        } else {
          await ReceiptService.printReceipt(
            sale: sale,
            pharmacyName:
            pharmacyData['pharmacyName']?.toString() ?? 'الصيدلية',
            pharmacyPhone: pharmacyData['phone']?.toString() ?? '',
            pharmacyAddress: pharmacyData['address']?.toString() ?? '',
            cashierName: sale.employeeName ?? authController.userName,
          );
        }
        return;
      }

      final isRefund = widget.salesController.refundMode.value;

      final saved = isRefund
          ? await widget.salesController.completeRefundAndPrint()
          : await widget.salesController.completeSaleAndPrint();

      if (!mounted) return;
      if (saved == null) return;

      if (printReceipt) {
        await ReceiptService.previewReceipt(
          context: context,
          sale: saved,
          pharmacyName:
          pharmacyData['pharmacyName']?.toString() ?? 'الصيدلية',
          pharmacyPhone: pharmacyData['phone']?.toString() ?? '',
          pharmacyAddress: pharmacyData['address']?.toString() ?? '',
          cashierName: saved.employeeName ?? authController.userName,
        );
      } else {
        DialogUtils.showSafeSnackbar(
          title: 'تم الحفظ',
          message: isRefund
              ? 'تم حفظ عملية الترجيع بنجاح'
              : 'تم حفظ الفاتورة بنجاح',
        );
      }
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showSafeSnackbar(
        title: 'خطأ',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isPrinting = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sale = widget.salesController.currentSale.value.recalculate();
      final isLoading = widget.salesController.isLoading.value;
      final isRefund = widget.salesController.refundMode.value;

      final isSavedInvoice =
          sale.isSaved || sale.status == InvoiceStatus.completed;

      final paymentValid = isSavedInvoice ? true : _isPaymentValid();

      final isDisabled =
          sale.items.isEmpty || isLoading || _isProcessing || !paymentValid;

      final mainColor = isSavedInvoice
          ? Colors.blue[700]
          : isRefund
          ? Colors.orange[700]
          : Colors.green[700];

      final saveText = sale.items.isEmpty
          ? 'أضف منتجات أولاً'
          : isSavedInvoice
          ? 'طباعة مباشرة'
          : isRefund
          ? 'حفظ الترجيع فقط'
          : 'حفظ الفاتورة فقط';

      final printText = sale.items.isEmpty
          ? 'أضف منتجات أولاً'
          : isSavedInvoice
          ? 'معاينة الفاتورة'
          : isRefund
          ? 'حفظ ومعاينة الإيصال'
          : 'حفظ ومعاينة الفاتورة';

      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isDisabled
                  ? null
                  : () => _processCheckout(printReceipt: false),
              icon: _isProcessing && !_isPrinting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(
                isSavedInvoice
                    ? Iconsax.printer
                    : Iconsax.archive_tick,
                size: 19,
              ),
              label: Text(
                saveText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: mainColor,
                minimumSize: const Size(double.infinity, 54),
                side: BorderSide(
                  color: isDisabled
                      ? Colors.grey.shade300
                      : mainColor ?? Colors.green,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isDisabled
                  ? null
                  : () => _processCheckout(printReceipt: true),
              icon: _isProcessing && _isPrinting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                isSavedInvoice
                    ? Iconsax.eye
                    : isRefund
                    ? Iconsax.arrow_left_2
                    : Iconsax.receipt_discount,
                size: 19,
              ),
              label: Text(
                printText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey[400] : mainColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

}