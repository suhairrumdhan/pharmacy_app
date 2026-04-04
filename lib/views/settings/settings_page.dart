import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pharmacy_desktop/views/settings/widgets/business_hours_widget.dart';
import 'package:pharmacy_desktop/views/settings/widgets/employees_widget.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import 'widgets/pharmacy_info_widget.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final SettingsController settingsController = Get.put(SettingsController());
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    // تحقق من الصلاحية قبل عرض أي شيء
    if (!authController.can('settings.view')) {
      // المستخدم غير مخول، نعرض ديالوج تحذيري
      Future.microtask(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("تنبيه"),
              content: const Text("أنت غير مخول للوصول إلى صفحة الإعدادات."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("موافق"),
                ),
              ],
            ),
          );
        });
      });

      // نرجع ودجت فارغ لمنع أي عرض خاطئ
      return const SizedBox.shrink();
    }

    // المستخدم مخول، نعرض الصفحة
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Obx(() {
        final settings = settingsController.settings.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // النصف الأيسر: ودجت معلومات الصيدلية
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: buildPharmacySettingsCard(settings),
              ),
            ),

            const SizedBox(width: 24),

            // النصف الأيمن: الموظفين وساعات العمل
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildEmployeesCard(),
                    const SizedBox(height: 10),
                    if (!(settings.is24Hours))
                    BusinessHoursCard(
                    key: ValueKey(settings.businessHours.hashCode),
                    hours: settings.businessHours,
                    ),
                    if (!(settings.is24Hours ))
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
