import 'package:flutter/material.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';
import 'search_card.dart';
import 'search_results_card.dart';
import 'current_sale_card.dart';

class LeftPanel extends StatefulWidget {
  final SalesController salesController;
  final InventoryController inventoryController;

  const LeftPanel({
    super.key,
    required this.salesController,
    required this.inventoryController,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  // استبدل ScrollController بـ GlobalKey
  final GlobalKey _resultsListKey = GlobalKey();

  void _onMedicineAdded(Medicine medicine) {
    // الطريقة الآمنة - استخدام PostFrameCallback للانتظار حتى يكون الـ Widget جاهزاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsListKey.currentContext;
      if (context != null && context.mounted) {
        // استخدم Scrollable.ensureVisible بدلاً من ScrollController.animateTo
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.1, // تمرير قليلاً للأعلى لإظهار العنصر
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث المحسن
        SearchCard(
          salesController: widget.salesController,
          onMedicineAdded: _onMedicineAdded,
        ),

        const SizedBox(height: 12),

        // نتائج البحث المحسنة مع GlobalKey
        Expanded(
          child: SearchResultsCard(
            key: _resultsListKey, // ✨ إضافة الـ GlobalKey هنا
            salesController: widget.salesController,
            onMedicineSelected: _onMedicineAdded,
          ),
        ),

        const SizedBox(height: 12),

        // الفاتورة الحالية
        Expanded(
          flex: 2,
          child: CurrentSaleCard(
            salesController: widget.salesController,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // لا حاجة لتنظيف ScrollController بعد الآن
    super.dispose();
  }
}