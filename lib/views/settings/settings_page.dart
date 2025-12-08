import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../models/settings_model.dart';
import '../employees/employees_page.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  final SettingsController settingsController = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Obx(() {
        final settings = settingsController.settings.value;

        return SingleChildScrollView(
          child: Column(
            children: [
              // معلومات الصيدلية
              _buildPharmacyInfoCard(settings),
              const SizedBox(height: 24),

              // الإعدادات العامة
              _buildGeneralSettingsCard(settings),
              const SizedBox(height: 24),

              // أوقات العمل
              _buildBusinessHoursCard(settings.businessHours),
              const SizedBox(height: 24),

              // الإعدادات المالية
              _buildFinancialSettingsCard(settings),
              const SizedBox(height: 24),

              // أزرار الحفظ
              _buildActionButtons(),

              // في نهاية ملف SettingsPage.dart بعد _buildActionButtons()

// إدارة الموظفين
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'إدارة الموظفين',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'إدارة موظفي الصيدلية، الأدوار، والصلاحيات',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.people_alt),
                          label: const Text('إدارة الموظفين'),
                          onPressed: () {
                            Get.to(() => EmployeesPage());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPharmacyInfoCard(PharmacySettings settings) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'معلومات الصيدلية',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: [
                _buildInfoField('اسم الصيدلية', settings.name, Icons.store),
                _buildInfoField('المالك', settings.ownerName, Icons.person),
                _buildInfoField('البريد الإلكتروني', settings.email, Icons.email),
                _buildInfoField('رقم الهاتف', settings.phoneNumber, Icons.phone),
                _buildInfoField('العنوان', settings.address, Icons.location_on),
                _buildInfoField('رقم الترخيص', settings.licenseNumber, Icons.badge),
                _buildInfoField('الحالة', settings.status, Icons.verified),
                _buildInfoField('مفتوح 24 ساعة', settings.is24Hours ? 'نعم' : 'لا', Icons.access_time),
                _buildInfoField('متصل', settings.isOnline ? 'نعم' : 'لا', Icons.online_prediction),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('تعديل المعلومات'),
                onPressed: _showEditPharmacyInfoDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsCard(PharmacySettings settings) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'الإعدادات العامة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('وضع 24 ساعة'),
                    subtitle: const Text('الصيدلية مفتوحة 24 ساعة'),
                    value: settings.is24Hours,
                    onChanged: (value) {
                      //_updateSetting('is24Hours', value);
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('الحالة المتاحة'),
                    subtitle: const Text('الصيدلية متاحة للطلبات'),
                    value: settings.isOnline,
                    onChanged: (value) {
                     // _updateSetting('isOnline', value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursCard(BusinessHours hours) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'أوقات العمل',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                _buildBusinessHoursRow('الأحد', hours.sunday),
                _buildBusinessHoursRow('الإثنين', hours.monday),
                _buildBusinessHoursRow('الثلاثاء', hours.tuesday),
                _buildBusinessHoursRow('الأربعاء', hours.wednesday),
                _buildBusinessHoursRow('الخميس', hours.thursday),
                _buildBusinessHoursRow('الجمعة', hours.friday),
                _buildBusinessHoursRow('السبت', hours.saturday),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('تعديل أوقات العمل'),
                onPressed: _showEditBusinessHoursDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildBusinessHoursRow(String day, String hours) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(hours),
        ),
      ],
    );
  }

  Widget _buildFinancialSettingsCard(PharmacySettings settings) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'الإعدادات المالية',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: _buildFinancialField('العملة', settings.currency),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.money),
                label: const Text('تعديل الإعدادات المالية'),
                onPressed: _showEditFinancialSettingsDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            settingsController.loadSettings();
          },
          child: const Text('إعادة تعيين'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            // TODO: حفظ الإعدادات
            Get.snackbar('تم', 'تم حفظ الإعدادات بنجاح');
          },
          child: const Text('حفظ الإعدادات'),
        ),
      ],
    );
  }



  void _showEditPharmacyInfoDialog() {
    // TODO: تنفيذ نافذة تعديل معلومات الصيدلية
    Get.snackbar('تعديل', 'سيتم تنفيذ نافذة تعديل المعلومات');
  }

  void _showEditBusinessHoursDialog() {
    // TODO: تنفيذ نافذة تعديل أوقات العمل
    Get.snackbar('تعديل', 'سيتم تنفيذ نافذة تعديل أوقات العمل');
  }

  void _showEditFinancialSettingsDialog() {
    // TODO: تنفيذ نافذة تعديل الإعدادات المالية
    Get.snackbar('تعديل', 'سيتم تنفيذ نافذة تعديل الإعدادات المالية');
  }



}