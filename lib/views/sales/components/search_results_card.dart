import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../dialogs/add_quantity_dialog.dart';
import 'medicine_item.dart';

class SearchResultsCard extends StatelessWidget {
  final SalesController salesController;

  const SearchResultsCard({
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
                    return MedicineItem(
                      medicine: medicine,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddQuantityDialog(
                            medicine: medicine,
                            salesController: salesController,
                          ),
                        );
                      },
                    );
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