import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../views/home_page.dart';
import '../views/login_page.dart';
import '../views/waiting_approval_page.dart';

class AuthController extends GetxController {
  // المتغيرات القابلة للملاحظة
  var email = ''.obs;
  var password = ''.obs;
  var pharmacyName = ''.obs;
  var ownerName = ''.obs;
  var licenseNumber = ''.obs;
  var phoneNumber = ''.obs;
  var address = ''.obs;
  var isLoading = false.obs;
  var rememberMe = false.obs;

  // مثيلات Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final HttpsCallable getUserRoleCallable =
  FirebaseFunctions.instance.httpsCallable('getUserRole');

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  // تحميل بيانات تسجيل الدخول المحفوظة
  void _loadSavedCredentials() {
    // يمكن إضافة shared preferences هنا لحفظ بيانات الدخول
  }

  // حفظ بيانات تسجيل الدخول
  void _saveCredentials() {
    if (rememberMe.value) {
      // حفظ باستخدام shared preferences
    }
  }

  // دالة التسجيل للصيدليات فقط
  Future<void> signUpPharmacy() async {
    try {
      if (!_validatePharmacySignUp()) return;

      isLoading.value = true;

      // إنشاء المستخدم في Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = userCredential.user!;

      // إضافة طلب التسجيل إلى Firestore
      await _createPharmacyRequest(user.uid);

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
      Get.snackbar(
        "خطأ",
        "فشل في التسجيل: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

    if (errors.isNotEmpty) {
      Get.snackbar(
        "خطأ في البيانات",
        errors.join('\n'),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    }

    return true;
  }
  Future<bool> checkApprovalStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final uid = user.uid;

      // 1) نجيبه من pharmacies مباشرة
      final pharmacyDoc = await _firestore.collection('pharmacies').doc(uid).get();

      if (pharmacyDoc.exists) {
        final data = pharmacyDoc.data()!;
        final status = data['status'] ?? 'pending';
        final userType = data['userType'] ?? 'pharmacy';

        return (status == "approved" && userType == "pharmacy");
      }

      // 2) لو مش موجود في pharmacies → نبحث في طلبات التسجيل
      final requestDoc = await _firestore.collection('pharmacyRequests').doc(uid).get();

      if (!requestDoc.exists) {
        return false; // لا يوجد طلب ولا صيدلية
      }

      final req = requestDoc.data()!;
      final status = req['status'] ?? 'pending';

      if (status == "approved") {
        // الطلب approved ولكن مش موجود داخل pharmacies
        await createPharmacyAfterApproval(uid, req);
        return true;
      }

      return false;
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> createPharmacyAfterApproval(String uid, Map<String, dynamic> requestData) async {
    await _firestore.collection('pharmacies').doc(uid).set({
      'name': requestData['pharmacyName'],
      'ownerName': requestData['ownerName'],
      'email': requestData['email'],
      'phoneNumber': requestData['phoneNumber'],
      'licenseNumber': requestData['licenseNumber'],
      'address': requestData['address'],
      'status': 'approved',
      'userType': 'pharmacy',
      'isOnline': true,
      'is24Hours': false,
      'imageUrl': '',
      'latitude': '',
      'longitude': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // إنشاء طلب الصيدلية
  Future<void> _createPharmacyRequest(String userId) async {
    try {
      await _firestore.collection('pharmacyRequests').doc(userId).set({
        'userId': userId,
        'email': email.value.trim(),
        'pharmacyName': pharmacyName.value.trim(),
        'ownerName': ownerName.value.trim(),
        'licenseNumber': licenseNumber.value.trim(),
        'phoneNumber': phoneNumber.value.trim(),
        'address': address.value.trim(),
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'userType': 'pharmacy', // للتأكيد أن هذا مستخدم صيدلية
      });
    } catch (e) {
      throw Exception('فشل في حفظ طلب الصيدلية: $e');
    }
  }
  Future<void> login() async {
    try {
      if (!_validateLogin()) return;

      isLoading.value = true;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = userCredential.user!;

      // تحديث التوكن
      await user.getIdToken(true);

      // حفظ بيانات الدخول إذا طلب
      if (rememberMe.value) {
        _saveCredentials();
      }

      // التحقق من نوع المستخدم وتوجيهه
      await _checkUserTypeAndRedirect(user.uid);
      await loadPharmacyData();

      // مهم جداً: لا تضع أي توجيه هنا !!
      // لأن _checkUserTypeAndRedirect() هي اللي تقوم بكل التوجيه

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
    }
  }
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxMap<String, dynamic> pharmacyData = <String, dynamic>{}.obs;

  Future<void> loadPharmacyData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection("pharmacies").doc(uid).get();
    if (doc.exists) {
      pharmacyData.value = doc.data()!;
    }
  }
  // التحقق من بيانات الدخول
  bool _validateLogin() {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar(
        "خطأ",
        "البريد الإلكتروني وكلمة المرور مطلوبان",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  // التحقق من نوع المستخدم وإعادة التوجيه
  Future<void> _checkUserTypeAndRedirect(String uid) async {
    final approved = await checkApprovalStatus();

    isLoading.value = false;

    if (approved) {
      Get.offAll(() => const HomePage());
    } else {
      Get.offAll(() => const WaitingApprovalPage());
    }
  }

  // الحصول على بيانات المستخدم
  Future<Map<String, dynamic>> _getUserData(String uid) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'getUserRoleAndStatus',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 10),
        ),
      );

      final result = await callable.call({'uid': uid});
      return result.data;
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على الحالة من Firestore
  Future<Map<String, dynamic>> _getUserStatusFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('pharmacyRequests').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'role': 'pharmacy',
          'status': data['status'] ?? 'pending',
        };
      } else {
        // إذا لم يكن لديه طلب صيدلية، فهو مستخدم عادي
        return {
          'role': 'user',
          'status': 'approved',
        };
      }
    } catch (e) {
      rethrow;
    }
  }

  // إعادة توجيه المستخدم
  void _redirectUser(Map<String, dynamic> userData) {
    isLoading.value = false;

    final role = userData['role'] ?? 'user';
    final status = userData['status'] ?? 'pending';

    if (role == 'admin') {
      Get.offAll(() => const HomePage());
    } else if (role == 'pharmacy' && status == 'approved') {
      Get.offAll(() => const HomePage());
    } else if (role == 'pharmacy') {
      Get.offAll(() => const WaitingApprovalPage());
    } else {
      // المستخدمون العاديون غير مسموح لهم بالدخول
      Get.snackbar(
        "غير مصرح",
        "هذا التطبيق مخصص للصيدليات فقط",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      logout();
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
        message = "خطأ في الشبكة. يرجى التحقق من الاتصال";
        break;
      default:
        message = "فشل في المصادقة: ${e.message}";
    }

    Get.snackbar(
      "خطأ في المصادقة",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  // تسجيل الخروج
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _clearLocalData();
      Get.offAll(() => const LoginPage());
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في تسجيل الخروج: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
    rememberMe.value = false;
  }

  // التحقق من اتصال Firebase
  Future<bool> checkConnection() async {
    try {
      await _auth.currentUser?.getIdToken();
      return true;
    } catch (e) {
      return false;
    }
  }

  // إعادة تعيين الحقول
  void resetFields() {
    _clearLocalData();
  }
}