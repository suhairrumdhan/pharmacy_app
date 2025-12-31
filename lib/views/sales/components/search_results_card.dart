import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';
import 'medicine_item.dart';

class SearchResultsCard extends StatelessWidget {
  final SalesController salesController;
  final Function(Medicine)? onMedicineSelected;

  const SearchResultsCard({
    super.key,
    required this.salesController,
    this.onMedicineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // عنوان مع تحديثات
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
                  Icon(Iconsax.search_status, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() {
                      final query = salesController.searchQuery.value;
                      final count = salesController.searchResults.length;

                      return Text(
                        query.isEmpty
                            ? 'نتائج البحث'
                            : 'نتائج البحث عن "$query"',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      );
                    }),
                  ),
                  Obx(() => Text(
                    '${salesController.searchResults.length} منتج',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  )),
                ],
              ),
            ),

            // قائمة النتائج مع تحسينات
            Expanded(
              child: Obx(() {
                if (salesController.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          'جاري البحث...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final results = salesController.searchResults;
                final query = salesController.searchQuery.value;

                if (query.isEmpty) {
                  return _buildEmptyState(
                    icon: Iconsax.search_normal,
                    title: 'ابدأ بالكتابة للبحث',
                    subtitle: 'ابحث بالاسم، الباركود أو الاسم العلمي',
                  );
                }

                if (results.isEmpty) {
                  return _buildEmptyState(
                    icon: Iconsax.search_status,
                    title: 'لا توجد نتائج',
                    subtitle: 'تأكد من الكتابة بشكل صحيح أو جرب مصطلحات أخرى',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final medicine = results[index];
                    final isBarcodeSearch = salesController.isBarcodeInput(query);

                    return MedicineItem(
                      medicine: medicine,
                      salesController: salesController,
                      autoSelect: isBarcodeSearch && index == 0,
                      onSelected: () {
                        if (onMedicineSelected != null) {
                          onMedicineSelected!(medicine);
                        }
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}