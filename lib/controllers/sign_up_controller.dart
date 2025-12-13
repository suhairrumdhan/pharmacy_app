import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import '../../models/pharmacy_model.dart';
import '../services/file_upload_services.dart';
import '../services/location_service.dart';
import '../views/login_page.dart';
import '../views/waiting_approval_page.dart';

// Enums مباشرة في نفس الملف
enum FileUploadStatus { idle, uploading, success, error }
enum SignUpStatus { idle, loading, success, error }

class SignUpController extends GetxController {
  // --- Services ---
  final LocationService locationService = Get.find<LocationService>();
  final FileUploadService _uploadService = FileUploadService();

  // --- Firebase ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Form ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- Text Controllers ---
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pharmacyNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ownerIdNumberController = TextEditingController();

  // --- Rx Variables using GetX ---
  // متغيرات النموذج الأساسية
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString pharmacyName = ''.obs;
  final RxString ownerName = ''.obs;
  final RxString licenseNumber = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString addressDescription = ''.obs;
  final RxString ownerIdNumber = ''.obs;

  // ملفات الصور
  final RxString licenseFileUrl = ''.obs;
  final RxString ownerIdFileUrl = ''.obs;

  // الحالات
  final Rx<FileUploadStatus> licenseStatus = FileUploadStatus.idle.obs;
  final Rx<FileUploadStatus> ownerIdStatus = FileUploadStatus.idle.obs;
  final Rx<SignUpStatus> signUpStatus = SignUpStatus.idle.obs;

  // الإعدادات والتoggles
  final RxBool is24Hours = false.obs;
  final RxBool isOnline = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool isFormValid = false.obs;

  // ملفات مؤقتة
  XFile? _licenseImage;
  XFile? _ownerIdImage;

  // --- Focus Nodes ---
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode pharmacyNameFocus = FocusNode();
  final FocusNode ownerNameFocus = FocusNode();
  final FocusNode licenseFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode ownerIdFocus = FocusNode();

  // --- Lifecycle Methods ---
  @override
  void onInit() {
    super.onInit();
    _setupTextControllerListeners();
    _setupGetXWorkers();
  }

  @override
  void onReady() {
    super.onReady();
    // تهيئة الخريطة بعد بناء الصفحة
    locationService.initializeMapWithUserLocation();
  }

  @override
  void onClose() {
    _disposeResources();
    super.onClose();
  }

  // --- GetX Workers للتفاعلات التلقائية ---
  void _setupGetXWorkers() {
    // تحديث صحة النموذج عند تغيير أي حقل
    everAll([
      email, password, pharmacyName, ownerName,
      licenseNumber, phoneNumber, ownerIdNumber,
      licenseFileUrl, ownerIdFileUrl,
      locationService.currentMapCenter
    ], (_) => _updateFormValidity());

    // تحديث العنوان عند تحديد موقع جديد
    ever(locationService.currentMapCenter, (location) {
      if (location != null && addressDescription.value.isEmpty) {
        _updateAddressFromLocation(location);
      }
    });
  }

  void _setupTextControllerListeners() {
    // ربط الـ TextControllers مع Rx variables
    emailController.addListener(() => email.value = emailController.text.trim());
    passwordController.addListener(() => password.value = passwordController.text);
    pharmacyNameController.addListener(() => pharmacyName.value = pharmacyNameController.text.trim());
    ownerNameController.addListener(() => ownerName.value = ownerNameController.text.trim());
    licenseController.addListener(() => licenseNumber.value = licenseController.text.trim());
    phoneController.addListener(() => phoneNumber.value = phoneController.text.trim());
    addressController.addListener(() => addressDescription.value = addressController.text.trim());
    ownerIdNumberController.addListener(() => ownerIdNumber.value = ownerIdNumberController.text.trim());
  }

  // --- دوال التحقق التلقائي ---
  void _updateFormValidity() {
    final isValid =
        email.value.isNotEmpty &&
            password.value.isNotEmpty &&
            pharmacyName.value.isNotEmpty &&
            ownerName.value.isNotEmpty &&
            licenseNumber.value.isNotEmpty &&
            phoneNumber.value.isNotEmpty &&
            ownerIdNumber.value.isNotEmpty &&
            licenseFileUrl.value.isNotEmpty &&
            ownerIdFileUrl.value.isNotEmpty &&
            locationService.currentMapCenter.value != null;

    isFormValid.value = isValid;
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    try {
      final address = await locationService.getAddressForLocation(
          location.latitude,
          location.longitude
      );
      if (address != null && addressDescription.value.isEmpty) {
        addressController.text = address;
        addressDescription.value = address;
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  // --- دوال رفع الملفات مع GetX ---
  Future<void> uploadLicenseImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        _licenseImage = image;
        licenseStatus.value = FileUploadStatus.uploading;

        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        String tempUserId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        String? url = await _uploadService.uploadImage(
          imageFile: image,
          userId: tempUserId,
          fileType: 'license',
        );

        Get.back();

        if (url != null) {
          licenseFileUrl.value = url;
          licenseStatus.value = FileUploadStatus.success;
          Get.snackbar(
            'نجاح',
            'تم رفع صورة الترخيص بنجاح',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          licenseStatus.value = FileUploadStatus.error;
          Get.snackbar(
            'خطأ',
            'فشل تحميل صورة الترخيص',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.back();
      licenseStatus.value = FileUploadStatus.error;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل الصورة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> uploadOwnerIdImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        _ownerIdImage = image;
        ownerIdStatus.value = FileUploadStatus.uploading;

        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        String tempUserId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        String? url = await _uploadService.uploadImage(
          imageFile: image,
          userId: tempUserId,
          fileType: 'ownerId',
        );

        Get.back();

        if (url != null) {
          ownerIdFileUrl.value = url;
          ownerIdStatus.value = FileUploadStatus.success;
          Get.snackbar(
            'نجاح',
            'تم رفع صورة الهوية بنجاح',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          ownerIdStatus.value = FileUploadStatus.error;
          Get.snackbar(
            'خطأ',
            'فشل تحميل صورة الهوية',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.back();
      ownerIdStatus.value = FileUploadStatus.error;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل الصورة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> clearLicenseImage() async {
    if (licenseFileUrl.value.isNotEmpty) {
      await _uploadService.deleteFile(licenseFileUrl.value);
    }
    _licenseImage = null;
    licenseFileUrl.value = '';
    licenseStatus.value = FileUploadStatus.idle;
    Get.snackbar(
      'تم الحذف',
      'تم حذف صورة الترخيص',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> clearOwnerIdImage() async {
    if (ownerIdFileUrl.value.isNotEmpty) {
      await _uploadService.deleteFile(ownerIdFileUrl.value);
    }
    _ownerIdImage = null;
    ownerIdFileUrl.value = '';
    ownerIdStatus.value = FileUploadStatus.idle;
    Get.snackbar(
      'تم الحذف',
      'تم حذف صورة الهوية',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // --- دوال التحول بين إظهار وإخفاء كلمة المرور ---
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  void toggle24Hours() {
    is24Hours.value = !is24Hours.value;
  }

  void toggleOnline() {
    isOnline.value = !isOnline.value;
  }

  // --- دوال التحقق والتسجيل ---
  Future<void> submitSignUp() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;
      signUpStatus.value = SignUpStatus.loading;

      String tempUserId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );
      String uid = userCredential.user!.uid;

      await updatePharmacyFiles(uid);

      PharmacyModel pharmacy = PharmacyModel(
        id: uid,
        email: email.value.trim(),
        pharmacyName: pharmacyName.value.trim(),
        ownerName: ownerName.value.trim(),
        licenseNumber: licenseNumber.value.trim(),
        licenseFileUrl: licenseFileUrl.value,
        ownerIdFileUrl: ownerIdFileUrl.value,
        phoneNumber: phoneNumber.value.trim(),
        locationCoordinates: locationService.getLocationCoordinates(),
        location: locationService.getLocationAsMap(),
        ownerIdNumber: ownerIdNumber.value.trim(),
        is24Hours: is24Hours.value,
        isOnline: isOnline.value,
        status: 'pending',
        requestDate: DateTime.now(),
      );

      await _firestore.collection('pharmacyRequests').doc(uid).set(pharmacy.toMap());

      isLoading.value = false;
      signUpStatus.value = SignUpStatus.success;

      Get.snackbar(
        "نجاح",
        "تم إرسال طلب التسجيل بنجاح. سيتم مراجعته من الإدارة.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // الانتقال إلى صفحة الانتظار
      Get.offAll(() => WaitingApprovalPage());
    } catch (e) {
      isLoading.value = false;
      signUpStatus.value = SignUpStatus.error;
      print("SignUp error: $e");

      String errorMessage = "فشل تسجيل الصيدلية";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "البريد الإلكتروني مستخدم بالفعل";
            break;
          case 'weak-password':
            errorMessage = "كلمة المرور ضعيفة جداً";
            break;
          case 'invalid-email':
            errorMessage = "بريد إلكتروني غير صالح";
            break;
          case 'network-request-failed':
            errorMessage = "فشل في الاتصال بالشبكة";
            break;
        }
      }

      Get.snackbar(
        "خطأ",
        "$errorMessage: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void handleSignUp() {
    if (formKey.currentState != null &&
        formKey.currentState!.validate() &&
        locationService.validateLocation()) {
      submitSignUp();
    } else {
      Get.snackbar(
        "بيانات ناقصة",
        "يرجى ملء جميع الحقول المطلوبة وتحديد الموقع",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  // --- دوال مساعدة ---
  Future<void> updatePharmacyFiles(String uid) async {
    try {
      // تحديث ملف الترخيص
      if (licenseFileUrl.value.isNotEmpty &&
          licenseFileUrl.value.contains('temp_')) {
        final newLicenseUrl = await _copyFileToPermanentPath(
            uid,
            licenseFileUrl.value,
            'license'
        );
        if (newLicenseUrl != null) {
          licenseFileUrl.value = newLicenseUrl;
          await _firestore.collection('pharmacyRequests').doc(uid).update({
            'licenseFileUrl': newLicenseUrl,
          });
        }
      }

      // تحديف ملف الهوية
      if (ownerIdFileUrl.value.isNotEmpty &&
          ownerIdFileUrl.value.contains('temp_')) {
        final newOwnerIdUrl = await _copyFileToPermanentPath(
            uid,
            ownerIdFileUrl.value,
            'ownerId'
        );
        if (newOwnerIdUrl != null) {
          ownerIdFileUrl.value = newOwnerIdUrl;
          await _firestore.collection('pharmacyRequests').doc(uid).update({
            'ownerIdFileUrl': newOwnerIdUrl,
          });
        }
      }
    } catch (e) {
      print("Error updating pharmacy files: $e");
      Get.snackbar(
        "تحذير",
        "تم التسجيل ولكن حدث خطأ في نقل الملفات",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  Future<String?> _copyFileToPermanentPath(
      String uid,
      String tempFileUrl,
      String fileType
      ) async {
    try {
      final response = await http.get(Uri.parse(tempFileUrl));
      if (response.statusCode == 200) {
        final tempRef = _storage.refFromURL(tempFileUrl);
        final tempFile = await tempRef.getData();

        if (tempFile != null) {
          String fileName = '${fileType}_${DateTime.now().millisecondsSinceEpoch}';
          Reference permanentRef = _storage
              .ref()
              .child('pharmacies')
              .child(uid)
              .child('documents')
              .child(fileType)
              .child(fileName);

          await permanentRef.putData(tempFile);
          return await permanentRef.getDownloadURL();
        }
      }
    } catch (e) {
      print("Error copying file: $e");
    }
    return null;
  }

  void _disposeResources() {
    // تنظيف الـ TextControllers
    emailController.dispose();
    passwordController.dispose();
    pharmacyNameController.dispose();
    ownerNameController.dispose();
    licenseController.dispose();
    phoneController.dispose();
    addressController.dispose();
    ownerIdNumberController.dispose();

    // تنظيف الـ FocusNodes
    emailFocus.dispose();
    passwordFocus.dispose();
    pharmacyNameFocus.dispose();
    ownerNameFocus.dispose();
    licenseFocus.dispose();
    phoneFocus.dispose();
    addressFocus.dispose();
    ownerIdFocus.dispose();
  }

  // --- التنقل ---
  void navigateToLogin() {
    Get.off(() => const LoginPage());
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    pharmacyNameController.clear();
    ownerNameController.clear();
    licenseController.clear();
    phoneController.clear();
    addressController.clear();
    ownerIdNumberController.clear();

    licenseFileUrl.value = '';
    ownerIdFileUrl.value = '';

    is24Hours.value = false;
    isOnline.value = false;
    showPassword.value = false;

    licenseStatus.value = FileUploadStatus.idle;
    ownerIdStatus.value = FileUploadStatus.idle;
    signUpStatus.value = SignUpStatus.idle;
    isFormValid.value = false;
  }

  // --- دوال التحقق من النموذج ---
  String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }

    if (value.contains(' ')) {
      return 'البريد الإلكتروني لا يمكن أن يحتوي على مسافات';
    }

    if (!value.contains('@')) {
      return 'يرجى إدخال بريد إلكتروني صحيح (يجب أن يحتوي على @)';
    }

    final parts = value.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return 'تنسيق البريد الإلكتروني غير صالح';
    }

    if (!parts[1].contains('.')) {
      return 'يرجى إدخال اسم نطاق صحيح (مثال: example.com)';
    }

    final domainParts = parts[1].split('.');
    if (domainParts.length < 2 ||
        domainParts.last.length < 2 ||
        parts[1].contains('..')) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    List<String> errors = [];

    if (value.length < 8) {
      errors.add('8 أحرف على الأقل');
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('حرف كبير واحد على الأقل');
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('حرف صغير واحد على الأقل');
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('رقم واحد على الأقل');
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('حرف خاص واحد على الأقل');
    }

    if (errors.isNotEmpty) {
      return 'كلمة مرور ضعيفة. يجب أن تحتوي على:\n${errors.map((e) => '• $e').join('\n')}';
    }

    return null;
  }

  String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    final trimmedValue = value.trim();

    if (!RegExp(r'^[\d\+\-\(\)\s]+$').hasMatch(trimmedValue)) {
      return 'يجب أن يحتوي على أرقام فقط مع الرموز (+, -, (, ))';
    }

    final digitsOnly = trimmedValue.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 9) {
      return 'يجب أن يحتوي على 9 أرقام على الأقل';
    }

    if (digitsOnly.length > 15) {
      return 'يجب ألا يتجاوز 15 رقماً';
    }

    return null;
  }

  bool validateForm() {
    // التحقق من صحة النموذج
    final form = formKey.currentState;
    if (form == null) return false;
    if (!form.validate()) return false;

    // التحقق من تحديد الموقع
    if (!locationService.validateLocation()) {
      Get.snackbar(
        "الموقع مطلوب",
        "يرجى تحديد موقع الصيدلية على الخريطة",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    // التحقق من رفع الملفات
    if (licenseFileUrl.value.isEmpty || ownerIdFileUrl.value.isEmpty) {
      Get.snackbar(
        "الملفات مطلوبة",
        "يرجى رفع صورة الترخيص وصورة البطاقة الشخصية للمالك",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }
}