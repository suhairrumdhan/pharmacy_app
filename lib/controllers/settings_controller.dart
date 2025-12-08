// controllers/settings_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/settings_model.dart';
import 'auth_controller.dart';

class SettingsController extends GetxController {
  // الحصول على الـ UID من AuthController أو Firebase مباشرة
  String get pharmacyId => FirebaseAuth.instance.currentUser?.uid ?? '';

  var settings = PharmacySettings(
    id: '',
    name: '',
    ownerName: '',
    email: '',
    phoneNumber: '',
    address: '',
    licenseNumber: '',
    status: '',
    is24Hours: false,
    isOnline: false,
    currency: '',
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
  var errorMessage = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();

    // انتظر حتى يكون هناك مستخدم مسجل الدخول
    ever(Get.find<AuthController>().pharmacyData, (data) {
      if (data.isNotEmpty && pharmacyId.isNotEmpty) {
        loadSettings();
      }
    });

    // أو يمكنك استخدام هذا إذا كنت تريد تحميل الإعدادات مباشرة
    if (pharmacyId.isNotEmpty) {
      loadSettings();
    }
  }

  // تحميل الإعدادات من Firebase Firestore
  Future<void> loadSettings() async {
    try {
      if (pharmacyId.isEmpty) {
        errorMessage('لم يتم العثور على معرف الصيدلية');
        return;
      }

      isLoading(true);
      errorMessage('');

      print('جاري تحميل إعدادات الصيدلية ID: $pharmacyId');

      // جلب بيانات الصيدلية من collection 'pharmacies'
      final pharmacyDoc = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .get();

      if (!pharmacyDoc.exists) {
        // إذا لم توجد بيانات، نبحث في pharmacyRequests
        await _loadFromPharmacyRequests();
        return;
      }

      final pharmacyData = pharmacyDoc.data()!;

      // جلب أوقات العمل إذا كانت في وثيقة منفصلة
      Map<String, dynamic> businessHoursData = {};
      final businessHoursDoc = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('settings')
          .doc('businessHours')
          .get();

      if (businessHoursDoc.exists) {
        businessHoursData = businessHoursDoc.data()!;
      }

      // تحديث الإعدادات
      settings.value = PharmacySettings(
        id: pharmacyId,
        name: pharmacyData['name']?.toString() ?? '',
        ownerName: pharmacyData['ownerName']?.toString() ?? '',
        email: pharmacyData['email']?.toString() ?? '',
        phoneNumber: pharmacyData['phoneNumber']?.toString() ?? '',
        address: pharmacyData['address']?.toString() ?? '',
        licenseNumber: pharmacyData['licenseNumber']?.toString() ?? '',
        status: pharmacyData['status']?.toString() ?? 'pending',
        is24Hours: pharmacyData['is24Hours'] ?? false,
        isOnline: pharmacyData['isOnline'] ?? false,
        currency: pharmacyData['currency']?.toString() ?? 'دينار',
        businessHours: BusinessHours(
          sunday: businessHoursData['sunday']?.toString() ?? '09:00 - 18:00',
          monday: businessHoursData['monday']?.toString() ?? '09:00 - 18:00',
          tuesday: businessHoursData['tuesday']?.toString() ?? '09:00 - 18:00',
          wednesday: businessHoursData['wednesday']?.toString() ?? '09:00 - 18:00',
          thursday: businessHoursData['thursday']?.toString() ?? '09:00 - 18:00',
          friday: businessHoursData['friday']?.toString() ?? '09:00 - 18:00',
          saturday: businessHoursData['saturday']?.toString() ?? '09:00 - 18:00',
        ),
      );

      print('تم تحميل الإعدادات بنجاح: ${settings.value.name}');

    } catch (e) {
      errorMessage('فشل في تحميل الإعدادات: $e');
      print('Error loading settings: $e');
    } finally {
      isLoading(false);
    }
  }

  // تحميل البيانات من طلبات التسجيل (إذا كانت الصيدلية في حالة انتظار الموافقة)
  Future<void> _loadFromPharmacyRequests() async {
    try {
      final requestDoc = await _firestore
          .collection('pharmacyRequests')
          .doc(pharmacyId)
          .get();

      if (!requestDoc.exists) {
        errorMessage('لا توجد بيانات للصيدلية');
        return;
      }

      final requestData = requestDoc.data()!;

      settings.value = PharmacySettings(
        id: pharmacyId,
        name: requestData['pharmacyName']?.toString() ?? '',
        ownerName: requestData['ownerName']?.toString() ?? '',
        email: requestData['email']?.toString() ?? '',
        phoneNumber: requestData['phoneNumber']?.toString() ?? '',
        address: requestData['address']?.toString() ?? '',
        licenseNumber: requestData['licenseNumber']?.toString() ?? '',
        status: requestData['status']?.toString() ?? 'pending',
        is24Hours: false, // قيمة افتراضية للطلبات الجديدة
        isOnline: false,  // قيمة افتراضية للطلبات الجديدة
        currency: 'دينار', // قيمة افتراضية
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
    } catch (e) {
      errorMessage('فشل في تحميل بيانات الطلب: $e');
      print('Error loading from requests: $e');
    }
  }

  // تحديث الإعدادات وحفظها في Firebase
  Future<bool> updateSettings(PharmacySettings newSettings) async {
    try {
      if (pharmacyId.isEmpty) {
        errorMessage('لم يتم العثور على معرف الصيدلية');
        return false;
      }

      isLoading(true);

      // تحديث بيانات الصيدلية الرئيسية
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .update({
        'name': newSettings.name,
        'ownerName': newSettings.ownerName,
        'email': newSettings.email,
        'phoneNumber': newSettings.phoneNumber,
        'address': newSettings.address,
        'licenseNumber': newSettings.licenseNumber,
        'is24Hours': newSettings.is24Hours,
        'isOnline': newSettings.isOnline,
        'currency': newSettings.currency,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // تحديث أوقات العمل في وثيقة منفصلة
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('settings')
          .doc('businessHours')
          .set({
        'sunday': newSettings.businessHours.sunday,
        'monday': newSettings.businessHours.monday,
        'tuesday': newSettings.businessHours.tuesday,
        'wednesday': newSettings.businessHours.wednesday,
        'thursday': newSettings.businessHours.thursday,
        'friday': newSettings.businessHours.friday,
        'saturday': newSettings.businessHours.saturday,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تحديث القيمة المحلية
      settings.value = newSettings.copyWith(id: pharmacyId);

      // تحديث بيانات الصيدلية في AuthController
      Get.find<AuthController>().loadPharmacyData();

      return true;
    } catch (e) {
      errorMessage('فشل في حفظ الإعدادات: $e');
      print('Error saving settings: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  // تحديث أوقات العمل فقط
  Future<bool> updateBusinessHours(BusinessHours newHours) async {
    try {
      if (pharmacyId.isEmpty) return false;

      isLoading(true);

      // حفظ أوقات العمل في Firebase
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('settings')
          .doc('businessHours')
          .set({
        'sunday': newHours.sunday,
        'monday': newHours.monday,
        'tuesday': newHours.tuesday,
        'wednesday': newHours.wednesday,
        'thursday': newHours.thursday,
        'friday': newHours.friday,
        'saturday': newHours.saturday,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تحديث القيمة المحلية
      final currentSettings = settings.value;
      settings.value = currentSettings.copyWith(
        businessHours: newHours,
      );

      return true;
    } catch (e) {
      errorMessage('فشل في حفظ أوقات العمل: $e');
      print('Error saving business hours: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  // تحديث الحالة المتاحة (isOnline)
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      if (pharmacyId.isEmpty) return false;

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .update({
        'isOnline': isOnline,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      final currentSettings = settings.value;
      settings.value = currentSettings.copyWith(isOnline: isOnline);

      return true;
    } catch (e) {
      errorMessage('فشل في تحديث الحالة: $e');
      print('Error updating online status: $e');
      return false;
    }
  }

  // تحديث وضع 24 ساعة
  Future<bool> update24HoursStatus(bool is24Hours) async {
    try {
      if (pharmacyId.isEmpty) return false;

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .update({
        'is24Hours': is24Hours,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final currentSettings = settings.value;
      settings.value = currentSettings.copyWith(is24Hours: is24Hours);

      return true;
    } catch (e) {
      errorMessage('فشل في تحديث وضع 24 ساعة: $e');
      print('Error updating 24 hours status: $e');
      return false;
    }
  }

  // تحديث العملة
  Future<bool> updateCurrency(String currency) async {
    try {
      if (pharmacyId.isEmpty) return false;

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .update({
        'currency': currency,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final currentSettings = settings.value;
      settings.value = currentSettings.copyWith(currency: currency);

      return true;
    } catch (e) {
      errorMessage('فشل في تحديث العملة: $e');
      print('Error updating currency: $e');
      return false;
    }
  }

  // التحقق مما إذا كان وقت العمل الحالي ضمن ساعات العمل
  bool isWithinBusinessHours() {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday

    if (settings.value.is24Hours) return true;

    final hours = settings.value.businessHours;
    String todayHours = '';

    switch (currentDay) {
      case 1: todayHours = hours.monday; break;
      case 2: todayHours = hours.tuesday; break;
      case 3: todayHours = hours.wednesday; break;
      case 4: todayHours = hours.thursday; break;
      case 5: todayHours = hours.friday; break;
      case 6: todayHours = hours.saturday; break;
      case 7: todayHours = hours.sunday; break;
    }

    // تحليل أوقات العمل (تنسيق: "09:00 - 18:00")
    try {
      final parts = todayHours.split(' - ');
      if (parts.length != 2) return false;

      final openTime = parts[0].trim();
      final closeTime = parts[1].trim();

      final openHour = int.parse(openTime.split(':')[0]);
      final openMinute = int.parse(openTime.split(':')[1]);

      final closeHour = int.parse(closeTime.split(':')[0]);
      final closeMinute = int.parse(closeTime.split(':')[1]);

      final nowTime = now.hour * 60 + now.minute;
      final openTimeInMinutes = openHour * 60 + openMinute;
      final closeTimeInMinutes = closeHour * 60 + closeMinute;

      return nowTime >= openTimeInMinutes && nowTime <= closeTimeInMinutes;
    } catch (e) {
      return false;
    }
  }

  // الحصول على حالة الصيدلية الحالية (بناءً على الوقت وisOnline)
  String getCurrentStatus() {
    if (!settings.value.isOnline) return 'غير متصل';
    if (settings.value.is24Hours) return 'متصل 24 ساعة';
    if (isWithinBusinessHours()) return 'متصل';
    return 'خارج أوقات العمل';
  }

  // تحديث صورة الصيدلية
  Future<bool> updatePharmacyImage(String imageUrl) async {
    try {
      if (pharmacyId.isEmpty) return false;

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      errorMessage('فشل في تحديث الصورة: $e');
      print('Error updating pharmacy image: $e');
      return false;
    }
  }

  // الاستماع للتغييرات في الوقت الحقيقي
  void startRealtimeListener() {
    if (pharmacyId.isEmpty) return;

    _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;

        final currentSettings = settings.value;
        settings.value = currentSettings.copyWith(
          isOnline: data['isOnline'] ?? currentSettings.isOnline,
          is24Hours: data['is24Hours'] ?? currentSettings.is24Hours,
          name: data['name']?.toString() ?? currentSettings.name,
        );
      }
    });
  }

  // إعادة تحميل الإعدادات
  Future<void> refreshSettings() async {
    await loadSettings();
  }
}