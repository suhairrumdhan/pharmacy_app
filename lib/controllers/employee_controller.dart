import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/security/default_permissions.dart';
import '../models/employee_model.dart';
import 'auth_controller.dart';

class EmployeeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController auth = Get.find<AuthController>();

  String get pharmacyId => auth.pharmacyId;

  // ===== Controllers =====
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  RxBool isActive = true.obs;
  final hiringDate = DateTime.now().obs;
  RxString selectedRoleDisplay = 'صيدلي'.obs; // للعرض في الواجهة
  RxString selectedRoleId = 'pharmacist'.obs; // للتخزين في Firebase
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
  // متغيرات لتخزين الملفات المحددة
  final Rx<File?> idCardFile = Rx<File?>(null);
  final Rx<File?> certificateFile = Rx<File?>(null);
  final RxList<File> certificateFiles = <File>[].obs;

  // روابط الملفات المرفوعة
  final RxString idCardUrl = ''.obs;
  final RxString certificateUrl = ''.obs;
  final RxList<String> certificateUrls = <String>[].obs;

  // حالة التحميل
  final RxBool isUploadingIdCard = false.obs;
  final RxBool isUploadingCertificate = false.obs;

  // Image Picker
  final ImagePicker _picker = ImagePicker();


  @override
  void onInit() {
    super.onInit();
    listenEmployees();
  }

  // ================= FIREBASE STREAM =================
// In your controller
  void listenEmployees() {
    try {
      print('Listening to employees for pharmacy: $pharmacyId');

      isLoading.value = true; // Set loading to true

      if (pharmacyId.isEmpty) {
        print('ERROR: pharmacyId is empty!');
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
          print('Snapshot received with ${snapshot.docs.length} documents');

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
          isLoading.value = false; // Set loading to false
          print('Successfully loaded ${employees.length} employees');
        },
        onError: (error) {
          print('Error in employees stream: $error');
          isLoading.value = false; // Set loading to false on error
        },
      );
    } catch (e) {
      print('Exception in listenEmployees: $e');
      isLoading.value = false; // Set loading to false on exception
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
    final arabicRole = selectedRoleDisplay.value; // القيمة العربية
    final englishRoleId = _translateRoleToEnglish(arabicRole); // القيمة الإنجليزية

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

      final actor = auth.actorInfo;

      await ref.set({
        'id': ref.id,
        'name': nameCtrl.text.trim(),
        'username': username,
        'password': password,
        'phone': phoneCtrl.text.trim(),
        'roleId': englishRoleId, // تخزين القيمة الإنجليزية
        'roleDisplay': arabicRole, // يمكنك تخزين القيمة العربية أيضاً إذا أردت
        'isActive': isActive.value,
        'contractType': contractType.value,
        'hiringDate': Timestamp.fromDate(hiringDate.value),
        'permissionOverrides': {}, // Initialize empty overrides
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': actor,
      });

      Get.snackbar('نجاح', 'تم إضافة الموظف بنجاح');
      clearForm();
      return true;
    } catch (e) {
      print('Error adding employee: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء الإضافة');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
  // Map لتحويل الأدوار من العربية إلى الإنجليزية
  final Map<String, String> roleTranslation = {
    'إداري': 'admin',
    'صيدلي': 'pharmacist',
    'محاسب': 'cashier',
    // يمكنك إضافة المزيد من الأدوار هنا
  };
  // Map للتحويل العكسي (من الإنجليزية إلى العربية)
  final Map<String, String> reverseRoleTranslation = {
    'admin': 'إداري',
    'pharmacist': 'صيدلي',
    'cashier': 'محاسب',
    // يمكنك إضافة المزيد من الأدوار هنا
  };
  // ================= UPDATE =================
  String _translateRoleToEnglish(String arabicRole) {
    return roleTranslation[arabicRole] ?? 'pharmacist'; // افتراضي
  }

  // دالة للتحويل من الإنجليزية إلى العربية
  String _translateRoleToArabic(String englishRole) {
    return reverseRoleTranslation[englishRole] ?? 'صيدلي'; // افتراضي
  }

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
      // 1. حفظ بيانات الموظف الأساسية
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employeeId)
          .update({
        'name': name,
        'phone': phone,
        'roleId': roleId,
        'isActive': isActive.value,
        'contractType': contractType.value,
        'hiringDate': Timestamp.fromDate(hiringDate.value),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actor,
      });

      // 2. حفظ التعديلات المعلقة للصلاحيات (إذا وجدت)
      if (_hasPendingChanges.value && _pendingPermissionOverrides.isNotEmpty) {
        await savePermissionChanges(employeeId);
      }

      await _logAction(
        action: 'update_employee',
        targetId: employeeId,
      );
      return true;
    } catch (e) {
      print('Error updating employee: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء التحديث');
      return false;
    }
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

      await _logAction(
        action: 'delete_employee',
        targetId: employeeId,
      );
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

  // ================= HELPERS =================
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
  }
  void clearForm() {
    currentEmployee.value = null;
    nameCtrl.clear();
    usernameCtrl.clear();
    passwordCtrl.clear();
    phoneCtrl.clear();
    selectedRoleDisplay.value = 'صيدلي'; // القيمة الافتراضية المعروضة
    selectedRoleId.value = 'pharmacist'; // القيمة الافتراضية للتخزين
    contractType.value = 'دوام كامل';
    isActive.value = true;
    hiringDate.value = DateTime.now();
  }

  // ================= FILTER =================
  List<Employee> get filteredEmployees {
    final search = searchText.value.trim().toLowerCase();

    if (search.isEmpty) {
      return employees;
    }

    return employees.where((e) {
      return e.name.toLowerCase().contains(search) ||
          e.phone.contains(search) ||
          e.username.toLowerCase().contains(search);
    }).toList();
  }

  // ================= PERMISSION METHODS =================

  // Permission cache for role permissions
  final RxMap<String, Map<String, bool>> _rolePermissions = <String, Map<String, bool>>{}.obs;
  Map<String, bool> getRolePermissions(String roleId) {
    return _rolePermissions[roleId] ?? {};
  }


  void toggleCustomPermissions(bool value) {
    if (currentEmployee.value != null) {
      final employee = currentEmployee.value!;
      final updatedEmployee = employee.copyWith(
        hasCustomPermissions: value,
        // إذا قمنا بتعطيل الصلاحيات المخصصة، نمسح الـ overrides
        permissionOverrides: value ? employee.permissionOverrides : {},
      );

      // تحديث مباشرة في الـ currentEmployee
      currentEmployee.value = updatedEmployee;

      print('✅ تم تغيير hasCustomPermissions إلى: $value');

      // للموظفين الموجودين فقط، قم بالتحديث في Firebase
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

  // Load role permissions from Firestore
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

// تعديل دالة updatePermissionOverride
  Future<bool> updatePermissionOverride({
    required String employeeId,
    required String permissionKey,
    required bool value,
  }) async {
    try {
      print('🚀 تحديث صلاحية محلياً للموظف $employeeId: $permissionKey -> $value');

      // 1. تخزين التعديل مؤقتاً
      if (employeeId.isEmpty) {
        // للموظفين الجدد: تحديث مباشرة في الـ currentEmployee
        if (currentEmployee.value != null) {
          final updatedOverrides = Map<String, bool>.from(
              currentEmployee.value!.permissionOverrides
          );
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
        // للموظفين الموجودين: تخزين في pending map
        _pendingPermissionOverrides[permissionKey] = value;
        _hasPendingChanges.value = true;

        // تحديث الواجهة فقط (لا Firebase)
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
      print('❌ خطأ في تحديث الصلاحية محلياً: $e');
      return false;
    }
  }
// دالة جديدة لحفظ التعديلات إلى Firebase
  Future<bool> savePermissionChanges(String employeeId) async {
    try {
      if (_pendingPermissionOverrides.isEmpty) return true;

      print('💾 حفظ التعديلات لـ $employeeId: $_pendingPermissionOverrides');

      final employeeDoc = _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employeeId);

      // الحصول على الوثيقة الحالية
      final doc = await employeeDoc.get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final currentOverrides = Map<String, bool>.from(
          data['permissionOverrides'] ?? {}
      );

      currentOverrides.addAll(_pendingPermissionOverrides);

      await employeeDoc.update({
        'permissionOverrides': currentOverrides,
        'hasCustomPermissions': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': auth.actorInfo,
      });

      // تحديث الحالة المحلية
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

      // مسح التعديلات المعلقة
      _pendingPermissionOverrides.clear();
      _hasPendingChanges.value = false;
      return true;

    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ الصلاحيات');
      return false;
    }
  }

// دالة لإلغاء التعديلات
  void cancelPermissionChanges() {
    _pendingPermissionOverrides.clear();
    _hasPendingChanges.value = false;

    // إعادة تحميل الموظف من البيانات الأصلية
    final currentEmp = currentEmployee.value;
    if (currentEmp != null && currentEmp.id.isNotEmpty) {
      // البحث عن الموظف في القائمة وإعادة تعيينه
      final originalEmployee = employees.firstWhereOrNull((e) => e.id == currentEmp.id);
      if (originalEmployee != null) {
        currentEmployee.value = originalEmployee;
      }
    }

    print('🗑️ تم إلغاء التعديلات المعلقة');
  }

// تعديل دالة updateEmployee لتتضمن حفظ الصلاحيات
  // Get all available permissions from all roles
  Set<String> getAllPermissions() {
    final allPermissions = <String>{};

    for (final perms in _rolePermissions.values) {
      allPermissions.addAll(perms.keys);
    }

    return allPermissions;
  }
// في EmployeeController
  Future<void> resetPermissionsToDefault() async {
    if (currentEmployee.value == null) return;

    final employeeId = currentEmployee.value!.id;
    final roleId = selectedRoleId.value;

    // الحصول على الصلاحيات الافتراضية للدور
    final defaultPermissions = DefaultPermissionsHelper.getPermissionsForRole(roleId);

    // إنشاء overrides فارغة (إرجاع للإفتراضي)
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

    // تحديث الحالة المحلية
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
}