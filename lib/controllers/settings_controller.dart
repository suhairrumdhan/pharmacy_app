// controllers/settings_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/settings_model.dart';
class SettingsController extends GetxController {
  // ====== Dependencies ======
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // ====== Basic state ======
  String get pharmacyId => FirebaseAuth.instance.currentUser?.uid ?? '';

  var isLoading = false.obs;
  var isUploadingImage = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

  // ====== Rx model holder ======
  var settings = PharmacySettings.empty().obs;

  // ====== Text controllers for UI binding ======
  final nameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final ownerIdNumberController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final licenseNumberController = TextEditingController();

  // ====== Reactive simple fields ======
  var imageUrl = ''.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  // ====== Field-specific error messages ======
  final RxMap<String, String?> fieldErrors = <String, String?>{
    'name': null,
    'ownerName': null,
    'ownerIdNumber': null,
    'email': null,
    'phone': null,
    'address': null,
    'description': null,
    'licenseNumber': null,
  }.obs;

  void initializeControllers(PharmacySettings settings) {
    nameController.text = settings.name ?? '';
    ownerNameController.text = settings.ownerName ?? '';
    ownerIdNumberController.text = settings.ownerIdNumber ?? '';
    emailController.text = settings.email ?? '';
    phoneController.text = settings.phoneNumber ?? '';
    addressController.text = settings.address ?? '';
    licenseNumberController.text = settings.licenseNumber ?? '';
  }
  @override
  void onInit() {
    super.onInit();

    // إذا كان المستخدم موجودًا، حمّل الإعدادات تلقائياً
    if (pharmacyId.isNotEmpty) {
      loadSettings();
      startRealtimeListener();
    }
  }

  @override
  void onClose() {
    // تنظيف TextEditingControllers
    nameController.dispose();
    ownerNameController.dispose();
    ownerIdNumberController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    licenseNumberController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    if (pharmacyId.isEmpty) {
      errorMessage('لم يتم العثور على معرف الصيدلية');
      return;
    }

    try {
      isLoading(true);
      errorMessage.value = '';

      final doc = await _firestore.collection('pharmacies').doc(pharmacyId).get();
      final data = doc.data() ?? {};

      // معالجة الموقع
      // التعامل مع الماب location
      final locData = (data['location'] is Map)
          ? Map<String, dynamic>.from(data['location'])
          : {};

      // أولاً: خط العرض والطول
      final lat = _parseDouble(locData['lat']) ??
          _parseDouble(data['lat']) ??
          (data['locationCoordinates'] is List && data['locationCoordinates'].length >= 1
              ? _parseDouble(data['locationCoordinates'][0])
              : 0.0);

      final lng = _parseDouble(locData['lng']) ??
          _parseDouble(data['lng']) ??
          (data['locationCoordinates'] is List && data['locationCoordinates'].length >= 2
              ? _parseDouble(data['locationCoordinates'][1])
              : 0.0);

      // العنوان
      final address = locData['address']?.toString() ??
          data['address']?.toString() ??
          'no address';

      // معالجة أوقات العمل
      Map<String, dynamic> businessHoursData = {};
      try {
        final businessHoursDoc = await _firestore
            .collection('pharmacies')
            .doc(pharmacyId)
            .collection('settings')
            .doc('businessHours')
            .get();

        if (businessHoursDoc.exists && businessHoursDoc.data() != null) {
          businessHoursData = businessHoursDoc.data()!;
        } else if (data['businessHours'] is Map) {
          businessHoursData = Map<String, dynamic>.from(data['businessHours']);
        }
      } catch (e) {
        print('Error loading business hours: $e');
      }

      final is24 = data['is24Hours'] ?? false;

      final loaded = PharmacySettings(
        uid: data['uid']?.toString() ?? '',
        name: data['pharmacyName']?.toString() ?? '',
        ownerName: data['ownerName']?.toString() ?? '',
        ownerIdNumber: data['ownerIdNumber']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        phoneNumber: data['phoneNumber']?.toString() ?? '',
        address: address,
        licenseNumber: data['licenseNumber']?.toString() ?? '',
        status: data['status']?.toString() ?? 'pending',
        is24Hours: is24,
        isOnline: data['isOnline'] ?? false,
        imageUrl: data['imageUrl']?.toString() ?? '',
        location: PharmacyLocation(latitude: lat!, longitude: lng!),

        businessHours: BusinessHours.fromMap(
          businessHoursData,
          is24Hours: is24,
        ),

        createdAt: (data['createdAt'] is Timestamp)
            ? data['createdAt']
            : Timestamp.now(),
        updatedAt: (data['updatedAt'] is Timestamp)
            ? data['updatedAt']
            : Timestamp.now(),
      );

      // تحديث الحالة + الكونترولرز
      settings.value = loaded;
      imageUrl.value = loaded.imageUrl ?? '';
      latitude.value = loaded.location?.latitude ?? 0.0;
      longitude.value = loaded.location?.longitude ?? 0.0;

      nameController.text = loaded.name ?? '';
      ownerNameController.text = loaded.ownerName ?? '';
      ownerIdNumberController.text = loaded.ownerIdNumber ?? '';
      emailController.text = loaded.email ?? '';
      phoneController.text = loaded.phoneNumber ?? '';
      addressController.text = loaded.address ?? '**';
      licenseNumberController.text = loaded.licenseNumber ?? '';
    } catch (e, st) {
      errorMessage('فشل في تحميل الإعدادات: $e');
      print('loadSettings error: $e\n$st');
    } finally {
      isLoading(false);
    }
  }



  /// اختيار صورة من المعرض ورفعها تلقائياً
  Future<void> pickAndUploadImage() async {
    if (pharmacyId.isEmpty) {
      _showErrorSnackbar('المستخدم غير موثّق');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      await _uploadImageFile(File(image.path));
    } catch (e) {
      _showErrorSnackbar('فشل في اختيار الصورة: $e');
    }
  }
  Future<String?> _uploadImageFile(File file) async {
    if (pharmacyId.isEmpty) return null;
    try {
      isUploadingImage(true);
      final ext = file.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'pharmacy_logo_$timestamp.$ext';
      final ref = _storage.ref().child('pharmacies/$pharmacyId/imageUrl/$fileName');
      final metadata = SettableMetadata(
        contentType: 'image/$ext',
        customMetadata: {
          'uploadedBy': pharmacyId,
          'uploadedAt': timestamp.toString(),
          'originalName': file.path.split('/').last,
        },
      );
      final uploadTask = ref.putFile(file, metadata);
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'imageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      imageUrl.value = downloadUrl;
      if (settings.value != null) {
        settings.value = settings.value!.copyWith(
          imageUrl: downloadUrl,
          updatedAt: Timestamp.now(),
        );
      }
      return downloadUrl;
    } catch (e, st) {
      _showErrorSnackbar('فشل في رفع الصورة: ${e.toString()}');
      return null;
    } finally {
      isUploadingImage(false);
    }
  }
  Future<void> deleteCurrentImage() async {
    if (pharmacyId.isEmpty || imageUrl.value.isEmpty) return;

    try {
      isUploadingImage(true);
      final currentUrl = imageUrl.value;
      try {
        final ref = _storage.refFromURL(currentUrl);
        await ref.delete();
      } catch (e) {
        print('Note: Could not delete from Storage: $e');
      }
      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'imageUrl': FieldValue.delete(),
      });
      imageUrl.value = '';
      if (settings.value != null) {
        settings.value = settings.value!.copyWith(
          imageUrl: '',
        );
      }
    } catch (e) {
      _showErrorSnackbar('فشل في حذف الصورة: $e');
    } finally {
      isUploadingImage(false);
    }
  }


  Future<bool> updateSettings({bool requireLocation = false}) async {
    if (pharmacyId.isEmpty) {
      errorMessage('لم يتم العثور على معرف الصيدلية');
      return false;
    }

    if (!validateAllFields(requireLocation: requireLocation)) {
      return false;
    }

    try {
      isLoading(true);
      errorMessage.value = '';

      final updateData = <String, dynamic>{
        'pharmacyName': nameController.text.trim(),
        'ownerName': ownerNameController.text.trim(),
        'ownerIdNumber': ownerIdNumberController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'licenseNumber': licenseNumberController.text.trim(),
        'is24Hours': settings.value?.is24Hours ?? false,
        'isOnline': settings.value?.isOnline ?? false,
      };

      // إضافة الصورة إذا موجودة
      if (imageUrl.value.isNotEmpty) {
        updateData['imageUrl'] = imageUrl.value;
      }

      // إضافة الموقع
      if (latitude.value != 0.0 || longitude.value != 0.0) {
        updateData['location'] = {
          'latitude': latitude.value,
          'longitude': longitude.value,
        };
        updateData['latitude'] = latitude.value;
        updateData['longitude'] = longitude.value;
      }

      // تحديث Firestore فقط للبيانات الأساسية، بدون ساعات العمل
      await _firestore.collection('pharmacies').doc(pharmacyId).update(updateData);

      // تحديث الحالة المحلية
      if (settings.value != null) {
        final newSettings = settings.value!.copyWith(
          name: nameController.text.trim(),
          ownerName: ownerNameController.text.trim(),
          ownerIdNumber: ownerIdNumberController.text.trim(),
          email: emailController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          address: addressController.text.trim(),
          licenseNumber: licenseNumberController.text.trim(),
          imageUrl: imageUrl.value.isNotEmpty
              ? imageUrl.value
              : settings.value!.imageUrl,
          location: PharmacyLocation(
            latitude: latitude.value,
            longitude: longitude.value,
          ),
        );
        settings.value = newSettings;
      }

      return true;
    } catch (e) {
      errorMessage('فشل في حفظ الإعدادات: $e');
      print('updateSettings error: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> saveBusinessHours(BusinessHours newHours) async {
    final currentSettings = this.settings.value;
    if (currentSettings == null) return;

    final pharmacyId = this.pharmacyId;
    final bh = newHours;

    // إعداد البيانات
    final toSave = currentSettings.is24Hours
        ? {
      'sunday': '24 Hours',
      'monday': '24 Hours',
      'tuesday': '24 Hours',
      'wednesday': '24 Hours',
      'thursday': '24 Hours',
      'friday': '24 Hours',
      'saturday': '24 Hours',
    }
        : {
      'sunday': bh.sunday,
      'monday': bh.monday,
      'tuesday': bh.tuesday,
      'wednesday': bh.wednesday,
      'thursday': bh.thursday,
      'friday': bh.friday,
      'saturday': bh.saturday,
    };

    // المرجع للكولكشن/دوكومنت
    final docRef = _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('settings')
        .doc('businessHours');

    // التحقق إذا كان الدوكومنت موجود أو لا
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      // إذا الدوكومنت غير موجود، سيتم إنشاؤه تلقائيًا مع set
    }

    // حفظ البيانات مع merge للتأكد من عدم مسح أي بيانات أخرى
    await docRef.set({
      ...toSave,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // تحديث الحالة المحلية عبر Rx
    this.settings.value = currentSettings.copyWith(businessHours: bh);
  }
// في settings_controller.dart
  Future<void> toggleDayStatus(String dayKey) async {
    final settings = this.settings.value;
    if (settings == null) return;

    final hours = settings.businessHours;

    // الحصول على الوقت الحالي لليوم
    final currentTime = _getDayTime(dayKey, hours);
    final isClosed = currentTime.toLowerCase() == 'مغلق';

    // الوقت الجديد
    final newTime = isClosed ? '09:00 ص - 05:00 م' : 'مغلق';

    // إنشاء ساعات جديدة
    final newHours = BusinessHours(
      sunday: dayKey == 'sunday' ? newTime : hours.sunday,
      monday: dayKey == 'monday' ? newTime : hours.monday,
      tuesday: dayKey == 'tuesday' ? newTime : hours.tuesday,
      wednesday: dayKey == 'wednesday' ? newTime : hours.wednesday,
      thursday: dayKey == 'thursday' ? newTime : hours.thursday,
      friday: dayKey == 'friday' ? newTime : hours.friday,
      saturday: dayKey == 'saturday' ? newTime : hours.saturday,
    );

    // تحديث المحلي
    this.settings.value = settings.copyWith(businessHours: newHours);

    // حفظ في الفايرستور
    await saveBusinessHours(newHours);
  }

// دالة مساعدة داخل الكونترولر
  String _getDayTime(String dayKey, BusinessHours hours) {
    switch (dayKey) {
      case 'sunday': return hours.sunday;
      case 'monday': return hours.monday;
      case 'tuesday': return hours.tuesday;
      case 'wednesday': return hours.wednesday;
      case 'thursday': return hours.thursday;
      case 'friday': return hours.friday;
      case 'saturday': return hours.saturday;
      default: return 'مغلق';
    }
  }

  Future<bool> updateOnlineStatus(bool isOnline) async {
    if (pharmacyId.isEmpty) return false;
    try {
      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'isOnline': isOnline,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (settings.value != null) {
        settings.value = settings.value!.copyWith(isOnline: isOnline);
      }
      return true;
    } catch (e) {
      errorMessage('فشل في تحديث الحالة: $e');
      return false;
    }
  }

  Future<bool> update24HoursStatus(bool is24) async {
    if (pharmacyId.isEmpty) return false;
    try {
      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'is24Hours': is24,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (settings.value != null) {
        settings.value = settings.value!.copyWith(is24Hours: is24);
      }
      return true;
    } catch (e) {
      errorMessage('فشل في تحديث وضع 24 ساعة: $e');
      return false;
    }
  }

  Future<void> toggle24HoursWithUI() async {

    try{
      final newValue = !(settings.value?.is24Hours ?? false);
      final success = await update24HoursStatus(newValue);
    }catch (e) {
      _showErrorSnackbar('فشل في تحديث وضع 24 ساعة',);
    }
  }

  Future<void> toggleOnlineStatusWithUI() async {
    try {

      final newValue = !(settings.value?.isOnline ?? false);
      await updateOnlineStatus(newValue);

    }catch(e){
      _showSuccessSnackbar('فشل في تحديث   ');
    }
  }

  Future<bool> saveSettingsWithUI({bool requireLocation = false}) async {
    final success = await updateSettings(requireLocation: requireLocation);

    if (success) {
      _showSuccessSnackbar('تم حفظ الإعدادات بنجاح');
      return true;
    } else {
      final error = errorMessage.value.isNotEmpty
          ? errorMessage.value
          : 'فشل في حفظ الإعدادات';
      _showErrorSnackbar(error);
      return false;
    }
  }

  Future<void> refreshSettingsWithUI() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      await loadSettings();
      Get.back();
      _showSuccessSnackbar('تم تحديث البيانات بنجاح');
    } catch (e) {
      Get.back();
      _showErrorSnackbar('فشل في تحديث البيانات: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    successMessage.value = message;
    Get.snackbar(
      'نجاح',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnackbar(String message) {
    errorMessage.value = message;
    Get.snackbar(
      'خطأ',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  bool get is24HoursValue => settings.value?.is24Hours ?? false;
  bool get isOnlineValue => settings.value?.isOnline ?? false;
  String get imageUrlValue => settings.value?.imageUrl ?? '';
  String get nameValue => settings.value?.name ?? '';
  PharmacySettings? get currentSettings => settings.value;
  bool get hasImage => imageUrl.value.isNotEmpty;
  StreamSubscription<DocumentSnapshot>? _settingsSub;

  void startRealtimeListener() {
    if (pharmacyId.isEmpty) return;
    _settingsSub?.cancel();
    _settingsSub = _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      if (settings.value != null) {
        settings.value = settings.value!.copyWith(
          isOnline: data['isOnline'] ?? settings.value!.isOnline,
          is24Hours: data['is24Hours'] ?? settings.value!.is24Hours,
          name: data['name']?.toString() ?? settings.value!.name,
        );
      }
      if (data['imageUrl'] != null && data['imageUrl'] != imageUrl.value) {
        imageUrl.value = data['imageUrl'].toString();
      }
    });
  }

  void stopRealtimeListener() {
    _settingsSub?.cancel();
    _settingsSub = null;
  }

  void setLocation(double lat, double lng) {
    latitude.value = lat;
    longitude.value = lng;
  }

  void clearFieldErrors() {
    fieldErrors.keys.forEach((k) => fieldErrors[k] = null);
    fieldErrors.refresh();
    errorMessage('');
    successMessage('');
  }
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? validateName(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال اسم الصيدلية';
    if (value.trim().length < 2) return 'اسم الصيدلية قصير جدا';
    return null;
  }

  String? validateOwnerName(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال اسم المالك';
    if (value.trim().length < 2) return 'اسم المالك قصير جدا';
    return null;
  }

  String? validateOwnerIdNumber(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال رقم الهوية أو جواز السفر';
    final v = value.trim();
    if (v.length < 4 || v.length > 30) return 'رقم الهوية غير صالح';
    final reg = RegExp(r'^[\w\-\/]+$');
    if (!reg.hasMatch(v)) return 'يوجد أحرف غير مسموح بها في رقم الهوية';
    return null;
  }

  String? validateEmail(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    final reg = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$");
    if (!reg.hasMatch(value.trim())) return 'البريد الإلكتروني غير صالح';
    return null;
  }

  String? validatePhone(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال رقم الهاتف';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) return 'رقم الهاتف يجب أن يحتوي بين 7 و 15 رقم';
    return null;
  }

  String? validateAddress(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال العنوان';
    return null;
  }

  String? validateDescription(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال الوصف';
    if (value.trim().length < 4) return 'الوصف قصير جدا';
    return null;
  }

  String? validateLicenseNumber(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال رقم الترخيص';
    if (value.trim().length < 3) return 'رقم الترخيص غير صالح';
    return null;
  }

  bool validateLocation() {
    if (latitude.value == 0.0 && longitude.value == 0.0) {
      errorMessage('إحداثيات الموقع غير محددة');
      return false;
    }
    return true;
  }

  bool validateAllFields({bool requireLocation = false}) {
    fieldErrors['name'] = validateName(nameController.text);
    fieldErrors['ownerName'] = validateOwnerName(ownerNameController.text);
    fieldErrors['ownerIdNumber'] = validateOwnerIdNumber(ownerIdNumberController.text);
    fieldErrors['email'] = validateEmail(emailController.text);
    fieldErrors['phone'] = validatePhone(phoneController.text);
    fieldErrors['address'] = validateAddress(addressController.text);
    fieldErrors['licenseNumber'] = validateLicenseNumber(licenseNumberController.text);

    fieldErrors.refresh();

    final hasFieldError = fieldErrors.values.any((v) => v != null);

    if (hasFieldError) {
      errorMessage('يرجى تصحيح الحقول المشار إليها');
      return false;
    }

    if (requireLocation && !validateLocation()) {
      return false;
    }

    errorMessage('');
    return true;
  }
}