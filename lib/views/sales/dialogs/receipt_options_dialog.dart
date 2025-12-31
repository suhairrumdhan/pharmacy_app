import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../utils/dialog_utils.dart';

class ReceiptOptionsDialog extends StatefulWidget {
  final SalesController salesController;
  final String invoiceNumber;

  const ReceiptOptionsDialog({
    super.key,
    required this.salesController,
    required this.invoiceNumber,
  });

  @override
  State<ReceiptOptionsDialog> createState() => _ReceiptOptionsDialogState();
}

class _ReceiptOptionsDialogState extends State<ReceiptOptionsDialog> {
  bool _isPrinting = false;
  bool _isEmailing = false;

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      // محاكاة عملية الطباعة
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      DialogUtils.showSafeSnackbar(
        title: 'نجاح',
        message: 'تمت طباعة الفاتورة #${widget.invoiceNumber}',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      DialogUtils.showSafeSnackbar(
        title: 'خطأ',
        message: 'فشل في الطباعة: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _sendEmailReceipt() async {
    setState(() => _isEmailing = true);

    try {
      // محاكاة إرسال البريد الإلكتروني
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      DialogUtils.showSafeSnackbar(
        title: 'تم الإرسال',
        message: 'تم إرسال الفاتورة إلى البريد الإلكتروني',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      DialogUtils.showSafeSnackbar(
        title: 'خطأ',
        message: 'فشل في إرسال البريد: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isEmailing = false);
      }
    }
  }

  void _viewReceipt() {
    Navigator.of(context).pop(false);
    Get.toNamed('/receipt/${widget.salesController.currentSale.value.id}');
  }

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
          const SizedBox(height: 16),
          Text(
            'تم حفظ الفاتورة بنجاح!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'رقم الفاتورة: ${widget.invoiceNumber}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          if (_isPrinting || _isEmailing)
            _buildProgressIndicator()
          else
            _buildOptions(),
        ],
      ),
      actions: [
        if (!_isPrinting && !_isEmailing) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'لاحقاً',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: _viewReceipt,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
            ),
            child: const Text('عرض الفاتورة'),
          ),
          ElevatedButton(
            onPressed: _printReceipt,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('طباعة'),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          _isPrinting ? 'جاري الطباعة...' : 'جاري إرسال البريد...',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        const Text(
          'اختر طريقة استلام الفاتورة:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // خيار الطباعة
        _buildOptionCard(
          icon: Iconsax.printer,
          title: 'طباعة فورية',
          subtitle: 'إرسال الفاتورة للطابعة',
          color: Colors.blue,
          onTap: _printReceipt,
        ),

        const SizedBox(height: 12),

        // خيار البريد الإلكتروني
        _buildOptionCard(
          icon: Iconsax.sms,
          title: 'إرسال بالبريد',
          subtitle: 'إرسال إلى البريد الإلكتروني',
          color: Colors.orange,
          onTap: _sendEmailReceipt,
        ),

        const SizedBox(height: 12),

        // خيار الحفظ
        _buildOptionCard(
          icon: Iconsax.save_2,
          title: 'حفظ فقط',
          subtitle: 'حفظ الفاتورة في النظام',
          color: Colors.green,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_left_2,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}