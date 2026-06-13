// lib/views/suppliers/supplier_details_dialog.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../controllers/purchase_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/purchase_model.dart';
import '../../models/supplier_model.dart';
import '../../services/supplier_statement_service.dart';

class SupplierDetailsDialog extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailsDialog({
    super.key,
    required this.supplier,
  });

  String _money(num value) => '${value.toStringAsFixed(2)} د.ل';

  @override
  Widget build(BuildContext context) {
    final purchaseCtrl = Get.find<PurchaseController>();

    final supplierInvoices = purchaseCtrl.invoices
        .where((inv) => inv.supplierId == supplier.id)
        .toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    final totalPurchases =
    supplierInvoices.fold<double>(0, (sum, inv) => sum + inv.total);
    final totalPaid =
    supplierInvoices.fold<double>(0, (sum, inv) => sum + inv.paid);
    final totalDue =
    supplierInvoices.fold<double>(0, (sum, inv) => sum + inv.remaining);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980, maxHeight: 900),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context, supplierInvoices),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFinancialSummary(
                      totalPurchases: totalPurchases,
                      totalPaid: totalPaid,
                      totalDue: totalDue,
                      invoicesCount: supplierInvoices.length,
                    ),
                    const SizedBox(height: 16),
                    _buildBasicInfo(),
                    const SizedBox(height: 16),
                    _buildContractInfo(),
                    if (supplier.suppliedMedications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildMedicationsSection(),
                    ],
                    if (supplier.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildNotesSection(),
                    ],
                    const SizedBox(height: 16),
                    _buildInvoicesSection(supplierInvoices),
                    const SizedBox(height: 16),
                    _buildExtraInfo(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<PurchaseInvoice> invoices) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.buildings_2,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تفاصيل المورد - ${supplier.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: invoices.isEmpty
                ? null
                : () async {
              final settings = Get.isRegistered<SettingsController>()
                  ? Get.find<SettingsController>().currentSettings
                  : null;

              await SupplierStatementService.previewStatement(
                context: context,
                supplier: supplier,
                invoices: invoices,
                pharmacyName: settings?.name.trim().isNotEmpty == true
                    ? settings!.name.trim()
                    : 'الصيدلية',
                pharmacyPhone: settings?.phoneNumber ?? '',
                pharmacyAddress: settings?.address ?? '',
              );
            },
            icon: const Icon(Iconsax.printer, size: 18),
            label: const Text('كشف حساب PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: invoices.isEmpty
                ? null
                : () => _showSupplierInvoicesDialog(invoices),
            icon: const Icon(Iconsax.receipt_text, size: 18),
            label: const Text('فواتير الشركة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade200),
            ),
          ),

          const SizedBox(width: 10),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Iconsax.close_circle,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }
  void _showSupplierInvoicesDialog(List<PurchaseInvoice> invoices) {
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.receipt_text, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'فواتير ${supplier.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${invoices.length} فاتورة',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
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
                    return _supplierInvoiceFullCard(invoices[index], index + 1);
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
  Widget _supplierInvoiceFullCard(PurchaseInvoice invoice, int index) {
    final remaining = invoice.remaining;
    final statusColor = remaining <= 0 ? Colors.green : Colors.orange;

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
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(.25)),
                ),
                child: Text(
                  _paymentStatusLabel(invoice.paymentStatus.name),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniInfo('التاريخ', DateFormat('yyyy/MM/dd').format(invoice.invoiceDate)),
              _miniInfo('تاريخ الاستلام', invoice.receivedDate == null ? '--' : DateFormat('yyyy/MM/dd').format(invoice.receivedDate!)),
              _miniInfo('رقم المورد', invoice.referenceNumber ?? '--'),
              _miniInfo('تاريخ الاستحقاق', invoice.dueDate == null ? '--' : DateFormat('yyyy/MM/dd').format(invoice.dueDate!)),
              _miniInfo('الإجمالي', _money(invoice.total)),
              _miniInfo('المدفوع', _money(invoice.paid)),
              _miniInfo('المتبقي', _money(invoice.remaining)),
            ],
          ),

          if ((invoice.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'ملاحظات: ${invoice.notes}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],

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
  Widget _miniInfo(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  Widget _itemsHeader() {
    return Row(
      children: const [
        Expanded(flex: 3, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('السعر', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text('الصلاحية', style: TextStyle(fontWeight: FontWeight.w800))),
      ],
    );
  }

  Widget _invoiceItemRow(PurchaseItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.medicineName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: Text('${item.quantity}')),
          Expanded(child: Text(_money(item.price))),
          Expanded(child: Text(_money(item.subtotal))),
          Expanded(
            child: Text(
              item.expiryDate == null
                  ? '--'
                  : DateFormat('yyyy/MM/dd').format(item.expiryDate!),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFinancialSummary({
    required double totalPurchases,
    required double totalPaid,
    required double totalDue,
    required int invoicesCount,
  }) {
    return Row(
      children: [
        _summaryCard('إجمالي المشتريات', _money(totalPurchases), Iconsax.receipt, Colors.blue),
        const SizedBox(width: 12),
        _summaryCard('المدفوع', _money(totalPaid), Iconsax.money_send, Colors.green),
        const SizedBox(width: 12),
        _summaryCard('المتبقي', _money(totalDue), Iconsax.warning_2, totalDue > 0 ? Colors.orange : Colors.green),
        const SizedBox(width: 12),
        _summaryCard('عدد الفواتير', '$invoicesCount', Iconsax.document, Colors.purple),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
                  Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection(
      title: 'المعلومات الأساسية',
      icon: Iconsax.information,
      children: [
        _buildDetailRow(Iconsax.user, 'الشخص المسؤول', supplier.contactPerson, Colors.blue.shade700),
        _buildDetailRow(Iconsax.call, 'رقم الهاتف', supplier.phone, Colors.blue.shade700),
        _buildDetailRow(Iconsax.location, 'العنوان', supplier.address, Colors.blue.shade700),
      ],
    );
  }

  Widget _buildContractInfo() {
    return _buildSection(
      title: 'معلومات التعاقد',
      icon: Iconsax.document,
      children: [
        _buildDetailRow(
          Iconsax.calendar_1,
          'تاريخ بدء التعاقد',
          DateFormat('yyyy-MM-dd').format(supplier.contractStartDate),
          Colors.blue.shade700,
        ),
        _buildDetailRow(
          Iconsax.calendar_tick,
          'تاريخ نهاية التعاقد',
          supplier.contractEndDate != null
              ? DateFormat('yyyy-MM-dd').format(supplier.contractEndDate!)
              : 'غير محدد',
          supplier.contractEndDate != null ? Colors.blue.shade700 : Colors.grey,
        ),
        _buildStatusRow(status: supplier.status, color: _getStatusColor(supplier.status)),
      ],
    );
  }

  Widget _buildMedicationsSection() {
    return _buildSection(
      title: 'الأدوية الموردة',
      icon: Iconsax.health,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: supplier.suppliedMedications.map((medication) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                medication,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'ملاحظات',
      icon: Iconsax.note_text,
      children: [
        Text(
          supplier.notes,
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesSection(List<PurchaseInvoice> invoices) {
    return _buildSection(
      title: 'فواتير المورد',
      icon: Iconsax.receipt_item,
      children: [
        if (invoices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'لا توجد فواتير شراء لهذا المورد',
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
          Expanded(child: Text('المدفوع', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _invoiceRow(PurchaseInvoice invoice) {
    final remaining = invoice.remaining;
    final statusColor = remaining <= 0 ? Colors.green : Colors.orange;

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
          Expanded(flex: 2, child: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(DateFormat('yyyy/MM/dd').format(invoice.invoiceDate))),
          Expanded(child: Text(_money(invoice.total))),
          Expanded(child: Text(_money(invoice.paid), style: const TextStyle(color: Colors.green))),
          Expanded(child: Text(_money(remaining), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _paymentStatusLabel(invoice.paymentStatus.name),
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraInfo() {
    return _buildSection(
      title: 'المعلومات الإضافية',
      icon: Iconsax.calendar,
      children: [
        _buildDetailRow(
          Iconsax.calendar_add,
          'تاريخ الإنشاء',
          DateFormat('yyyy-MM-dd HH:mm').format(supplier.createdAt),
          Colors.blue.shade700,
        ),
        _buildDetailRow(
          Iconsax.refresh,
          'آخر تحديث',
          DateFormat('yyyy-MM-dd HH:mm').format(supplier.updatedAt),
          Colors.blue.shade700,
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(color: Colors.blue.shade100.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String status,
    required Color color,
  }) {
    return _buildDetailRow(Iconsax.status, 'الحالة', status, color);
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

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مسددة';
      case 'partiallyPaid':
        return 'جزئية';
      case 'unpaid':
      default:
        return 'غير مسددة';
    }
  }
}