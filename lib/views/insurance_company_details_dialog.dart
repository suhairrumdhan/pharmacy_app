// lib/views/insurance/insurance_company_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../controllers/insurance_company_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/insurance_company_model.dart';
import '../../models/sales_model.dart';
import '../../services/insurance_statement_service.dart';

class InsuranceCompanyDetailsDialog extends StatelessWidget {
  final InsuranceCompany company;

  const InsuranceCompanyDetailsDialog({
    super.key,
    required this.company,
  });

  String _money(num value) => '${value.toStringAsFixed(2)} د.ل';

  @override
  Widget build(BuildContext context) {
    final salesCtrl = Get.find<SalesController>();
    final insuranceCtrl = Get.find<InsuranceCompanyController>();

    return Obx(() {
      final currentCompany =
          insuranceCtrl.companies.firstWhereOrNull((c) => c.id == company.id) ??
              company;

      final insuranceInvoices = salesCtrl.historyInvoices
          .where(
            (sale) =>
        sale.insuranceCompanyId == currentCompany.id &&
            sale.type == SaleType.sale &&
            !sale.isDeleted,
      )
          .toList()
        ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

      final totalInvoices = insuranceInvoices.fold<double>(
        0,
            (sum, inv) => sum + inv.subtotal,
      );

      final totalCustomerPaid = insuranceInvoices.fold<double>(
        0,
            (sum, inv) => sum + (inv.paidAmount ?? inv.total),
      );

      final totalInsuranceClaim = insuranceInvoices.fold<double>(
        0,
            (sum, inv) =>
        sum + ((inv.insuranceClaimAmount ?? inv.insuranceDiscount ?? 0.0)),
      );

      return Container(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 900),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(context, currentCompany, insuranceInvoices),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFinancialSummary(
                      totalInvoices: totalInvoices,
                      totalCustomerPaid: totalCustomerPaid,
                      totalInsuranceClaim: totalInsuranceClaim,
                      totalCollected: currentCompany.effectiveTotalCollected,
                      currentReceivable: currentCompany.calculatedReceivable,
                      invoicesCount: insuranceInvoices.length,
                    ),
                    const SizedBox(height: 16),
                    _buildMainInfoCard(currentCompany),
                    const SizedBox(height: 16),
                    _buildContactInfoCard(currentCompany),
                    const SizedBox(height: 16),
                    _buildDiscountCard(currentCompany),
                    if (currentCompany.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildNotesCard(currentCompany),
                    ],
                    const SizedBox(height: 16),
                    _buildInvoicesSection(insuranceInvoices),
                    const SizedBox(height: 16),
                    _buildDatesCard(currentCompany),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(
      BuildContext context,
      InsuranceCompany currentCompany,
      List<Sale> invoices,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.building, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              currentCompany.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton.icon(
            onPressed: invoices.isEmpty
                ? null
                : () async {
              final settings = Get.isRegistered<SettingsController>()
                  ? Get.find<SettingsController>().currentSettings
                  : null;

              await InsuranceStatementService.previewStatement(
                context: context,
                company: currentCompany,
                invoices: invoices,
                pharmacyName: settings?.name.trim().isNotEmpty == true
                    ? settings!.name.trim()
                    : 'الصيدلية',
                pharmacyPhone: settings?.phoneNumber ?? '',
                pharmacyAddress: settings?.address ?? '',
              );
            },
            icon: const Icon(Iconsax.printer, size: 18),
            label: const Text('كشف مستحقات PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: invoices.isEmpty
                ? null
                : () async {
              final settings = Get.isRegistered<SettingsController>()
                  ? Get.find<SettingsController>().currentSettings
                  : null;

              await InsuranceStatementService.previewDetailedInvoices(
                context: context,
                company: currentCompany,
                invoices: invoices,
                pharmacyName: settings?.name.trim().isNotEmpty == true
                    ? settings!.name.trim()
                    : 'الصيدلية',
                pharmacyPhone: settings?.phoneNumber ?? '',
                pharmacyAddress: settings?.address ?? '',
              );
            },
            icon: const Icon(Iconsax.document_text, size: 18),
            label: const Text('تفاصيل الفواتير PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _showCollectInsuranceDialog(currentCompany),
            icon: const Icon(Iconsax.money_recive, size: 18),
            label: const Text('تسجيل تحصيل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: invoices.isEmpty
                ? null
                : () => _showInsuranceInvoicesDialog(currentCompany, invoices),
            icon: const Icon(Iconsax.receipt_text, size: 18),
            label: const Text('فواتير الشركة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  void _showCollectInsuranceDialog(InsuranceCompany currentCompany) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    String paymentMethod = 'cash';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('تسجيل تحصيل من ${currentCompany.name}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المستحق الحالي: ${_money(currentCompany.calculatedReceivable)}',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المحصل',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                      DropdownMenuItem(value: 'card', child: Text('معاملة مصرفية')),
                      DropdownMenuItem(value: 'bank', child: Text('تحويل مصرفي')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => paymentMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم المرجع / التحويل',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                  if (amount <= 0) {
                    Get.snackbar('تنبيه', 'أدخل مبلغ صحيح');
                    return;
                  }

                  final result =
                  await Get.find<InsuranceCompanyController>()
                      .collectInsurancePayment(
                    companyId: currentCompany.id,
                    amount: amount,
                    paymentMethod: paymentMethod,
                    collectionYear: DateTime.now().year,
                    collectionMonth: DateTime.now().month,
                    referenceNumber: refCtrl.text.trim().isEmpty
                        ? null
                        : refCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );

                  if (result == null) return;

                  Get.back();

                  final settings = Get.isRegistered<SettingsController>()
                      ? Get.find<SettingsController>().currentSettings
                      : null;

                  await InsuranceStatementService.previewInsuranceCollectionReceipt(
                    context: Get.context!,
                    company: currentCompany,
                    amount: result['amount'],
                    previousReceivable: result['previousReceivable'],
                    newReceivable: result['newReceivable'],
                    collectionYear: result['collectionYear'],
                    collectionMonth: result['collectionMonth'],
                    paymentMethod: result['paymentMethod'],
                    collectionId: result['collectionId'],
                    transactionId: result['transactionId'],
                    referenceNumber: result['referenceNumber'],
                    notes: result['notes'],
                    collectionDate: result['collectionDate'],
                    pharmacyName: settings?.name.trim().isNotEmpty == true
                        ? settings!.name.trim()
                        : 'الصيدلية',
                    pharmacyPhone: settings?.phoneNumber ?? '',
                    pharmacyAddress: settings?.address ?? '',
                  );
                },
                icon: const Icon(Iconsax.tick_circle),
                label: const Text('حفظ التحصيل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinancialSummary({
    required double totalInvoices,
    required double totalCustomerPaid,
    required double totalInsuranceClaim,
    required double totalCollected,
    required double currentReceivable,
    required int invoicesCount,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 220,
          child: _summaryCard(
            'إجمالي الفواتير',
            _money(totalInvoices),
            Iconsax.receipt,
            Colors.blue,
          ),
        ),
        SizedBox(
          width: 220,
          child: _summaryCard(
            'حصة الزبائن',
            _money(totalCustomerPaid),
            Iconsax.money_recive,
            Colors.green,
          ),
        ),
        SizedBox(
          width: 220,
          child: _summaryCard(
            'مطالبات التأمين',
            _money(totalInsuranceClaim),
            Iconsax.wallet_3,
            Colors.orange,
          ),
        ),
        SizedBox(
          width: 220,
          child: _summaryCard(
            'المحصل',
            _money(totalCollected),
            Iconsax.money_send,
            Colors.green,
          ),
        ),
        SizedBox(
          width: 220,
          child: _summaryCard(
            'المتبقي',
            _money(currentReceivable),
            Iconsax.warning_2,
            currentReceivable > 0 ? Colors.red : Colors.green,
          ),
        ),
        SizedBox(
          width: 220,
          child: _summaryCard(
            'عدد الفواتير',
            '$invoicesCount',
            Iconsax.document,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(InsuranceCompany currentCompany) {
    return _buildSection(
      title: 'معلومات الشركة',
      icon: Iconsax.information,
      children: [
        _buildDetailRow(Iconsax.code, 'الكود الموحد', currentCompany.code),
        _buildDetailRow(Iconsax.location, 'العنوان', currentCompany.address),
        _buildStatusRow(currentCompany.status),
      ],
    );
  }

  Widget _buildContactInfoCard(InsuranceCompany currentCompany) {
    return _buildSection(
      title: 'معلومات الاتصال',
      icon: Iconsax.call_calling,
      children: [
        _buildDetailRow(Iconsax.call, 'رقم الهاتف', currentCompany.phone),
        _buildDetailRow(Iconsax.user, 'الشخص المسؤول', currentCompany.contactPerson),
      ],
    );
  }

  Widget _buildDiscountCard(InsuranceCompany currentCompany) {
    return _buildSection(
      title: 'معلومات الخصم',
      icon: Iconsax.percentage_circle,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'نسبة الخصم المعتمدة',
                style: TextStyle(color: Colors.green.shade700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200, width: 1.5),
                ),
                child: Text(
                  currentCompany.formattedDiscount,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(InsuranceCompany currentCompany) {
    return _buildSection(
      title: 'ملاحظات',
      icon: Iconsax.note_text,
      children: [
        Text(
          currentCompany.notes,
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesSection(List<Sale> invoices) {
    return _buildSection(
      title: 'فواتير التأمين',
      icon: Iconsax.receipt_item,
      children: [
        if (invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'لا توجد فواتير مرتبطة بهذه الشركة',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          Column(
            children: [
              _invoiceHeader(),
              const SizedBox(height: 6),
              ...invoices.map(_invoiceRow),
            ],
          ),
      ],
    );
  }

  Widget _invoiceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('حصة الزبون', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('حصة التأمين', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _invoiceRow(Sale invoice) {
    final insurancePart =
    (invoice.insuranceClaimAmount ?? invoice.insuranceDiscount ?? 0.0)
        .clamp(0.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(DateFormat('yyyy/MM/dd').format(invoice.saleDate))),
          Expanded(child: Text(_money(invoice.subtotal))),
          Expanded(
            child: Text(
              _money(invoice.paidAmount ?? invoice.total),
              style: const TextStyle(color: Colors.green),
            ),
          ),
          Expanded(
            child: Text(
              _money(insurancePart),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(_statusLabel(invoice.status.name), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showInsuranceInvoicesDialog(
      InsuranceCompany currentCompany,
      List<Sale> invoices,
      ) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(22),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 980,
          height: 760,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.receipt_text, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'فواتير ${currentCompany.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${invoices.length} فاتورة',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Iconsax.close_circle, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, index) {
                    return _insuranceInvoiceFullCard(invoices[index], index + 1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _insuranceInvoiceFullCard(Sale invoice, int index) {
    final insurancePart =
    (invoice.insuranceClaimAmount ?? invoice.insuranceDiscount ?? 0.0)
        .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'فاتورة ${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _statusChip(_statusLabel(invoice.status.name), Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniInfo('التاريخ', DateFormat('yyyy/MM/dd').format(invoice.saleDate)),
              _miniInfo('الزبون', invoice.customerName ?? '--'),
              _miniInfo('إجمالي الفاتورة', _money(invoice.subtotal)),
              _miniInfo('حصة الزبون', _money(invoice.paidAmount ?? invoice.total)),
              _miniInfo('حصة التأمين', _money(insurancePart)),
              _miniInfo('عدد الأصناف', '${invoice.items.length}'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _itemsHeader(),
                const Divider(height: 14),
                ...invoice.items.map(_invoiceItemRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsHeader() {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('السعر', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w800))),
      ],
    );
  }

  Widget _invoiceItemRow(SaleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: Text('${item.quantity}')),
          Expanded(child: Text(_money(item.unitPrice))),
          Expanded(child: Text(_money(item.total))),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesCard(InsuranceCompany currentCompany) {
    return _buildSection(
      title: 'التواريخ',
      icon: Iconsax.calendar,
      children: [
        _buildDetailRow(Iconsax.calendar_add, 'تاريخ الإنشاء', _formatDate(currentCompany.createdAt)),
        _buildDetailRow(Iconsax.calendar_edit, 'آخر تحديث', _formatDate(currentCompany.updatedAt)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.65),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Iconsax.close_circle),
              label: const Text('إغلاق'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(Iconsax.status, color: _getStatusColor(status), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text('الحالة', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          _statusChip(status, _getStatusColor(status)),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'فعال':
        return Colors.green;
      case 'معلق':
        return Colors.orange;
      case 'متوقف':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}