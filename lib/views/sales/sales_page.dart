import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../controllers/insurance_company_controller.dart';
import '../../controllers/shift_controller.dart';
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
    final shiftCtrl = Get.find<ShiftController>();

    return Obx(() {
      final active = shiftCtrl.activeShift.value;

      if (active == null) {
        // تقدر تخليها صفحة لطيفة بدل snackbar
        return Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.clock, size: 52, color: Colors.orange[700]),
                const SizedBox(height: 10),
                const Text('لا توجد وردية نشطة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('لا يمكن تنفيذ المبيعات بدون فتح وردية.', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      }

      // ✅ لو فيه وردية نشطة عادي كمل واجهة المبيعات
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: LeftPanel(
                  salesController: salesController,
                  inventoryController: inventoryController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: RightPanel(salesController: salesController),
              ),
            ],
          ),
        ),
      );
    });
  }

}
