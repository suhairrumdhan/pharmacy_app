import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../dialogs/barcode_scanner_dialog.dart';

class SearchCard extends StatelessWidget {
  final SalesController salesController;

  const SearchCard({
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
                        showDialog(
                          context: context,
                          builder: (_) => BarcodeScannerDialog(salesController: salesController),
                        );
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
                      // TODO: Implement low stock filter
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
}