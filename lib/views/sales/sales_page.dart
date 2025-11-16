import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sales_controller.dart';
import '../../dialog/new_sale_dialog.dart';
import '../../models/sales_model.dart';

class SalesPage extends StatelessWidget {
  SalesPage({super.key});
  final SalesController salesController = Get.put(SalesController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // شريط الإحصائيات السريعة
          _buildQuickStats(),
          const SizedBox(height: 24),

          // شريط الأدوات
          _buildToolbar(context),
          const SizedBox(height: 24),

          // قائمة المبيعات
          Expanded(
            child: _buildSalesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Obx(() {
      final summary = salesController.salesSummary.value;
      return Row(
        children: [
          _buildStatItem("مبيعات اليوم", "${summary.todaySales.toStringAsFixed(2)} ريال", Colors.green),
          const SizedBox(width: 16),
          _buildStatItem("مبيعات الشهر", "${summary.monthlySales.toStringAsFixed(2)} ريال", Colors.blue),
          const SizedBox(width: 16),
          _buildStatItem("عدد المعاملات", summary.totalTransactions.toString(), Colors.orange),
          const SizedBox(width: 16),
          _buildStatItem("متوسط البيع", "${summary.averageSale.toStringAsFixed(2)} ريال", Colors.purple),
        ],
      );
    });
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("بيع جديد"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const NewSaleDialog(),
            );
          },
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.filter_list),
          label: const Text("تصفية"),
          onPressed: () {},
        ),
        const Spacer(),
        SizedBox(
          width: 300,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'بحث في المبيعات...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesList() {
    return Obx(() {
      if (salesController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // رأس الجدول
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text("العميل", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("المبلغ", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("الطريقة", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("التاريخ", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text("الحالة", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 80), // مساحة للأزرار
                ],
              ),
            ),

            // قائمة المبيعات
            Expanded(
              child: ListView.builder(
                itemCount: salesController.sales.length,
                itemBuilder: (context, index) {
                  final sale = salesController.sales[index];
                  return SaleListItem(sale: sale);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class SaleListItem extends StatelessWidget {
  final Sale sale;
  final SalesController salesController = Get.find();

  SaleListItem({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sale.customerPhone,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text("${sale.finalAmount.toStringAsFixed(2)} ريال"),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor(sale.paymentMethod),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getPaymentMethodText(sale.paymentMethod),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text(_formatDate(sale.saleDate)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(sale.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(sale.status),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, size: 18),
                  onPressed: () {
                    _showSaleDetails(context, sale);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    salesController.deleteSale(sale.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'cash': return Colors.green;
      case 'card': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash': return 'نقدي';
      case 'card': return 'بطاقة';
      default: return method;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return 'مكتمل';
      case 'pending': return 'قيد الانتظار';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSaleDetails(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل البيع'),
        content: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('العميل: ${sale.customerName}'),
              Text('الهاتف: ${sale.customerPhone}'),
              const SizedBox(height: 16),
              const Text('الأدوية:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...sale.items.map((item) =>
                  Text('${item.medicineName} - ${item.quantity} × ${item.price} ريال')
              ),
              const SizedBox(height: 16),
              Text('الإجمالي: ${sale.totalAmount} ريال'),
              Text('الخصم: ${sale.discount} ريال'),
              Text('الضريبة: ${sale.tax} ريال'),
              Text('المبلغ النهائي: ${sale.finalAmount} ريال'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}