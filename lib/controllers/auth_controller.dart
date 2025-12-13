import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pharmacy_desktop/controllers/settings_controller.dart';
import 'package:pharmacy_desktop/services/firestore_service.dart';
import 'package:pharmacy_desktop/services/local_storage_service.dart';
import '../views/home_page.dart';
import '../views/login_page.dart';
import '../views/waiting_approval_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();

  // Rx variables
  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;
  var currentUser = Rxn<User>();

  // بيانات الصيدلية
  final RxMap<String, dynamic> pharmacyData = <String, dynamic>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _localStorage.init();
    _auth.authStateChanges().listen((user) {
      currentUser.value = user;
      if (user != null) {
        loadPharmacyData(user.uid);
      }
    });
  }

  // تسجيل الدخول
  Future<void> login() async {
    try {
      if (!_validateLogin()) return;
      isLoading.value = true;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = userCredential.user;
      if (user != null) {
        await _checkUserStatus(user.uid);
      }

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

  // تحميل بيانات الصيدلية
  Future<void> loadPharmacyData(String uid) async {
    try {
      isLoading.value = true;

      // جلب بيانات الصيدلية من Firestore
      final data = await _firestoreService.getPharmacyData(uid);

      if (data != null) {
        pharmacyData.value = {
          'name': data['pharmacyName'] ?? 'غير معروف',
          'address': data['addressDescription'] ?? 'غير معروف',
          'ownerName': data['ownerName'] ?? 'غير معروف',
          'phone': data['phoneNumber'] ?? 'غير معروف',
          'status': data['status'] ?? 'pending',
          'is24Hours': data['is24Hours'] ?? false,
          'isOnline': data['isOnline'] ?? false,
        };

        // تحميل إعدادات الصيدلية
        await _loadPharmacySettings();
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('Error loading pharmacy data: $e');
    }
  }

  // التحقق من حالة المستخدم
  Future<void> _checkUserStatus(String uid) async {
    try {
      final result = await _firestoreService.checkApprovalStatus(uid);
      if (result?['exists'] == true) {
        final status = result!['status'];
        final collection = result['collection'];

        if (status == "approved") {
          // إذا كان الطلب معتمداً لكنه في pharmacyRequests، أنقله إلى pharmacies
          if (collection == 'pharmacyRequests') {
            await _firestoreService.createPharmacyFromRequest(uid, result['data']);
          }

          // تحميل بيانات الصيدلية
          await loadPharmacyData(uid);

          Get.offAll(() => const HomePage());
          return;
        } else if (status == "pending") {
          Get.offAll(() => const WaitingApprovalPage());
          return;
        } else if (status == "rejected") {
          await logout();
          Get.snackbar(
            "تم رفض طلبك",
            "يرجى التواصل مع الإدارة",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // إذا لم يكن لديه طلب تسجيل
      Get.offAll(() => const WaitingApprovalPage());
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في التحقق من الحالة: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

  // التحقق من بيانات تسجيل الدخول
  bool _validateLogin() {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar("خطأ", "البريد الإلكتروني وكلمة المرور مطلوبان",
          backgroundColor: Colors.orange);
      return false;
    }

    if (!email.value.contains('@')) {
      Get.snackbar("خطأ", "البريد الإلكتروني غير صالح",
          backgroundColor: Colors.orange);
      return false;
    }

    return true;
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

  // Getters
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;

  // Getter لاسم المستخدم
  String get userName {
    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return userEmail?.split('@').first ?? 'مستخدم';
  }

  // Getter لدور المستخدم
  String get userRole {
    final data = pharmacyData;
    if (data.isNotEmpty && data['role'] != null) {
      return data['role'];
    }
    return 'صاحب الصيدلية'; // الدور الافتراضي
  }
}