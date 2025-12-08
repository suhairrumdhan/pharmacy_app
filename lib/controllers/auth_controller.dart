import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:pharmacy_desktop/controllers/settings_controller.dart';
import 'package:pharmacy_desktop/services/firestore_service.dart';
import 'package:pharmacy_desktop/services/location_service.dart';
import 'package:pharmacy_desktop/services/local_storage_service.dart';
import '../views/home_page.dart';
import '../views/login_page.dart';
import '../views/waiting_approval_page.dart';

class AuthController extends GetxController {
  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();

  // المتغيرات القابلة للملاحظة
  var email = ''.obs;
  var password = ''.obs;
  var pharmacyName = ''.obs;
  var ownerName = ''.obs;
  var licenseNumber = ''.obs;
  var phoneNumber = ''.obs;
  var address = ''.obs;
  var isLoading = false.obs;
  Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  RxMap<String, dynamic> pharmacyData = <String, dynamic>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _localStorage.init();
    if (_auth.currentUser != null) {
      await loadPharmacyData();
    }
  }

  // الحصول على الموقع الحالي
  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;

      Get.snackbar(
        "جاري الحصول على الموقع",
        "يرجى الانتظار...",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      final location = await _locationService.getCurrentLocation();

      if (location != null) {
        selectedLocation.value = location;

        // جلب العنوان
        final addressStr = await _locationService.getAddressForLocation(
            location.latitude, location.longitude);

        if (addressStr != null && address.value.isEmpty) {
          address.value = addressStr;
        }

        Get.snackbar(
          "تم تحديد موقعك بنجاح",
          "الإحداثيات: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // استخدام الموقع الافتراضي
        selectedLocation.value = _locationService.getSafeDefaultLocation();
        address.value = "موقع افتراضي - ليبيا";
        Get.snackbar(
          "تنبيه",
          "تم استخدام موقع افتراضي",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("خطأ في الحصول على الموقع: $e");
      Get.snackbar("خطأ", "فشل في تحديد الموقع", backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // اختيار موقع يدوي
  void selectLocation(LatLng location) {
    selectedLocation.value = location;
  }

  // مسح الموقع
  void clearLocation() {
    selectedLocation.value = null;
  }

  // مسح النموذج
  void clearForm() {
    email.value = '';
    password.value = '';
    pharmacyName.value = '';
    ownerName.value = '';
    licenseNumber.value = '';
    phoneNumber.value = '';
    address.value = '';
    selectedLocation.value = null;
  }

  // تسجيل الصيدلية
  Future<void> signUpPharmacy() async {
    try {
      if (!_validatePharmacySignUp()) return;

      if (selectedLocation.value == null) {
        Get.snackbar("الموقع مطلوب", "حدد موقع الصيدلية",
            backgroundColor: Colors.orange);
        return;
      }

      isLoading.value = true;
      print("📝 بدء تسجيل صيدلية جديدة...");

      // إنشاء المستخدم في Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = userCredential.user!;
      final String uid = user.uid;
      print("✅ حساب مستخدم مخلوق - UID: $uid");

      // إضافة طلب التسجيل إلى Firestore
      await _firestoreService.createPharmacyRequest(
        userId: uid,
        email: email.value.trim(),
        pharmacyName: pharmacyName.value.trim(),
        ownerName: ownerName.value.trim(),
        licenseNumber: licenseNumber.value.trim(),
        phoneNumber: phoneNumber.value.trim(),
        address: address.value.trim(),
        latitude: selectedLocation.value!.latitude,
        longitude: selectedLocation.value!.longitude,
      );

      isLoading.value = false;

      Get.snackbar(
        "تم تقديم الطلب بنجاح",
        "سيتم مراجعة طلبك من قبل الإدارة",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      Get.offAll(() => const WaitingApprovalPage());
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      _handleAuthError(e);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("خطأ", "فشل في التسجيل: ${e.toString()}",
          backgroundColor: Colors.red);
    }
  }

  // التحقق من بيانات تسجيل الصيدلية
  bool _validatePharmacySignUp() {
    final errors = <String>[];

    if (email.value.isEmpty || !email.value.contains('@')) {
      errors.add('البريد الإلكتروني غير صحيح');
    }
    if (password.value.length < 6) {
      errors.add('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }
    if (pharmacyName.value.isEmpty) {
      errors.add('اسم الصيدلية مطلوب');
    }
    if (ownerName.value.isEmpty) {
      errors.add('اسم المالك مطلوب');
    }
    if (licenseNumber.value.isEmpty) {
      errors.add('رقم الترخيص مطلوب');
    }
    if (phoneNumber.value.isEmpty) {
      errors.add('رقم الهاتف مطلوب');
    }
    if (address.value.isEmpty) {
      errors.add('العنوان مطلوب');
    }
    if (selectedLocation.value == null) {
      errors.add('يرجى تحديد موقع الصيدلية على الخريطة');
    }

    if (errors.isNotEmpty) {
      Get.snackbar("خطأ في البيانات", errors.join('\n'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5));
      return false;
    }

    return true;
  }

  Future<void> _checkUserTypeAndRedirect(String uid) async {
    final result = await _firestoreService.checkApprovalStatus(uid);

    if (result?['exists'] == true) {
      final status = result!['status'];
      final collection = result['collection'];

      if (status == "approved") {
        // إذا كان الطلب معتمداً لكنه في pharmacyRequests، أنقله إلى pharmacies
        if (collection == 'pharmacyRequests') {
          await _firestoreService.createPharmacyFromRequest(
              uid, result['data']);
        }

        Get.offAll(() => const HomePage());
        return;
      }
    }

    Get.offAll(() => const WaitingApprovalPage());
  }

  // إعادة تسجيل الدخول بعد الموافقة
  Future<bool> reLoginAfterApproval() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return false;

      // تسجيل الخروج أولاً
      await FirebaseAuth.instance.signOut();

      // لن نتمكن من إعادة تسجيل الدخول تلقائياً بعد إزالة حفظ كلمة المرور
      // سيحتاج المستخدم لإدخال كلمة المرور يدوياً
      Get.snackbar(
        "تم الموافقة على طلبك",
        "يرجى تسجيل الدخول باستخدام بريدك الإلكتروني وكلمة المرور",
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      );

      return false;
    } catch (e) {
      print("🔥 فشل إعادة تسجيل الدخول: $e");
      return false;
    }
  }

  bool _validateLogin() {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar("خطأ", "البريد الإلكتروني وكلمة المرور مطلوبان",
          backgroundColor: Colors.orange);
      return false;
    }
    return true;
  }

  Future<void> login() async {
    try {
      if (!_validateLogin()) return;
      isLoading.value = true;

      // تسجيل الدخول
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = userCredential.user;

      // تحديث token
      await user?.getIdToken(true);

      // Check user type and redirect
      if (user != null) {
        await _checkUserTypeAndRedirect(user.uid);
      }

      // Load pharmacy data if needed
      await loadPharmacyData();
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      _handleAuthError(e);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "خطأ",
        "فشل في تسجيل الدخول: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // معالجة أخطاء المصادقة
  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = "لا يوجد مستخدم بهذا البريد الإلكتروني";
        break;
      case 'wrong-password':
        message = "كلمة المرور غير صحيحة";
        break;
      case 'invalid-email':
        message = "بريد إلكتروني غير صحيح";
        break;
      case 'user-disabled':
        message = "هذا الحساب معطل";
        break;
      case 'email-already-in-use':
        message = "هذا البريد الإلكتروني مستخدم بالفعل";
        break;
      case 'weak-password':
        message = "كلمة المرور ضعيفة جداً";
        break;
      case 'network-request-failed':
        message = "خطأ في الشبكة";
        break;
      default:
        message = "فشل في المصادقة: ${e.message}";
    }

    Get.snackbar("خطأ في المصادقة", message, backgroundColor: Colors.red);
  }

  // تحميل بيانات الصيدلية
  Future<void> loadPharmacyData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final data = await _firestoreService.getPharmacyData(uid);
    if (data != null) {
      pharmacyData.value = data;
      await _loadPharmacySettings();
    }
  }

  // تحميل إعدادات الصيدلية
  Future<void> _loadPharmacySettings() async {
    try {
      final settingsController = Get.find<SettingsController>();
      await settingsController.loadSettings();
    } catch (e) {
      print('Error loading pharmacy settings: $e');
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _clearLocalData();
      Get.offAll(() => const LoginPage());
    } catch (e) {
      Get.snackbar("خطأ", "فشل في تسجيل الخروج: ${e.toString()}",
          backgroundColor: Colors.red);
    }
  }

  // مسح البيانات المحلية
  void _clearLocalData() {
    email.value = '';
    password.value = '';
    pharmacyName.value = '';
    ownerName.value = '';
    licenseNumber.value = '';
    phoneNumber.value = '';
    address.value = '';
    selectedLocation.value = null;
    pharmacyData.clear();
  }

  // التحقق من الاتصال
  Future<bool> checkConnection() async {
    try {
      await _auth.currentUser?.getIdToken();
      return true;
    } catch (e) {
      return false;
    }
  }
}