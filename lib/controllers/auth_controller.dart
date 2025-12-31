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

  // للمستخدم الداخلي (موظف الصيدلية)
  RxString internalUsername = ''.obs;
  RxString internalPassword = ''.obs;

  // بيانات المستخدم الحالي
  RxString currentUserName = ''.obs;
  RxString currentUserRole = ''.obs;

  // بيانات الصيدلية
  final RxMap<String, dynamic> pharmacyData = <String, dynamic>{}.obs;
  Rx<Map<String, dynamic>?> currentEmployee = Rx<Map<String, dynamic>?>(null);
  final isPharmacyLoaded = false.obs;
  final isPermissionsLoaded = false.obs;
  RxMap<String, bool> rolePermissions = <String, bool>{}.obs;
  RxMap<String, bool> employeeOverrides = <String, bool>{}.obs;

  // تسجيل الخروج الداخلي
  void logoutInternal() {
    currentEmployee.value = null;
    internalUsername.value = '';
    internalPassword.value = '';
    currentUserName.value = '';
    currentUserRole.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _localStorage.init();

    _auth.authStateChanges().listen((user) {
      currentUser.value = user;

      if (user != null && !isPharmacyLoaded.value) {
        loadPharmacyData(user.uid);
      }
    });
  }

  // تسجيل الدخول
  Future<void> login() async {
    if (!_validateLogin()) return;
    try {
      isLoading.value = true;
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );
      final user = userCredential.user;
      if (user != null) {
        await _checkUserStatus(user.uid);
      }
      email.value = '';
      password.value = '';


    } on FirebaseAuthException catch (e) {
      _handleFirebaseLoginError(e);

    } catch (_) {
      Get.snackbar(
        "خطأ غير متوقع",
        "حدث خطأ غير معروف، حاول مرة أخرى",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

    } finally {
      isLoading.value = false;
    }
  }

  void _handleFirebaseLoginError(FirebaseAuthException e) {
    String title = "خطأ";
    String message = "حدث خطأ أثناء تسجيل الدخول";

    switch (e.code) {
      case 'network-request-failed':
        title = "لا يوجد اتصال بالإنترنت";
        message = "تأكد من اتصالك بالإنترنت وحاول مرة أخرى";
        break;

      case 'user-not-found':
        title = "الحساب غير موجود";
        message = "لا يوجد حساب مرتبط بهذا البريد الإلكتروني";
        break;

      case 'wrong-password':
        title = "كلمة مرور خاطئة";
        message = "كلمة المرور غير صحيحة";
        break;

      case 'invalid-email':
        title = "بريد إلكتروني غير صالح";
        message = "تحقق من صيغة البريد الإلكتروني";
        break;

      case 'user-disabled':
        title = "الحساب موقوف";
        message = "تم إيقاف هذا الحساب، يرجى التواصل مع الإدارة";
        break;

      case 'too-many-requests':
        title = "محاولات كثيرة";
        message = "تم حظر المحاولة مؤقتًا، حاول لاحقًا";
        break;
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
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

      // تحديث اسم المستخدم والدور
      currentUserName.value = employee['username'] ?? '';
      currentUserRole.value = await _getRoleName(pharmacyId, employee['roleId']);

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

  Future<String> _getRoleName(String pharmacyId, String roleId) async {
    try {
      if (roleId == 'admin') return 'مدير النظام';

      final roleDoc = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('roles')
          .doc(roleId)
          .get();

      if (roleDoc.exists) {
        return roleDoc.data()?['name'] ?? roleId;
      }
      return roleId;
    } catch (e) {
      print('❌ خطأ في جلب اسم الدور: $e');
      return roleId;
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

  void _clearLocalData() {
    email.value = '';
    password.value = '';
    pharmacyData.clear();
    currentEmployee.value = null;
    currentUserName.value = '';
    currentUserRole.value = '';
  }

  // دالة تبديل المستخدم
  Future<void> switchUser() async {
    try {
      // حفظ بيانات الصيدلية الحالية
      final currentPharmacyId = pharmacyId;
      final currentPharmacyName = pharmacyData['pharmacyName'] ?? '';

      // مسح بيانات الموظف الحالي
      currentEmployee.value = null;
      currentUserName.value = '';
      currentUserRole.value = '';
      internalUsername.value = '';
      internalPassword.value = '';

      // العودة إلى صفحة تسجيل الدخول الداخلي
      Get.offAll(() => const InternalLoginPage());

    } catch (e) {
      print('❌ خطأ في تبديل المستخدم: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تبديل المستخدم',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Getters
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;

  // Getter لاسم المستخدم
  String get userName {
    if (currentUserName.value.isNotEmpty) {
      return currentUserName.value;
    }

    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return userEmail?.split('@').first ?? 'مستخدم';
  }

  // Getter لدور المستخدم
  String get userRole {
    if (currentUserRole.value.isNotEmpty) {
      return currentUserRole.value;
    }

    if (currentEmployee.value != null) {
      return 'موظف';
    }

    return 'صاحب الصيدلية';
  }

  /// هل المستخدم الحالي صاحب صيدلية (FirebaseAuth)
  bool get isOwner => currentUser.value != null;

  /// معرف الصيدلية الحالي
  String get pharmacyId => userId ?? '';

  /// من قام بالفعل (Owner أو Employee)
  Map<String, dynamic> get actorInfo {
    if (currentEmployee.value != null) {
      // طباعة البيانات للتحقق
      print('🔍 currentEmployee.value: ${currentEmployee.value}');

      return {
        'type': 'employee',
        'id': currentEmployee.value!['id']?.toString() ??
            currentEmployee.value!['userId']?.toString() ??
            FirebaseAuth.instance.currentUser?.uid ??
            'unknown_employee',
        'name': currentEmployee.value!['name']?.toString() ??
            currentEmployee.value!['fullName']?.toString() ??
            currentEmployee.value!['username']?.toString() ??
            currentUserName.value,
        'username': currentUserName.value,
        'role': currentUserRole.value,
        'roleId': currentEmployee.value!['roleId']?.toString() ?? 'employee',
      };
    }

    // صاحب الصيدلية
    final user = FirebaseAuth.instance.currentUser;
    return {
      'type': 'owner',
      'id': user?.uid ?? 'unknown_owner',
      'email': user?.email ?? '',
      'name': userName,
      'role': 'صاحب الصيدلية',
    };
  }

  // في AuthController
  Future<Map<String, dynamic>> getSaleActorInfo() async {
    try {
      print('🔍 جلب معلومات منفذ البيع...');

      if (currentEmployee.value != null) {
        print('👤 موظف داخلي: ${currentEmployee.value}');

        // محاولة جلب البيانات الكاملة من Firestore
        final employeeId = currentEmployee.value!['id']?.toString() ??
            currentEmployee.value!['userId']?.toString();

        if (employeeId != null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('pharmacies')
                .doc(pharmacyId)
                .collection('employees')
                .doc(employeeId)
                .get();

            if (doc.exists) {
              final data = doc.data();
              return {
                'type': 'employee',
                'id': employeeId,
                'name': data?['name'] ??
                    data?['fullName'] ??
                    currentEmployee.value!['username'] ??
                    'موظف',
                'username': currentUserName.value,
                'role': currentUserRole.value,
                'roleId': currentEmployee.value!['roleId'] ?? 'employee',
                'pharmacyId': pharmacyId,
              };
            }
          } catch (e) {
            print('⚠️ فشل جلب بيانات الموظف من Firestore: $e');
          }
        }

        // استخدام البيانات المحلية
        return {
          'type': 'employee',
          'id': employeeId ?? FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          'name': currentEmployee.value!['name']?.toString() ??
              currentEmployee.value!['fullName']?.toString() ??
              currentEmployee.value!['username']?.toString() ??
              currentUserName.value,
          'username': currentUserName.value,
          'role': currentUserRole.value,
          'roleId': currentEmployee.value!['roleId']?.toString() ?? 'employee',
          'pharmacyId': pharmacyId,
        };
      }

      // صاحب الصيدلية
      final user = FirebaseAuth.instance.currentUser;
      print('👑 صاحب الصيدلية: ${user?.email}');

      return {
        'type': 'owner',
        'id': user?.uid ?? 'unknown_owner',
        'email': user?.email ?? '',
        'name': userName,
        'role': 'صاحب الصيدلية',
        'pharmacyId': pharmacyId,
      };

    } catch (e, stackTrace) {
      print('❌ خطأ في getSaleActorInfo: $e');
      print('📜 Stack trace: $stackTrace');

      // بيانات افتراضية
      return {
        'type': 'unknown',
        'id': 'error_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'موظف',
        'role': 'موظف',
        'pharmacyId': pharmacyId,
      };
    }
  }



}