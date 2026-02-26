import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

class ActionButtons extends StatelessWidget {
  final AddMedicineController controller;

  const ActionButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool loading = controller.isAddingMedicine.value;
      final bool isEdit = controller.isEditMode.value;

      final String btnText = isEdit ? 'حفظ التعديلات' : 'إضافة الدواء';
      final String loadingText = isEdit ? 'جاري الحفظ...' : 'جاري الإضافة...';
      final IconData btnIcon = isEdit ? Icons.save : Icons.add;

      return Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // زر الإلغاء
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () {
                  controller.resetForm();
                  Navigator.pop(context); // أو Get.back()
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

            // زر الحفظ/الإضافة
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                  final errors = controller.validateFormForUI();

                  if (errors.isEmpty) {
                    try {
                      await controller.submit(); // ✅ add أو update حسب isEditMode
                      Navigator.pop(context);
                    } catch (_) {
                      // الأخطاء تتعرض داخل controller
                    }
                  } else {
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
                  backgroundColor: loading ? Colors.grey : Colors.blue,
                  elevation: 1,
                ),
                icon: loading
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : Icon(btnIcon, size: 14, color: Colors.white),
                label: Text(
                  loading ? loadingText : btnText,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}