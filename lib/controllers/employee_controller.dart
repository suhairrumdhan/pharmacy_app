// controllers/employee_controller.dart

import 'package:get/get.dart';
import 'package:pharmacy_desktop/controllers/settings_controller.dart';
import '../models/employee_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // إذا كنت تستخدم Firestore

class EmployeeController extends GetxController {
  // الحصول على معرف الصيدلية من المتحكم الرئيسي
  String get pharmacyId => Get.find<SettingsController>().settings.value.id;

  RxList<PharmacyEmployee> employees = <PharmacyEmployee>[].obs;
  RxList<EmployeeRole> roles = <EmployeeRole>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    // انتظر حتى يتم تحميل الإعدادات ثم قم بتحميل الموظفين
    ever(Get.find<SettingsController>().settings, (settings) {
      if (settings.id.isNotEmpty) {
        loadEmployees();
        loadRoles();
      }
    });
  }

  // تحميل الموظفين من Firestore
  Future<void> loadEmployees() async {
    try {
      isLoading(true);
      errorMessage('');

      final querySnapshot = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .orderBy('fullName')
          .get();

      employees.assignAll(
        querySnapshot.docs.map((doc) {
          return PharmacyEmployee.fromMap({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList(),
      );
    } catch (e) {
      errorMessage('فشل في تحميل الموظفين: $e');
      print('Error loading employees: $e');
    } finally {
      isLoading(false);
    }
  }

  // تحميل الأدوار من Firestore
  Future<void> loadRoles() async {
    try {
      isLoading(true);

      final querySnapshot = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('roles')
          .get();

      if (querySnapshot.docs.isEmpty) {
        // إنشاء أدوار افتراضية إذا لم توجد
        await createDefaultRoles();
        roles.assignAll(EmployeeRole.getDefaultRoles(pharmacyId));
      } else {
        roles.assignAll(
          querySnapshot.docs.map((doc) {
            return EmployeeRole.fromMap({
              'id': doc.id,
              ...doc.data(),
            });
          }).toList(),
        );
      }
    } catch (e) {
      errorMessage('فشل في تحميل الأدوار: $e');
      print('Error loading roles: $e');
    } finally {
      isLoading(false);
    }
  }

  // إنشاء الأدوار الافتراضية في Firestore
  Future<void> createDefaultRoles() async {
    try {
      final defaultRoles = EmployeeRole.getDefaultRoles(pharmacyId);

      for (final role in defaultRoles) {
        await _firestore
            .collection('pharmacies')
            .doc(pharmacyId)
            .collection('roles')
            .doc(role.id)
            .set(role.toMap());
      }
    } catch (e) {
      print('Error creating default roles: $e');
    }
  }

  // إضافة موظف جديد
  Future<bool> addEmployee({
    required String fullName,
    required String username,
    required String password,
    required String email,
    required String phoneNumber,
    required String roleId,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // التحقق من عدم تكرار اسم المستخدم
      if (employees.any((e) => e.username == username)) {
        errorMessage('اسم المستخدم موجود مسبقاً');
        return false;
      }

      // التحقق من وجود الدور
      if (!roles.any((r) => r.id == roleId)) {
        errorMessage('الدور غير موجود');
        return false;
      }

      final employee = PharmacyEmployee(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pharmacyId: pharmacyId,
        fullName: fullName,
        username: username,
        encryptedPassword: PharmacyEmployee.encryptPassword(password),
        email: email,
        phoneNumber: phoneNumber,
        roleId: roleId,
        joinDate: DateTime.now(),
        isActive: true,
        additionalInfo: additionalInfo,
      );

      // حفظ في Firestore
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employee.id)
          .set(employee.toMap());

      // تحديث القائمة المحلية
      employees.add(employee);

      return true;
    } catch (e) {
      errorMessage('فشل في إضافة الموظف: $e');
      print('Error adding employee: $e');
      return false;
    }
  }

  // تحديث موظف
  Future<bool> updateEmployee(PharmacyEmployee employee) async {
    try {
      // التحقق من عدم تكرار اسم المستخدم
      if (employees.any((e) =>
      e.username == employee.username && e.id != employee.id)) {
        errorMessage('اسم المستخدم موجود مسبقاً');
        return false;
      }

      // التحقق من وجود الدور
      if (!roles.any((r) => r.id == employee.roleId)) {
        errorMessage('الدور غير موجود');
        return false;
      }

      // تحديث في Firestore
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employee.id)
          .update(employee.toMap());

      // تحديث القائمة المحلية
      final index = employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        employees[index] = employee;
        employees.refresh();
      }

      return true;
    } catch (e) {
      errorMessage('فشل في تحديث الموظف: $e');
      print('Error updating employee: $e');
      return false;
    }
  }

  // حذف موظف
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .doc(employeeId)
          .delete();

      employees.removeWhere((e) => e.id == employeeId);

      return true;
    } catch (e) {
      errorMessage('فشل في حذف الموظف: $e');
      print('Error deleting employee: $e');
      return false;
    }
  }

  // تغيير حالة الموظف (تفعيل/تعطيل)
  Future<bool> toggleEmployeeStatus(String employeeId) async {
    try {
      final employee = employees.firstWhere((e) => e.id == employeeId);
      final updatedEmployee = employee.copyWith(isActive: !employee.isActive);

      return await updateEmployee(updatedEmployee);
    } catch (e) {
      errorMessage('فشل في تغيير حالة الموظف: $e');
      print('Error toggling employee status: $e');
      return false;
    }
  }

  // إضافة دور جديد
  Future<bool> addRole({
    required String name,
    required String description,
    required List<Permission> permissions,
  }) async {
    try {
      final roleId = DateTime.now().millisecondsSinceEpoch.toString();

      final role = EmployeeRole(
        id: roleId,
        pharmacyId: pharmacyId,
        name: name,
        description: description,
        permissions: permissions,
        createdAt: DateTime.now(),
      );

      // حفظ في Firestore
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('roles')
          .doc(roleId)
          .set(role.toMap());

      // تحديث القائمة المحلية
      roles.add(role);

      return true;
    } catch (e) {
      errorMessage('فشل في إضافة الدور: $e');
      print('Error adding role: $e');
      return false;
    }
  }

  // تحديث دور
  Future<bool> updateRole(EmployeeRole role) async {
    try {
      if (!role.isEditable) {
        errorMessage('هذا الدور غير قابل للتعديل');
        return false;
      }

      // تحديث في Firestore
      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('roles')
          .doc(role.id)
          .update(role.toMap());

      // تحديث القائمة المحلية
      final index = roles.indexWhere((r) => r.id == role.id);
      if (index != -1) {
        roles[index] = role;
        roles.refresh();
      }

      return true;
    } catch (e) {
      errorMessage('فشل في تحديث الدور: $e');
      print('Error updating role: $e');
      return false;
    }
  }

  // حذف دور
  Future<bool> deleteRole(String roleId) async {
    try {
      final role = roles.firstWhere((r) => r.id == roleId);

      if (!role.isEditable) {
        errorMessage('هذا الدور غير قابل للحذف');
        return false;
      }

      // التحقق من عدم وجود موظفين يستخدمون هذا الدور
      if (employees.any((e) => e.roleId == roleId)) {
        errorMessage('لا يمكن حذف الدور لأنه مستخدم من قبل موظفين');
        return false;
      }

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('roles')
          .doc(roleId)
          .delete();

      roles.removeWhere((r) => r.id == roleId);

      return true;
    } catch (e) {
      errorMessage('فشل في حذف الدور: $e');
      print('Error deleting role: $e');
      return false;
    }
  }

  // الحصول على دور بواسطة المعرف
  EmployeeRole? getRoleById(String roleId) {
    try {
      return roles.firstWhere((r) => r.id == roleId);
    } catch (e) {
      return null;
    }
  }

  // الحصول على الموظفين حسب الدور
  List<PharmacyEmployee> getEmployeesByRole(String roleId) {
    return employees.where((e) => e.roleId == roleId).toList();
  }

  // التحقق من صلاحية الموظف
  bool checkPermission(String employeeId, Permission permission) {
    try {
      final employee = employees.firstWhere((e) => e.id == employeeId);
      final role = getRoleById(employee.roleId);

      if (role == null) return false;

      // إذا كان للموظف صلاحية manageAll
      if (role.hasPermission(Permission.manageAll)) return true;

      return role.hasPermission(permission);
    } catch (e) {
      return false;
    }
  }

  // الحصول على إحصائيات الموظفين
  Map<String, dynamic> getEmployeeStats() {
    final activeEmployees = employees.where((e) => e.isActive).length;
    final inactiveEmployees = employees.length - activeEmployees;

    final roleStats = <String, int>{};
    for (final role in roles) {
      roleStats[role.name] = getEmployeesByRole(role.id).length;
    }

    return {
      'total': employees.length,
      'active': activeEmployees,
      'inactive': inactiveEmployees,
      'byRole': roleStats,
    };
  }
}