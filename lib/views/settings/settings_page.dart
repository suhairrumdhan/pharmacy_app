





import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pharmacy_desktop/views/settings/widgets/business_hours_widget.dart';
import 'package:pharmacy_desktop/views/settings/widgets/employees_widget.dart';
import '../../controllers/settings_controller.dart';
import 'widgets/pharmacy_info_widget.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  final SettingsController settingsController = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Obx(() {
        final settings = settingsController.settings.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // النصف الأيسر: الودجت الجديد المدمج
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: buildPharmacySettingsCard(settings),
              ),
            ),

            const SizedBox(width: 24),

            // النصف الأيمن: باقي المكونات
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildEmployeesCard(),
                    const SizedBox(height: 10),
                    // BUSINESS HOURS (ظهر فقط إذا ليست 24 ساعة)
                    if (!(settings.is24Hours ?? false))
                      buildBusinessHoursCard(context,settings.businessHours),
                    if (!(settings.is24Hours ?? false))
                      const SizedBox(height: 18),
                  ],
                ),

              ),
            ),
          ],
        );
      }),
    );
  }


}
