// lib/controllers/insurance_company_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/insurance_company_model.dart';
import '../services/search_index_service.dart';
import 'auth_controller.dart';
import '../services/audit_log_service.dart';
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


  final AuditLogService _auditLogService = AuditLogService();
  AuthController get _authController => Get.find<AuthController>();

  Map<String, dynamic> get _actor =>
      Map<String, dynamic>.from(_authController.actorInfo);

  void _ensureCan(String permission, String message) {
    if (!_authController.can(permission)) {
      throw Exception(message);
    }
  }


  bool _checkUserPermissions(String permission) {
    try {
      return _authController.can(permission);
    } catch (_) {
      return false;
    }
  }


  Future<void> _logCreateInsuranceCompany(InsuranceCompany company) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: currentPharmacyId.value,
        action: AuditActions.createInsuranceCompany,
        module: AuditModules.insurance,
        targetType: AuditTargetTypes.insuranceCompany,
        targetId: company.id,
        targetName: company.name,
        performedBy: _actor,
        details: {
          'note': 'تم إنشاء شركة تأمين جديدة',
          'newValues': {
            'name': company.name,
            'code': company.code,
            'contactPerson': company.contactPerson,
            'phone': company.phone,
            'discountPercentage': company.discountPercentage,
            'status': company.status,
            'contractStartDate': company.contractStartDate.toIso8601String(),
            'contractEndDate': company.contractEndDate?.toIso8601String(),
            'notes': company.notes,
          },
        },
        entityPath:
        'pharmacies/${currentPharmacyId.value}/insurance_companies/${company.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (create_insurance_company): $e');
    }
  }

  Future<void> _logUpdateInsuranceCompany({
    required InsuranceCompany oldCompany,
    required InsuranceCompany newCompany,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: currentPharmacyId.value,
        action: AuditActions.updateInsuranceCompany,
        module: AuditModules.insurance,
        targetType: AuditTargetTypes.insuranceCompany,
        targetId: newCompany.id,
        targetName: newCompany.name,
        performedBy: _actor,
        details: {
          'note': 'تم تحديث بيانات شركة التأمين',
          'oldValues': {
            'name': oldCompany.name,
            'code': oldCompany.code,
            'contactPerson': oldCompany.contactPerson,
            'phone': oldCompany.phone,
            'discountPercentage': oldCompany.discountPercentage,
            'status': oldCompany.status,
            'contractStartDate': oldCompany.contractStartDate.toIso8601String(),
            'contractEndDate': oldCompany.contractEndDate?.toIso8601String(),
            'notes': oldCompany.notes,
          },
          'newValues': {
            'name': newCompany.name,
            'code': newCompany.code,
            'contactPerson': newCompany.contactPerson,
            'phone': newCompany.phone,
            'discountPercentage': newCompany.discountPercentage,
            'status': newCompany.status,
            'contractStartDate': newCompany.contractStartDate.toIso8601String(),
            'contractEndDate': newCompany.contractEndDate?.toIso8601String(),
            'notes': newCompany.notes,
          },
        },
        entityPath:
        'pharmacies/${currentPharmacyId.value}/insurance_companies/${newCompany.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (update_insurance_company): $e');
    }
  }

  Future<void> _logDeleteInsuranceCompany(InsuranceCompany company) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: currentPharmacyId.value,
        action: AuditActions.deleteInsuranceCompany,
        module: AuditModules.insurance,
        targetType: AuditTargetTypes.insuranceCompany,
        targetId: company.id,
        targetName: company.name,
        performedBy: _actor,
        details: {
          'note': 'تم حذف شركة التأمين',
          'deletedSnapshot': {
            'name': company.name,
            'code': company.code,
            'contactPerson': company.contactPerson,
            'phone': company.phone,
            'discountPercentage': company.discountPercentage,
            'status': company.status,
            'contractStartDate': company.contractStartDate.toIso8601String(),
            'contractEndDate': company.contractEndDate?.toIso8601String(),
            'notes': company.notes,
          },
        },
        entityPath:
        'pharmacies/${currentPharmacyId.value}/insurance_companies/${company.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (delete_insurance_company): $e');
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
      if (!_checkUserPermissions('insurance.view')) {
        companies.clear();
        return;
      }
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


  // lib/controllers/insurance_company_controller.dart

// أضف هذه الدالة الجديدة
  Future<void> _updatePharmacyAcceptedInsuranceCodes(String insuranceCode, {bool isAdding = true}) async {
    try {
      if (currentPharmacyId.isEmpty) return;

      final pharmacyRef = _firestore.collection('pharmacies').doc(currentPharmacyId.value);

      if (isAdding) {
        // إضافة الكود الجديد إذا لم يكن موجوداً
        await pharmacyRef.update({
          'acceptedInsuranceCodes': FieldValue.arrayUnion([insuranceCode.trim().toUpperCase()])
        });
      } else {
        // حذف الكود (عند حذف شركة التأمين)
        await pharmacyRef.update({
          'acceptedInsuranceCodes': FieldValue.arrayRemove([insuranceCode.trim().toUpperCase()])
        });
      }

      debugPrint('✅ Updated pharmacy acceptedInsuranceCodes with: $insuranceCode');
    } catch (e) {
      debugPrint('❌ Error updating pharmacy acceptedInsuranceCodes: $e');
      // لا نرمي الخطأ حتى لا يعطل العملية الرئيسية
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
      _ensureCan('insurance.create', 'ليس لديك صلاحية لإضافة شركات التأمين');

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

      final docRef = await insuranceCompaniesCollection.add(companyData);

      final createdCompany = company.copyWith(id: docRef.id);
      await _logCreateInsuranceCompany(createdCompany);
      await _updatePharmacyAcceptedInsuranceCodes(company.code, isAdding: true);
      await _rebuildSearchIndexForCurrentPharmacy();
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
      _ensureCan('insurance.update', 'ليس لديك صلاحية لتعديل شركات التأمين');

      // ✅ IMPORTANT: احصل على الشركة القديمة قبل التعديل
      final oldCompany = companies.firstWhere((c) => c.id == id);
      final oldCode = oldCompany.code;

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

      final updatedCompany = company.copyWith(id: id);

      await _logUpdateInsuranceCompany(
        oldCompany: oldCompany,
        newCompany: updatedCompany,
      );

      // ✅ تحديث الكود في الصيدلية إذا تغير
      await _updatePharmacyAcceptedInsuranceCodeOnEdit(oldCode, company.code);
      await _rebuildSearchIndexForCurrentPharmacy();
      await fetchInsuranceCompanies();

      Get.snackbar('نجاح', 'تم تحديث بيانات شركة التأمين بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث بيانات شركة التأمين');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }



  Future<void> _rebuildSearchIndexForCurrentPharmacy() async {
    try {
      if (currentPharmacyId.isEmpty) return;

      final pharmacyDoc = await _firestore
          .collection('pharmacies')
          .doc(currentPharmacyId.value)
          .get();

      final pharmacyData = pharmacyDoc.data();
      if (pharmacyData == null) return;

      await SearchIndexService().rebuildPharmacyIndex(
        pharmacyId: currentPharmacyId.value,
        pharmacyData: pharmacyData,
      );

      debugPrint('🔥 Search index rebuilt after insurance update');
    } catch (e) {
      debugPrint('❌ Error rebuilding search index: $e');
    }
  }





  // أضف هذه الدالة الجديدة
  Future<void> _updatePharmacyAcceptedInsuranceCodeOnEdit(String oldCode, String newCode) async {
    try {
      if (currentPharmacyId.isEmpty) return;
      if (oldCode == newCode) return; // لا تغيير في الكود

      final pharmacyRef = _firestore.collection('pharmacies').doc(currentPharmacyId.value);

      // إزالة الكود القديم وإضافة الجديد في عملية واحدة
      await pharmacyRef.update({
        'acceptedInsuranceCodes': FieldValue.arrayRemove([oldCode.trim().toUpperCase()])
      });

      await pharmacyRef.update({
        'acceptedInsuranceCodes': FieldValue.arrayUnion([newCode.trim().toUpperCase()])
      });

      debugPrint('✅ Updated insurance code from $oldCode to $newCode in pharmacy');
    } catch (e) {
      debugPrint('❌ Error updating insurance code in pharmacy: $e');
    }
  }
  Future<void> deleteInsuranceCompany(String id) async {
    try {
      _ensureCan('insurance.delete', 'ليس لديك صلاحية لحذف شركات التأمين');

      // ✅ احصل على الشركة قبل حذفها لمعرفة الكود
      final companyToDelete = companies.firstWhere((c) => c.id == id);

      isLoading.value = true;
      await insuranceCompaniesCollection.doc(id).delete();
      companies.removeWhere((company) => company.id == id);

      // ✅ أضف هذا السطر: حذف الكود من الصيدلية
      await _updatePharmacyAcceptedInsuranceCodes(companyToDelete.code, isAdding: false);
      await _rebuildSearchIndexForCurrentPharmacy();
      await _logDeleteInsuranceCompany(companyToDelete);
      Get.snackbar('نجاح', 'تم حذف شركة التأمين بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف شركة التأمين');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  List<InsuranceCompany> get filteredCompanies {
    if (!_checkUserPermissions('insurance.view')) return [];
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

  bool get canViewInsurancePage => _checkUserPermissions('insurance.view');
  bool canAddInsurance() => _checkUserPermissions('insurance.create');
  bool canEditInsurance() => _checkUserPermissions('insurance.update');
  bool canDeleteInsurance() => _checkUserPermissions('insurance.delete');
}