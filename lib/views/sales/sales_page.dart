import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../controllers/insurance_company_controller.dart';
import 'components/left_panel.dart';
import 'components/right_panel.dart';

class SalesPage extends StatelessWidget {
  SalesPage({super.key});

  final SalesController salesController = Get.put(SalesController());
  final InventoryController inventoryController = Get.find<
      InventoryController>();
  final InsuranceCompanyController insuranceController = Get.find<
      InsuranceCompanyController>();

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
              child: LeftPanel(
                salesController: salesController,
                inventoryController: inventoryController,
              ),
            ),
            const SizedBox(width: 16),
            // الجانب الأيمن ع
            Expanded(
              flex: 3,
              child: RightPanel(salesController: salesController),
            ),
          ],
        ),
      ),
    );
  }
}
