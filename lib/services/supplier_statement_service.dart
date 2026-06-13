import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../models/supplier_model.dart';
import '../models/purchase_model.dart';

class SupplierStatementService {
  static final _money = NumberFormat('#,##0.00', 'en');
  static final _date = DateFormat('yyyy/MM/dd');

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

  static Future<void> previewStatement({
    required BuildContext context,
    required Supplier supplier,
    required List<PurchaseInvoice> invoices,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
  }) async {
    final pdfBytes = await buildStatementPdf(
      supplier: supplier,
      invoices: invoices,
      pharmacyName: pharmacyName,
      pharmacyPhone: pharmacyPhone,
      pharmacyAddress: pharmacyAddress,
    );

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(22),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 860,
          height: 760,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
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
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'معاينة كشف حساب المورد - ${supplier.name}',
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
                  pdfFileName: 'supplier_statement_${supplier.name}.pdf',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                            name: 'supplier_statement_${supplier.name}.pdf',
                            onLayout: (_) async => pdfBytes,
                          );
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text(
                          'طباعة',
                          style: TextStyle(fontWeight: FontWeight.w900),
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

  static Future<Uint8List> buildStatementPdf({
    required Supplier supplier,
    required List<PurchaseInvoice> invoices,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final regularFont = _regularFont!;
    final boldFont = _boldFont!;

    final sortedInvoices = [...invoices]
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));

    final totalPurchases =
    sortedInvoices.fold<double>(0, (sum, inv) => sum + inv.total);
    final totalPaid =
    sortedInvoices.fold<double>(0, (sum, inv) => sum + inv.paid);
    final totalDue =
    sortedInvoices.fold<double>(0, (sum, inv) => sum + inv.remaining);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (_) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _header(
                    pharmacyName: pharmacyName,
                    pharmacyPhone: pharmacyPhone,
                    pharmacyAddress: pharmacyAddress,
                  ),
                  pw.SizedBox(height: 12),
                  _title('كشف حساب مورد'),
                  pw.SizedBox(height: 12),
                  _supplierInfo(supplier),
                  pw.SizedBox(height: 12),
                  _summaryCards(
                    totalPurchases: totalPurchases,
                    totalPaid: totalPaid,
                    totalDue: totalDue,
                    unpaidInvoices: sortedInvoices
                        .where((e) => e.remaining > 0)
                        .length,
                  ),
                  pw.SizedBox(height: 14),
                  _invoiceTable(sortedInvoices),
                  pw.SizedBox(height: 18),
                  _totals(
                    totalPurchases: totalPurchases,
                    totalPaid: totalPaid,
                    totalDue: totalDue,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'تم إنشاء هذا الكشف آليًا من نظام إدارة الصيدلية.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _header({
    required String pharmacyName,
    required String pharmacyPhone,
    required String pharmacyAddress,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            pharmacyName,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (pharmacyAddress.trim().isNotEmpty)
            pw.Text(
              pharmacyAddress,
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
            ),
          if (pharmacyPhone.trim().isNotEmpty)
            pw.Text(
              'هاتف: $pharmacyPhone',
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
            ),
        ],
      ),
    );
  }

  static pw.Widget _title(String text) {
    return pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _supplierInfo(Supplier supplier) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _row('اسم المورد', supplier.name),
          _row('الشخص المسؤول', supplier.contactPerson),
          _row('الهاتف', supplier.phone),
          _row('العنوان', supplier.address),
          _row('تاريخ الكشف', DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards({
    required double totalPurchases,
    required double totalPaid,
    required double totalDue,
    required int unpaidInvoices,
  }) {
    return pw.Row(
      children: [
        _summaryCard('إجمالي المشتريات', totalPurchases),
        pw.SizedBox(width: 8),
        _summaryCard('إجمالي المدفوع', totalPaid),
        pw.SizedBox(width: 8),
        _summaryCard('المتبقي', totalDue),
        pw.SizedBox(width: 8),
        _summaryCard('فواتير غير مسددة', unpaidInvoices.toDouble(), isCount: true),
      ],
    );
  }

  static pw.Widget _summaryCard(String title, double value, {bool isCount = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          border: pw.Border.all(color: PdfColors.blue100),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 4),
            pw.Text(
              isCount ? value.toInt().toString() : '${_money.format(value)} د.ل',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _invoiceTable(List<PurchaseInvoice> invoices) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('رقم الفاتورة', bold: true),
            _cell('التاريخ', bold: true),
            _cell('الإجمالي', bold: true),
            _cell('المدفوع', bold: true),
            _cell('المتبقي', bold: true),
            _cell('الحالة', bold: true),
          ],
        ),
        ...invoices.map((inv) {
          return pw.TableRow(
            children: [
              _cell(inv.invoiceNumber),
              _cell(_date.format(inv.invoiceDate)),
              _cell(_money.format(inv.total)),
              _cell(_money.format(inv.paid)),
              _cell(_money.format(inv.remaining)),
              _cell(_paymentStatusLabel(inv.paymentStatus.name)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _totals({
    required double totalPurchases,
    required double totalPaid,
    required double totalDue,
  }) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 260,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _row('الإجمالي', '${_money.format(totalPurchases)} د.ل'),
            _row('المدفوع', '${_money.format(totalPaid)} د.ل'),
            pw.Divider(),
            _row('الرصيد المتبقي', '${_money.format(totalDue)} د.ل', bold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.left,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مسددة';
      case 'partiallyPaid':
        return 'مدفوعة جزئياً';
      case 'unpaid':
      default:
        return 'غير مسددة';
    }
  }
}