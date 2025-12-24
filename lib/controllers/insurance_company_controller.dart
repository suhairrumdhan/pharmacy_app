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

  // معلومات الصيدلية
  RxString currentPharmacyId = ''.obs;
  RxString currentUserId = ''.obs;
  RxString currentUserRole = ''.obs;

  // التحقق من الصلاحيات
  bool _checkUserPermissions(String permission) {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentEmployee.value == null) {
        return true; // المالك لديه كل الصلاحيات
      }
      return authController.can(permission);
    } catch (e) {
      return false;
    }
  }

  // الصلاحيات
  static const String PERMISSION_VIEW_INSURANCE = 'view_insurance_companies';
  static const String PERMISSION_ADD_INSURANCE = 'add_insurance_companies';
  static const String PERMISSION_EDIT_INSURANCE = 'edit_insurance_companies';
  static const String PERMISSION_DELETE_INSURANCE = 'delete_insurance_companies';

  @override
  void onInit() {
    super.onInit();
    _getCurrentUserInfo();
    fetchInsuranceCompanies();
  }

  Future<void> _getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        currentUserId.value = user.uid;

        final authController = Get.find<AuthController>();
        currentPharmacyId.value = authController.userId ?? user.uid;
        currentUserRole.value = authController.currentEmployee.value != null
            ? 'employee'
            : 'owner';
      }
    } catch (e) {
      print('❌ Error in _getCurrentUserInfo: $e');
    }
  }

  // المرجع الرئيسي لشركات التأمين
  CollectionReference get insuranceCompaniesCollection {
    if (currentPharmacyId.isEmpty) {
      throw Exception('لم يتم تحديد الصيدلية');
    }

    return _firestore
        .collection('pharmacies')
        .doc(currentPharmacyId.value)
        .collection('insurance_companies');
  }

  // جلب جميع شركات التأمين
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

      final querySnapshot = await insuranceCompaniesCollection
          .orderBy('name')
          .get();

      if (querySnapshot.docs.isEmpty) {
        companies.clear();
      } else {
        final companiesList = <InsuranceCompany>[];

        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final company = InsuranceCompany.fromMap(data, doc.id);
            companiesList.add(company);
          } catch (e) {
            print('Error converting document ${doc.id}: $e');
          }
        }

        companies.assignAll(companiesList);
      }

    } catch (e) {
      print('❌ ERROR in fetchInsuranceCompanies: $e');
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

  // إضافة شركة تأمين جديدة
  Future<void> addInsuranceCompany(InsuranceCompany company) async {
    try {
      if (!_checkUserPermissions(PERMISSION_ADD_INSURANCE)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لإضافة شركات التأمين');
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

  // تحديث بيانات شركة التأمين
  Future<void> updateInsuranceCompany(String id, InsuranceCompany company) async {
    try {
      if (!_checkUserPermissions(PERMISSION_EDIT_INSURANCE)) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لتعديل شركات التأمين');
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

  // حذف شركة تأمين
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

  // البحث والتصفية
  List<InsuranceCompany> get filteredCompanies {
    if (!_checkUserPermissions(PERMISSION_VIEW_INSURANCE)) return [];
    if (searchQuery.isEmpty) return companies;

    final query = searchQuery.value.toLowerCase();
    return companies.where((company) {
      return company.name.toLowerCase().contains(query) ||
          company.contactPerson.toLowerCase().contains(query) ||
          company.phone.contains(query);
    }).toList();
  }

  // الإحصائيات
  RxMap<String, dynamic> get companyStats {
    final totalCompanies = companies.length;
    final activeCompanies = companies.where((c) => c.status == 'فعال').length;
    final expiredContracts = companies.where((c) => c.isContractExpired).length;


    return {
      'totalCompanies': totalCompanies,
      'activeCompanies': activeCompanies,
      'expiredContracts': expiredContracts,
    }.obs;
  }

  // التحقق من الصلاحيات للواجهة
  bool get canViewInsurancePage => _checkUserPermissions(PERMISSION_VIEW_INSURANCE);
  bool canAddInsurance() => _checkUserPermissions(PERMISSION_ADD_INSURANCE);
  bool canEditInsurance() => _checkUserPermissions(PERMISSION_EDIT_INSURANCE);
  bool canDeleteInsurance() => _checkUserPermissions(PERMISSION_DELETE_INSURANCE);
}