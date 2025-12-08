import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_desktop/views/inventory/widgets/unit_selection_section.dart';
import '../../../controllers/add_medicine_controller.dart';
import 'widgets/dialog_header.dart';
import 'widgets/basic_info_section.dart';
import 'widgets/purchase_info_section.dart';
import 'widgets/selling_info_section.dart';
import 'widgets/additional_info_section.dart';
import 'widgets/action_buttons.dart';
import 'add_category_dialog.dart';

class AddMedicineDialog extends StatelessWidget {
  const AddMedicineDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMedicineController());

    return Dialog(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DialogHeader(),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  child: Column(
                    children: [
                      BasicInfoSection(controller: controller),
                      const SizedBox(height: 16),
                      UnitSelectionSection(controller: controller),
                      const SizedBox(height: 16),
                      PurchaseInfoSection(controller: controller),
                      const SizedBox(height: 16),
                      SellingInfoSection(controller: controller),
                      const SizedBox(height: 16),
                      AdditionalInfoSection(controller: controller),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            ActionButtons(controller: controller),
          ],
        ),
      ),
    );
  }
}

// Helper function to show add category dialog
void showAddCategoryDialog(BuildContext context, AddMedicineController controller) {
  showDialog(
    context: context,
    builder: (context) => AddCategoryDialog(controller: controller),
  );
}

// Helper function to format date
String formatDate(DateTime date) {
  return DateFormat('yyyy/MM/dd').format(date);
}