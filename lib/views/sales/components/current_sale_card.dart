import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_desktop/views/sales/components/sales_history_screen.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/sales_model.dart';
import '../dialogs/edit_item_dialog.dart';
import 'sale_item.dart';

class CurrentSaleCard extends StatelessWidget {
  final SalesController salesController;

  const CurrentSaleCard({super.key, required this.salesController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allUserInvoices = salesController.allUserInvoices;
      final currentSale = salesController.currentSale.value;
      final activeInvoices = salesController.activeInvoices;
      final userCompletedInvoices = salesController.userCompletedInvoices;
      final items = currentSale.items;

      // البحث عن الفهرس الحالي في جميع الفواتير
      final currentIndex = allUserInvoices.indexWhere(
              (inv) => inv.invoiceNumber == currentSale.invoiceNumber
      );

      final hasPrevious = currentIndex > 0;
      final hasNext = currentIndex < allUserInvoices.length - 1;

      // فرز الفواتير: المؤقتة أولاً، ثم المكتملة بالأحدث
      final sortedInvoices = List<Sale>.from(allUserInvoices)
        ..sort((a, b) {
          // الفواتير المؤقتة أولاً
          if (a.status == InvoiceStatus.pending &&
              b.status != InvoiceStatus.pending) return -1;
          if (a.status != InvoiceStatus.pending &&
              b.status == InvoiceStatus.pending) return 1;

          // ثم الفواتير المكتملة من الأحدث للأقدم
          return b.saleDate.compareTo(a.saleDate);
        });

      // البحث عن الفهرس بعد الفرز
      final sortedIndex = sortedInvoices.indexWhere(
              (inv) => inv.invoiceNumber == currentSale.invoiceNumber
      );

      // السماح بالحذف فقط للفواتير قيد التنفيذ وغير المحفوظة
      final canDelete = activeInvoices.length > 1 &&
          !currentSale.isSaved &&
          currentSale.status != InvoiceStatus.completed;

      // لون الهيدر بناءً على حالة الفاتورة
      Color headerColor = Colors.blue[50]!;
      Color iconColor = Colors.blue[700]!;
      String statusText = 'قيد التنفيذ';

      if (currentSale.isSaved) {
        headerColor = Colors.green[50]!;
        iconColor = Colors.green[700]!;
        statusText = 'مكتملة';
      } else if (currentSale.status == InvoiceStatus.cancelled) {
        headerColor = Colors.red[50]!;
        iconColor = Colors.red[700]!;
        statusText = 'ملغية';
      }

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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    // الصف الأول: معلومات الفاتورة
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            currentSale.isSaved ? Iconsax.receipt : Iconsax.receipt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Invoice info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'فاتورة #${currentSale.invoiceNumber}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: iconColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (currentSale.isSaved) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'محفوظة',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${items.length} أصناف • $statusText',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // عدادات الفواتير
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Iconsax.receipt, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${sortedIndex + 1}/${sortedInvoices.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // عرض عدد الفواتير المؤقتة
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${activeInvoices.length} نشطة',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // عرض عدد الفواتير المكتملة
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${userCompletedInvoices.length} مكتملة',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // زر سجل الفواتير
                        IconButton(
                          icon: Icon(
                            Iconsax.receipt_search,
                            color: Colors.blue[700],
                          ),
                          onPressed: () => Get.to(() => SalesHistoryScreen()),
                          tooltip: 'سجل الفواتير',
                        ),
                      ],
                    ),

                    // الصف الثاني: أزرار التحكم
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // زر الفاتورة السابقة (من جميع الفواتير)
                        IconButton(
                          icon: Icon(
                            Iconsax.arrow_left_3,
                            color: hasPrevious ? iconColor : Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: hasPrevious
                              ? () {
                            if (sortedIndex > 0) {
                              salesController.loadInvoiceForEditing(
                                sortedInvoices[sortedIndex - 1],
                              );
                            }
                          }
                              : null,
                          tooltip: 'الفاتورة السابقة',
                        ),

                        // زر فاتورة جديدة
                        IconButton(
                          icon: Icon(
                            Iconsax.add,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          onPressed: salesController.createNewInvoice,
                          tooltip: 'فاتورة جديدة',
                        ),

                        // زر الفاتورة التالية (من جميع الفواتير)
                        IconButton(
                          icon: Icon(
                            Iconsax.arrow_right_2,
                            color: hasNext ? iconColor : Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: hasNext
                              ? () {
                            if (sortedIndex < sortedInvoices.length - 1) {
                              salesController.loadInvoiceForEditing(
                                sortedInvoices[sortedIndex + 1],
                              );
                            }
                          }
                              : null,
                          tooltip: 'الفاتورة التالية',
                        ),

                        // Delete Invoice (مخفى للفواتير المحفوظة)
                        if (!currentSale.isSaved)
                          IconButton(
                            icon: Icon(
                              Iconsax.trash,
                              color: canDelete ? Colors.red[400] : Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: canDelete
                                ? () {
                              salesController.deleteCurrentInvoice();
                            }
                                : null,
                            tooltip: canDelete
                                ? 'حذف الفاتورة الحالية'
                                : 'لا يمكن حذف فاتورة محفوظة',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items List or Empty State
              Expanded(
                child: items.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentSale.isSaved
                            ? Iconsax.receipt
                            : Iconsax.shopping_cart,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentSale.isSaved
                            ? 'فاتورة مكتملة'
                            : 'السلة فارغة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSale.isSaved
                            ? 'تم حفظ هذه الفاتورة'
                            : 'ابحث وأضف منتجات للفاتورة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      if (currentSale.isSaved && currentSale.completedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'تم الإكمال: ${DateFormat('hh:mm a').format(currentSale.completedAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SaleItemWidget(
                      item: item,
                      index: index,
                      onEdit: currentSale.isSaved
                          ? null
                          : () {
                        showDialog(
                          context: context,
                          builder: (_) => EditItemDialog(
                            index: index,
                            salesController: salesController,
                          ),
                        );
                      },
                      onDelete: currentSale.isSaved
                          ? null
                          : () => salesController.removeItem(index),
                      isEditable: !currentSale.isSaved,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}