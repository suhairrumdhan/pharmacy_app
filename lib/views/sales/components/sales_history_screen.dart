import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../controllers/sales_controller.dart';
import '../../../models/sales_model.dart';

enum HistoryFilter { today, all }

class SalesHistoryScreen extends StatelessWidget {
  final SalesController salesController = Get.find<SalesController>();

  SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = HistoryFilter.today.obs;

    // أول ما تفتح الصفحة: حمّل اليوم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      salesController.loadMyHistoryToday();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل فواتيري'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () async {
              if (filter.value == HistoryFilter.today) {
                await salesController.loadMyHistoryToday();
              } else {
                await salesController.loadMyHistoryAll();
              }
              Get.snackbar('تم التحديث', 'تم تحديث القائمة');
            },
          ),
        ],
      ),
      body: Obx(() {
        final allInvoices = salesController.allInvoices;
        final isLoading = salesController.isLoading.value;

        // تقسيم
        final pending = allInvoices.where((s) => s.status == InvoiceStatus.pending).toList();
        final completed = allInvoices.where((s) => s.status == InvoiceStatus.completed && !s.isDeleted).toList();

        // إجماليات (completed فقط)
        double cashTotal = 0, cardTotal = 0, insTotal = 0;
        for (final s in completed) {
          switch (s.paymentMethod) {
            case PaymentMethod.cash: cashTotal += s.total; break;
            case PaymentMethod.card: cardTotal += s.total; break;
            case PaymentMethod.insurance: insTotal += s.total; break;
          }
        }
        final grandTotal = cashTotal + cardTotal + insTotal;

        if (isLoading && allInvoices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ===== Summary + Filter + Close =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  _SummaryCard(
                    totalCount: allInvoices.length,
                    pendingCount: pending.length,
                    completedCount: completed.length,
                    cashTotal: cashTotal,
                    cardTotal: cardTotal,
                    insuranceTotal: insTotal,
                    grandTotal: grandTotal,
                    isToday: filter.value == HistoryFilter.today,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterPill(
                          label: 'اليوم',
                          selected: filter.value == HistoryFilter.today,
                          onTap: () async {
                            filter.value = HistoryFilter.today;
                            await salesController.loadMyHistoryToday();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterPill(
                          label: 'الكل',
                          selected: filter.value == HistoryFilter.all,
                          onTap: () async {
                            filter.value = HistoryFilter.all;
                            await salesController.loadMyHistoryAll();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Iconsax.tick_circle),
                        label: const Text('إقفال اليوم'),
                        onPressed: (filter.value != HistoryFilter.today || completed.isEmpty)
                            ? null
                            : () async {
                          try {
                            final payload = await salesController.closeMyDay();
                            final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

                            Get.bottomSheet(
                              _CloseResultSheet(
                                dateStr: date,
                                completedCount: payload['completedCount'] ?? 0,
                                cashTotal: (payload['cashTotal'] ?? 0).toDouble(),
                                cardTotal: (payload['cardTotal'] ?? 0).toDouble(),
                                insuranceTotal: (payload['insuranceTotal'] ?? 0).toDouble(),
                                grandTotal: (payload['grandTotal'] ?? 0).toDouble(),
                              ),
                              isScrollControlled: true,
                            );
                          } catch (e) {
                            Get.snackbar('تنبيه', e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ===== List =====
            Expanded(
              child: allInvoices.isEmpty
                  ? _EmptyState()
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (pending.isNotEmpty) ...[
                    _section('قيد التنفيذ (${pending.length})'),
                    ...pending.map(_invoiceCard),
                    const SizedBox(height: 16),
                  ],
                  if (completed.isNotEmpty) ...[
                    _section('مكتملة (${completed.length})'),
                    ...completed.map(_invoiceCard),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
  );

  Widget _invoiceCard(Sale invoice) {
    final isPending = invoice.status == InvoiceStatus.pending;
    final iconColor = isPending ? Colors.orange : Colors.green;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(isPending ? Iconsax.receipt_edit : Iconsax.receipt, color: iconColor, size: 20),
        ),
        title: Text('فاتورة #${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${invoice.items.length} صنف • ${invoice.total.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 2),
            Text('التاريخ: ${dateFormat.format(invoice.saleDate)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        trailing: Icon(Iconsax.arrow_left_3, color: Colors.grey[400], size: 18),
        onTap: () {
          salesController.switchToInvoice(invoice);
          Get.back();
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Iconsax.receipt, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('لا توجد فواتير', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text('لم يتم إنشاء أي فواتير بعد', style: TextStyle(color: Colors.grey[500])),
      ]),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.blue.withOpacity(0.35) : Colors.grey[200]!),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.blue[800] : Colors.grey[700])),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final int completedCount;
  final double cashTotal;
  final double cardTotal;
  final double insuranceTotal;
  final double grandTotal;
  final bool isToday;

  const _SummaryCard({
    required this.totalCount,
    required this.pendingCount,
    required this.completedCount,
    required this.cashTotal,
    required this.cardTotal,
    required this.insuranceTotal,
    required this.grandTotal,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.chart_2, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isToday ? 'ملخص اليوم' : 'ملخص عام', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('الإجمالي: ${grandTotal.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[800])),
                    const SizedBox(height: 2),
                    Text('عدد: $totalCount • مكتملة: $completedCount • معلقة: $pendingCount', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _mini('نقدي', cashTotal)),
                const SizedBox(width: 8),
                Expanded(child: _mini('بطاقة', cardTotal)),
                const SizedBox(width: 8),
                Expanded(child: _mini('تأمين', insuranceTotal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, double v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(v.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CloseResultSheet extends StatelessWidget {
  final String dateStr;
  final int completedCount;
  final double cashTotal, cardTotal, insuranceTotal, grandTotal;

  const _CloseResultSheet({
    required this.dateStr,
    required this.completedCount,
    required this.cashTotal,
    required this.cardTotal,
    required this.insuranceTotal,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(Iconsax.clipboard_tick),
              SizedBox(width: 8),
              Text('تم إقفال اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _row('التاريخ', dateStr),
          _row('عدد الفواتير', '$completedCount'),
          _row('نقدي', cashTotal.toStringAsFixed(2)),
          _row('بطاقة', cardTotal.toStringAsFixed(2)),
          _row('تأمين', insuranceTotal.toStringAsFixed(2)),
          const Divider(),
          _row('الإجمالي', grandTotal.toStringAsFixed(2)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: TextStyle(color: Colors.grey[700]))),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
