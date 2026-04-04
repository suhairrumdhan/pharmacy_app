// lib/controllers/insurance_company_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/insurance_company_model.dart';
import 'auth_controller.dart';

class InsuranceCompanyController extends GetxController {
  static InsuranceCompanyController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<InsuranceCompany> companies = <InsuranceCompany>[].obs;
  final Rx<InsuranceCompany?> selectedCompany = Rx<InsuranceCompany?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  RxString currentPharmacyId = ''.obs;
  RxString currentUserId = ''.obs;
  RxString currentUserRole = ''.obs;

  static const String PERMISSION_VIEW_INSURANCE = 'view_insurance_companies';
  static const String PERMISSION_ADD_INSURANCE = 'add_insurance_companies';
  static const String PERMISSION_EDIT_INSURANCE = 'edit_insurance_companies';
  static const String PERMISSION_DELETE_INSURANCE = 'delete_insurance_companies';

  bool _checkUserPermissions(String permission) {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentEmployee.value == null) {
        return true;
      }
      return authController.can(permission);
    } catch (_) {
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _getCurrentUserInfo();
    await fetchInsuranceCompanies();
  }

  Future<void> _getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        currentUserId.value = user.uid;

        final authController = Get.find<AuthController>();
        currentPharmacyId.value = authController.userId ?? user.uid;
        currentUserRole.value =
        authController.currentEmployee.value != null ? 'employee' : 'owner';
      }
    } catch (e) {
      debugPrint('❌ Error in _getCurrentUserInfo: $e');
    }
  }

  CollectionReference<Map<String, dynamic>> get insuranceCompaniesCollection {
    if (currentPharmacyId.isEmpty) {
      throw Exception('لم يتم تحديد الصيدلية');
    }

    return _firestore
        .collection('pharmacies')
        .doc(currentPharmacyId.value)
        .collection('insurance_companies');
  }

  Future<void> fetchInsuranceCompanies() async {
    try {
      isLoading.value = true;

      if (currentPharmacyId.isEmpty) {
        await _getCurrentUserInfo();
        if (currentPharmacyId.isEmpty) {
          Get.snackbar('خطأ', 'لا يمكن تحديد الصيدلية');
          return;
        }
      }

      final querySnapshot = await insuranceCompaniesCollection.orderBy('name').get();

      final companiesList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return InsuranceCompany.fromMap(data, doc.id);
      }).toList();

      companies.assignAll(companiesList);
    } catch (e) {
      debugPrint('❌ ERROR in fetchInsuranceCompanies: $e');
      companies.clear();
      Get.snackbar(
        'خطأ',
        'فشل في جلب بيانات شركات التأمين',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> isInsuranceCodeExists(String code, {String? excludeId}) async {
    final normalizedCode = code.trim().toUpperCase();

    final existing = companies.where((c) {
      if (excludeId != null && c.id == excludeId) return false;
      return c.code.trim().toUpperCase() == normalizedCode;
    }).toList();

    return existing.isNotEmpty;
  }

  Future<void> addInsuranceCompany(InsuranceCompany company) async {
    try {
      if (!_checkUserPermissions(PERMISSION_ADD_INSURANCE)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لإضافة شركات التأمين');
        return;
      }

      if (await isInsuranceCodeExists(company.code)) {
        Get.snackbar(
          'تنبيه',
          'كود شركة التأمين مستخدم مسبقًا، الرجاء إدخال كود مختلف',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      final companyData = company.toMap()
        ..addAll({
          'createdBy': currentUserId.value,
          'createdByType': currentUserRole.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

      await insuranceCompaniesCollection.add(companyData);
      await fetchInsuranceCompanies();

      Get.snackbar(
        'نجاح',
        'تم إضافة شركة التأمين بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة شركة التأمين');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateInsuranceCompany(String id, InsuranceCompany company) async {
    try {
      if (!_checkUserPermissions(PERMISSION_EDIT_INSURANCE)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لتعديل شركات التأمين');
        return;
      }

      if (await isInsuranceCodeExists(company.code, excludeId: id)) {
        Get.snackbar(
          'تنبيه',
          'كود شركة التأمين مستخدم مسبقًا، الرجاء إدخال كود مختلف',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      final companyData = company.toMap()
        ..addAll({
          'updatedBy': currentUserId.value,
          'updatedByType': currentUserRole.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });

      await insuranceCompaniesCollection.doc(id).update(companyData);
      await fetchInsuranceCompanies();

      Get.snackbar('نجاح', 'تم تحديث بيانات شركة التأمين بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث بيانات شركة التأمين');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteInsuranceCompany(String id) async {
    try {
      if (!_checkUserPermissions(PERMISSION_DELETE_INSURANCE)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لحذف شركات التأمين');
        return;
      }

      isLoading.value = true;
      await insuranceCompaniesCollection.doc(id).delete();
      companies.removeWhere((company) => company.id == id);

      Get.snackbar('نجاح', 'تم حذف شركة التأمين بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف شركة التأمين');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  List<InsuranceCompany> get filteredCompanies {
    if (!_checkUserPermissions(PERMISSION_VIEW_INSURANCE)) return [];
    if (searchQuery.value.trim().isEmpty) return companies;

    final query = searchQuery.value.toLowerCase().trim();

    return companies.where((company) {
      return company.name.toLowerCase().contains(query) ||
          company.code.toLowerCase().contains(query) ||
          company.contactPerson.toLowerCase().contains(query) ||
          company.phone.toLowerCase().contains(query);
    }).toList();
  }

  RxMap<String, dynamic> get companyStats {
    final totalCompanies = companies.length;
    final activeCompanies = companies.where((c) => c.status == 'فعال').length;
    final expiredContracts = companies.where((c) => c.isContractExpired).length;
    final expiringSoonContracts =
        companies.where((c) => c.isContractExpiringSoon).length;

    return {
      'totalCompanies': totalCompanies,
      'activeCompanies': activeCompanies,
      'expiredContracts': expiredContracts,
      'expiringSoonContracts': expiringSoonContracts,
    }.obs;
  }

  bool get canViewInsurancePage => _checkUserPermissions(PERMISSION_VIEW_INSURANCE);
  bool canAddInsurance() => _checkUserPermissions(PERMISSION_ADD_INSURANCE);
  bool canEditInsurance() => _checkUserPermissions(PERMISSION_EDIT_INSURANCE);
  bool canDeleteInsurance() => _checkUserPermissions(PERMISSION_DELETE_INSURANCE);
}