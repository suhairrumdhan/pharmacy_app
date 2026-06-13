import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../models/sales_model.dart';

class ReceiptService {
  static final _money = NumberFormat('#,##0.00', 'en');

  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<void> _loadFonts() async {
    _regularFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    _boldFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );
  }

  static Future<void> previewReceipt({
    required BuildContext context,
    required Sale sale,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
    String cashierName = '',
  }) async {
    final pdfBytes = await buildReceiptPdf(
      sale: sale,
      pharmacyName: pharmacyName,
      pharmacyPhone: pharmacyPhone,
      pharmacyAddress: pharmacyAddress,
      cashierName: cashierName,
    );

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(22),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 560,
          height: 760,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sale.type == SaleType.refund
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sale.type == SaleType.refund
                            ? 'معاينة إيصال الترجيع'
                            : 'معاينة فاتورة البيع',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PdfPreview(
                  build: (_) async => pdfBytes,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  allowPrinting: false,
                  allowSharing: false,
                  canDebug: false,
                  pdfFileName: 'receipt_${sale.invoiceNumber}.pdf',
                ),
              ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('إغلاق'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Printing.layoutPdf(
                            name: 'receipt_${sale.invoiceNumber}.pdf',
                            onLayout: (_) async => pdfBytes,
                          );
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text(
                          'طباعة',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  static Future<void> printReceipt({
    required Sale sale,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
    String cashierName = '',
  }) async {
    final pdfBytes = await buildReceiptPdf(
      sale: sale,
      pharmacyName: pharmacyName,
      pharmacyPhone: pharmacyPhone,
      pharmacyAddress: pharmacyAddress,
      cashierName: cashierName,
    );

    await Printing.layoutPdf(
      name: 'receipt_${sale.invoiceNumber}.pdf',
      onLayout: (_) async => pdfBytes,
    );
  }

  static Future<Uint8List> buildReceiptPdf({
    required Sale sale,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
    String cashierName = '',
  }) async {
    await _loadFonts();

    final regularFont = _regularFont!;
    final boldFont = _boldFont!;

    final pdf = pw.Document();
    final isRefund = sale.type == SaleType.refund;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (_) {
          return pw.Theme(
            data: pw.ThemeData.withFont(
              base: regularFont,
              bold: boldFont,
            ),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _center(
                    pharmacyName,
                    size: 12,
                    bold: true,
                  ),

                  if (pharmacyAddress.trim().isNotEmpty)
                    _center(
                      pharmacyAddress.trim(),
                      size: 6.5,
                    ),

                  if (pharmacyPhone.trim().isNotEmpty)
                    _center(
                      'هاتف: ${pharmacyPhone.trim()}',
                      size: 6.5,
                    ),

                  _space(3),
                  _line(),

                  _center(
                    isRefund ? 'إيصال ترجيع' : 'فاتورة بيع',
                    size: 10,
                    bold: true,
                  ),

                  _space(3),

                  _row('رقم الإيصال', sale.invoiceNumber),

                  if (sale.source == 'order' &&
                      (sale.orderNumber ?? '').trim().isNotEmpty)
                    _row(
                      'رقم الطلب',
                      sale.orderNumber!.trim(),
                    ),

                  if (isRefund)
                    _row(
                      'الفاتورة الأصلية',
                      sale.refInvoiceNumber ?? '--',
                    ),

                  _row(
                    'التاريخ',
                    DateFormat(
                      'yyyy/MM/dd  hh:mm a',
                    ).format(sale.saleDate),
                  ),

                  _row(
                    'الكاشير',
                    cashierName.trim().isNotEmpty
                        ? cashierName.trim()
                        : (sale.employeeName ?? '--'),
                  ),

                  if ((sale.customerName ?? '').trim().isNotEmpty)
                    _row(
                      'الزبون',
                      sale.customerName!.trim(),
                    ),

                  _space(3),
                  _line(),

                  /// HEADER
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(width: .5),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            'البيان',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),

                        pw.Expanded(
                          flex: 2,
                          child: pw.Center(
                            child: pw.Text(
                              'الكمية',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        pw.Expanded(
                          flex: 2,
                          child: pw.Center(
                            child: pw.Text(
                              'السعر',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        pw.Expanded(
                          flex: 2,
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                              'الإجمالي',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ITEMS
                  ...sale.items.map((item) {
                    final total =
                        item.unitPrice * item.quantity;

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 2,
                      ),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            width: .2,
                            color: PdfColors.grey300,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              item.name,
                              style: const pw.TextStyle(
                                fontSize: 6.8,
                              ),
                              maxLines: 2,
                            ),
                          ),

                          pw.Expanded(
                            flex: 2,
                            child: pw.Center(
                              child: pw.Text(
                                '${item.quantity}',
                                style: const pw.TextStyle(
                                  fontSize: 6.8,
                                ),
                              ),
                            ),
                          ),

                          pw.Expanded(
                            flex: 2,
                            child: pw.Center(
                              child: pw.Text(
                                _money.format(item.unitPrice),
                                style: const pw.TextStyle(
                                  fontSize: 6.8,
                                ),
                              ),
                            ),
                          ),

                          pw.Expanded(
                            flex: 2,
                            child: pw.Align(
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text(
                                _money.format(total),
                                style: pw.TextStyle(
                                  fontSize: 6.8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  _space(4),
                  _line(),

                  if (isRefund) ...[
                    _totalRow(
                      'إجمالي الترجيع',
                      '${_money.format(sale.refundPaidOut)} د.ل',
                    ),

                    _row(
                      'كاش خارج',
                      '${_money.format(sale.cashOut)} د.ل',
                    ),

                    _row(
                      'مصرفي خارج',
                      '${_money.format(sale.cardOut)} د.ل',
                    ),
                  ] else ...[
                    _row(
                      'الإجمالي',
                      '${_money.format(sale.subtotal)} د.ل',
                    ),

                    if ((sale.discount ?? 0) > 0)
                      _row(
                        'الخصم',
                        '${_money.format(sale.discount ?? 0)} د.ل',
                      ),

                    if (sale.companyBilledAmount > 0) ...[
                      _row(
                        'شركة التأمين',
                        sale.insuranceCompanyName ?? '--',
                      ),

                      _row(
                        'على التأمين',
                        '${_money.format(sale.companyBilledAmount)} د.ل',
                      ),
                    ],

                    _totalRow(
                      'الصافي',
                      '${_money.format(sale.customerPaidAmount)} د.ل',
                    ),

                    _row(
                      'طريقة الدفع',
                      sale.customerPaymentMethod ==
                          PaymentMethod.cash
                          ? 'نقدا '
                          : 'معاملة مصرفية',
                    ),
                  ],

                  _row(
                    'عدد القطع',
                    '${sale.items.fold<int>(0, (s, i) => s + i.quantity)}',
                  ),

                  _space(4),
                  _line(),

                  _space(3),

                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: sale.invoiceNumber,
                      width: 110,
                      height: 30,
                    ),
                  ),

                  _space(4),

                  _center(
                    isRefund
                        ? 'تم تنفيذ الترجيع'
                        : 'شكراً لتعاملكم معنا',
                    size: 6.5,
                  ),

                  _space(2),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _center(
      String text, {
        double size = 8,
        bool bold = false,
      }) {
    return pw.Center(
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _row(
      String label,
      String value,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7),
          ),

          pw.SizedBox(width: 4),

          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.left,
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(
      String label,
      String value,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 3,
        horizontal: 2,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey600,
          width: .5,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _line() {
    return pw.Container(
      height: .5,
      color: PdfColors.grey600,
      margin: const pw.EdgeInsets.symmetric(vertical: 3),
    );
  }

  static pw.Widget _space(double h) {
    return pw.SizedBox(height: h);
  }
}