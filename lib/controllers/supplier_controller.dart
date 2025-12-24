// lib/controllers/supplier_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/supplier_model.dart';
import 'auth_controller.dart';

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

  @override
  void onInit() {
    super.onInit();
    print('🎯 SupplierController - onInit');
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
        print('📱 AuthController currentEmployee: ${_authController.currentEmployee.value}');
        print('📱 AuthController userId: ${_authController.userId}');
        print('📱 AuthController pharmacyData: ${_authController.pharmacyData}');

        // استخدام userId مباشرة كـ pharmacyId (افتراضياً)
        currentPharmacyId.value = _authController.userId ?? user.uid;
        print('🏥 Set currentPharmacyId to: ${currentPharmacyId.value}');

        // تحديد دور المستخدم
        currentUserRole.value = _authController.currentEmployee.value != null
            ? 'employee'
            : 'owner';
        print('🎭 User role: ${currentUserRole.value}');
      } else {
        print('⚠️ No user logged in');
        currentPharmacyId.value = '';
        currentUserId.value = '';
        currentUserRole.value = '';
      }
    } catch (e) {
      print('❌ Error in _getCurrentUserInfo: $e');
      currentPharmacyId.value = '';
      currentUserId.value = '';
      currentUserRole.value = '';
    }
  }

  // دالة للحصول على المرجع الرئيسي للموردين
  CollectionReference get suppliersCollection {
    if (currentPharmacyId.isEmpty) {
      print('🚨 ERROR: currentPharmacyId is empty!');
      throw Exception('لم يتم تحديد الصيدلية');
    }

    final path = 'pharmacies/${currentPharmacyId.value}/suppliers';
    print('📂 Firestore path: $path');

    return _firestore
        .collection('pharmacies')
        .doc(currentPharmacyId.value)
        .collection('suppliers');
  }

  // جلب جميع الموردين للصيدلية الحالية
  Future<void> fetchSuppliers() async {
    try {
      print('🔄 fetchSuppliers() started');
      print('📌 currentPharmacyId: ${currentPharmacyId.value}');
      print('📌 currentPharmacyId isEmpty: ${currentPharmacyId.isEmpty}');

      isLoading.value = true;

      // التأكد من وجود pharmacyId
      if (currentPharmacyId.isEmpty) {
        print('⚠️ pharmacyId is empty, refreshing...');
        await _getCurrentUserInfo();

        if (currentPharmacyId.isEmpty) {
          print('🚨 Still no pharmacyId!');
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

        print('✅ Pharmacy document exists: ${pharmacyDoc.exists}');
        if (!pharmacyDoc.exists) {
          print('⚠️ Pharmacy document does not exist!');
        }
      } catch (e) {
        print('❌ Error checking pharmacy document: $e');
      }

      print('📡 Fetching suppliers from Firestore...');
      final querySnapshot = await suppliersCollection.orderBy('name').get();

      print('📊 Query returned ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ No suppliers found in collection');
        suppliers.clear();
      } else {
        print('📝 Processing ${querySnapshot.docs.length} documents...');

        final suppliersList = <Supplier>[];

        for (var doc in querySnapshot.docs) {
          try {
            print('📄 Document ID: ${doc.id}');
            print('📄 Document data type: ${doc.data().runtimeType}');
            print('📄 Document data: ${doc.data()}');

            final data = doc.data() as Map<String, dynamic>;
            final supplier = Supplier.fromMap(data, doc.id);
            suppliersList.add(supplier);
            print('✅ Successfully converted document ${doc.id}');
          } catch (e, stackTrace) {
            print('❌ ERROR converting document ${doc.id}: $e');
            print('📝 Stack trace: $stackTrace');
            print('📝 Problematic data: ${doc.data()}');
          }
        }

        suppliers.assignAll(suppliersList);
        print('✅ Successfully loaded ${suppliers.length} suppliers');
      }

    } catch (e, stackTrace) {
      print('❌ ERROR in fetchSuppliers: $e');
      print('📝 Stack trace: $stackTrace');
      print('❌ Error type: ${e.runtimeType}');

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
      print('➕ addSupplier() started for: ${supplier.name}');
      print('📌 currentPharmacyId: ${currentPharmacyId.value}');

      isLoading.value = true;

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

      print('📝 Supplier data to save:');
      print('  name: ${supplierData['name']}');
      print('  phone: ${supplierData['phone']}');
      print('  contractStartDate: ${supplierData['contractStartDate']}');
      print('  createdAt: ${supplierData['createdAt']}');
      print('  pharmacyId: ${supplierData['pharmacyId']}');

      final docRef = await suppliersCollection.add(supplierData);
      print('✅ Supplier added with ID: ${docRef.id}');

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
      if (_authController.currentEmployee.value == null) {
        return true;
      }
      return _authController.can(permission);
    } catch (e) {
      return false;
    }
  }

  // الصلاحيات
  static const String PERMISSION_VIEW_SUPPLIERS = 'view_suppliers';
  static const String PERMISSION_ADD_SUPPLIERS = 'add_suppliers';
  static const String PERMISSION_EDIT_SUPPLIERS = 'edit_suppliers';
  static const String PERMISSION_DELETE_SUPPLIERS = 'delete_suppliers';
  static const String PERMISSION_MANAGE_SUPPLIER_CREDIT = 'manage_supplier_credit';

  String _getCurrentUserName() {
    if (_authController.currentEmployee.value != null) {
      return _authController.currentEmployee.value!['name'] ?? 'موظف';
    }
    return _authController.userName;
  }

  // باقي الدوال كما هي...
  Future<void> updateSupplier(String id, Supplier supplier) async {
    try {
      if (!_checkUserPermissions(PERMISSION_EDIT_SUPPLIERS)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لتعديل الموردين');
        return;
      }

      isLoading.value = true;
      final supplierData = supplier.toMap()
        ..addAll({
          'updatedBy': currentUserId.value,
          'updatedByType': currentUserRole.value,
          'updatedByName': _getCurrentUserName(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

      await suppliersCollection.doc(id).update(supplierData);
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
      if (!_checkUserPermissions(PERMISSION_DELETE_SUPPLIERS)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لحذف الموردين');
        return;
      }
      isLoading.value = true;
      await suppliersCollection.doc(id).delete();
      suppliers.removeWhere((supplier) => supplier.id == id);
      Get.snackbar('نجاح', 'تم حذف المورد بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف المورد');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  List<Supplier> get filteredSuppliers {
    if (!_checkUserPermissions(PERMISSION_VIEW_SUPPLIERS)) return [];
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
      if (!_checkUserPermissions(PERMISSION_VIEW_SUPPLIERS)) return null;
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

  bool get canViewSuppliersPage => _checkUserPermissions(PERMISSION_VIEW_SUPPLIERS);
  bool canAddSuppliers() => _checkUserPermissions(PERMISSION_ADD_SUPPLIERS);
  bool canEditSuppliers() => _checkUserPermissions(PERMISSION_EDIT_SUPPLIERS);
  bool canDeleteSuppliers() => _checkUserPermissions(PERMISSION_DELETE_SUPPLIERS);
  bool canManageSupplierCredit() => _checkUserPermissions(PERMISSION_MANAGE_SUPPLIER_CREDIT);
}