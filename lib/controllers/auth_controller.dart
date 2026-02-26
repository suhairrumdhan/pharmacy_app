import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pharmacy_desktop/controllers/settings_controller.dart';
import 'package:pharmacy_desktop/controllers/shift_controller.dart';
import 'package:pharmacy_desktop/services/firestore_service.dart';
import 'package:pharmacy_desktop/services/local_storage_service.dart';
import '../internal_login_page.dart';
import '../views/home_page.dart';
import '../views/login_page.dart';
import '../views/waiting_approval_page.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Added iconsax import

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rx variables
  var email = ''.obs;
  var password = ''.obs;
  final isAuthLoading = false.obs;      // للّوجين/لوجاوت
  final isPharmacyLoading = false.obs;  // لتحميل بيانات الصيدلية
  final isInternalLoading = false.obs;  // لدخول الموظف
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



  void logoutInternal() {
    currentEmployee.value = null;

    internalUsername.value = '';
    internalPassword.value = '';

    currentUserName.value = '';
    currentUserRole.value = '';

    // ✅ مهم: امسح صلاحيات الموظف وارجع flags
    rolePermissions.clear();
    employeeOverrides.clear();
    isPermissionsLoaded.value = false;
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
  Future<void> loginOwner() async {
    if (!_validateLogin()) return;

    try {
      isAuthLoading.value = true;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = userCredential.user;
      if (user == null) return;

      // ✅ تحقق الموافقة + إنشاء الصيدلية لو تحتاج
      await _checkUserStatusAndGoHome(user.uid);

      email.value = '';
      password.value = '';
    } on FirebaseAuthException catch (e) {
      _handleFirebaseLoginError(e);
    } catch (e) {
      Get.snackbar(
        "خطأ غير متوقع",
        "حدث خطأ غير معروف، حاول مرة أخرى",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAuthLoading.value = false;
    }
  }
  Future<void> _checkUserStatusAndGoHome(String uid) async {
    final result = await _firestoreService.checkApprovalStatus(uid);

    if (result?['exists'] != true) {
      Get.offAll(() => const WaitingApprovalPage());
      return;
    }

    final status = result!['status'];
    final data = result['data'];

    switch (status) {
      case 'approved':
        final pharmacyExists = await _firestoreService.pharmacyExists(uid);
        if (!pharmacyExists) {
          await _firestoreService.createPharmacyFromRequest(uid, data);
        }

        // ✅ تحميل بيانات الصيدلية (المالك)
        await loadPharmacyData(uid);

        // ✅ هنا بالضبط: سجل ShiftController بعد نجاح الدخول
        if (!Get.isRegistered<ShiftController>()) {
          Get.put(ShiftController(), permanent: true);
        }

        // ✅ المالك يدخل Home مباشرة
        logoutInternal();
        isPermissionsLoaded.value = true;
        Get.offAll(() => const HomePage());
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
        Get.offAll(() => const WaitingApprovalPage());
    }
  }
  void openInternalLogin() {
    if (!isLoggedIn) {
      Get.snackbar('تنبيه', 'لازم المالك يسجل دخول أولاً');
      return;
    }
    Get.offAll(() => const InternalLoginPage());
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
    isInternalLoading.value = true; // تفعيل حالة التحميل
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
      isInternalLoading.value = false; // إيقاف حالة التحميل دائماً
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
    if (permission.isEmpty) return false;

    // ✅ المالك (FirebaseAuth) بدون موظف داخلي = صلاحيات كاملة
    if (currentEmployee.value == null) return true;

    final employee = currentEmployee.value!;
    if (employee['roleId'] == 'admin') return true; // لو عندك دور admin لموظف لاحقاً

    if (employeeOverrides.containsKey(permission)) {
      return employeeOverrides[permission] == true;
    }
    if (rolePermissions.containsKey(permission)) {
      return rolePermissions[permission] == true;
    }
    return false;
  }



  Future<void> logoutOwnerSecure() async {
    // ✅ لو فيه موظف داخلي شغال: نطلع الموظف فقط
    if (currentEmployee.value != null) {
      logoutInternal();
      Get.offAll(() => const InternalLoginPage());
      return;
    }

    final passCtrl = TextEditingController();
    bool isPasswordHidden = true;

    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: 320, // فقط أضفت هذا السطر
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.white,
                    Colors.blue.shade50,
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(.6)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Header
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'تأكيد تسجيل الخروج',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(result: false),
                        icon: const Icon(Icons.close_rounded),
                        splashRadius: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'أدخل كلمة مرور حساب المالك للتأكيد',
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Password field
                  TextField(
                    controller: passCtrl,
                    obscureText: isPasswordHidden,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => Get.back(result: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(.85),
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.blueGrey.withOpacity(.25),
                        ),
                      ),
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        onPressed: () {
                          setState(() => isPasswordHidden = !isPasswordHidden);
                        },
                        icon: Icon(
                          isPasswordHidden
                              ? Iconsax.eye
                              : Iconsax.eye_slash,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(result: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.blueGrey.withOpacity(.3)),
                            backgroundColor: Colors.white.withOpacity(.55),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                          ),
                          child: const Text('تأكيد'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );

    final enteredPass = passCtrl.text.trim();
    passCtrl.dispose();

    if (confirmed != true) return;

    if (enteredPass.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل كلمة المرور أولاً',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isAuthLoading.value = true;

      final user = _auth.currentUser;
      final emailNow = user?.email;

      if (user == null || emailNow == null) {
        Get.snackbar(
          'خطأ',
          'لا يوجد حساب مالك مسجل حالياً',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // ✅ Authentication عادي: SignIn للتحقق
      await _auth.signInWithEmailAndPassword(
        email: emailNow,
        password: enteredPass,
      );

      // ✅ لو صح: خروج + مسح مؤقت + للـ Login
      await _auth.signOut();
      _clearLocalData();
      Get.offAll(() => const LoginPage());

    } on FirebaseAuthException catch (e) {
      String msg = 'فشل التحقق';
      if (e.code == 'wrong-password') msg = 'كلمة المرور غير صحيحة';
      if (e.code == 'user-not-found') msg = 'الحساب غير موجود';
      if (e.code == 'too-many-requests') msg = 'محاولات كثيرة، حاول لاحقاً';
      if (e.code == 'network-request-failed') msg = 'مشكلة في الإنترنت';

      Get.snackbar('فشل', msg,
          backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isAuthLoading.value = false;
    }
  }


  Future<void> loadPharmacyData(String uid) async {
    isPharmacyLoading.value = true; // تفعيل حالة التحميل في البداية
    isPharmacyLoaded.value = false;

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
      isPharmacyLoading.value = false; // إيقاف حالة التحميل
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
    isPharmacyLoaded.value = false;
    isPermissionsLoaded.value = false;
    rolePermissions.clear();
    employeeOverrides.clear();
  }

  // دالة تبديل المستخدم
  Future<void> switchUser() async {
    try {
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
    // ✅ موظف داخلي
    if (currentEmployee.value != null) {
      final emp = currentEmployee.value!;

      // ⚠️ لازم employeeId يكون doc.id الحقيقي من employees
      final employeeId = emp['id']?.toString() ?? '';

      return {
        'type': 'employee',
        'id': employeeId.isEmpty ? 'unknown_employee' : employeeId,
        'name': emp['name']?.toString() ??
            emp['fullName']?.toString() ??
            emp['username']?.toString() ??
            currentUserName.value,
        'username': emp['username']?.toString() ?? currentUserName.value,
        'role': currentUserRole.value,
        'roleId': emp['roleId']?.toString() ?? 'employee',
        'pharmacyId': pharmacyId,
      };
    }

    // ✅ Owner
    final user = FirebaseAuth.instance.currentUser;
    return {
      'type': 'owner',
      'id': user?.uid ?? 'unknown_owner',
      'email': user?.email ?? '',
      'name': userName,
      'role': 'صاحب الصيدلية',
      'pharmacyId': pharmacyId,
    };
  }


  // في AuthController
  Future<Map<String, dynamic>> getSaleActorInfo() async {
    try {
      print('🔍 جلب معلومات منفذ البيع...');

      // ✅ موظف داخلي
      if (currentEmployee.value != null) {
        final emp = currentEmployee.value!;
        final employeeId = emp['id']?.toString() ?? '';

        print('👤 موظف داخلي: $emp');

        // ✅ لو id فاضي -> ما نستخدموش uid المالك كبديل
        if (employeeId.isEmpty) {
          return {
            'type': 'employee',
            'id': 'unknown_employee',
            'name': emp['name']?.toString() ??
                emp['fullName']?.toString() ??
                emp['username']?.toString() ??
                currentUserName.value,
            'username': emp['username']?.toString() ?? currentUserName.value,
            'role': currentUserRole.value,
            'roleId': emp['roleId']?.toString() ?? 'employee',
            'pharmacyId': pharmacyId,
          };
        }

        // ✅ جرب نجيب البيانات الكاملة من Firestore (اختياري)
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
              'name': data?['name']?.toString() ??
                  data?['fullName']?.toString() ??
                  emp['username']?.toString() ??
                  'موظف',
              'username': emp['username']?.toString() ?? currentUserName.value,
              'role': currentUserRole.value,
              'roleId': emp['roleId']?.toString() ?? 'employee',
              'pharmacyId': pharmacyId,
            };
          }
        } catch (e) {
          print('⚠️ فشل جلب بيانات الموظف من Firestore: $e');
        }

        // ✅ fallback محلي (بدون uid المالك)
        return {
          'type': 'employee',
          'id': employeeId,
          'name': emp['name']?.toString() ??
              emp['fullName']?.toString() ??
              emp['username']?.toString() ??
              currentUserName.value,
          'username': emp['username']?.toString() ?? currentUserName.value,
          'role': currentUserRole.value,
          'roleId': emp['roleId']?.toString() ?? 'employee',
          'pharmacyId': pharmacyId,
        };
      }

      // ✅ Owner
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