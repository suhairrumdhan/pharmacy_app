import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';

void showEditBusinessHoursDialog(
    BuildContext context, SettingsController controller) {
  final hours = controller.settings.value?.businessHours ??
      BusinessHours.empty();

  // Controllers لكل يوم
  final sundayController = TextEditingController(text: hours.sunday);
  final mondayController = TextEditingController(text: hours.monday);
  final tuesdayController = TextEditingController(text: hours.tuesday);
  final wednesdayController = TextEditingController(text: hours.wednesday);
  final thursdayController = TextEditingController(text: hours.thursday);
  final fridayController = TextEditingController(text: hours.friday);
  final saturdayController = TextEditingController(text: hours.saturday);

  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('تعديل أوقات العمل', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildDayField('الأحد', sundayController),
            _buildDayField('الإثنين', mondayController),
            _buildDayField('الثلاثاء', tuesdayController),
            _buildDayField('الأربعاء', wednesdayController),
            _buildDayField('الخميس', thursdayController),
            _buildDayField('الجمعة', fridayController),
            _buildDayField('السبت', saturdayController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade700)),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final newHours = BusinessHours(
                sunday: sundayController.text.trim(),
                monday: mondayController.text.trim(),
                tuesday: tuesdayController.text.trim(),
                wednesday: wednesdayController.text.trim(),
                thursday: thursdayController.text.trim(),
                friday: fridayController.text.trim(),
                saturday: saturdayController.text.trim(),
              );

              // تحديث Firestore لساعات العمل فقط
              await controller.saveBusinessHours(newHours);

              Get.back();
              Get.snackbar('نجاح', 'تم تحديث أوقات العمل بنجاح',
                  backgroundColor: Colors.green, colorText: Colors.white);
            } catch (e) {
              Get.snackbar('خطأ', 'فشل في حفظ أوقات العمل: $e',
                  backgroundColor: Colors.red, colorText: Colors.white);
            }
          },
          child: Text('حفظ'),
        ),
      ],
    ),
  );
}

Widget _buildDayField(String day, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: day,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
  );
}
