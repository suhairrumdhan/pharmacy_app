import 'package:get/get.dart';
import '../models/settings_model.dart';

class SettingsController extends GetxController {
  var settings = PharmacySettings(
    name: '',
    ownerName: '',
    email: '',
    phoneNumber: '',
    address: '',
    licenseNumber: '',
    status: '',
    is24Hours: false,
    isOnline: false,
    taxNumber: '',
    taxRate: 15.0,
    currency: 'ريال',
    businessHours: BusinessHours(
      sunday: '09:00 - 18:00',
      monday: '09:00 - 18:00',
      tuesday: '09:00 - 18:00',
      wednesday: '09:00 - 18:00',
      thursday: '09:00 - 18:00',
      friday: '09:00 - 18:00',
      saturday: '09:00 - 18:00',
    ),
  ).obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    isLoading(true);

    // TODO: جلب الإعدادات من Firestore
    // بيانات تجريبية
    settings.value = PharmacySettings(
      name: 'صيدلية الحياة',
      ownerName: 'أحمد محمد',
      email: 'ahmed@alhayat-pharmacy.com',
      phoneNumber: '0512345678',
      address: 'الرياض - حي الملك فهد - شارع الملك خالد',
      licenseNumber: 'PH123456',
      status: 'نشط',
      is24Hours: true,
      isOnline: true,
      taxNumber: '123456789',
      taxRate: 15.0,
      currency: 'ريال',
      businessHours: BusinessHours(
        sunday: '09:00 - 18:00',
        monday: '09:00 - 18:00',
        tuesday: '09:00 - 18:00',
        wednesday: '09:00 - 18:00',
        thursday: '09:00 - 18:00',
        friday: '09:00 - 18:00',
        saturday: '09:00 - 18:00',
      ),
    );

    isLoading(false);
  }

  void updateSettings(PharmacySettings newSettings) {
    settings.value = newSettings;
    // TODO: حفظ في Firestore
  }

  void updateBusinessHours(BusinessHours newHours) {
    final currentSettings = settings.value;
    settings.value = PharmacySettings(
      name: currentSettings.name,
      ownerName: currentSettings.ownerName,
      email: currentSettings.email,
      phoneNumber: currentSettings.phoneNumber,
      address: currentSettings.address,
      licenseNumber: currentSettings.licenseNumber,
      status: currentSettings.status,
      is24Hours: currentSettings.is24Hours,
      isOnline: currentSettings.isOnline,
      taxNumber: currentSettings.taxNumber,
      taxRate: currentSettings.taxRate,
      currency: currentSettings.currency,
      businessHours: newHours,
    );
  }
}