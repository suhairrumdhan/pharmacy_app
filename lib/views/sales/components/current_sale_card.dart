import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../dialogs/edit_item_dialog.dart';
import 'sale_item.dart';

class CurrentSaleCard extends StatelessWidget {
  final SalesController salesController;

  const CurrentSaleCard({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
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
// في current_sale_card.dart

// ... الكود السابق ...

// عنوان الفاتورة مع السهمين
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


                  // أيقونة ومعلومات الفاتورة
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

                  // معلومات الفاتورة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final invoiceNumber = salesController.currentSale.value.invoiceNumber;
                          final currentIndex = salesController.currentInvoiceIndex.value;
                          final totalInvoices = salesController.activeInvoices.length;

                          return Row(
                            children: [
                              Text(
                                'فاتورة #$invoiceNumber',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (totalInvoices > 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${currentIndex + 1}/$totalInvoices',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                        Obx(() => Text(
                          '${salesController.currentSale.value.items.length} أصناف',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )),
                      ],
                    ),
                  ),
                  // السهم الأيسر (الفاتورة السابقة)
                  Obx(() {
                    final hasPrevious = salesController.activeInvoices.length > 1;
                    return IconButton(
                      icon: Icon(
                        Iconsax.arrow_left_3,
                        color: hasPrevious ? Colors.blue[700] : Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: hasPrevious
                          ? salesController.switchToPreviousInvoice
                          : null,
                      tooltip: 'الفاتورة السابقة',
                    );
                  }),
                  // السهم الأيمن (الفاتورة التالية)
                  Obx(() {
                    final hasNext = salesController.activeInvoices.length > 1;
                    return IconButton(
                      icon: Icon(
                        Iconsax.arrow_right_2,
                        color: hasNext ? Colors.blue[700] : Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: hasNext
                          ? salesController.switchToNextInvoice
                          : null,
                      tooltip: 'الفاتورة التالية',
                    );
                  }),

                  // زر فاتورة جديدة
                  IconButton(
                    icon: Icon(
                      Iconsax.refresh,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    onPressed: salesController.createNewInvoice,
                    tooltip: 'فاتورة جديدة',
                  ),

                  // زر حذف الفاتورة الحالية
                  Obx(() {
                    final canDelete = salesController.activeInvoices.length > 1;
                    return IconButton(
                      icon: Icon(
                        Iconsax.trash,
                        color: canDelete ? Colors.red[400] : Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: canDelete
                          ? salesController.deleteCurrentInvoice
                          : null,
                      tooltip: 'حذف الفاتورة الحالية',
                    );
                  }),
                ],
              ),
            ),            // قائمة الأصناف
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

                    // ... كود سابق ...

                    // عند استخدام الـ Widget:
                    return SaleItemWidget(
                      item: items[index],
                      index: index,
                      onEdit: () {
                        showDialog(
                          context: context,
                          builder: (_) => EditItemDialog(
                            index: index,
                            salesController: salesController,
                          ),
                        );
                      },
                      onDelete: () => salesController.removeItem(index),
                    );

                    // ... كود لاحق ...
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}