import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../controllers/sales_controller.dart';
import 'search_card.dart';
import 'search_results_card.dart';
import 'current_sale_card.dart';

class LeftPanel extends StatelessWidget {
  final SalesController salesController;
  final InventoryController inventoryController;

  const LeftPanel({
    super.key,
    required this.salesController,
    required this.inventoryController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث
        SearchCard(salesController: salesController),

        const SizedBox(height: 12),

        // نتائج البحث
        Expanded(
          child: SearchResultsCard(salesController: salesController),
        ),

        const SizedBox(height: 12),

        // قائمة المنتجات المضافة
        Expanded(
          flex: 2,
          child: CurrentSaleCard(salesController: salesController),
        ),
      ],
    );
  }
}