import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

class ActionButtons extends StatelessWidget {
  final AddMedicineController controller;

  const ActionButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // زر الإلغاء
          SizedBox(
            height: 32, // ارتفاع صغير مناسب للنص
            child: OutlinedButton.icon(
              onPressed: controller.isAddingMedicine.value ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact, // يقلل مسافات الزر
                padding: const EdgeInsets.symmetric(horizontal: 12), // حجم داخلي صغير
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              icon: const Icon(Icons.cancel, size: 14, color: Colors.grey),
              label: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // زر إضافة الدواء مع حالة التحميل
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: controller.isAddingMedicine.value
                  ? null
                  : () async {
                final errors = controller.validateFormForUI();

                if (errors.isEmpty) {
                  try {
                    await controller.addMedicine();
                    Navigator.pop(context);
                  } catch (e) {
                    // الخطأ تم التعامل معه في الـ controller بالفعل
                    // ولكن يمكننا إضافة رسالة إضافية هنا إذا أردت
                  }
                } else {
                  // عرض جميع الأخطاء في رسالة واحدة
                  final errorMessage = errors.entries
                      .map((e) => '• ${e.value}')
                      .join('\n');

                  Get.snackbar(
                    'يرجى تصحيح الأخطاء التالية',
                    errorMessage,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 5),
                    snackPosition: SnackPosition.TOP,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: controller.isAddingMedicine.value
                    ? Colors.grey
                    : Colors.blue,
                elevation: 1,
              ),
              icon: controller.isAddingMedicine.value
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Icon(Icons.add, size: 14, color: Colors.white),
              label: controller.isAddingMedicine.value
                  ? const Text(
                'جاري الإضافة...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              )
                  : const Text(
                'إضافة الدواء',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}