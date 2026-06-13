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
import '../services/search_index_service.dart';

class SettingsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String get pharmacyId => FirebaseAuth.instance.currentUser?.uid ?? '';

  final isLoading = false.obs;
  final isUploadingImage = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  final settings = PharmacySettings.empty().obs;

  final nameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final ownerIdNumberController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final licenseNumberController = TextEditingController();

  final imageUrl = ''.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;

  final RxMap<String, String?> fieldErrors = <String, String?>{
    'name': null,
    'ownerName': null,
    'ownerIdNumber': null,
    'email': null,
    'phone': null,
    'address': null,
    'licenseNumber': null,
  }.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;

  @override
  void onInit() {
    super.onInit();
    if (pharmacyId.isNotEmpty) {
      loadSettings();
      startRealtimeListener();
    }
  }

  @override
  void onClose() {
    _settingsSub?.cancel();
    nameController.dispose();
    ownerNameController.dispose();
    ownerIdNumberController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    licenseNumberController.dispose();
    super.onClose();
  }

  void initializeControllers(PharmacySettings current) {
    nameController.text = current.name;
    ownerNameController.text = current.ownerName;
    ownerIdNumberController.text = current.ownerIdNumber;
    emailController.text = current.email;
    phoneController.text = current.phoneNumber;
    addressController.text = current.address;
    licenseNumberController.text = current.licenseNumber;

    imageUrl.value = current.imageUrl ?? '';
    latitude.value = current.location.latitude;
    longitude.value = current.location.longitude;
  }

  Future<void> loadSettings() async {
    if (pharmacyId.isEmpty) {
      errorMessage.value = 'لم يتم العثور على معرف الصيدلية';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final pharmacyRef = _firestore.collection('pharmacies').doc(pharmacyId);
      final pharmacyDoc = await pharmacyRef.get();

      if (!pharmacyDoc.exists || pharmacyDoc.data() == null) {
        errorMessage.value = 'بيانات الصيدلية غير موجودة';
        return;
      }

      final data = pharmacyDoc.data()!;

      final generalDoc = await pharmacyRef.collection('settings').doc('general').get();
      final generalData = generalDoc.data() ?? <String, dynamic>{};

      Map<String, dynamic> businessHoursData = {};
      final businessHoursDoc =
      await pharmacyRef.collection('settings').doc('businessHours').get();
      if (businessHoursDoc.exists && businessHoursDoc.data() != null) {
        businessHoursData = businessHoursDoc.data()!;
      } else if (data['businessHours'] is Map<String, dynamic>) {
        businessHoursData = Map<String, dynamic>.from(data['businessHours']);
      }

      final locationData = data['location'] is Map
          ? Map<String, dynamic>.from(data['location'])
          : <String, dynamic>{};

      final double parsedLat =
          _parseDouble(locationData['latitude']) ??
              _parseDouble(locationData['lat']) ??
              _parseDouble(data['latitude']) ??
              _parseDouble(data['lat']) ??
              0.0;

      final double parsedLng =
          _parseDouble(locationData['longitude']) ??
              _parseDouble(locationData['lng']) ??
              _parseDouble(data['longitude']) ??
              _parseDouble(data['lng']) ??
              0.0;

      final String parsedAddress =
      (locationData['address']?.toString().trim().isNotEmpty ?? false)
          ? locationData['address'].toString().trim()
          : (data['address']?.toString().trim().isNotEmpty ?? false)
          ? data['address'].toString().trim()
          : '';

      final bool parsedIs24Hours =
          (generalData['is24Hours'] ?? data['is24Hours'] ?? false) == true;

      final bool parsedIsOnline =
          (generalData['isOnline'] ?? data['isOnline'] ?? false) == true;

      final loaded = PharmacySettings(
        uid: data['id']?.toString() ?? pharmacyId,
        name: data['pharmacyName']?.toString() ?? '',
        ownerName: data['ownerName']?.toString() ?? '',
        ownerIdNumber: data['ownerIdNumber']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        phoneNumber: data['phoneNumber']?.toString() ?? '',
        address: parsedAddress,
        licenseNumber: data['licenseNumber']?.toString() ?? '',
        status: data['status']?.toString() ?? 'pending',
        is24Hours: parsedIs24Hours,
        isOnline: parsedIsOnline,
        imageUrl: data['imageUrl']?.toString() ?? '',
        location: PharmacyLocation(
          latitude: parsedLat,
          longitude: parsedLng,
          address: parsedAddress,
        ),
        businessHours: BusinessHours.fromMap(
          businessHoursData,
          is24Hours: parsedIs24Hours,
        ),
        createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
        updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : Timestamp.now(),
        notificationsEnabled: (generalData['notificationsEnabled'] ?? true) == true,
      );

      settings.value = loaded;
      imageUrl.value = loaded.imageUrl ?? '';
      latitude.value = loaded.location.latitude ?? 0.0;
      longitude.value = loaded.location.longitude ?? 0.0;

      nameController.text = loaded.name ?? '';
      ownerNameController.text = loaded.ownerName ?? '';
      ownerIdNumberController.text = loaded.ownerIdNumber ?? '';
      emailController.text = loaded.email ?? '';
      phoneController.text = loaded.phoneNumber ?? '';
      addressController.text = loaded.address ?? '';
      licenseNumberController.text = loaded.licenseNumber ?? '';
    } catch (e, st) {
      errorMessage.value = 'فشل في تحميل الإعدادات: $e';
      print('loadSettings error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

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
      isUploadingImage.value = true;

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
        final progress =
            (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'imageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      imageUrl.value = downloadUrl;
      settings.value = settings.value.copyWith(
        imageUrl: downloadUrl,
        updatedAt: Timestamp.now(),
      );

      return downloadUrl;
    } catch (e) {
      _showErrorSnackbar('فشل في رفع الصورة: $e');
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> deleteCurrentImage() async {
    if (pharmacyId.isEmpty || imageUrl.value.isEmpty) return;

    try {
      isUploadingImage.value = true;

      final currentUrl = imageUrl.value;
      try {
        final ref = _storage.refFromURL(currentUrl);
        await ref.delete();
      } catch (e) {
        print('Note: Could not delete from Storage: $e');
      }

      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'imageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      imageUrl.value = '';
      settings.value = settings.value.copyWith(imageUrl: '');
    } catch (e) {
      _showErrorSnackbar('فشل في حذف الصورة: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<bool> updateSettings({bool requireLocation = false}) async {
    if (pharmacyId.isEmpty) {
      errorMessage.value = 'لم يتم العثور على معرف الصيدلية';
      return false;
    }

    if (!validateAllFields(requireLocation: requireLocation)) {
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final pharmacyRef = _firestore.collection('pharmacies').doc(pharmacyId);

      final updateData = <String, dynamic>{
        'pharmacyName': nameController.text.trim(),
        'ownerName': ownerNameController.text.trim(),
        'ownerIdNumber': ownerIdNumberController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'licenseNumber': licenseNumberController.text.trim(),
        'is24Hours': settings.value.is24Hours ?? false,
        'isOnline': settings.value.isOnline ?? false,
        'location': {
          'address': addressController.text.trim(),
          'latitude': latitude.value,
          'longitude': longitude.value,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl.value.isNotEmpty) {
        updateData['imageUrl'] = imageUrl.value;
      }

      await pharmacyRef.update(updateData);

      await pharmacyRef.collection('settings').doc('general').set({
        'is24Hours': settings.value.is24Hours ?? false,
        'isOnline': settings.value.isOnline ?? false,
        'notificationsEnabled': settings.value.notificationsEnabled ?? true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final pharmacyDoc = await pharmacyRef.get();
      final pharmacyData = pharmacyDoc.data();
      if (pharmacyData == null) return false;

      await SearchIndexService().rebuildPharmacyIndex(
        pharmacyId: pharmacyId,
        pharmacyData: pharmacyData,
      );

      settings.value = settings.value.copyWith(
        name: nameController.text.trim(),
        ownerName: ownerNameController.text.trim(),
        ownerIdNumber: ownerIdNumberController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        licenseNumber: licenseNumberController.text.trim(),
        imageUrl: imageUrl.value,
        location: PharmacyLocation(
          latitude: latitude.value,
          longitude: longitude.value,
          address: addressController.text.trim(),
        ),
      );
      isLoading.value = false;
      Get.back();
      Get.snackbar('نجاح', 'تم تحديث البيانات والبحث بنجاح');
      return true;
    } catch (e) {
      errorMessage.value = 'فشل في حفظ الإعدادات: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveBusinessHours(BusinessHours newHours) async {
    final currentSettings = settings.value;

    final pharmacyRef = _firestore
        .collection('pharmacies')
        .doc(pharmacyId);

    final businessHoursRef = pharmacyRef
        .collection('settings')
        .doc('businessHours');

    final Map<String, dynamic> toSave = currentSettings.is24Hours == true
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
      'sunday': newHours.sunday,
      'monday': newHours.monday,
      'tuesday': newHours.tuesday,
      'wednesday': newHours.wednesday,
      'thursday': newHours.thursday,
      'friday': newHours.friday,
      'saturday': newHours.saturday,
    };

    await businessHoursRef.set({
      ...toSave,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // مهم جدًا: هذا يخلي تطبيق المستخدم يسمع التغيير
    await pharmacyRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });

    settings.value = currentSettings.copyWith(
      businessHours: currentSettings.is24Hours == true
          ? BusinessHours(
        sunday: '24 Hours',
        monday: '24 Hours',
        tuesday: '24 Hours',
        wednesday: '24 Hours',
        thursday: '24 Hours',
        friday: '24 Hours',
        saturday: '24 Hours',
      )
          : newHours,
    );
  }

  Future<void> toggleDayStatus(String dayKey) async {
    final current = settings.value;
    final hours = current.businessHours;

    final currentTime = _getDayTime(dayKey, hours);
    final isClosed = currentTime.toLowerCase() == 'مغلق';
    final newTime = isClosed ? '09:00 ص - 05:00 م' : 'مغلق';

    final newHours = BusinessHours(
      sunday: dayKey == 'sunday' ? newTime : hours.sunday,
      monday: dayKey == 'monday' ? newTime : hours.monday,
      tuesday: dayKey == 'tuesday' ? newTime : hours.tuesday,
      wednesday: dayKey == 'wednesday' ? newTime : hours.wednesday,
      thursday: dayKey == 'thursday' ? newTime : hours.thursday,
      friday: dayKey == 'friday' ? newTime : hours.friday,
      saturday: dayKey == 'saturday' ? newTime : hours.saturday,
    );

    settings.value = current.copyWith(businessHours: newHours);
    await saveBusinessHours(newHours);
  }

  String _getDayTime(String dayKey, BusinessHours hours) {
    switch (dayKey) {
      case 'sunday':
        return hours.sunday;
      case 'monday':
        return hours.monday;
      case 'tuesday':
        return hours.tuesday;
      case 'wednesday':
        return hours.wednesday;
      case 'thursday':
        return hours.thursday;
      case 'friday':
        return hours.friday;
      case 'saturday':
        return hours.saturday;
      default:
        return 'مغلق';
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

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('settings')
          .doc('general')
          .set({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      settings.value = settings.value.copyWith(isOnline: isOnline);
      return true;
    } catch (e) {
      errorMessage.value = 'فشل في تحديث الحالة: $e';
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

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('settings')
          .doc('general')
          .set({
        'is24Hours': is24,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      settings.value = settings.value.copyWith(is24Hours: is24);
      return true;
    } catch (e) {
      errorMessage.value = 'فشل في تحديث وضع 24 ساعة: $e';
      return false;
    }
  }

  Future<void> toggle24HoursWithUI() async {
    try {
      final newValue = !(settings.value.is24Hours ?? false);
      final success = await update24HoursStatus(newValue);
      if (!success) {
        _showErrorSnackbar('فشل في تحديث وضع 24 ساعة');
      }
    } catch (_) {
      _showErrorSnackbar('فشل في تحديث وضع 24 ساعة');
    }
  }

  Future<void> toggleOnlineStatusWithUI() async {
    try {
      final newValue = !(settings.value.isOnline ?? false);
      final success = await updateOnlineStatus(newValue);
      if (!success) {
        _showErrorSnackbar('فشل في تحديث الحالة');
      }
    } catch (_) {
      _showErrorSnackbar('فشل في تحديث الحالة');
    }
  }

  Future<bool> saveSettingsWithUI({bool requireLocation = false}) async {
    final success = await updateSettings(requireLocation: requireLocation);

    if (success) {
      _showSuccessSnackbar('تم حفظ الإعدادات بنجاح');
      return true;
    } else {
      final error =
      errorMessage.value.isNotEmpty ? errorMessage.value : 'فشل في حفظ الإعدادات';
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

  bool get is24HoursValue => settings.value.is24Hours ?? false;
  bool get isOnlineValue => settings.value.isOnline ?? false;
  String get imageUrlValue => settings.value.imageUrl ?? '';
  String get nameValue => settings.value.name ?? '';
  PharmacySettings get currentSettings => settings.value;
  bool get hasImage => imageUrl.value.isNotEmpty;

  void startRealtimeListener() {
    if (pharmacyId.isEmpty) return;

    _settingsSub?.cancel();
    _settingsSub = _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;

      final data = snapshot.data()!;
      final locationData = data['location'] is Map
          ? Map<String, dynamic>.from(data['location'])
          : <String, dynamic>{};

      final liveLat =
          _parseDouble(locationData['latitude']) ??
              _parseDouble(locationData['lat']) ??
              latitude.value;

      final liveLng =
          _parseDouble(locationData['longitude']) ??
              _parseDouble(locationData['lng']) ??
              longitude.value;

      final liveAddress =
          locationData['address']?.toString() ?? addressController.text.trim();

      settings.value = settings.value.copyWith(
        isOnline: data['isOnline'] ?? settings.value.isOnline,
        is24Hours: data['is24Hours'] ?? settings.value.is24Hours,
        name: data['pharmacyName']?.toString() ?? settings.value.name,
        ownerName: data['ownerName']?.toString() ?? settings.value.ownerName,
        ownerIdNumber:
        data['ownerIdNumber']?.toString() ?? settings.value.ownerIdNumber,
        email: data['email']?.toString() ?? settings.value.email,
        phoneNumber: data['phoneNumber']?.toString() ?? settings.value.phoneNumber,
        licenseNumber:
        data['licenseNumber']?.toString() ?? settings.value.licenseNumber,
        address: liveAddress,
        imageUrl: data['imageUrl']?.toString() ?? settings.value.imageUrl,
        status: data['status']?.toString() ?? settings.value.status,
        location: PharmacyLocation(
          latitude: liveLat,
          longitude: liveLng,
          address: liveAddress,
        ),
      );

      latitude.value = liveLat;
      longitude.value = liveLng;
      imageUrl.value = data['imageUrl']?.toString() ?? imageUrl.value;

      nameController.text = settings.value.name ?? '';
      ownerNameController.text = settings.value.ownerName ?? '';
      ownerIdNumberController.text = settings.value.ownerIdNumber ?? '';
      emailController.text = settings.value.email ?? '';
      phoneController.text = settings.value.phoneNumber ?? '';
      addressController.text = settings.value.address ?? '';
      licenseNumberController.text = settings.value.licenseNumber ?? '';
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
    for (final key in fieldErrors.keys) {
      fieldErrors[key] = null;
    }
    fieldErrors.refresh();
    errorMessage.value = '';
    successMessage.value = '';
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
    final reg = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!reg.hasMatch(value.trim())) return 'البريد الإلكتروني غير صالح';
    return null;
  }

  String? validatePhone(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال رقم الهاتف';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'رقم الهاتف يجب أن يحتوي بين 7 و 15 رقم';
    }
    return null;
  }

  String? validateAddress(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال العنوان';
    return null;
  }

  String? validateLicenseNumber(String value) {
    if (value.trim().isEmpty) return 'الرجاء إدخال رقم الترخيص';
    if (value.trim().length < 3) return 'رقم الترخيص غير صالح';
    return null;
  }

  bool validateLocation() {
    if (latitude.value == 0.0 && longitude.value == 0.0) {
      errorMessage.value = 'إحداثيات الموقع غير محددة';
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
      errorMessage.value = 'يرجى تصحيح الحقول المشار إليها';
      return false;
    }

    if (requireLocation && !validateLocation()) {
      return false;
    }

    errorMessage.value = '';
    return true;
  }
}