// lib/controllers/supplier_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/supplier_model.dart';
import 'auth_controller.dart';
import '../services/audit_log_service.dart';
class SupplierController extends GetxController {
  static SupplierController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final Rx<Supplier?> selectedSupplier = Rx<Supplier?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // معلومات الصيدلية الحالية
  RxString currentPharmacyId = ''.obs;
  RxString currentUserId = ''.obs;
  RxString currentUserRole = ''.obs;

  // مرجع لـ AuthController
  AuthController get _authController => Get.find<AuthController>();
  final AuditLogService _auditLogService = AuditLogService();

  Map<String, dynamic> get _actor =>
      Map<String, dynamic>.from(_authController.actorInfo);

  void _ensureCan(String permission, String message) {
    if (!_authController.can(permission)) {
      throw Exception(message);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _getCurrentUserInfo();
    fetchSuppliers();
  }

  Future<void> _getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      print('👤 Firebase current user: ${user?.uid}');

      if (user != null) {
        currentUserId.value = user.uid;

        // تحقق من AuthController

        // استخدام userId مباشرة كـ pharmacyId (افتراضياً)
        currentPharmacyId.value = _authController.userId ?? user.uid;

        // تحديد دور المستخدم
        currentUserRole.value = _authController.currentEmployee.value != null
            ? 'employee'
            : 'owner';
      } else {
        currentPharmacyId.value = '';
        currentUserId.value = '';
        currentUserRole.value = '';
      }
    } catch (e) {
      currentPharmacyId.value = '';
      currentUserId.value = '';
      currentUserRole.value = '';
    }
  }

  // دالة للحصول على المرجع الرئيسي للموردين
  CollectionReference get suppliersCollection {
    if (currentPharmacyId.isEmpty) {
      throw Exception('لم يتم تحديد الصيدلية');
    }


    return _firestore
        .collection('pharmacies')
        .doc(currentPharmacyId.value)
        .collection('suppliers');
  }

  // جلب جميع الموردين للصيدلية الحالية
  Future<void> fetchSuppliers() async {
    try {

      isLoading.value = true;
      if (!_checkUserPermissions('suppliers.view')) {
        suppliers.clear();
        return;
      }
      // التأكد من وجود pharmacyId
      if (currentPharmacyId.isEmpty) {
        await _getCurrentUserInfo();

        if (currentPharmacyId.isEmpty) {
          Get.snackbar(
            'خطأ',
            'لا يمكن تحديد الصيدلية',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // اختبار الاتصال بـ Firestore
      try {
        final pharmacyDoc = await _firestore
            .collection('pharmacies')
            .doc(currentPharmacyId.value)
            .get();

        if (!pharmacyDoc.exists) {
        }
      } catch (e) {
        print('❌ Error checking pharmacy document: $e');
      }

      final querySnapshot = await suppliersCollection.orderBy('name').get();

      if (querySnapshot.docs.isEmpty) {
        suppliers.clear();
      } else {
        final suppliersList = <Supplier>[];
        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final supplier = Supplier.fromMap(data, doc.id);
            suppliersList.add(supplier);
          } catch (e, stackTrace) {

            print('📝 Problematic data: ${doc.data()}');
          }
        }

        suppliers.assignAll(suppliersList);
      }

    } catch (e, stackTrace) {

      suppliers.clear();

      Get.snackbar(
        'خطأ',
        'فشل في جلب بيانات الموردين',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('✅ fetchSuppliers() completed');
    }
  }

  // إضافة مورد جديد (مع ديباجنغ)
  Future<void> addSupplier(Supplier supplier) async {
    try {

      isLoading.value = true;
      _ensureCan('suppliers.create', 'ليس لديك صلاحية إضافة الموردين');
      // إضافة معلومات إضافية
      final supplierData = supplier.toMap()
        ..addAll({
          'createdBy': currentUserId.value,
          'createdByType': currentUserRole.value,
          'createdByName': _getCurrentUserName(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'pharmacyId': currentPharmacyId.value,
        });

      final docRef = await suppliersCollection.add(supplierData);

      final createdSupplier = supplier.copyWith(id: docRef.id);
      await _logCreateSupplier(createdSupplier);
      // الانتظار قليلاً ثم إعادة الجلب
      await Future.delayed(Duration(milliseconds: 500));
      await fetchSuppliers();

      Get.snackbar(
        'نجاح',
        'تم إضافة المورد بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      print('❌ Error adding supplier: $e');
      print('📝 Stack trace: $stackTrace');
      Get.snackbar(
        'خطأ',
        'فشل في إضافة المورد: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // دالة مساعدة لاختبار الاتصال ومعرفة المسار الصحيح
  Future<void> debugFirestoreStructure() async {
    try {
      print('🔍 Debugging Firestore structure...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('👤 Current user UID: ${user.uid}');
      print('📧 Current user email: ${user.email}');
      print('🏥 AuthController userId: ${_authController.userId}');
      print('👥 AuthController currentEmployee: ${_authController.currentEmployee.value}');

      // التحقق من وجود مستند الصيدلية
      final pharmacyId = _authController.userId ?? user.uid;
      print('🔍 Checking pharmacy document at: pharmacies/$pharmacyId');

      final pharmacyDoc = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .get();

      print('📄 Pharmacy document exists: ${pharmacyDoc.exists}');
      if (pharmacyDoc.exists) {
        print('📝 Pharmacy data: ${pharmacyDoc.data()}');
      }

      // التحقق من وجود suppliers collection
      final suppliersSnapshot = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('suppliers')
          .limit(1)
          .get();

      print('📊 Suppliers collection has ${suppliersSnapshot.docs.length} documents');
      if (suppliersSnapshot.docs.isNotEmpty) {
        print('📝 First supplier: ${suppliersSnapshot.docs.first.data()}');
      }

    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  // تحديث المودل ليكون أكثر مرونة مع التواريخ
  static Supplier _safeFromMap(Map<String, dynamic> map, String id) {
    try {
      return Supplier(
        id: id,
        name: map['name']?.toString() ?? '',
        contactPerson: map['contactPerson']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        suppliedMedications: List<String>.from(map['suppliedMedications'] ?? []),
        contractStartDate: _parseDate(map['contractStartDate']),
        contractEndDate: map['contractEndDate'] != null
            ? _parseDate(map['contractEndDate'])
            : null,
        status: map['status']?.toString() ?? 'فعال',
        notes: map['notes']?.toString() ?? '',
        createdAt: _parseDate(map['createdAt']),
        updatedAt: _parseDate(map['updatedAt']),
      );
    } catch (e) {
      print('❌ Error in _safeFromMap: $e');
      print('📝 Map data: $map');
      rethrow;
    }
  }

  static DateTime _parseDate(dynamic dateValue) {
    try {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.parse(dateValue);
      return DateTime.now();
    } catch (e) {
      print('❌ Error parsing date: $dateValue');
      return DateTime.now();
    }
  }

  // التحقق من الصلاحيات
  bool _checkUserPermissions(String permission) {
    try {
      return _authController.can(permission);
    } catch (_) {
      return false;
    }
  }
  Future<void> _logCreateSupplier(Supplier supplier) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: currentPharmacyId.value,
        action: 'create_supplier',
        module: AuditModules.suppliers,
        targetType: AuditTargetTypes.supplier,
        targetId: supplier.id,
        targetName: supplier.name,
        performedBy: _actor,
        details: {
          'note': 'تم إنشاء مورد جديد',
          'newValues': {
            'name': supplier.name,
            'contactPerson': supplier.contactPerson,
            'phone': supplier.phone,
            'address': supplier.address,
            'status': supplier.status,
            'suppliedMedications': supplier.suppliedMedications,
            'contractStartDate': supplier.contractStartDate.toIso8601String(),
            'contractEndDate': supplier.contractEndDate?.toIso8601String(),
            'notes': supplier.notes,
          },
        },
        entityPath: 'pharmacies/${currentPharmacyId.value}/suppliers/${supplier.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (create_supplier): $e');
    }
  }

  Future<void> _logUpdateSupplier({
    required Supplier oldSupplier,
    required Supplier newSupplier,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: currentPharmacyId.value,
        action: 'update_supplier',
        module: AuditModules.suppliers,
        targetType: AuditTargetTypes.supplier,
        targetId: newSupplier.id,
        targetName: newSupplier.name,
        performedBy: _actor,
        details: {
          'note': 'تم تحديث بيانات المورد',
          'oldValues': {
            'name': oldSupplier.name,
            'contactPerson': oldSupplier.contactPerson,
            'phone': oldSupplier.phone,
            'address': oldSupplier.address,
            'status': oldSupplier.status,
            'suppliedMedications': oldSupplier.suppliedMedications,
            'contractStartDate': oldSupplier.contractStartDate.toIso8601String(),
            'contractEndDate': oldSupplier.contractEndDate?.toIso8601String(),
            'notes': oldSupplier.notes,
          },
          'newValues': {
            'name': newSupplier.name,
            'contactPerson': newSupplier.contactPerson,
            'phone': newSupplier.phone,
            'address': newSupplier.address,
            'status': newSupplier.status,
            'suppliedMedications': newSupplier.suppliedMedications,
            'contractStartDate': newSupplier.contractStartDate.toIso8601String(),
            'contractEndDate': newSupplier.contractEndDate?.toIso8601String(),
            'notes': newSupplier.notes,
          },
        },
        entityPath: 'pharmacies/${currentPharmacyId.value}/suppliers/${newSupplier.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (update_supplier): $e');
    }
  }

  Future<void> _logDeleteSupplier(Supplier supplier) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: currentPharmacyId.value,
        action: 'delete_supplier',
        module: AuditModules.suppliers,
        targetType: AuditTargetTypes.supplier,
        targetId: supplier.id,
        targetName: supplier.name,
        performedBy: _actor,
        details: {
          'note': 'تم حذف المورد',
          'deletedSnapshot': {
            'name': supplier.name,
            'contactPerson': supplier.contactPerson,
            'phone': supplier.phone,
            'address': supplier.address,
            'status': supplier.status,
            'suppliedMedications': supplier.suppliedMedications,
            'contractStartDate': supplier.contractStartDate.toIso8601String(),
            'contractEndDate': supplier.contractEndDate?.toIso8601String(),
            'notes': supplier.notes,
          },
        },
        entityPath: 'pharmacies/${currentPharmacyId.value}/suppliers/${supplier.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (delete_supplier): $e');
    }
  }

  String _getCurrentUserName() {
    if (_authController.currentEmployee.value != null) {
      return _authController.currentEmployee.value!['name'] ?? 'موظف';
    }
    return _authController.userName;
  }

  // باقي الدوال كما هي...
  Future<void> updateSupplier(String id, Supplier supplier) async {
    try {
      _ensureCan('suppliers.update', 'ليس لديك صلاحية لتعديل الموردين');

      final oldSupplier = suppliers.firstWhereOrNull((s) => s.id == id);
      if (oldSupplier == null) {
        Get.snackbar('تنبيه', 'المورد غير موجود');
        return;
      }
      isLoading.value = true;
      final updatedSupplier = supplier.copyWith(id: id);
      await _logUpdateSupplier(
        oldSupplier: oldSupplier,
        newSupplier: updatedSupplier,
      );

      await fetchSuppliers();
      Get.snackbar('نجاح', 'تم تحديث بيانات المورد بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث بيانات المورد');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      _ensureCan('suppliers.delete', 'ليس لديك صلاحية حذف الموردين');

      final supplier = suppliers.firstWhereOrNull((s) => s.id == id);
      if (supplier == null) {
        Get.snackbar('تنبيه', 'المورد غير موجود');
        return;
      }

      isLoading.value = true;

      await suppliersCollection.doc(id).delete();

      await _logDeleteSupplier(supplier);

      suppliers.removeWhere((s) => s.id == id);

      Get.snackbar('نجاح', 'تم حذف المورد بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف المورد');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  List<Supplier> get filteredSuppliers {
    if (!_checkUserPermissions('suppliers.view')) return [];
    if (searchQuery.isEmpty) return suppliers;

    final query = searchQuery.value.toLowerCase();
    return suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(query) ||
          supplier.contactPerson.toLowerCase().contains(query) ||
          supplier.phone.contains(query);
    }).toList();
  }

// في SupplierController
  RxMap<String, dynamic> get supplierStats {
    final totalSuppliers = suppliers.length;
    final activeSuppliers = suppliers.where((s) => s.status == 'فعال').length;
    final suspendedSuppliers = suppliers.where((s) => s.status == 'معلق').length;
    final totalMedications = suppliers.fold(0, (sum, supplier) => sum + supplier.suppliedMedications.length);

    return {
      'totalSuppliers': totalSuppliers,
      'activeSuppliers': activeSuppliers,
      'suspendedSuppliers': suspendedSuppliers,
      'totalMedications': totalMedications,
    }.obs;
  }
  Future<Supplier?> getSupplierById(String id) async {
    try {
      if (!_checkUserPermissions('suppliers.view')) return null;
      final doc = await suppliersCollection.doc(id).get();
      if (doc.exists) {
        return _safeFromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> reloadSuppliers() async {
    await fetchSuppliers();
  }

  bool get canViewSuppliersPage => _checkUserPermissions('suppliers.view');
  bool canAddSuppliers() => _checkUserPermissions('suppliers.create');
  bool canEditSuppliers() => _checkUserPermissions('suppliers.update');
  bool canDeleteSuppliers() => _checkUserPermissions('suppliers.delete');
  bool canManageSupplierCredit() => _checkUserPermissions('suppliers.credit.manage');
}