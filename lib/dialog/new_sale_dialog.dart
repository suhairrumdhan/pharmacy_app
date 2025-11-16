import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';
import '../models/sales_model.dart';

class NewSaleDialog extends StatefulWidget {
  const NewSaleDialog({super.key});

  @override
  State<NewSaleDialog> createState() => _NewSaleDialogState();
}

class _NewSaleDialogState extends State<NewSaleDialog> {
  final SalesController salesController = Get.find();
  final _formKey = GlobalKey<FormState>();

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final List<SaleItem> items = [];
  double totalAmount = 0;
  double discount = 0;
  double tax = 0;
  double finalAmount = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'بيع جديد',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // معلومات العميل
                      _buildCustomerInfo(),
                      const SizedBox(height: 20),

                      // قائمة الأدوية
                      _buildItemsList(),
                      const SizedBox(height: 20),

                      // الملخص
                      _buildSummary(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('معلومات العميل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم العميل';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('الأدوية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة دواء'),
                  onPressed: _showAddItemDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Text('لم يتم إضافة أي أدوية بعد'),
              )
            else
              ..._buildItemsTable(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemsTable() {
    return [
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('الدواء', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ...items.map((item) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item.medicineName),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${item.price} ريال'),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item.quantity.toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${item.total} ريال'),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(item),
                ),
              ),
            ],
          )),
        ],
      ),
    ];
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الملخص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: discount.toString(),
                    decoration: const InputDecoration(
                      labelText: 'الخصم (ريال)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        discount = double.tryParse(value) ?? 0;
                        _calculateFinalAmount();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: tax.toString(),
                    decoration: const InputDecoration(
                      labelText: 'الضريبة (ريال)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        tax = double.tryParse(value) ?? 0;
                        _calculateFinalAmount();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('الإجمالي', '$totalAmount ريال'),
            _buildSummaryRow('الخصم', '$discount ريال'),
            _buildSummaryRow('الضريبة', '$tax ريال'),
            _buildSummaryRow('المبلغ النهائي', '$finalAmount ريال', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _completeSale,
          child: const Text('إتمام البيع'),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    // TODO: تنفيذ نافذة إضافة دواء للبيع
    // بيانات تجريبية
    final newItem = SaleItem(
      medicineId: 'temp',
      medicineName: 'دواء تجريبي',
      quantity: 1,
      price: 50.0,
      total: 50.0,
    );

    setState(() {
      items.add(newItem);
      _calculateTotalAmount();
    });
  }

  void _removeItem(SaleItem item) {
    setState(() {
      items.remove(item);
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    totalAmount = items.fold(0, (sum, item) => sum + item.total);
    _calculateFinalAmount();
  }

  void _calculateFinalAmount() {
    finalAmount = totalAmount - discount + tax;
  }

  void _completeSale() {
    if (_formKey.currentState!.validate() && items.isNotEmpty) {
      final newSale = Sale(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: customerNameController.text,
        customerPhone: customerPhoneController.text,
        items: items,
        totalAmount: totalAmount,
        discount: discount,
        tax: tax,
        finalAmount: finalAmount,
        saleDate: DateTime.now(),
        paymentMethod: 'cash',
        status: 'completed',
      );

      salesController.addSale(newSale);
      Navigator.pop(context);
    } else if (items.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إضافة أدوية للبيع');
    }
  }
}