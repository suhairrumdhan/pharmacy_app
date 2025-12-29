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