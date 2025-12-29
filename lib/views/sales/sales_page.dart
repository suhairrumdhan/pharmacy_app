// lib/views/sales/sales_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../controllers/insurance_company_controller.dart';
import '../../models/inventory_model.dart';
import '../../models/sales_model.dart';
import '../../models/insurance_company_model.dart';

class SalesPage extends StatelessWidget {
  SalesPage({super.key});
  final SalesController salesController = Get.put(SalesController());
  final InventoryController inventoryController = Get.find<InventoryController>();
  final InsuranceCompanyController insuranceController = Get.find<InsuranceCompanyController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الجانب الأيسر: قائمة المنتجات والبحث
            Expanded(
              flex: 5,
              child: _buildLeftPanel(),
            ),

            const SizedBox(width: 16),

            // الجانب الأيمن: الفاتورة والدفع
            Expanded(
              flex: 3,
              child: _buildRightPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        // شريط البحث
        _buildSearchCard(),

        const SizedBox(height: 12),

        // نتائج البحث
        Expanded(
          child: _buildSearchResultsCard(),
        ),

        const SizedBox(height: 12),

        // قائمة المنتجات المضافة
        Expanded(
          flex: 2,
          child: _buildCurrentSaleCard(),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        // معلومات الفاتورة
        _buildInvoiceHeaderCard(),

        const SizedBox(height: 12),

        // تفاصيل الدفع
        Expanded(
          child: _buildPaymentCard(),
        ),

        const SizedBox(height: 12),

        // زر إنهاء البيع
        _buildCheckoutButton(),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: TextEditingController(text: salesController.searchQuery.value),
                        onChanged: (value) {
                          salesController.searchQuery.value = value;
                          salesController.searchMedicines(value);
                        },
                        decoration: InputDecoration(
                          hintText: '🔍 ابحث بالاسم، الباركود أو العلمي...',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Iconsax.scan_barcode,
                              color: Colors.blue[700],
                              size: 22,
                            ),
                            onPressed: salesController.toggleBarcodeScanner,
                            tooltip: 'مسح باركود',
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => salesController.isScanning.value
                      ? Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: IconButton(
                      onPressed: () {
                        salesController.toggleBarcodeScanner();
                      },
                      icon: Icon(
                        Iconsax.close_circle,
                        color: Colors.red[700],
                        size: 22,
                      ),
                      tooltip: 'إلغاء المسح',
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _showBarcodeScannerDialog();
                      },
                      icon: Icon(
                        Iconsax.scan,
                        color: Colors.blue[700],
                        size: 22,
                      ),
                      tooltip: 'مسح باركود',
                    ),
                  ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // فلاتر سريعة
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('🏥 كل المنتجات', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('⚠️ منخفض المخزون', false, () {
                      salesController.searchQuery.value = '';
                      salesController.searchResults.assignAll(
                        inventoryController.lowStockMedicines,
                      );
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('🔥 الأكثر مبيعاً', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('🆕 جديد', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // عنوان القسم
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.search_status,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نتائج البحث',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Obx(() => Text(
                    '${salesController.searchResults.length} منتج',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  )),
                ],
              ),
            ),

            // قائمة النتائج
            Expanded(
              child: Obx(() {
                if (salesController.searchResults.isEmpty && salesController.searchQuery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.search_normal,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ابدأ بالبحث عن منتجات',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (salesController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: salesController.searchResults.length,
                  itemBuilder: (context, index) {
                    final medicine = salesController.searchResults[index];
                    return _buildMedicineItem(medicine);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(Medicine medicine) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: medicine.imageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              medicine.imageUrl!,
              fit: BoxFit.cover,
            ),
          )
              : Icon(
            Iconsax.medal_star,
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        title: Text(
          medicine.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          medicine.scientificName,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(medicine.sellingPrice ?? 0).toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: medicine.isLowStock ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: medicine.isLowStock ? Colors.orange[100]! : Colors.green[100]!,
                ),
              ),
              child: Text(
                '${medicine.quantity} متبقي',
                style: TextStyle(
                  fontSize: 10,
                  color: medicine.isLowStock ? Colors.orange[700] : Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showAddQuantityDialog(medicine),
      ),
    );
  }

  Widget _buildCurrentSaleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // عنوان الفاتورة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.receipt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        'فاتورة #${salesController.currentSale.value.invoiceNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      )),
                      Obx(() => Text(
                        '${salesController.currentSale.value.items.length} أصناف',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Iconsax.refresh,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    onPressed: salesController.resetSale,
                    tooltip: 'فاتورة جديدة',
                  ),
                ],
              ),
            ),

            // قائمة الأصناف
            Expanded(
              child: Obx(() {
                final items = salesController.currentSale.value.items;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.shopping_cart,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'السلة فارغة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'ابحث وأضف منتجات للفاتورة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildSaleItem(items[index], index);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItem(SaleItem item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.scientificName != null)
              Text(
                item.scientificName!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                if (item.discountAmount != null || item.discountPercentage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.discountAmount != null
                            ? 'خصم ${item.discountAmount!.toStringAsFixed(2)}'
                            : '${item.discountPercentage}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'د.ل ${item.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  icon: Iconsax.edit_2,
                  color: Colors.blue,
                  onTap: () => _showEditItemDialog(index),
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Iconsax.trash,
                  color: Colors.red,
                  onTap: () => salesController.removeItem(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  Widget _buildInvoiceHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.receipt_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فاتورة البيع',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Obx(() => Text(
                        '#${salesController.currentSale.value.invoiceNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // المجموع الإجمالي
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'المجموع الإجمالي',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    Obx(() {
                      final total = salesController.currentSale.value.total;
                      return Text(
                        '${total.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طريقة الدفع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 12),

              // طرق الدفع
              Obx(() {
                final currentMethod = salesController.currentSale.value.paymentMethod;
                return Row(
                  children: [
                    _buildPaymentMethodChip(
                      '💵 نقدي',
                      currentMethod == PaymentMethod.cash,
                          () => salesController.changePaymentMethod(PaymentMethod.cash),
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodChip(
                      '💳 بطاقة',
                      currentMethod == PaymentMethod.card,
                          () => salesController.changePaymentMethod(PaymentMethod.card),
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodChip(
                      '🏥 تأمين',
                      currentMethod == PaymentMethod.insurance,
                          () => salesController.changePaymentMethod(PaymentMethod.insurance),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // تفاصيل الدفع النقدي
              Obx(() {
                if (salesController.currentSale.value.paymentMethod != PaymentMethod.cash) {
                  return Container();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ المستلم',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0.0;
                          salesController.setCashReceived(amount);
                        },
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ المستلم',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixText: 'ر.س',
                          suffixStyle: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    Obx(() {
                      final change = salesController.changeAmount.value;
                      final received = salesController.cashReceived.value;
                      final total = salesController.currentSale.value.total;

                      if (change > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.money_send,
                                color: Colors.green[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'المبلغ المتبقي: ${change.toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (received > 0 && received < total) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: Colors.orange[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ناقص: ${(total - received).toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container();
                    }),
                  ],
                );
              }),

              // اختيار شركة التأمين
              Obx(() {
                if (salesController.currentSale.value.paymentMethod != PaymentMethod.insurance) {
                  return Container();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'شركة التأمين',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<InsuranceCompany>(
                            value: salesController.selectedInsuranceCompany.value,
                            items: salesController.insuranceCompanies.map((company) {
                              return DropdownMenuItem(
                                value: company,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Iconsax.shield_tick,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            company.name,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          Text(
                                            'خصم ${company.discountPercentage}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (company) => salesController.selectInsuranceCompany(company),
                            isExpanded: true,
                            hint: Text(
                              'اختر شركة التأمين',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Iconsax.arrow_down_1,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // معلومات الزبون
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                leading: Icon(
                  Iconsax.user,
                  color: Colors.blue[700],
                  size: 20,
                ),
                title: Text(
                  'معلومات الزبون (اختياري)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                children: [
                  Column(
                    children: [
                      _buildCustomerField(
                        '👤 اسم الزبون',
                        salesController.customerNameController,
                      ),
                      const SizedBox(height: 8),
                      _buildCustomerField(
                        '📞 رقم الجوال',
                        salesController.customerPhoneController,
                        TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: salesController.notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: '💬 ملاحظات إضافية',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue[700] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.blue[700]! : Colors.grey[200]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerField(String hint, TextEditingController controller, [TextInputType keyboardType = TextInputType.text]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Obx(() {
      final sale = salesController.currentSale.value;
      final isLoading = salesController.isLoading.value;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: sale.items.isEmpty || isLoading
              ? null
              : () => _showCheckoutConfirmation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.receipt_discount,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'إنهاء البيع وطباعة الفاتورة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ===== الدوال المساعدة =====
  void _showAddQuantityDialog(Medicine medicine) {
    int quantity = 1;

    showDialog(
      context: Get.context!,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      Iconsax.add_circle,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إضافة ${medicine.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المخزون المتوفر: ${medicine.quantity}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Iconsax.minus,
                          color: Colors.red[700],
                          size: 32,
                        ),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          Iconsax.add_circle,
                          color: Colors.green[700],
                          size: 32,
                        ),
                        onPressed: quantity < medicine.quantity
                            ? () => setState(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Future.microtask(() {
                      salesController.addMedicineToSale(
                        medicine,
                        quantity: quantity,
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditItemDialog(int index) {
    final item = salesController.currentSale.value.items[index];
    int quantity = item.quantity;

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
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
                Iconsax.edit_2,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'تعديل ${item.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'السعر: ${item.unitPrice.toStringAsFixed(2)} ر.س',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.minus,
                    color: Colors.red[700],
                    size: 32,
                  ),
                  onPressed: () {
                    if (quantity > 1) quantity--;
                    (context as Element).markNeedsBuild();
                  },
                ),
                const SizedBox(width: 24),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    Iconsax.add_circle,
                    color: Colors.green[700],
                    size: 32,
                  ),
                  onPressed: () {
                    quantity++;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              salesController.updateQuantity(index, quantity);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeScannerDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
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
                Iconsax.scan_barcode,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'مسح الباركود',
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.scan,
                size: 48,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اضغط لبدء مسح الباركود',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'أو أدخل الباركود يدوياً',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Iconsax.keyboard,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    salesController.searchByBarcode(value);
                    Get.back();
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutConfirmation() {
    final sale = salesController.currentSale.value;

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.tick_circle,
                color: Colors.green[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد عملية البيع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الفاتورة:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildConfirmationRow('📊 عدد الأصناف', '${sale.items.length}'),
            _buildConfirmationRow('💰 المجموع', '${sale.total.toStringAsFixed(2)} ر.س'),
            _buildConfirmationRow('💳 طريقة الدفع', sale.paymentMethod.arabicName),
            if (sale.insuranceCompanyName != null)
              _buildConfirmationRow('🏥 شركة التأمين', sale.insuranceCompanyName!),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    color: Colors.blue[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هل أنت متأكد من إنهاء البيع؟',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await salesController.saveSale();
              if (success) {
                _showReceiptOptions();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تأكيد وطباعة'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptOptions() {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
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
            const SizedBox(height: 20),
            const Text(
              'تم حفظ الفاتورة بنجاح.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'هل تريد طباعة الفاتورة؟',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'لاحقاً',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _printReceipt();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('نعم، اطبع'),
          ),
        ],
      ),
    );
  }

  void _printReceipt() {
    Get.snackbar(
      'طباعة الفاتورة',
      '✅ سيتم إرسال الفاتورة للطباعة',
      backgroundColor: Colors.green[700],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}