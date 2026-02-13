// إنشاء ملف جديد: lib/views/sales/sales_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/sales_model.dart';

class SalesHistoryScreen extends StatelessWidget {
  final SalesController salesController = Get.find<SalesController>();

  SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سجل الفواتير'),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh),
            onPressed: () async {
              await salesController.loadSavedInvoices(forceRefresh: true);
              Get.snackbar('تم التحديث', 'تم تحديث قائمة الفواتير');
            },
          ),
        ],
      ),
      body: Obx(() {
        final allInvoices = salesController.allInvoices;
        final isLoading = salesController.isLoading.value;

        if (isLoading && allInvoices.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (allInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.receipt, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'لا توجد فواتير',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'لم يتم إنشاء أي فواتير بعد',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // فصل الفواتير المؤقتة والمكتملة
        final pendingInvoices = allInvoices
            .where((inv) => inv.status == InvoiceStatus.pending)
            .toList();

        final completedInvoices = allInvoices
            .where((inv) => inv.status == InvoiceStatus.completed)
            .toList();

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            // الفواتير المؤقتة
            if (pendingInvoices.isNotEmpty) ...[
              _buildSectionHeader('فواتير قيد التنفيذ (${pendingInvoices.length})'),
              ...pendingInvoices.map((invoice) => _buildInvoiceCard(invoice)),
              SizedBox(height: 16),
            ],

            // الفواتير المكتملة
            if (completedInvoices.isNotEmpty) ...[
              _buildSectionHeader('فواتير مكتملة (${completedInvoices.length})'),
              ...completedInvoices.map((invoice) => _buildInvoiceCard(invoice)),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Sale invoice) {
    final isPending = invoice.status == InvoiceStatus.pending;
    final iconColor = isPending ? Colors.orange : Colors.green;
    final statusText = isPending ? 'قيد التنفيذ' : 'مكتملة';
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPending ? Iconsax.receipt_edit : Iconsax.receipt,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'فاتورة #${invoice.invoiceNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPending ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPending ? Colors.orange[100]! : Colors.green[100]!,
                ),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: isPending ? Colors.orange[700] : Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${invoice.items.length} صنف • ${invoice.total.toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 2),
            Text(
              'التاريخ: ${dateFormat.format(invoice.saleDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            if (invoice.customerName?.isNotEmpty == true) ...[
              SizedBox(height: 2),
              Text(
                'العميل: ${invoice.customerName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Iconsax.arrow_left_3,
          color: Colors.grey[400],
          size: 18,
        ),
        onTap: () {
          if (isPending) {
            // تحميل الفاتورة المؤقتة للتحرير
            salesController.loadInvoiceForEditing(invoice);
            Get.back(); // العودة لشاشة البيع
          } else {
            // عرض تفاصيل الفاتورة المكتملة
           // Get.to(() => InvoiceDetailsScreen(invoice: invoice));
          }
        },
      ),
    );
  }
}
