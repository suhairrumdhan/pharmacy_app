import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_desktop/views/inventory/widgets/image_upload_section.dart';
import 'package:pharmacy_desktop/views/inventory/widgets/unit_selection_section.dart';
import '../../../controllers/add_medicine_controller.dart';
import '../../../models/inventory_model.dart';
import 'widgets/dialog_header.dart';
import 'widgets/basic_info_section.dart';
import 'widgets/purchase_info_section.dart';
import 'widgets/selling_info_section.dart';
import 'widgets/additional_info_section.dart';
import 'widgets/action_buttons.dart';
import 'add_category_dialog.dart';

class AddMedicineDialog extends StatelessWidget {
  final Medicine? medicine; // 👈 مهم جداً

  const AddMedicineDialog({super.key, this.medicine});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMedicineController());

    /// 👇 تهيئة وضع إضافة / تعديل مرة واحدة فقط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.init(medicine);
    });

    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final dialogWidth = w < 900 ? w * 0.94 : (w < 1400 ? w * 0.92 : 1500.0);
    final dialogHeight = h < 800 ? h * 0.92 : (h * 0.88).clamp(650.0, 900.0);

    final bool oneColumn = w < 950;
    final bool twoColumns = w >= 950 && w < 1300;

    Widget sectionCard(Widget child) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    final col1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionCard(BasicInfoSection(controller: controller)),
        const SizedBox(height: 16),
        sectionCard(UnitSelectionSection(controller: controller)),
      ],
    );

    final col2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionCard(PurchaseInfoSection(controller: controller)),
        const SizedBox(height: 16),
        sectionCard(SellingInfoSection(controller: controller)),
      ],
    );

    final col3 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionCard(ImageUploadSection(controller: controller)),
        const SizedBox(height: 16),
        sectionCard(AdditionalInfoSection(controller: controller)),
      ],
    );

    Widget buildBody() {
      if (oneColumn) {
        return Column(
          children: [
            col1,
            const SizedBox(height: 16),
            col2,
            const SizedBox(height: 16),
            col3,
          ],
        );
      }

      if (twoColumns) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: col1),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  col2,
                  const SizedBox(height: 16),
                  col3,
                ],
              ),
            ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: col1),
          const SizedBox(width: 16),
          Expanded(child: col2),
          const SizedBox(width: 16),
          Expanded(child: col3),
        ],
      );
    }

    return Dialog(
      elevation: 10,
      insetPadding: EdgeInsets.symmetric(
        horizontal: w < 900 ? 12 : 24,
        vertical: h < 800 ? 12 : 24,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            /// 👇 العنوان يتغير حسب الوضع
            Obx(() => DialogHeader(
              title: controller.isEditMode.value
                  ? 'تحديث دواء'
                  : 'إضافة دواء',
            )),

            const SizedBox(height: 14),

            Expanded(
              child: Form(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 6),
                    child: buildBody(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            ActionButtons(controller: controller),
          ],
        ),
      ),
    );
  }
}
