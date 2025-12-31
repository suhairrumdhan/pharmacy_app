import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../core/security/default_permissions.dart';
import '../models/employee_model.dart';
import 'auth_controller.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';

class EmployeeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController auth = Get.find<AuthController>();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get pharmacyId => auth.pharmacyId;

  // ===== Controllers =====
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  RxBool isActive = true.obs;
  final hiringDate = DateTime.now().obs;
  RxString selectedRoleDisplay = 'صيدلي'.obs;
  RxString selectedRoleId = 'pharmacist'.obs;
  final contractType = 'دوام كامل'.obs;

  // ===== State =====
  final employees = <Employee>[].obs;
  final currentEmployee = Rx<Employee?>(null);
  final searchText = ''.obs;
  final isLoading = false.obs;
  final RxMap<String, bool> _pendingPermissionOverrides = <String, bool>{}.obs;
  final RxBool _hasPendingChanges = false.obs;
  final usernameError = RxnString();
  final passwordError = RxnString();
  final roleError = RxnString();
  final isSaving = false.obs;

  // ===== المرفقات =====

  // الملفات المؤقتة للتعديل
  Rx<File?> tempIdCardFile = Rx<File?>(null);
  Rx<File?> tempCertificateFile = Rx<File?>(null);

  // الروابط المخزنة في Firebase
  RxString storedIdCardUrl = ''.obs;
  RxString storedCertificateUrl = ''.obs;

  // روابط العرض (تدمج الملفات المؤقتة والمخزنة)
  RxString displayIdCardUrl = ''.obs;
  RxString displayCertificateUrl = ''.obs;

  // حالة التحميل
  RxBool isUploadingIdCard = false.obs;
  RxBool isUploadingCertificate = false.obs;

  // متغيرات لتتبع حالة المرفقات
  RxBool hasNewIdCard = false.obs;      // هل هناك ملف هوية جديد؟
  RxBool hasNewCertificate = false.obs; // هل هناك شهادة جديدة؟
  RxBool shouldDeleteIdCard = false.obs; // هل يجب حذف صورة الهوية؟
  RxBool shouldDeleteCertificate = false.obs; // هل يجب حذف الشهادة؟

  @override
  void onInit() {
    super.onInit();
    listenEmployees();
  }

  // ================= FIREBASE STREAM =================
  void listenEmployees() {
    try {
      isLoading.value = true;

      if (pharmacyId.isEmpty) {
        isLoading.value = false;
        return;
      }

      _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
          final List<Employee> loadedEmployees = [];

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final employee = Employee.fromMap(doc.id, data);
              loadedEmployees.add(employee);
            } catch (e) {
              print('Error parsing document ${doc.id}: $e');
            }
          }

          employees.value = loadedEmployees;
          isLoading.value = false;
        },
        onError: (error) {
          isLoading.value = false;
        },
      );
    } catch (e) {
      isLoading.value = false;
    }
  }

  // ================= ADD EMPLOYEE =================
  Future<bool> addEmployee() async {
    if (pharmacyId.isEmpty) {
      Get.snackbar('خطأ', 'لم يتم تحديد الصيدلية');
      return false;
    }

    usernameError.value = null;
    passwordError.value = null;
    roleError.value = null;

    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final arabicRole = selectedRoleDisplay.value;
    final englishRoleId = _translateRoleToEnglish(arabicRole);

    bool isValid = true;

    if (username.isEmpty) {
      usernameError.value = 'اسم المستخدم مطلوب';
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError.value = 'كلمة المرور مطلوبة';
      isValid = false;
    }

    if (arabicRole.isEmpty) {
      roleError.value = 'يجب اختيار دور';
      isValid = false;
    }

    if (!isValid) return false;

    if (isSaving.value) return false;
    isSaving.value = true;

    try {
      // Check for duplicate username
      final existing = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        usernameError.value = 'اسم المستخدم مستخدم بالفعل';
        isSaving.value = false;
        return false;
      }

      final ref = _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc();

      final employeeId = ref.id;
      final uploadedUrls = await _uploadAllAttachments(employeeId);

      final actor = auth.actorInfo;

      await ref.set({
        'id': employeeId,
        'name': nameCtrl.text.trim(),
        'username': username,
        'password': password,
        'phone': phoneCtrl.text.trim(),
        'roleId': englishRoleId,
        'roleDisplay': arabicRole,
        'isActive': isActive.value,
        'contractType': contractType.value,
        'hiringDate': Timestamp.fromDate(hiringDate.value),
        'permissionOverrides': {},
        'idCardImageUrl': uploadedUrls['idCard'],
        'certificateImageUrl': uploadedUrls['certificate'],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': actor,
      });

      Get.snackbar('نجاح', 'تم إضافة الموظف بنجاح');
      clearForm();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء الإضافة');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ================= UPDATE EMPLOYEE =================
  Future<bool> updateEmployee(String employeeId) async {
    if (employeeId.isEmpty) return false;

    final actor = auth.actorInfo;
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final roleId = selectedRoleId.value;

    bool isValid = true;

    if (name.isEmpty) isValid = false;
    if (roleId.isEmpty) isValid = false;

    if (!isValid) return false;

    try {
      // 1. التعامل مع المرفقات
      final updatedAttachments = await _processAttachmentsForUpdate(employeeId);

      // 2. إعداد بيانات التحديث
      final updateData = {
        'name': name,
        'phone': phone,
        'roleId': roleId,
        'isActive': isActive.value,
        'contractType': contractType.value,
        'hiringDate': Timestamp.fromDate(hiringDate.value),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actor,
      };

      // 3. إضافة المرفقات المحدثة - استخدام نفس الأسماء
      if (updatedAttachments.containsKey('idCard')) {
        if (updatedAttachments['idCard'] != null) {
          updateData['idCardImageUrl'] = updatedAttachments['idCard']!;
        } else {
          updateData['idCardImageUrl'] = FieldValue.delete();
        }
      } else if (shouldDeleteIdCard.value) {
        updateData['idCardImageUrl'] = FieldValue.delete();
      }

      if (updatedAttachments.containsKey('certificate')) {
        if (updatedAttachments['certificate'] != null) {
          updateData['certificateImageUrl'] = updatedAttachments['certificate']!;
        } else {
          updateData['certificateImageUrl'] = FieldValue.delete();
        }
      } else if (shouldDeleteCertificate.value) {
        updateData['certificateImageUrl'] = FieldValue.delete();
      }


      // 4. تنفيذ التحديث في Firebase
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employeeId)
          .update(updateData);

      // 5. حفظ التعديلات المعلقة للصلاحيات (إذا وجدت)
      if (_hasPendingChanges.value && _pendingPermissionOverrides.isNotEmpty) {
        await savePermissionChanges(employeeId);
      }

      await _logAction(action: 'update_employee', targetId: employeeId);

      // 6. إعادة تعيين حالات المرفقات
      _resetAttachmentStates();

      Get.snackbar('نجاح', 'تم تحديث بيانات الموظف بنجاح');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء التحديث');
      return false;
    }
  }

  // ================= ATTACHMENT METHODS =================

  // دالة لتحميل موظف للتعديل مع المرفقات
  void loadEmployeeForEdit(Employee e) {
    currentEmployee.value = e;
    nameCtrl.text = e.name;
    usernameCtrl.text = e.username;
    phoneCtrl.text = e.phone;
    selectedRoleDisplay.value = _translateRoleToArabic(e.roleId);
    selectedRoleId.value = e.roleId;
    contractType.value = e.contractType;
    isActive.value = e.isActive;
    hiringDate.value = e.hiringDate;

    // إعادة تعيين حالات المرفقات
    _resetAttachmentStates();

    // تعبئة الروابط المخزنة - استخدام نفس الأسماء
    storedIdCardUrl.value = e.idCardImageUrl ?? '';
    storedCertificateUrl.value = e.certificateImageUrl ?? '';

    // تعبئة روابط العرض
    displayIdCardUrl.value = e.idCardImageUrl ?? '';
    displayCertificateUrl.value = e.certificateImageUrl ?? '';

  }
  // دالة لإرفاق صورة هوية جديدة
  Future<void> attachIdCard() async {
    try {
      final filePickerResult = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        dialogTitle: 'اختر صورة الهوية',
      );

      if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
        final pickedFile = filePickerResult.files.first;
        tempIdCardFile.value = File(pickedFile.path!);
        hasNewIdCard.value = true;
        shouldDeleteIdCard.value = false; // إذا كان هناك ملف جديد، لا نحذف القديم

        Get.snackbar(
          '✅ تم إرفاق صورة الهوية',
          'سيتم استبدال الصورة القديمة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في إرفاق صورة الهوية: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // دالة لإرفاق شهادة جديدة
  Future<void> attachCertificate() async {
    try {
      final filePickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        dialogTitle: 'اختر ملف الشهادة',
      );

      if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
        final pickedFile = filePickerResult.files.first;
        tempCertificateFile.value = File(pickedFile.path!);
        hasNewCertificate.value = true;
        shouldDeleteCertificate.value = false; // إذا كان هناك ملف جديد، لا نحذف القديم

        Get.snackbar(
          '✅ تم إرفاق الشهادة',
          'سيتم استبدال الشهادة القديمة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في إرفاق الشهادة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // دالة لحذف صورة الهوية (المخزنة أو المؤقتة)
  Future<void> removeIdCard() async {
    if (hasNewIdCard.value) {
      // حذف الملف المؤقت فقط
      tempIdCardFile.value = null;
      hasNewIdCard.value = false;
      Get.snackbar(
        '🗑️ تم الإزالة',
        'تم إزالة صورة الهوية المرفوعة حديثاً',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else if (storedIdCardUrl.value.isNotEmpty) {
      // وضع علامة لحذف الملف المخزن
      shouldDeleteIdCard.value = true;
      storedIdCardUrl.value = '';
      displayIdCardUrl.value = '';
      Get.snackbar(
        '🗑️ تم التحديد للحذف',
        'سيتم حذف صورة الهوية عند حفظ التعديلات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'ℹ️ لا يوجد ملف',
        'لا توجد صورة هووية لحذفها',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  // دالة لحذف الشهادة (المخزنة أو المؤقتة)
  Future<void> removeCertificate() async {
    if (hasNewCertificate.value) {
      // حذف الملف المؤقت فقط
      tempCertificateFile.value = null;
      hasNewCertificate.value = false;
      Get.snackbar(
        '🗑️ تم الإزالة',
        'تم إزالة الشهادة المرفوعة حديثاً',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else if (storedCertificateUrl.value.isNotEmpty) {
      // وضع علامة لحذف الملف المخزن
      shouldDeleteCertificate.value = true;
      storedCertificateUrl.value = '';
      displayCertificateUrl.value = '';
      Get.snackbar(
        '🗑️ تم التحديد للحذف',
        'سيتم حذف الشهادة عند حفظ التعديلات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'ℹ️ لا يوجد ملف',
        'لا توجد شهادة لحذفها',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  // دالة لرفع الملفات إلى Firebase Storage
  Future<String?> _uploadFileToFirebase(File file, String employeeId, String fileType) async {
    try {
      isUploadingIdCard.value = fileType == 'id_card';
      isUploadingCertificate.value = fileType == 'certificate';

      final fileName = '${employeeId}_${fileType}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final storagePath = 'pharmacies/$pharmacyId/employees/$employeeId/$fileName';

      final uploadTask = _storage.ref(storagePath).putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      Get.snackbar('خطأ في الرفع', 'فشل في رفع $fileType');
      return null;
    } finally {
      isUploadingIdCard.value = false;
      isUploadingCertificate.value = false;
    }
  }

  // دالة لمعالجة المرفقات عند التحديث
  Future<Map<String, String?>> _processAttachmentsForUpdate(String employeeId) async {
    final Map<String, String?> uploadedUrls = {};

    // 1. التعامل مع صورة الهوية
    if (shouldDeleteIdCard.value && storedIdCardUrl.value.isNotEmpty) {
      // حذف الملف القديم من Firebase
      await _deleteFileFromFirebase(storedIdCardUrl.value);
      uploadedUrls['idCard'] = null;
    } else if (tempIdCardFile.value != null) {
      // رفع ملف جديد واستبدال القديم
      final idCardUrl = await _uploadFileToFirebase(
        tempIdCardFile.value!,
        employeeId,
        'id_card',
      );
      uploadedUrls['idCard'] = idCardUrl;

      // حذف الملف القديم إذا كان موجوداً
      if (storedIdCardUrl.value.isNotEmpty) {
        await _deleteFileFromFirebase(storedIdCardUrl.value);
      }
    }

    // 2. التعامل مع الشهادة
    if (shouldDeleteCertificate.value && storedCertificateUrl.value.isNotEmpty) {
      // حذف الملف القديم من Firebase
      await _deleteFileFromFirebase(storedCertificateUrl.value);
      uploadedUrls['certificate'] = null;
    } else if (tempCertificateFile.value != null) {
      // رفع ملف جديد واستبدال القديم
      final certificateUrl = await _uploadFileToFirebase(
        tempCertificateFile.value!,
        employeeId,
        'certificate',
      );
      uploadedUrls['certificate'] = certificateUrl;

      // حذف الملف القديم إذا كان موجوداً
      if (storedCertificateUrl.value.isNotEmpty) {
        await _deleteFileFromFirebase(storedCertificateUrl.value);
      }
    }

    return uploadedUrls;
  }

  // دالة لرفع المرفقات عند الإضافة
  Future<Map<String, String?>> _uploadAllAttachments(String employeeId) async {
    final Map<String, String?> uploadedUrls = {};

    if (tempIdCardFile.value != null) {
      final idCardUrl = await _uploadFileToFirebase(
        tempIdCardFile.value!,
        employeeId,
        'id_card',
      );
      uploadedUrls['idCard'] = idCardUrl;
    }

    if (tempCertificateFile.value != null) {
      final certificateUrl = await _uploadFileToFirebase(
        tempCertificateFile.value!,
        employeeId,
        'certificate',
      );
      uploadedUrls['certificate'] = certificateUrl;
    }

    return uploadedUrls;
  }

  // دالة لحذف ملف من Firebase Storage
  Future<void> _deleteFileFromFirebase(String url) async {
    try {
      if (url.isNotEmpty) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      }
    } catch (e) {
      print('Error deleting file from Firebase: $e');
    }
  }

  // دالة إعادة تعيين حالات المرفقات
  void _resetAttachmentStates() {
    tempIdCardFile.value = null;
    tempCertificateFile.value = null;
    hasNewIdCard.value = false;
    hasNewCertificate.value = false;
    shouldDeleteIdCard.value = false;
    shouldDeleteCertificate.value = false;
  }

  // ================= HELPER METHODS =================

  void clearForm() {
    currentEmployee.value = null;
    nameCtrl.clear();
    usernameCtrl.clear();
    passwordCtrl.clear();
    phoneCtrl.clear();
    selectedRoleDisplay.value = 'صيدلي';
    selectedRoleId.value = 'pharmacist';
    contractType.value = 'دوام كامل';
    isActive.value = true;
    hiringDate.value = DateTime.now();

    _resetAttachmentStates();
    storedIdCardUrl.value = '';
    storedCertificateUrl.value = '';
    displayIdCardUrl.value = '';
    displayCertificateUrl.value = '';

    isUploadingIdCard.value = false;
    isUploadingCertificate.value = false;
    cancelPermissionChanges();
  }

  // دوال تحويل الأدوار
  final Map<String, String> roleTranslation = {
    'إداري': 'admin',
    'صيدلي': 'pharmacist',
    'محاسب': 'cashier',
  };

  final Map<String, String> reverseRoleTranslation = {
    'admin': 'إداري',
    'pharmacist': 'صيدلي',
    'cashier': 'محاسب',
  };

  String _translateRoleToEnglish(String arabicRole) {
    return roleTranslation[arabicRole] ?? 'pharmacist';
  }

  String _translateRoleToArabic(String englishRole) {
    return reverseRoleTranslation[englishRole] ?? 'صيدلي';
  }

  // ================= FILTER =================
  List<Employee> get filteredEmployees {
    final search = searchText.value.trim().toLowerCase();
    if (search.isEmpty) return employees;

    return employees.where((e) {
      return e.name.toLowerCase().contains(search) ||
          e.phone.contains(search) ||
          e.username.toLowerCase().contains(search);
    }).toList();
  }

  // ================= PERMISSION METHODS =================
  final RxMap<String, Map<String, bool>> _rolePermissions = <String, Map<String, bool>>{}.obs;

  Map<String, bool> getRolePermissions(String roleId) {
    return _rolePermissions[roleId] ?? {};
  }

  Future<bool> updatePermissionOverride({
    required String employeeId,
    required String permissionKey,
    required bool value,
  }) async {
    try {
      if (employeeId.isEmpty) {
        if (currentEmployee.value != null) {
          final updatedOverrides = Map<String, bool>.from(currentEmployee.value!.permissionOverrides);
          updatedOverrides[permissionKey] = value;
          final updatedEmployee = currentEmployee.value!.copyWith(
            permissionOverrides: updatedOverrides,
            hasCustomPermissions: true,
          );
          currentEmployee.value = updatedEmployee;
          _hasPendingChanges.value = true;
          return true;
        }
        return false;
      } else {
        _pendingPermissionOverrides[permissionKey] = value;
        _hasPendingChanges.value = true;

        final currentEmp = currentEmployee.value;
        if (currentEmp != null) {
          final updatedOverrides = Map<String, bool>.from(currentEmp.permissionOverrides);
          updatedOverrides[permissionKey] = value;
          final updatedEmployee = currentEmp.copyWith(
            permissionOverrides: updatedOverrides,
            hasCustomPermissions: true,
          );
          currentEmployee.value = updatedEmployee;
        }
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> savePermissionChanges(String employeeId) async {
    try {
      if (_pendingPermissionOverrides.isEmpty) return true;

      final employeeDoc = _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employeeId);

      final doc = await employeeDoc.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final currentOverrides = Map<String, bool>.from(data['permissionOverrides'] ?? {});
      currentOverrides.addAll(_pendingPermissionOverrides);

      await employeeDoc.update({
        'permissionOverrides': currentOverrides,
        'hasCustomPermissions': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': auth.actorInfo,
      });

      final index = employees.indexWhere((e) => e.id == employeeId);
      if (index != -1) {
        final employee = employees[index];
        final updatedEmployee = employee.copyWith(
          permissionOverrides: currentOverrides,
          hasCustomPermissions: true,
        );
        employees[index] = updatedEmployee;
        if (currentEmployee.value?.id == employeeId) {
          currentEmployee.value = updatedEmployee;
        }
      }

      _pendingPermissionOverrides.clear();
      _hasPendingChanges.value = false;
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ الصلاحيات');
      return false;
    }
  }

  void cancelPermissionChanges() {
    _pendingPermissionOverrides.clear();
    _hasPendingChanges.value = false;

    final currentEmp = currentEmployee.value;
    if (currentEmp != null && currentEmp.id.isNotEmpty) {
      final originalEmployee = employees.firstWhereOrNull((e) => e.id == currentEmp.id);
      if (originalEmployee != null) {
        currentEmployee.value = originalEmployee;
      }
    }
  }

  Future<void> loadRolePermissions() async {
    try {
      final snapshot = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('permissions')
          .get();

      for (var doc in snapshot.docs) {
        final roleId = doc.id;
        final data = doc.data();
        if (data.containsKey('permissions') && data['permissions'] is Map) {
          final permissions = Map<String, bool>.from(
              (data['permissions'] as Map).map(
                      (key, value) => MapEntry(key.toString(), value == true)
              )
          );
          _rolePermissions[roleId] = permissions;
        }
      }
    } catch (e) {
      print('Error loading role permissions: $e');
    }
  }

  Set<String> getAllPermissions() {
    final allPermissions = <String>{};
    for (final perms in _rolePermissions.values) {
      allPermissions.addAll(perms.keys);
    }
    return allPermissions;
  }

  void toggleCustomPermissions(bool value) {
    if (currentEmployee.value != null) {
      final employee = currentEmployee.value!;
      final updatedEmployee = employee.copyWith(
        hasCustomPermissions: value,
        permissionOverrides: value ? employee.permissionOverrides : {},
      );
      currentEmployee.value = updatedEmployee;

      if (!employee.id.isEmpty) {
        _firestore
            .collection('pharmacies')
            .doc(pharmacyId)
            .collection('employees')
            .doc(employee.id)
            .update({
          'hasCustomPermissions': value,
          'permissionOverrides': value ? employee.permissionOverrides : {},
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> resetPermissionsToDefault() async {
    if (currentEmployee.value == null) return;

    final employeeId = currentEmployee.value!.id;
    final roleId = selectedRoleId.value;

    await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('employees')
        .doc(employeeId)
        .update({
      'permissionOverrides': {},
      'hasCustomPermissions': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final index = employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      final employee = employees[index];
      final updatedEmployee = employee.copyWith(
        permissionOverrides: {},
        hasCustomPermissions: false,
      );
      employees[index] = updatedEmployee;
      currentEmployee.value = updatedEmployee;
    }

    Get.snackbar('نجاح', 'تم إعادة الصلاحيات للإعدادات الافتراضية');
  }

  // ================= DELETE =================
  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employeeId)
          .delete();

      await _logAction(action: 'delete_employee', targetId: employeeId);
    } catch (e) {
      print('Error deleting employee: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء الحذف');
    }
  }

  Future<void> _logAction({
    required String action,
    required String targetId,
  }) async {
    await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('audit_logs')
        .add({
      'action': action,
      'targetId': targetId,
      'targetType': 'employee',
      'performedBy': auth.actorInfo,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ================= UI HELPERS =================
  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: hiringDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) hiringDate.value = picked;
  }

  // دالة لمعاينة الملف
  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {

      final cleanedUrl = _cleanFirebaseStorageUrl(url);
      final extension = _getFileExtensionFromUrl(cleanedUrl);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName$extension';
      final ref = _storage.refFromURL(cleanedUrl);
      await ref.writeToFile(File(tempPath));
      final result = await OpenFilex.open(tempPath);
      if (result.type != ResultType.done) {
        Get.snackbar(
          'تنبيه',
          'تعذر فتح الملف. تأكد من وجود تطبيق مناسب للعرض',
          backgroundColor: Colors.orange,
        );
      } else {
      }
    } catch (e, stackTrace) {
      _tryOpenInBrowser(url);
    }
  }

// دالة لتنظيف رابط Firebase Storage
  String _cleanFirebaseStorageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // إزالة المعلمات من الـ URL
      return uri.replace(queryParameters: {}).toString();
    } catch (e) {
      return url.split('?').first; // إزالة كل شيء بعد ?
    }
  }

// دالة للحصول على امتداد الملف من الـ URL
  String _getFileExtensionFromUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final fileName = path.split('/').last;

      if (fileName.contains('.')) {
        return '.${fileName.split('.').last}';
      }

      // إذا لم يكن هناك امتداد واضح، نحدد حسب نوع الملف المتوقع
      if (url.toLowerCase().contains('idcard') ||
          url.toLowerCase().contains('id_card')) {
        return '.jpg';
      } else if (url.toLowerCase().contains('certificate')) {
        return '.pdf';
      }

      return '.file';
    } catch (e) {
      return '.file';
    }
  }

// حل بديل: فتح الرابط في المتصفح
  void _tryOpenInBrowser(String url) {
    try {
      Get.snackbar(
        'فتح في المتصفح',
        'سيتم فتح الملف في المتصفح',
        backgroundColor: Colors.blue,
      );

      // يمكنك استخدام package:url_launcher
      // launchUrl(Uri.parse(url));
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'لا يمكن فتح الملف. الرابط: ${url.split('?').first}',
        backgroundColor: Colors.red,
      );
    }
  }
  // دالة للحصول على اسم الملف من الرابط
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final parts = path.split('/');
      return parts.last;
    } catch (e) {
      return 'ملف مرفق';
    }
  }




}