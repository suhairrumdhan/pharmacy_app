import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pharmacy_desktop/controllers/settings_controller.dart';
import 'package:pharmacy_desktop/services/firestore_service.dart';
import 'package:pharmacy_desktop/services/local_storage_service.dart';
import '../internal_login_page.dart';
import '../views/home_page.dart';
import '../views/login_page.dart';
import '../views/sign_up/signup_page.dart';
import '../views/waiting_approval_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // Rx variables
  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;
  var currentUser = Rxn<User>();

  RxString internalUsername = ''.obs;
  RxString internalPassword = ''.obs;
  // بيانات الصيدلية
  final RxMap<String, dynamic> pharmacyData = <String, dynamic>{}.obs;
  Rx<Map<String, dynamic>?> currentEmployee = Rx<Map<String, dynamic>?>(null);

  final isPharmacyLoaded = false.obs;
  final isPermissionsLoaded = false.obs;

// من Firestore
  RxMap<String, bool> rolePermissions = <String, bool>{}.obs;
  RxMap<String, bool> employeeOverrides = <String, bool>{}.obs;

  // تسجيل الدخول الداخلي (الموظف)

  // تسجيل الخروج الداخلي
  void logoutInternal() {
    currentEmployee.value = null;
    internalUsername.value = '';
    internalPassword.value = '';
  }
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

  Future<bool> loginInternal({required String pharmacyId}) async {
    isLoading.value = true; // تفعيل حالة التحميل
    try {
      print('username: ${internalUsername.value}, password: ${internalPassword.value}, pharmacyId: $pharmacyId');

      // جلب بيانات الموظف
      final employee = await _firestoreService.getEmployeeByCredentials(
        pharmacyId: pharmacyId,
        username: internalUsername.value,
        password: internalPassword.value,
      );

      if (employee == null) {
        print('⚠️ خطأ: اسم المستخدم أو كلمة المرور خاطئة');
        return false;
      }

      // حفظ الموظف الحالي
      currentEmployee.value = employee;

      // تحميل الصلاحيات وبيانات الصيدلية
      await loadPermissions(pharmacyId);
      await loadPharmacyData(pharmacyId);

      return true;
    } catch (e, st) {
      print('❌ خطأ أثناء تسجيل الدخول : $e');
      print(st); // طباعة stack trace لتسهيل تتبع الأخطاء
      return false;
    } finally {
      isLoading.value = false; // إيقاف حالة التحميل دائماً
    }
  }


  Future<void> loadPermissions(String pharmacyId) async {
    final employee = currentEmployee.value;

    // تحقق من وجود الموظف
    if (employee == null) {
      print('⚠️ لم يتم العثور على الموظف الحالي.');
      isPermissionsLoaded.value = true; // لضمان انتهاء حالة التحميل في UI
      return;
    }

    final roleId = employee['roleId'];
    try {
      // جلب صلاحيات الدور من Firestore
      final roleDoc = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('permissions')
          .doc(roleId)
          .get();

      final roleData = roleDoc.data();

      if (roleData == null) {
        print('⚠️ لم يتم العثور على صلاحيات الدور $roleId للصيدلية $pharmacyId');
        rolePermissions.value = {};
      } else {
        rolePermissions.value = Map<String, bool>.from(roleData['permissions'] ?? {});
      }

      // Overrides الموظف
      employeeOverrides.value = Map<String, bool>.from(employee['permissionOverrides'] ?? {});
    } catch (e, st) {
      print('❌ خطأ أثناء تحميل الصلاحيات: $e');
      print(st);
      rolePermissions.value = {};
      employeeOverrides.value = {};
    } finally {
      // تأكيد انتهاء التحميل حتى عند الخطأ
      isPermissionsLoaded.value = true;
    }
  }

  bool can(String permission) {
    // Safety
    if (permission.isEmpty) return false;

    final employee = currentEmployee.value;
    if (employee == null) return false; // حماية null
    print('ROLE ID = ${employee['roleId']} (${employee['roleId'].runtimeType})');

    // Admin shortcut
    if (employee['roleId'] == 'admin') {
      return true;
    }

    // 1️⃣ Employee override (أعلى أولوية)
    if (employeeOverrides.containsKey(permission)) {
      return employeeOverrides[permission] == true;
    }

    // 2️⃣ Role permission
    if (rolePermissions.containsKey(permission)) {
      return rolePermissions[permission] == true;
    }

    // 3️⃣ Default deny
    return false;
  }

  Future<void> _checkUserStatus(String uid) async {
    try {
      final result = await _firestoreService.checkApprovalStatus(uid);

      if (result?['exists'] != true) {
        Get.offAll(() => const WaitingApprovalPage());
        return;
      }

      final status = result!['status'];
      final data = result['data'];

      switch (status) {
        case 'approved':
          final pharmacyExists =
          await _firestoreService.pharmacyExists(uid);

          if (!pharmacyExists) {
            await _firestoreService.createPharmacyFromRequest(uid, data);
          }

          await loadPharmacyData(uid);
          Get.offAll(() => const InternalLoginPage());
          break;

        case 'pending':
          Get.offAll(() => const WaitingApprovalPage());
          break;

        case 'rejected':
          await logout();
          Get.snackbar(
            'تم رفض الطلب',
            'يرجى التواصل مع الإدارة',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          break;

        default:
          throw Exception('Unknown status: $status');
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في التحقق من الحالة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> loadPharmacyData(String uid) async {
    isLoading.value = true; // تفعيل حالة التحميل في البداية

    try {
      final data = await _firestoreService.getPharmacyData(uid);

      if (data == null) {
        print('⚠️ لم يتم العثور على بيانات الصيدلية للـ UID: $uid');
        pharmacyData.value = {};
        isPharmacyLoaded.value = true; // لتجنب توقف الـ UI في حالة البيانات فارغة
        return;
      }

      // استخراج وصف الموقع بأمان
      final location = data['location'] as Map<String, dynamic>?;
      final addressDescription = location?['address'] ?? '';

      pharmacyData.value = {
        'pharmacyName': data['pharmacyName'] ?? 'غير معروف',
        'address': addressDescription,
        'ownerName': data['ownerName'] ?? 'غير معروف',
        'phone': data['phoneNumber'] ?? 'غير معروف',
        'status': data['status'] ?? 'pending',
        'is24Hours': data['is24Hours'] ?? false,
        'isOnline': data['isOnline'] ?? false,
      };

      // تحميل الإعدادات
      await _loadPharmacySettings();

      isPharmacyLoaded.value = true; // تأكيد انتهاء التحميل
    } catch (e, st) {
      print('❌ خطأ أثناء تحميل بيانات الصيدلية: $e');
      print(st);
      pharmacyData.value = {}; // تفريغ البيانات عند الخطأ
      isPharmacyLoaded.value = true; // لتجنب التحميل المستمر في الـ UI
    } finally {
      isLoading.value = false; // إيقاف حالة التحميل
    }
  }

  Future<void> _loadPharmacySettings() async {
    try {
      // التحقق من تسجيل SettingsController قبل الاستدعاء
      if (!Get.isRegistered<SettingsController>()) {
        print('⚠️ SettingsController غير مسجل.');
        return;
      }

      final settingsController = Get.find<SettingsController>();
      await settingsController.loadSettings();
    } catch (e, st) {
      print('❌ خطأ أثناء تحميل إعدادات الصيدلية: $e');
      print(st); // طباعة stack trace لتسهيل تتبع الخطأ
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

  /// هل المستخدم الحالي صاحب صيدلية (FirebaseAuth)
  bool get isOwner => currentUser.value != null;

  /// معرف الصيدلية الحالي
  String get pharmacyId => userId ?? '';

  /// من قام بالفعل (Owner أو Employee)
  Map<String, dynamic> get actorInfo {
    if (currentEmployee.value != null) {
      return {
        'type': 'employee',
        'id': currentEmployee.value!['id'],
        'name': currentEmployee.value!['name'],
        'roleId': currentEmployee.value!['roleId'],
      };
    }

    return {
      'type': 'owner',
      'id': userId,
      'email': userEmail,
    };
  }
}