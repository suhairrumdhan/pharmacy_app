import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../models/insurance_company_model.dart';
import '../models/sales_model.dart';

class InsuranceStatementService {
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
    required InsuranceCompany company,
    required List<Sale> invoices,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
  }) async {
    final pdfBytes = await buildStatementPdf(
      company: company,
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
                        'معاينة كشف مستحقات التأمين - ${company.name}',
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
                  pdfFileName: 'insurance_statement_${company.name}.pdf',
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
                            name: 'insurance_statement_${company.name}.pdf',
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
  static Future<void> previewDetailedInvoices({
    required BuildContext context,
    required InsuranceCompany company,
    required List<Sale> invoices,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
  }) async {
    final pdfBytes = await buildDetailedInvoicesPdf(
      company: company,
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
                  color: Colors.indigo.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'معاينة تفاصيل فواتير التأمين - ${company.name}',
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
                  pdfFileName: 'insurance_invoices_details_${company.name}.pdf',
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
                            name: 'insurance_invoices_details_${company.name}.pdf',
                            onLayout: (_) async => pdfBytes,
                          );
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text(
                          'طباعة التفاصيل',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
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

  static Future<void> previewInsuranceCollectionReceipt({
    required BuildContext context,
    required InsuranceCompany company,
    required double amount,
    required double previousReceivable,
    required double newReceivable,
    required int collectionYear,
    required int collectionMonth,
    required String paymentMethod,
    required String collectionId,
    required String transactionId,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
    String? referenceNumber,
    String? notes,
    DateTime? collectionDate,
  }) async {
    final pdfBytes = await buildInsuranceCollectionReceiptPdf(
      company: company,
      amount: amount,
      previousReceivable: previousReceivable,
      newReceivable: newReceivable,
      collectionYear: collectionYear,
      collectionMonth: collectionMonth,
      paymentMethod: paymentMethod,
      collectionId: collectionId,
      transactionId: transactionId,
      pharmacyName: pharmacyName,
      pharmacyPhone: pharmacyPhone,
      pharmacyAddress: pharmacyAddress,
      referenceNumber: referenceNumber,
      notes: notes,
      collectionDate: collectionDate,
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
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'إيصال تحصيل تأمين - ${company.name}',
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
                  pdfFileName: 'insurance_collection_$collectionId.pdf',
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
                            name: 'insurance_collection_$collectionId.pdf',
                            onLayout: (_) async => pdfBytes,
                          );
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text(
                          'طباعة الإيصال',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
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
  static Future<Uint8List> buildInsuranceCollectionReceiptPdf({
    required InsuranceCompany company,
    required double amount,
    required double previousReceivable,
    required double newReceivable,
    required int collectionYear,
    required int collectionMonth,
    required String paymentMethod,
    required String collectionId,
    required String transactionId,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
    String? referenceNumber,
    String? notes,
    DateTime? collectionDate,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final date = collectionDate ?? DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: _regularFont!,
          bold: _boldFont!,
        ),
        build: (_) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _header(
                  pharmacyName: pharmacyName,
                  pharmacyPhone: pharmacyPhone,
                  pharmacyAddress: pharmacyAddress,
                ),
                pw.SizedBox(height: 18),
                _title('إيصال تحصيل مستحقات تأمين'),
                pw.SizedBox(height: 16),

                _companyInfo(company),

                pw.SizedBox(height: 16),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green600),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      _row('رقم إيصال التحصيل', collectionId),
                      _row('رقم الحركة المالية', transactionId),
                      _row('تاريخ التحصيل', DateFormat('yyyy/MM/dd HH:mm').format(date)),
                      _row(
                        'فترة التحصيل',
                        '$collectionYear/${collectionMonth.toString().padLeft(2, '0')}',
                      ),
                      _row('طريقة الدفع', _paymentMethodLabel(paymentMethod)),
                      if ((referenceNumber ?? '').trim().isNotEmpty)
                        _row('رقم المرجع / التحويل', referenceNumber!.trim()),
                    ],
                  ),
                ),

                pw.SizedBox(height: 18),

                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green200),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      _row(
                        'الرصيد قبل التحصيل',
                        '${_money.format(previousReceivable)} د.ل',
                      ),
                      _row(
                        'المبلغ المحصل',
                        '${_money.format(amount)} د.ل',
                        bold: true,
                      ),
                      pw.Divider(),
                      _row(
                        'الرصيد بعد التحصيل',
                        '${_money.format(newReceivable)} د.ل',
                        bold: true,
                      ),
                    ],
                  ),
                ),

                if ((notes ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: _row('ملاحظات', notes!.trim()),
                  ),
                ],

                pw.Spacer(),

                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Divider(),
                          pw.Text('توقيع المستلم', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 60),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Divider(),
                          pw.Text('ختم / توقيع الصيدلية', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'تم إنشاء هذا الإيصال آليًا من نظام إدارة الصيدلية، ويثبت تسجيل تحصيل مالي من شركة التأمين.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }static String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'card':
        return 'معاملة مصرفية';
      case 'bank':
        return 'تحويل مصرفي';
      default:
        return method;
    }
  }
  static Future<Uint8List> buildDetailedInvoicesPdf({
    required InsuranceCompany company,
    required List<Sale> invoices,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final regularFont = _regularFont!;
    final boldFont = _boldFont!;

    final sortedInvoices = [...invoices]
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));

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
                  _title('تفاصيل فواتير شركة التأمين'),
                  pw.SizedBox(height: 12),
                  _companyInfo(company),
                  pw.SizedBox(height: 14),

                  ...sortedInvoices.map((invoice) {
                    final insurancePart =
                    (invoice.insuranceClaimAmount ??
                        invoice.insuranceDiscount ??
                        0.0)
                        .clamp(0.0, double.infinity);

                    final customerPart = invoice.paidAmount ?? invoice.total;

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 14),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue50,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(
                              children: [
                                _row('رقم الفاتورة', invoice.invoiceNumber),
                                _row('التاريخ', _date.format(invoice.saleDate)),
                                _row('الزبون', invoice.customerName ?? '--'),
                                _row('إجمالي الفاتورة',
                                    '${_money.format(invoice.subtotal)} د.ل'),
                                _row('حصة الزبون',
                                    '${_money.format(customerPart)} د.ل'),
                                _row('حصة التأمين',
                                    '${_money.format(insurancePart)} د.ل',
                                    bold: true),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _itemsTable(invoice.items),
                        ],
                      ),
                    );
                  }),

                  pw.SizedBox(height: 16),
                  _totals(
                    totalSales: sortedInvoices.fold<double>(
                      0,
                          (s, i) => s + i.subtotal,
                    ),
                    customerPaid: sortedInvoices.fold<double>(
                      0,
                          (s, i) => s + (i.paidAmount ?? i.total),
                    ),
                    insuranceClaim: sortedInvoices.fold<double>(
                      0,
                          (s, i) =>
                      s +
                          ((i.insuranceClaimAmount ??
                              i.insuranceDiscount ??
                              0.0)
                              .clamp(0.0, double.infinity)),
                    ),
                    totalReceivable: sortedInvoices.fold<double>(
                      0,
                          (s, i) =>
                      s +
                          ((i.insuranceClaimAmount ??
                              i.insuranceDiscount ??
                              0.0)
                              .clamp(0.0, double.infinity)),
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
  static pw.Widget _itemsTable(List<SaleItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(.8),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('الصنف', bold: true),
            _cell('الكمية', bold: true),
            _cell('السعر', bold: true),
            _cell('الإجمالي', bold: true),
          ],
        ),
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _cell(item.displayName),
              _cell('${item.quantity}'),
              _cell(_money.format(item.unitPrice)),
              _cell(_money.format(item.total)),
            ],
          );
        }),
      ],
    );
  }

  static Future<Uint8List> buildStatementPdf({
    required InsuranceCompany company,
    required List<Sale> invoices,
    required String pharmacyName,
    String pharmacyPhone = '',
    String pharmacyAddress = '',
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final regularFont = _regularFont!;
    final boldFont = _boldFont!;

    final sortedInvoices = [...invoices]
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));

    final totalSales = sortedInvoices.fold<double>(
      0,
          (sum, inv) => sum + inv.subtotal,
    );

    final totalCustomerPaid = sortedInvoices.fold<double>(
      0,
          (sum, inv) => sum + (inv.paidAmount ?? inv.total),
    );

    final totalInsuranceClaim = sortedInvoices.fold<double>(
      0,
          (sum, inv) =>
      sum +
          ((inv.insuranceClaimAmount ??
              inv.insuranceDiscount ??
              0.0)
              .clamp(0.0, double.infinity)),
    );

    final totalReceivable = totalInsuranceClaim;

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
                  _title('كشف مستحقات شركة التأمين'),
                  pw.SizedBox(height: 12),
                  _companyInfo(company),
                  pw.SizedBox(height: 12),
                  _summaryCards(
                    totalSales: totalSales,
                    customerPaid: totalCustomerPaid,
                    insuranceClaim: totalInsuranceClaim,
                    invoicesCount: sortedInvoices.length,
                  ),
                  pw.SizedBox(height: 14),
                  _invoiceTable(sortedInvoices),
                  pw.SizedBox(height: 18),
                  _totals(
                    totalSales: totalSales,
                    customerPaid: totalCustomerPaid,
                    insuranceClaim: totalInsuranceClaim,
                    totalReceivable: totalReceivable,
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

  static pw.Widget _companyInfo(InsuranceCompany company) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _row('اسم الشركة', company.name),
          _row('الكود', company.code),
          _row('الشخص المسؤول', company.contactPerson),
          _row('الهاتف', company.phone),
          _row('نسبة الخصم', company.formattedDiscount),
          _row('تاريخ الكشف', DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards({
    required double totalSales,
    required double customerPaid,
    required double insuranceClaim,
    required int invoicesCount,
  }) {
    return pw.Row(
      children: [
        _summaryCard('إجمالي الفواتير', totalSales),
        pw.SizedBox(width: 8),
        _summaryCard('حصة الزبائن', customerPaid),
        pw.SizedBox(width: 8),
        _summaryCard('حصة التأمين', insuranceClaim),
        pw.SizedBox(width: 8),
        _summaryCard('عدد الفواتير', invoicesCount.toDouble(), isCount: true),
      ],
    );
  }

  static pw.Widget _summaryCard(
      String title,
      double value, {
        bool isCount = false,
      }) {
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

  static pw.Widget _invoiceTable(List<Sale> invoices) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('رقم الفاتورة', bold: true),
            _cell('التاريخ', bold: true),
            _cell('الإجمالي', bold: true),
            _cell('حصة الزبون', bold: true),
            _cell('حصة التأمين', bold: true),
            _cell('الحالة', bold: true),
          ],
        ),
        ...invoices.map((inv) {
          final insurancePart =
          (inv.insuranceClaimAmount ?? inv.insuranceDiscount ?? 0.0)
              .clamp(0.0, double.infinity);

          return pw.TableRow(
            children: [
              _cell(inv.invoiceNumber),
              _cell(_date.format(inv.saleDate)),
              _cell(_money.format(inv.subtotal)),
              _cell(_money.format(inv.paidAmount ?? inv.total)),
              _cell(_money.format(insurancePart)),
              _cell(_statusLabel(inv.status.name)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _totals({
    required double totalSales,
    required double customerPaid,
    required double insuranceClaim,
    required double totalReceivable,
  }) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 280,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _row('إجمالي الفواتير', '${_money.format(totalSales)} د.ل'),
            _row('حصة الزبائن', '${_money.format(customerPaid)} د.ل'),
            _row('حصة التأمين', '${_money.format(insuranceClaim)} د.ل'),
            pw.Divider(),
            _row(
              'المستحق على الشركة',
              '${_money.format(totalReceivable)} د.ل',
              bold: true,
            ),
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

  static String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      case 'pending':
      default:
        return 'معلقة';
    }
  }
}