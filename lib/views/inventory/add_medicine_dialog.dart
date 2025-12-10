import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_desktop/views/inventory/widgets/image_upload_section.dart';
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
        width: 1500,
        height: 900,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DialogHeader(),
            const SizedBox(height: 20),

            // تصميم شبكي Grid Layout
            Expanded(
              child: Form(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  children: [
                    TableRow(
                      children: [
                        // العمود الأول
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BasicInfoSection(controller: controller),
                              const SizedBox(height: 16),
                              UnitSelectionSection(controller: controller),
                            ],
                          ),
                        ),

                        // العمود الثاني
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PurchaseInfoSection(controller: controller),
                              const SizedBox(height: 16),
                              SellingInfoSection(controller: controller),
                            ],
                          ),
                        ),

                        // العمود الثالث
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ImageUploadSection(controller: controller),
                              const SizedBox(height: 16),
                              AdditionalInfoSection(controller: controller),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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