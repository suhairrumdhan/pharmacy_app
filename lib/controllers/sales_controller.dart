// lib/controllers/sales_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmacy_desktop/controllers/shift_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_model.dart';
import '../models/sales_model.dart';
import '../models/insurance_company_model.dart';
import 'auth_controller.dart';
import 'inventory_controller.dart';
import 'insurance_company_controller.dart';
import '../services/audit_log_service.dart';
class SalesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FocusNode searchFocusNode = FocusNode();
  final RxBool allowAutoFocusSearch = true.obs;
  final RxDouble manualDiscount = 0.0.obs; // خصم موظف يدوي
  static const String _pendingInvoicesKey = 'pending_invoices_';
  static const String _kPharmacyHistory = '__pharmacy__';
  static const String _kMyHistory = '__my_history__';
  final RxMap<String, List<Sale>> _userInvoices = <String, List<Sale>>{}.obs;
  final RxInt currentInvoiceIndex = 0.obs;
  final Rx<Sale> currentSale = Sale(
    invoiceNumber: Sale.generateInvoiceNumber(),
    pharmacyId: '',
    employeeId: null,
    employeeName: null,
    items: const [],
    subtotal: 0.0,
    total: 0.0,
    paymentMethod: PaymentMethod.cash,
    saleDate: DateTime.now(),
  ).obs;

  final RxList<Medicine> searchResults = <Medicine>[].obs;
  final RxList<InsuranceCompany> insuranceCompanies = <InsuranceCompany>[].obs;
  final Rx<InsuranceCompany?> selectedInsuranceCompany =
  Rx<InsuranceCompany?>(null);

  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  final RxBool isScanning = false.obs;
  final RxString barcodeInput = ''.obs;
  StreamSubscription? _barcodeSubscription;

  final RxDouble cashReceived = 0.0.obs;
  final RxDouble changeAmount = 0.0.obs;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool _initialized = false;
  bool _employeeDataInitialized = false;
  bool _insuranceCompaniesLoaded = false;

  final RxBool refundMode = false.obs;

  final TextEditingController refundInvoiceController = TextEditingController();
  final Rxn<Sale> originalSale = Rxn<Sale>();

  final RxDouble refundCashOut = 0.0.obs;
  final RxDouble refundCardOut = 0.0.obs;

  final AuditLogService _auditLogService = AuditLogService();

  AuthController get authController => Get.find<AuthController>();

  void _ensureCan(String permission, String message) {
    if (!authController.can(permission)) {
      throw Exception(message);
    }
  }

  Map<String, dynamic> get _actor => Map<String, dynamic>.from(authController.actorInfo);


  Future<void> _logCreateSale(Sale savedSale) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: pharmacyId,
        action: AuditActions.createSale,
        module: AuditModules.sales,
        targetType: AuditTargetTypes.sale,
        targetId: savedSale.id ?? '',
        targetName: savedSale.invoiceNumber,
        performedBy: _actor,
        details: {
          'note': 'تم إنشاء فاتورة مبيعات',
          'newValues': {
            'invoiceNumber': savedSale.invoiceNumber,
            'saleType': savedSale.type.name,
            'itemsCount': savedSale.items.length,
            'subtotal': savedSale.subtotal,
            'total': savedSale.total,
            'customerPaid': _customerPaid(savedSale),
            'companyBilled': _companyBilled(savedSale),
            'paymentMethod': _customerMethod(savedSale).name,
            'employeeId': savedSale.employeeId,
            'employeeName': savedSale.employeeName,
            'customerName': savedSale.customerName,
            'customerPhone': savedSale.customerPhone,
            'insuranceCompanyId': savedSale.insuranceCompanyId,
            'insuranceCompanyName': savedSale.insuranceCompanyName,
            'shiftId': savedSale.shiftId,
            'isSaved': savedSale.isSaved,
            'isDeleted': savedSale.isDeleted,
          },
        },
        entityPath: 'pharmacies/$pharmacyId/sales/${savedSale.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (create_sale): $e');
    }
  }

  Future<void> _logRefundSale({
    required String saleId,
    required Sale refundSale,
    required Sale originalSale,
    required String shiftId,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: pharmacyId,
        action: AuditActions.refundSale,
        module: AuditModules.sales,
        targetType: AuditTargetTypes.sale,
        targetId: saleId,
        targetName: refundSale.invoiceNumber,
        performedBy: _actor,
        details: {
          'note': 'تم إنشاء فاتورة ترجيع',
          'oldValues': {
            'refSaleId': originalSale.id,
            'refInvoiceNumber': originalSale.invoiceNumber,
          },
          'newValues': {
            'refundInvoiceNumber': refundSale.invoiceNumber,
            'itemsCount': refundSale.items.length,
            'subtotal': refundSale.subtotal,
            'total': refundSale.total,
            'cashOut': refundCashOut.value,
            'cardOut': refundCardOut.value,
            'paymentMethod': refundSale.paymentMethod.name,
            'shiftId': shiftId,
          },
        },
        entityPath: 'pharmacies/$pharmacyId/sales/$saleId',
      );
    } catch (e) {
      debugPrint('❌ audit log error (refund_sale): $e');
    }
  }

  Future<void> _logDeleteSale({
    required String saleId,
    required Sale sale,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: pharmacyId,
        action: 'delete_sale',
        module: AuditModules.sales,
        targetType: AuditTargetTypes.sale,
        targetId: saleId,
        targetName: sale.invoiceNumber,
        performedBy: _actor,
        details: {
          'note': 'تم حذف الفاتورة منطقيًا',
          'deletedSnapshot': {
            'invoiceNumber': sale.invoiceNumber,
            'saleType': sale.type.name,
            'itemsCount': sale.items.length,
            'subtotal': sale.subtotal,
            'total': sale.total,
            'employeeId': sale.employeeId,
            'employeeName': sale.employeeName,
            'customerName': sale.customerName,
            'customerPhone': sale.customerPhone,
            'paymentMethod': sale.paymentMethod.name,
            'isSaved': sale.isSaved,
            'isDeleted': true,
          },
        },
        entityPath: 'pharmacies/$pharmacyId/sales/$saleId',
      );
    } catch (e) {
      debugPrint('❌ audit log error (delete_sale): $e');
    }
  }

  // =============================
  // Firebase refs
  // =============================
  String get pharmacyId {
    try {
      final authController = Get.find<AuthController>();
      return authController.pharmacyId;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على pharmacyId: $e');
      return '';
    }
  }
  double get customerPayable {
    final s = currentSale.value.recalculate();
    final base = s.total; // هذا إجمالي الزبون (بعد التأمين وخصم الفاتورة إن وجد)
    return (base - manualDiscount.value).clamp(0.0, double.infinity);
  }

  CollectionReference get salesCollection {
    final id = pharmacyId;
    if (id.isEmpty) throw Exception('لم يتم تحديد الصيدلية');
    return _firestore.collection('pharmacies').doc(id).collection('sales');
  }

  bool get isOwnerView {
    try {
      final auth = Get.find<AuthController>();
      return auth.actorInfo['type'] == 'owner';
    } catch (_) {
      return false;
    }
  }

  AuthController get _authCtrl => Get.find<AuthController>();

  String get actorKey {
    final type = (_authCtrl.actorInfo['type'] ?? '').toString();
    final id = (_authCtrl.actorInfo['id'] ?? '').toString();
    if (type.isEmpty || id.isEmpty) return '';
    return '$type:$id';
  }

  String get legacyEmployeeId => (_authCtrl.actorInfo['id'] ?? '').toString();

  String get _currentActorKey => actorKey;

  String get _currentDbEmployeeId =>
      (currentSale.value.employeeId ?? legacyEmployeeId).toString();

  String get _currentEmployeeId => _currentActorKey;

  // =============================
  // ✅ Insurance Split Helpers
  // =============================
  bool _hasInsurance(Sale s) =>
      (s.insuranceCompanyId != null &&
          (s.insuranceCompanyId ?? '').trim().isNotEmpty);

  double _companyBilled(Sale s) {
    if (!_hasInsurance(s)) return 0.0;
    return (s.insuranceDiscount ?? 0.0).clamp(0.0, double.infinity);
  }

  double _customerPaid(Sale s) => (s.total).clamp(0.0, double.infinity);

  PaymentMethod _customerMethod(Sale s) {
    // Back-compat: old docs might have paymentMethod = insurance
    if (s.paymentMethod == PaymentMethod.insurance) return PaymentMethod.cash;
    return s.paymentMethod;
  }

  // =============================
  // History getter
  // =============================
  List<Sale> get historyInvoices {
    if (isOwnerView) return _userInvoices[_kPharmacyHistory] ?? [];
    return _userInvoices[_kMyHistory] ?? [];
  }

  // =============================
  // Active/completed getters
  // =============================
  List<Sale> get allUserInvoices {
    final key = _currentActorKey;
    return _userInvoices[key] ?? [];
  }

  List<Sale> get activeInvoices {
    final key = _currentActorKey;
    return (_userInvoices[key] ?? [])
        .where((i) => i.status == InvoiceStatus.pending)
        .toList();
  }

  List<Sale> get completedInvoices {
    final key = _currentActorKey;
    return (_userInvoices[key] ?? [])
        .where((i) => i.status == InvoiceStatus.completed)
        .toList();
  }

  List<Sale> get allInvoices => allUserInvoices;

  List<Sale> get userCompletedInvoices {
    final key = _currentActorKey;
    return (_userInvoices[key] ?? [])
        .where((inv) => inv.status == InvoiceStatus.completed)
        .toList();
  }

  // =============================
  // Lifecycle
  // =============================
  @override
  Future<void> onInit() async {
    super.onInit();
    if (_initialized) return;

    try {
      final authController = Get.find<AuthController>();
      while (!authController.isPharmacyLoaded.value) {
        await Future.delayed(const Duration(milliseconds: 80));
      }

      Get.find<InventoryController>();

      await initializeEmployeeData();
      await loadInsuranceCompanies();
      await _loadUserInvoices();

      if (activeInvoices.isEmpty) {
        _createNewEmptyInvoice();
      } else {
        _loadInvoice(0);
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('❌ خطأ في تهيئة SalesController: $e');
      debugPrint('$st');
    }
  }

  @override
  void onClose() {
    _barcodeSubscription?.cancel();
    searchFocusNode.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    notesController.dispose();
    refundInvoiceController.dispose();

    _initialized = false;
    _employeeDataInitialized = false;
    _insuranceCompaniesLoaded = false;

    super.onClose();
  }

  // =============================
  // Employee data
  // =============================
  Future<void> initializeEmployeeData() async {
    if (_employeeDataInitialized) return;

    try {
      _employeeDataInitialized = true;

      final authController = Get.find<AuthController>();
      final actorInfo = await authController.getSaleActorInfo();

      final empId = (actorInfo['id'] ?? '').toString().trim();
      final empName =
      (actorInfo['name'] ?? actorInfo['username'] ?? '').toString().trim();

      final updated = currentSale.value
          .copyWith(
        employeeId: empId.isEmpty ? legacyEmployeeId : empId,
        employeeName: empName.isEmpty ? currentSale.value.employeeName : empName,
        pharmacyId: actorInfo['pharmacyId']?.toString() ?? pharmacyId,
      )
          .recalculate();

      currentSale.value = updated;
    } catch (e) {
      _employeeDataInitialized = false;
      _setFallbackData();
    }
  }
  void pauseAutoFocus() => allowAutoFocusSearch.value = false;
  void resumeAutoFocus() => allowAutoFocusSearch.value = true;
  void focusSearchIfAllowed() {
    // ننفذ بعد انتهاء الفريم الحالي لتفادي مشاكل rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // لو المستخدم ضغط على حقل آخر وما نبيوش نخطف الفوكس
      if (!allowAutoFocusSearch.value) return;

      // لو البحث مش مركز، رجّعله الفوكس
      if (!searchFocusNode.hasFocus) {
        searchFocusNode.requestFocus();
      }
    });
  }
  void _setFallbackData() {
    final user = _auth.currentUser;
    final uid = user?.uid ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    final email = user?.email ?? '';
    final nameFromEmail = email.contains('@') ? email.split('@').first : 'موظف';

    currentSale.value = currentSale.value
        .copyWith(
      employeeId: uid,
      employeeName: nameFromEmail.isNotEmpty ? nameFromEmail : 'موظف',
      pharmacyId: pharmacyId,
    )
        .recalculate();
  }

  // =============================
  // Insurance
  // =============================
  Future<void> loadInsuranceCompanies() async {
    if (_insuranceCompaniesLoaded) return;

    try {
      isLoading.value = true;

      final insuranceController = Get.find<InsuranceCompanyController>();
      await insuranceController.fetchInsuranceCompanies();

      insuranceCompanies.assignAll(
        insuranceController.companies.whereType<InsuranceCompany>().toList(),
      );

      _insuranceCompaniesLoaded = true;
    } catch (e, st) {
      debugPrint('❌ loadInsuranceCompanies error: $e');
      debugPrint('$st');
      insuranceCompanies.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // =============================
  // Load invoices (Firebase completed + Local pending)
  // =============================
  Future<void> _loadUserInvoices() async {
    final keyId = _currentActorKey;
    final dbEmployeeId = _currentDbEmployeeId;

    if (keyId.isEmpty || dbEmployeeId.isEmpty) return;

    try {
      isLoading.value = true;

      _userInvoices.putIfAbsent(keyId, () => []);
      _userInvoices[keyId]!.clear();

      final querySnapshot = await salesCollection
          .where('employeeId', isEqualTo: dbEmployeeId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('saleDate', descending: true)
          .get();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final sale = Sale.fromMap({'id': doc.id, ...data})
              .copyWith(id: doc.id)
              .recalculate();
          _userInvoices[keyId]!.add(sale);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل فاتورة من Firebase: $e');
        }
      }

      await _loadPendingInvoicesFromLocal(keyId);

      _userInvoices[keyId]!.sort((a, b) {
        if (a.status == InvoiceStatus.pending &&
            b.status != InvoiceStatus.pending) return -1;
        if (a.status != InvoiceStatus.pending &&
            b.status == InvoiceStatus.pending) return 1;
        return b.saleDate.compareTo(a.saleDate);
      });

      update();
    } catch (e, st) {
      debugPrint('❌ خطأ في تحميل فواتير المستخدم: $e');
      debugPrint('$st');
    } finally {
      isLoading.value = false;
    }
  }

  // =============================
  // Owner history
  // =============================
  Future<void> loadHistoryAllForOwner({String? employeeId}) async {
    try {
      isLoading.value = true;

      Query q = salesCollection
          .where('isDeleted', isEqualTo: false)
          .orderBy('saleDate', descending: true);

      if (employeeId != null && employeeId.isNotEmpty) {
        q = q.where('employeeId', isEqualTo: employeeId);
      }

      final qs = await q.get();

      final list = qs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Sale.fromMap({'id': doc.id, ...data})
            .copyWith(id: doc.id)
            .recalculate();
      }).toList();

      _userInvoices[_kPharmacyHistory] = list;
      _userInvoices.refresh();
      update();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> ensureHistoryLoaded() async {
    if (isOwnerView) {
      if ((_userInvoices[_kPharmacyHistory] ?? []).isEmpty) {
        await loadHistoryAllForOwner();
      }
    } else {
      if ((_userInvoices[_kMyHistory] ?? []).isEmpty) {
        await loadMyHistoryToday();
      }
    }
  }


  Future<void> loadHistoryByRange({
    required DateTime start,
    required DateTime end,
    bool includeLocalPending = false,
    String? employeeId,
  }) async {
    try {
      isLoading.value = true;

      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      Query q = salesCollection
          .where('isDeleted', isEqualTo: false)
          .where('saleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDay))
          .where('saleDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDay))
          .orderBy('saleDate', descending: true);

      if (employeeId != null && employeeId.isNotEmpty) {
        q = q.where('employeeId', isEqualTo: employeeId);
      } else if (!isOwnerView) {
        q = q.where('employeeId', isEqualTo: _currentDbEmployeeId);
      }

      final qs = await q.get();

      final list = qs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Sale.fromMap({'id': doc.id, ...data})
            .copyWith(id: doc.id)
            .recalculate();
      }).toList();

      if (isOwnerView) {
        _userInvoices[_kPharmacyHistory] = list;
      } else {
        _userInvoices[_kMyHistory] = list;
      }

      if (!isOwnerView && includeLocalPending) {
        await _loadPendingInvoicesFromLocal(_currentActorKey);

        final merged = <Sale>[];
        merged.addAll(_userInvoices[_kMyHistory] ?? []);
        merged.addAll(activeInvoices);

        final byNumber = <String, Sale>{};
        for (final s in merged) {
          byNumber[s.invoiceNumber] = s;
        }

        final out = byNumber.values.toList();
        out.sort((a, b) {
          if (a.status == InvoiceStatus.pending &&
              b.status != InvoiceStatus.pending) return -1;
          if (a.status != InvoiceStatus.pending &&
              b.status == InvoiceStatus.pending) return 1;
          return b.saleDate.compareTo(a.saleDate);
        });

        _userInvoices[_kMyHistory] = out;
      }

      _userInvoices.refresh();
      update();
    } finally {
      isLoading.value = false;
    }
  }

  // =============================
  // Local pending
  // =============================
  Future<void> loadSavedInvoices({bool forceRefresh = false}) async {
    await _loadUserInvoices();
  }

  Future<void> _loadPendingInvoicesFromLocal(String keyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final newKey = '$_pendingInvoicesKey$keyId';
      final jsonStringNew = prefs.getString(newKey);

      final legacyId = legacyEmployeeId;
      final legacyKey = '$_pendingInvoicesKey$legacyId';
      final jsonStringLegacy =
      (legacyId.isNotEmpty && legacyId != keyId) ? prefs.getString(legacyKey) : null;

      final List<dynamic> mergedRaw = [];

      void addJsonString(String? s) {
        if (s == null || s.isEmpty) return;
        final decoded = json.decode(s);
        if (decoded is List) mergedRaw.addAll(decoded);
      }

      addJsonString(jsonStringNew);
      addJsonString(jsonStringLegacy);

      if (mergedRaw.isEmpty) return;

      _userInvoices.putIfAbsent(keyId, () => []);

      for (final raw in mergedRaw) {
        if (raw is! Map) continue;

        try {
          final sale = Sale.fromLocalMap(Map<String, dynamic>.from(raw));
          if (sale.status != InvoiceStatus.pending) continue;

          final exists = (_userInvoices[keyId] ?? [])
              .any((inv) => inv.invoiceNumber == sale.invoiceNumber);
          if (!exists) {
            _userInvoices[keyId]!.add(sale.recalculate());
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحويل فاتورة محلية: $e');
        }
      }

      if (jsonStringLegacy != null && jsonStringLegacy.isNotEmpty) {
        final pending = (_userInvoices[keyId] ?? [])
            .where((s) => s.status == InvoiceStatus.pending)
            .map((e) => e.toLocalMap())
            .toList();
        await prefs.setString(newKey, json.encode(pending));
        await prefs.remove(legacyKey);
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الفواتير المؤقتة المحلية: $e');
    }
  }

  Future<void> _savePendingInvoicesToLocal() async {
    final keyId = _currentActorKey;
    if (keyId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pendingInvoicesKey$keyId';

      final pending = activeInvoices;
      if (pending.isEmpty) {
        await prefs.remove(key);
        return;
      }

      final list = pending.map((s) => s.toLocalMap()).toList();
      await prefs.setString(key, json.encode(list));
    } catch (e, st) {
      debugPrint('❌ خطأ في حفظ الفواتير المؤقتة محلياً: $e');
      debugPrint('$st');
    }
  }

  // =============================
  // Invoice list helpers
  // =============================
  void _addOrReplaceInvoice(Sale invoice) {
    final key = _currentActorKey;
    if (key.isEmpty) return;

    final list = List<Sale>.from(_userInvoices[key] ?? const <Sale>[]);

    if (invoice.status == InvoiceStatus.completed || invoice.isSaved) {
      list.removeWhere((x) =>
      x.invoiceNumber == invoice.invoiceNumber &&
          x.status == InvoiceStatus.pending);
    }

    final idx = list.indexWhere((x) => x.invoiceNumber == invoice.invoiceNumber);
    if (idx >= 0) {
      list[idx] = invoice;
    } else {
      list.add(invoice);
    }

    _userInvoices[key] = list;
    _userInvoices.refresh();
  }

  void _removeInvoiceFromUserList(String invoiceNumber) {
    final key = _currentActorKey;
    if (key.isEmpty) return;

    final list = List<Sale>.from(_userInvoices[key] ?? const <Sale>[]);
    list.removeWhere((inv) => inv.invoiceNumber == invoiceNumber);

    _userInvoices[key] = list;
    _userInvoices.refresh();
    _savePendingInvoicesToLocal();
  }

  void _setCurrentSale(Sale sale) {
    currentSale.value = sale.recalculate();

    cashReceived.value = 0.0;
    changeAmount.value = 0.0;

    if (currentSale.value.insuranceCompanyId != null) {
      selectedInsuranceCompany.value = insuranceCompanies.firstWhereOrNull(
            (c) => c.id == currentSale.value.insuranceCompanyId,
      );
    } else {
      selectedInsuranceCompany.value = null;
    }

    customerNameController.text = currentSale.value.customerName ?? '';
    customerPhoneController.text = currentSale.value.customerPhone ?? '';
    notesController.text = currentSale.value.notes ?? '';
  }

  // =============================
  // Invoice CRUD / Switching
  // =============================
  void _createNewEmptyInvoice() {
    final inv = Sale.empty(
      pharmacyId: pharmacyId,
      employeeId: _currentDbEmployeeId,
      employeeName: currentSale.value.employeeName,
    );

    _addOrReplaceInvoice(inv);
    currentInvoiceIndex.value = activeInvoices.length - 1;
    _setCurrentSale(inv);
  }

  void _loadInvoice(int index) {
    final invoices = activeInvoices;
    if (index < 0 || index >= invoices.length) return;

    currentInvoiceIndex.value = index;
    _setCurrentSale(invoices[index]);
  }

  void _saveCurrentInvoice() {
    final sale = currentSale.value;
    if (sale.items.isEmpty) return;
    if (sale.status != InvoiceStatus.pending) return;

    _addOrReplaceInvoice(sale.recalculate());
  }

  void createNewInvoice() {
    final key = _currentActorKey;
    if (key.isEmpty) return;

    final current = currentSale.value;

    if (!current.isSaved && current.status == InvoiceStatus.pending) {
      _addOrReplaceInvoice(current.recalculate());
    } else {
      final list = List<Sale>.from(_userInvoices[key] ?? const <Sale>[]);
      list.removeWhere((inv) =>
      inv.invoiceNumber == current.invoiceNumber &&
          inv.status == InvoiceStatus.pending);
      _userInvoices[key] = list;
      _userInvoices.refresh();
    }

    final newInvoice = Sale.empty(
      pharmacyId: pharmacyId,
      employeeId: _currentDbEmployeeId,
      employeeName: current.employeeName,
    );

    _addOrReplaceInvoice(newInvoice);
    _setCurrentSale(newInvoice);

    _savePendingInvoicesToLocal();
  }

  void deleteCurrentInvoice() {
    final sale = currentSale.value;

    if (sale.isSaved || sale.status == InvoiceStatus.completed) {
      _safeSnackbar('غير مسموح', 'لا يمكن حذف فاتورة تم حفظها');
      return;
    }

    if (activeInvoices.length <= 1) {
      _safeSnackbar('غير مسموح', 'يجب أن تبقى فاتورة واحدة نشطة على الأقل');
      return;
    }

    final invoiceNumber = sale.invoiceNumber;
    _removeInvoiceFromUserList(invoiceNumber);

    if (activeInvoices.isEmpty) {
      _createNewEmptyInvoice();
    } else {
      _loadInvoice(0);
    }

    update();
  }

  void switchToNextInvoice() {
    final invoices = activeInvoices;
    if (invoices.isEmpty) {
      createNewInvoice();
      return;
    }

    _saveCurrentInvoice();

    final currentIndex = invoices.indexWhere(
            (inv) => inv.invoiceNumber == currentSale.value.invoiceNumber);
    final nextIndex = (currentIndex + 1) % invoices.length;
    _loadInvoice(nextIndex);
  }

  void switchToPreviousInvoice() {
    final invoices = activeInvoices;
    if (invoices.isEmpty) return;

    _saveCurrentInvoice();

    final currentIndex = invoices.indexWhere(
            (inv) => inv.invoiceNumber == currentSale.value.invoiceNumber);
    final prevIndex = (currentIndex - 1 + invoices.length) % invoices.length;
    _loadInvoice(prevIndex);
  }

  void loadInvoiceForEditing(Sale invoice) {
    _setCurrentSale(invoice);

    if (invoice.status == InvoiceStatus.completed) {
      Get.snackbar('فاتورة مكتملة', 'هذه فاتورة مكتملة - للعرض فقط',
          duration: const Duration(seconds: 2));
    }
  }

  void switchToInvoice(Sale invoice) {
    final idx = activeInvoices
        .indexWhere((i) => i.invoiceNumber == invoice.invoiceNumber);
    if (idx >= 0) {
      _loadInvoice(idx);
      return;
    }
    loadInvoiceForEditing(invoice);
  }

  // =============================
  // Helpers: piece stock check
  // =============================
  bool _canSellPieces(Medicine med, int qty) {
    final units = med.unitsPerPackage ?? 0;
    if (units <= 0) return false;
    final pieces = (med.pieceQuantity ?? 0) + (med.quantity * units);
    return pieces >= qty;
  }

  // =============================
  // Add / Update / Remove items
  // =============================
  void addMedicineToSale(
      Medicine medicine, {
        int quantity = 1,
        bool sellAsPiece = false,
      }) {
    final sale = currentSale.value;

    if (sale.isSaved || sale.status == InvoiceStatus.completed) {
      _safeSnackbar('غير مسموح', 'لا يمكن إضافة منتجات إلى فاتورة محفوظة');
      return;
    }

    if (sellAsPiece) {
      if (!_canSellPieces(medicine, quantity)) {
        _safeSnackbar('مخزون غير كافي', 'لا توجد قطع كافية للبيع بالقطعة');
        return;
      }
    } else {
      if (medicine.quantity < quantity) {
        _safeSnackbar('مخزون غير كافي', 'المخزون المتوفر: ${medicine.quantity} فقط');
        return;
      }
    }

    final existingIndex = sale.items.indexWhere(
          (item) => item.medicineId == medicine.id && item.sellAsPiece == sellAsPiece,
    );

    final unitPrice = sellAsPiece && medicine.piecePrice != null
        ? medicine.piecePrice!
        : (medicine.sellingPrice ?? 0.0);

    Sale updatedSale;

    if (existingIndex >= 0) {
      final currentItem = sale.items[existingIndex];
      final newItem = currentItem.copyWith(quantity: currentItem.quantity + quantity);
      updatedSale = sale.updateItem(existingIndex, newItem);
    } else {
      final item = SaleItem(
        medicineId: medicine.id,
        name: medicine.name,
        scientificName: medicine.scientificName,
        barcode: medicine.barcode,
        unitPrice: unitPrice,
        quantity: quantity,
        sellAsPiece: sellAsPiece,
      );
      updatedSale = sale.addItem(item);
    }

    currentSale.value = updatedSale.recalculate();
    _saveCurrentInvoice();
    _clearSearchAfterAdd();
  }

  void updateQuantity(int index, int newQuantity) {
    final sale = currentSale.value;

    if (sale.isSaved || sale.status == InvoiceStatus.completed) {
      _safeSnackbar('غير مسموح', 'لا يمكن تعديل فاتورة محفوظة');
      return;
    }

    if (index < 0 || index >= sale.items.length) return;

    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final item = sale.items[index];

    final inventory = Get.find<InventoryController>();
    final med = inventory.getMedicineById(item.medicineId);

    if (med != null) {
      if (item.sellAsPiece) {
        if (!_canSellPieces(med, newQuantity)) {
          _safeSnackbar('مخزون غير كافي', 'لا توجد قطع كافية للبيع بالقطعة');
          return;
        }
      } else {
        if (med.quantity < newQuantity) {
          _safeSnackbar('مخزون غير كافي', 'المخزون المتوفر: ${med.quantity} فقط');
          return;
        }
      }
    }

    final updatedItem = item.copyWith(quantity: newQuantity);
    currentSale.value = sale.updateItem(index, updatedItem).recalculate();
    _saveCurrentInvoice();
  }

  void removeItem(int index) {
    final sale = currentSale.value;

    if (sale.isSaved || sale.status == InvoiceStatus.completed) {
      _safeSnackbar('غير مسموح', 'لا يمكن حذف منتج من فاتورة محفوظة');
      return;
    }

    currentSale.value = sale.removeItemAt(index).recalculate();
    _saveCurrentInvoice();
  }

  // =============================
  // Discount / Insurance / Payment
  // =============================
  void applyDiscount(double discountAmount) {
    final sale = currentSale.value;
    if (sale.isSaved || sale.status == InvoiceStatus.completed) return;

    currentSale.value = sale.copyWith(discount: discountAmount).recalculate();
    _saveCurrentInvoice();
  }

  /// ✅ التأمين = جزء على الشركة (insuranceDiscount)
  /// ✅ paymentMethod يبقى للزبون فقط (cash/card)
  void selectInsuranceCompany(InsuranceCompany? company) {
    final sale = currentSale.value;
    if (sale.isSaved || sale.status == InvoiceStatus.completed) return;

    final keepMethod = _customerMethod(sale);

    if (company == null) {
      selectedInsuranceCompany.value = null;
      currentSale.value = sale
          .copyWith(
        insuranceCompanyId: null,
        insuranceCompanyName: null,
        insuranceDiscount: null,
        paymentMethod: keepMethod,
      )
          .recalculate();
      _saveCurrentInvoice();
      return;
    }

    selectedInsuranceCompany.value = company;

    final recalculated = sale.recalculate();
    final itemsSubtotal = recalculated.subtotal;

    final invoiceDiscount =
    (recalculated.discount ?? 0.0).clamp(0.0, itemsSubtotal);
    final afterInvoiceDiscount =
    (itemsSubtotal - invoiceDiscount).clamp(0.0, double.infinity);

    final companyPortion = (afterInvoiceDiscount * company.discountPercentage / 100)
        .clamp(0.0, afterInvoiceDiscount);

    currentSale.value = sale
        .copyWith(
      insuranceCompanyId: company.id,
      insuranceCompanyName: company.name,
      insuranceDiscount: companyPortion,
      paymentMethod: keepMethod,
    )
        .recalculate();

    _saveCurrentInvoice();
  }

  /// ✅ منع insurance كطريقة دفع (Legacy فقط)
  void changePaymentMethod(PaymentMethod method) {
    final sale = currentSale.value;
    if (sale.isSaved || sale.status == InvoiceStatus.completed) return;

    if (method == PaymentMethod.insurance) {
      _safeSnackbar('غير مسموح',
          'التأمين مش طريقة دفع — اختار كاش أو بطاقة، والتأمين يتحسب كجزء على الشركة.');
      return;
    }

    currentSale.value = sale.copyWith(paymentMethod: method).recalculate();
    _saveCurrentInvoice();
  }

  void setCashReceived(double amount) {
    cashReceived.value = amount;
    final diff = amount - customerPayable;
    changeAmount.value = diff < 0 ? 0.0 : diff;
  }
  // =============================
  // Save sale to Firebase + Register on Shift (Split)
  // =============================
  Future<Sale?> completeSaleAndPrint() async {
    final shiftCtrl = Get.find<ShiftController>();
    final auth = Get.find<AuthController>();

    shiftCtrl.ensureActiveShiftOrThrow();
    final shiftId = shiftCtrl.activeShift.value!.id;

    final sale = currentSale.value;
    if (sale.items.isEmpty) throw Exception('السلة فارغة');
    if (sale.isSaved) throw Exception('هذه الفاتورة محفوظة مسبقاً');

    // ✅ تصحيح فواتير قديمة كانت insurance method
    if (sale.paymentMethod == PaymentMethod.insurance) {
      currentSale.value = sale.copyWith(paymentMethod: PaymentMethod.cash).recalculate();
    }

    final saved = await saveSale(
      shiftId: shiftId,
      performedBy: auth.actorInfo,
    );

    if (saved == null) throw Exception('فشل حفظ الفاتورة');

    // ✅ split: customer + company
    final customerPaid = _customerPaid(saved);
    final customerMethod = _customerMethod(saved);
    final companyBilled = _companyBilled(saved);

    if (customerPaid > 0) {
      await shiftCtrl.registerSaleOnShift(
        total: customerPaid,
        method: customerMethod,
        isRefund: false,
      );
    }

    if (companyBilled > 0) {
      await shiftCtrl.registerSaleOnShift(
        total: companyBilled,
        method: PaymentMethod.insurance,
        isRefund: false,
      );
    }

    return saved;
  }

  Future<bool> saveSaleSimple() async {
    final saved = await saveSale();
    return saved != null;
  }

  Future<Sale?> saveSale({
    String? shiftId,
    Map<String, dynamic>? performedBy,
  }) async {
    final sale = currentSale.value;
    if (sale.items.isEmpty) return null;

    _ensureCan('sales.create', 'ليس لديك صلاحية إنشاء مبيعات');

    if (sale.isSaved || sale.status == InvoiceStatus.completed) {
      _safeSnackbar('غير مسموح', 'هذه الفاتورة محفوظة مسبقاً');
      return null;
    }

    try {
      isLoading.value = true;

      final shiftCtrl = Get.find<ShiftController>();
      shiftCtrl.ensureActiveShiftOrThrow();
      final activeShiftId = shiftCtrl.activeShift.value!.id;

      final auth = Get.find<AuthController>();
      final actor = auth.actorInfo;

      // ✅ draft-first
      final recalculated = sale.recalculate();

      final now = DateTime.now();
      final customerName = customerNameController.text.trim();
      final customerPhone = customerPhoneController.text.trim();
      final notes = notesController.text.trim();

      // ✅ ضمان paymentMethod للزبون فقط
      final normalizedMethod = _customerMethod(recalculated);

      final completedSale = recalculated
          .copyWith(
        customerName: customerName.isEmpty ? null : customerName,
        customerPhone: customerPhone.isEmpty ? null : customerPhone,
        notes: notes.isEmpty ? null : notes,
        saleDate: now,
        status: InvoiceStatus.completed,
        completedAt: now,
        isSaved: true,
        isDeleted: false,
        paymentMethod: normalizedMethod,
        shiftId: activeShiftId,
        performedBy: actor,
        performedById: (actor['id'] ?? '').toString(),
        performedByName: (actor['name'] ?? actor['username'] ?? '').toString(),
      )
          .recalculate();

      final doc = salesCollection.doc();
      final draftId = doc.id;

      await doc.set({
        'invoiceNumber': recalculated.invoiceNumber,
        'pharmacyId': pharmacyId,
        'employeeId': recalculated.employeeId,
        'employeeName': recalculated.employeeName,
        'status': 'pending',
        'isSaved': false,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'saleDate': FieldValue.serverTimestamp(),
        'draft': true,
      }, SetOptions(merge: true));

      await _updateInventoryStockForSale(recalculated);

      final saved = completedSale.copyWith(id: draftId);
      final payload = saved.toMap();

      payload['createdAt'] ??= FieldValue.serverTimestamp();
      payload['shiftId'] ??= activeShiftId;
      payload['performedBy'] ??= actor;
      payload['performedById'] ??= (actor['id'] ?? '').toString();
      payload['performedByName'] ??= (actor['name'] ?? actor['username'] ?? '').toString();
      payload['draft'] = false;

      if (shiftId != null && shiftId.trim().isNotEmpty) {
        payload['shiftId'] = shiftId.trim();
      }
      if (performedBy != null && performedBy.isNotEmpty) {
        payload['performedBy'] = performedBy;
        payload['performedById'] ??= (performedBy['id'] ?? '').toString();
        payload['performedByName'] ??=
            (performedBy['name'] ?? performedBy['username'] ?? '').toString();
      }

      await doc.set(payload, SetOptions(merge: true));

      _addOrReplaceInvoice(saved);
      currentSale.value = saved;

      await _logCreateSale(saved);
      await _removePendingInvoiceByNumber('ignored', saved.invoiceNumber);
      await _savePendingInvoicesToLocal();

      createNewInvoice();
      return saved;
    } catch (e, st) {
      debugPrint('❌ saveSale error: $e');
      debugPrint('$st');
      _safeSnackbar('خطأ', 'فشل في حفظ الفاتورة: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateInventoryStockForSale(Sale sale) async {
    final inventoryController = Get.find<InventoryController>();

    for (final item in sale.items) {
      final medicine = inventoryController.getMedicineById(item.medicineId);
      if (medicine == null) continue;

      final int currentPackageQty = medicine.quantity;
      final int currentPieceQty = medicine.pieceQuantity ?? 0;
      final int unitsPerPackage = medicine.unitsPerPackage ?? 0;

      int newPackageQty = currentPackageQty;
      int newPieceQty = currentPieceQty;

      if (item.sellAsPiece) {
        if (unitsPerPackage <= 0) {
          throw Exception(
              'لا يمكن البيع بالقطعة لأن unitsPerPackage غير محدد للدواء ${medicine.name}');
        }

        final int totalPieces =
            currentPieceQty + (currentPackageQty * unitsPerPackage);
        final int newTotalPieces = totalPieces - item.quantity;

        if (newTotalPieces < 0) {
          throw Exception('مخزون غير كافي للدواء ${medicine.name}');
        }

        newPackageQty = newTotalPieces ~/ unitsPerPackage;
        newPieceQty = newTotalPieces % unitsPerPackage;
      } else {
        newPackageQty = currentPackageQty - item.quantity;

        if (newPackageQty < 0) {
          throw Exception('مخزون غير كافي للدواء ${medicine.name}');
        }
        newPieceQty = currentPieceQty;
      }

      await inventoryController.updateStock(
        id: medicine.id,
        newPackageQty: newPackageQty,
        newPieceQty: newPieceQty,
      );
    }
  }

  Future<void> _removePendingInvoiceByNumber(
      String userIdIgnored, String invoiceNumber) async {
    final key = _currentActorKey;
    if (key.isEmpty) return;

    final list = List<Sale>.from(_userInvoices[key] ?? const <Sale>[]);

    list.removeWhere((inv) =>
    inv.invoiceNumber == invoiceNumber &&
        inv.status == InvoiceStatus.pending);

    _userInvoices[key] = list;
    _userInvoices.refresh();

    await _savePendingInvoicesToLocal();
  }


  // =============================
  // Reports
  // =============================
  Future<List<Sale>> getSalesReport(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await salesCollection
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('saleDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Sale.fromMap({'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .copyWith(id: doc.id)
          .recalculate())
          .toList();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب التقرير: $e');
      return [];
    }
  }

  Future<Sale?> getSaleByInvoiceNumber(String invoiceNumber) async {
    try {
      final querySnapshot =
      await salesCollection.where('invoiceNumber', isEqualTo: invoiceNumber).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Sale.fromMap({'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .copyWith(id: doc.id)
            .recalculate();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteSale(String saleId) async {
    try {
      _ensureCan('sales.delete', 'ليس لديك صلاحية حذف المبيعات');

      final doc = await salesCollection.doc(saleId).get();
      if (!doc.exists) {
        Get.snackbar('تنبيه', 'الفاتورة غير موجودة');
        return false;
      }

      final sale = Sale.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).copyWith(id: doc.id).recalculate();

      await salesCollection.doc(saleId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _actor,
      });

      await _logDeleteSale(
        saleId: saleId,
        sale: sale,
      );

      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف الفاتورة');
      return false;
    }
  }

  // =============================
  // History helpers (My)
  // =============================
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _startOfNextDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<List<Sale>> fetchMySalesForDay(DateTime day) async {
    final dbId = _currentDbEmployeeId;
    if (dbId.isEmpty) return [];

    final start = _startOfDay(day);
    final end = _startOfNextDay(day);

    final qs = await salesCollection
        .where('employeeId', isEqualTo: dbId)
        .where('isDeleted', isEqualTo: false)
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('saleDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('saleDate', descending: true)
        .get();

    return qs.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Sale.fromMap({'id': doc.id, ...data}).copyWith(id: doc.id).recalculate();
    }).toList();
  }

  Future<void> loadMyHistoryToday({bool includeLocalPending = true}) async {
    final key = _currentActorKey;
    if (key.isEmpty) return;

    try {
      isLoading.value = true;

      final todayFromFirebase = await fetchMySalesForDay(DateTime.now());

      final merged = <Sale>[];
      merged.addAll(todayFromFirebase);

      if (includeLocalPending) {
        await _loadPendingInvoicesFromLocal(key);
        merged.addAll(activeInvoices);
      }

      final byNumber = <String, Sale>{};
      for (final s in merged) {
        byNumber[s.invoiceNumber] = s;
      }

      final list = byNumber.values.toList();
      list.sort((a, b) {
        if (a.status == InvoiceStatus.pending &&
            b.status != InvoiceStatus.pending) return -1;
        if (a.status != InvoiceStatus.pending &&
            b.status == InvoiceStatus.pending) return 1;
        return b.saleDate.compareTo(a.saleDate);
      });

      _userInvoices[_kMyHistory] = list;
      _userInvoices.refresh();
      update();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyHistoryAll() async {
    final dbId = _currentDbEmployeeId;
    final key = _currentActorKey;
    if (dbId.isEmpty || key.isEmpty) return;

    try {
      isLoading.value = true;

      final qs = await salesCollection
          .where('employeeId', isEqualTo: dbId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('saleDate', descending: true)
          .get();

      final list = qs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Sale.fromMap({'id': doc.id, ...data}).copyWith(id: doc.id).recalculate();
      }).toList();

      await _loadPendingInvoicesFromLocal(key);
      list.addAll(activeInvoices);

      final byNumber = <String, Sale>{};
      for (final s in list) {
        byNumber[s.invoiceNumber] = s;
      }

      final merged = byNumber.values.toList();
      merged.sort((a, b) {
        if (a.status == InvoiceStatus.pending &&
            b.status != InvoiceStatus.pending) return -1;
        if (a.status != InvoiceStatus.pending &&
            b.status == InvoiceStatus.pending) return 1;
        return b.saleDate.compareTo(a.saleDate);
      });

      _userInvoices[_kMyHistory] = merged;
      _userInvoices.refresh();
      update();
    } finally {
      isLoading.value = false;
    }
  }

  // =============================
  // Stats
  // =============================
  Map<String, dynamic> getInvoiceStats() {
    final pendingCount = activeInvoices.length;
    final completedCount = completedInvoices.length;
    final totalCount = allInvoices.length;

    final pendingItems =
    activeInvoices.fold<int>(0, (sum, inv) => sum + inv.items.length);
    final completedAmount = completedInvoices.fold<double>(
        0.0, (sum, inv) => sum + _customerPaid(inv));

    return {
      'totalInvoices': totalCount,
      'pendingInvoices': pendingCount,
      'completedInvoices': completedCount,
      'pendingItems': pendingItems,
      'completedAmountCustomer': completedAmount,
    };
  }

  Future<Map<String, dynamic>> getTodaySalesStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final sales = await getSalesReport(startOfDay, endOfDay);

      final completed = sales.where((s) =>
      s.status == InvoiceStatus.completed &&
          s.isDeleted == false &&
          s.isSaved == true).toList();

      final totalSales = completed.length;

      final totalCustomer =
      completed.fold<double>(0.0, (sum, s) => sum + _customerPaid(s));
      final totalInsuranceBilled =
      completed.fold<double>(0.0, (sum, s) => sum + _companyBilled(s));
      final grandTotal = totalCustomer + totalInsuranceBilled;

      final cashSales =
          completed.where((s) => _customerMethod(s) == PaymentMethod.cash).length;
      final cardSales =
          completed.where((s) => _customerMethod(s) == PaymentMethod.card).length;
      final insuranceSales = completed.where((s) => _companyBilled(s) > 0).length;

      return {
        'totalSales': totalSales,
        'totalCustomer': totalCustomer,
        'totalInsuranceBilled': totalInsuranceBilled,
        'grandTotal': grandTotal,
        'cashSales': cashSales,
        'cardSales': cardSales,
        'insuranceSales': insuranceSales,
        'averageSale': totalSales > 0 ? (grandTotal / totalSales) : 0.0,
      };
    } catch (_) {
      return {
        'totalSales': 0,
        'totalCustomer': 0.0,
        'totalInsuranceBilled': 0.0,
        'grandTotal': 0.0,
        'cashSales': 0,
        'cardSales': 0,
        'insuranceSales': 0,
        'averageSale': 0.0,
      };
    }
  }

  // =============================
  // Day closing
  // =============================
  Future<bool> isDayClosedForMe(DateTime day) async {
    final dbId = _currentDbEmployeeId;
    if (dbId.isEmpty) return false;

    final start = _startOfDay(day);
    final key =
        '${dbId}_${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}';

    final doc = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('dailyClosings')
        .doc(key)
        .get();

    return doc.exists;
  }

  Future<Map<String, dynamic>> closeMyDay() async {
    final dbId = _currentDbEmployeeId;
    if (dbId.isEmpty) throw Exception('employeeId فارغ');

    final now = DateTime.now();
    final start = _startOfDay(now);
    final key =
        '${dbId}_${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}';

    final alreadyClosed = await isDayClosedForMe(now);
    if (alreadyClosed) throw Exception('تم إقفال هذا اليوم مسبقاً');

    final todaySales = await fetchMySalesForDay(now);
    final completed = todaySales
        .where((s) =>
    s.status == InvoiceStatus.completed &&
        s.isDeleted == false &&
        s.isSaved == true)
        .toList();

    double cashTotal = 0, cardTotal = 0, insTotal = 0;

    for (final s in completed) {
      final customerPaid = _customerPaid(s);
      final companyBilled = _companyBilled(s);
      final method = _customerMethod(s);

      if (method == PaymentMethod.cash) {
        cashTotal += customerPaid;
      } else if (method == PaymentMethod.card) {
        cardTotal += customerPaid;
      }

      insTotal += companyBilled;
    }

    final grandTotal = cashTotal + cardTotal + insTotal;

    final payload = {
      'pharmacyId': pharmacyId,
      'employeeId': dbId,
      'employeeName': currentSale.value.employeeName,
      'date': Timestamp.fromDate(start),
      'createdAt': FieldValue.serverTimestamp(),
      'completedCount': completed.length,
      'cashTotal': cashTotal,
      'cardTotal': cardTotal,
      'insuranceTotal': insTotal,
      'grandTotal': grandTotal,
      'invoiceNumbers': completed.map((e) => e.invoiceNumber).toList(),
    };

    await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('dailyClosings')
        .doc(key)
        .set(payload, SetOptions(merge: true));

    return payload;
  }

  // =============================
  // Search
  // =============================
  bool isBarcodeInput(String text) => RegExp(r'^[0-9]{8,}$').hasMatch(text);

  Future<void> handleSmartSearch(String query) async {
    final results = await searchMedicinesWithSuggestions(query);

    if (isBarcodeInput(query) && results.length == 1) {
      final med = results.first;

      if (refundMode.value) {
        await addMedicineToRefund(med);
      } else {
        addMedicineToSale(med);
      }

      _clearSearchAfterAdd();
    }
  }

  Future<void> searchMedicines(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();

      // ✅ مصدر البيانات حسب الوضع
      final List<Medicine> baseList =
      (refundMode.value && originalSale.value != null)
          ? _getOriginalInvoiceMedicinesOnly()
          : inventoryController.medicines;

      final q = query.toLowerCase();

      final results = baseList.where((medicine) {
        final nameMatch = medicine.name.toLowerCase().contains(q);
        final sciMatch = medicine.scientificName.toLowerCase().contains(q);
        final barcodeMatch = (medicine.barcode ?? '').toLowerCase().contains(q);
        return nameMatch || sciMatch || barcodeMatch;
      }).toList();

      searchResults.assignAll(results);
    } finally {
      isLoading.value = false;
    }
  }
  List<Medicine> _getOriginalInvoiceMedicinesOnly() {
    final orig = originalSale.value;
    if (orig == null) return [];

    final inv = Get.find<InventoryController>();
    final ids = orig.items.map((e) => e.medicineId).toSet();

    final meds = <Medicine>[];
    for (final id in ids) {
      final m = inv.getMedicineById(id);
      if (m != null) meds.add(m);
    }
    return meds;
  }

  Future<List<Medicine>> searchMedicinesWithSuggestions(String query) async {
    if (query.isEmpty) {
      // ✅ في الترجيع نخلي النتائج تفضى عادي (نقدر لاحقًا نعرض أصناف الفاتورة تلقائي)
      searchResults.clear();
      return [];
    }

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();

      // ✅ مصدر البيانات: كل المخزون أو فقط أصناف الفاتورة الأصلية
      final List<Medicine> baseList =
      (refundMode.value && originalSale.value != null)
          ? _getOriginalInvoiceMedicinesOnly()
          : inventoryController.medicines;

      final q = query.toLowerCase();

      final results = baseList.where((medicine) {
        final name = medicine.name.toLowerCase();
        final sci = medicine.scientificName.toLowerCase();
        final barcode = (medicine.barcode ?? '').toLowerCase();

        final nameMatch = name.contains(q);
        final sciMatch = sci.contains(q);
        final barcodeMatch = barcode.contains(q);
        final nameStarts = name.startsWith(q);
        final sciStarts = sci.startsWith(q);

        return nameMatch || sciMatch || barcodeMatch || nameStarts || sciStarts;
      }).toList();

      results.sort((a, b) {
        final aStarts = a.name.toLowerCase().startsWith(q) ||
            a.scientificName.toLowerCase().startsWith(q);
        final bStarts = b.name.toLowerCase().startsWith(q) ||
            b.scientificName.toLowerCase().startsWith(q);

        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.name.compareTo(b.name);
      });

      searchResults.assignAll(results);
      return results;
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> searchByBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();
      final medicine = inventoryController.searchByBarcode(barcode);

      if (medicine != null) {
        searchResults.assignAll([medicine]);

        if (refundMode.value) {
          await addMedicineToRefund(medicine);
        } else {
          addMedicineToSale(medicine);
        }

        _clearSearchAfterAdd();
      } else {
        Get.snackbar('غير موجود', 'لم يتم العثور على منتج بهذا الباركود');
        searchResults.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> search(String query) async {
    searchQuery.value = query;

    if (query.isEmpty) {
      searchResults.clear();

      // ✅ اختيارية: في وضع الترجيع نعرض أصناف الفاتورة بدون كتابة
      if (refundMode.value && originalSale.value != null) {
        searchResults.assignAll(_getOriginalInvoiceMedicinesOnly());
      }
      return;
    }

    if (isBarcodeInput(query)) {
      await handleSmartSearch(query);
    } else {
      await searchMedicinesWithSuggestions(query); // ✅ بدل searchMedicines
    }
  }
  // =============================
  // Reset sale
  // =============================
  void resetSale() {
    final sale = currentSale.value;

    final reset = Sale.empty(
      pharmacyId: pharmacyId,
      employeeId: sale.employeeId,
      employeeName: sale.employeeName,
    );

    currentSale.value = reset.recalculate();

    customerNameController.clear();
    customerPhoneController.clear();
    notesController.clear();

    cashReceived.value = 0.0;
    changeAmount.value = 0.0;

    selectedInsuranceCompany.value = null;
    searchResults.clear();
    searchQuery.value = '';

    _focusSearchField();
  }

  void _focusSearchField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!allowAutoFocusSearch.value) return; // ✅ أهم سطر

      if (!searchFocusNode.hasFocus) {
        searchFocusNode.requestFocus();
      }
    });
  }

  void toggleBarcodeScanner() {
    isScanning.value = !isScanning.value;
  }

  // =============================
  // UI helper
  // =============================
  void _safeSnackbar(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rawSnackbar(
        title: title,
        message: message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    });
  }

  void _clearSearchAfterAdd() {
    searchQuery.value = '';
    searchResults.clear();
    _focusSearchField();
  }

  Future<void> toggleRefundMode() async {
    refundMode.value = !refundMode.value;

    if (!refundMode.value) {
      originalSale.value = null;
      refundInvoiceController.clear();
      refundCashOut.value = 0;
      refundCardOut.value = 0;
      manualDiscount.value = 0;
      selectedInsuranceCompany.value = null;
      resetSale(); // يرجع لوضع البيع
      return;
    }

    // ✅ دخول الترجيع
    await loadRecentCompletedInvoices(limit: 80);

    final s = Sale.empty(
      pharmacyId: pharmacyId,
      employeeId: _currentDbEmployeeId,
      employeeName: currentSale.value.employeeName,
    ).copyWith(
      invoiceNumber: 'REF-${Sale.generateInvoiceNumber().replaceFirst('INV-', '')}',
      type: SaleType.refund,
      discount: 0,
      insuranceDiscount: 0,
      insuranceCompanyId: null,
      insuranceCompanyName: null,
      paymentMethod: PaymentMethod.cash,
    ).recalculate();

    currentSale.value = s;
    searchResults.clear();
    searchQuery.value = '';
    _saveCurrentInvoice();
  }

  Future<void> loadOriginalInvoiceForRefund() async {
    final invNo = refundInvoiceController.text.trim();
    if (invNo.isEmpty) {
      _safeSnackbar('تنبيه', 'أدخل رقم الفاتورة الأصلية');
      return;
    }

    final sale = await getSaleByInvoiceNumber(invNo);
    if (sale == null || sale.isDeleted || sale.status != InvoiceStatus.completed) {
      _safeSnackbar('غير موجود', 'لم يتم العثور على فاتورة مكتملة بهذا الرقم');
      return;
    }

    // ما نسمحش بترجيع فاتورة ترجيع
    if (sale.type == SaleType.refund) {
      _safeSnackbar('غير مسموح', 'لا يمكن تحميل فاتورة ترجيع كأصل');
      return;
    }
    // ✅ اعرض أصناف الفاتورة مباشرة في نتائج البحث
    searchResults.assignAll(_getOriginalInvoiceMedicinesOnly());
    searchQuery.value = '';

    originalSale.value = sale;
    _safeSnackbar('تم', 'تم تحميل الفاتورة الأصلية ✅');
  }

  Future<Map<String, int>> _getAlreadyRefundedQtyByMedicine(String refSaleId) async {
    final qs = await salesCollection
        .where('type', isEqualTo: 'refund')
        .where('refSaleId', isEqualTo: refSaleId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final Map<String, int> refunded = {};
    for (final d in qs.docs) {
      final data = d.data() as Map<String, dynamic>;
      final r = Sale.fromMap({'id': d.id, ...data});
      for (final it in r.items) {
        refunded[it.medicineId] = (refunded[it.medicineId] ?? 0) + it.quantity;
      }
    }
    return refunded;
  }
  Future<void> addMedicineToRefund(Medicine medicine, {int quantity = 1, bool sellAsPiece = false}) async {
    final orig = originalSale.value;
    if (orig == null) {
      _safeSnackbar('مطلوب', 'حمّلي الفاتورة الأصلية أولاً');
      return;
    }

    // لازم الدواء موجود في الفاتورة الأصلية (نفس sellAsPiece)
    final soldItem = orig.items.firstWhereOrNull(
          (it) => it.medicineId == medicine.id && it.sellAsPiece == sellAsPiece,
    );

    if (soldItem == null) {
      _safeSnackbar('غير مسموح', 'هذا الصنف غير موجود في الفاتورة الأصلية');
      return;
    }

    // نحسب المتاح
    final refundedMap = await _getAlreadyRefundedQtyByMedicine(orig.id);
    final already = refundedMap[medicine.id] ?? 0;
    final available = soldItem.quantity - already;

    if (available <= 0) {
      _safeSnackbar('غير مسموح', 'تم ترجيع هذا الصنف بالكامل مسبقاً');
      return;
    }

    if (quantity > available) {
      _safeSnackbar('تنبيه', 'المتاح للترجيع: $available فقط');
      return;
    }

    // نضيف للسلة بسعر نفس الأصل (مهم)
    final unitPrice = soldItem.unitPrice;

    final sale = currentSale.value;
    final existingIndex = sale.items.indexWhere(
          (it) => it.medicineId == medicine.id && it.sellAsPiece == sellAsPiece,
    );

    Sale updated;
    if (existingIndex >= 0) {
      final cur = sale.items[existingIndex];
      updated = sale.updateItem(existingIndex, cur.copyWith(quantity: cur.quantity + quantity));
    } else {
      updated = sale.addItem(SaleItem(
        medicineId: medicine.id,
        name: medicine.name,
        scientificName: medicine.scientificName,
        barcode: medicine.barcode,
        unitPrice: unitPrice,
        quantity: quantity,
        sellAsPiece: sellAsPiece,
      ));
    }

    currentSale.value = updated.recalculate();
    _saveCurrentInvoice();
    _clearSearchAfterAdd();
  }
  double get refundTotal => currentSale.value.recalculate().subtotal;
  Future<Sale?> completeRefundAndPrint() async {
    final shiftCtrl = Get.find<ShiftController>();
    final auth = Get.find<AuthController>();

    shiftCtrl.ensureActiveShiftOrThrow();
    final shiftId = shiftCtrl.activeShift.value!.id;

    final orig = originalSale.value;
    _ensureCan('sales.refund', 'ليس لديك صلاحية إرجاع المبيعات');
    if (orig == null) throw Exception('حمّلي الفاتورة الأصلية أولاً');

    final r = currentSale.value;
    if (r.items.isEmpty) throw Exception('سلة الترجيع فارغة');

    final total = r.recalculate().subtotal;
    final out = (refundCashOut.value + refundCardOut.value);

    if ((out - total).abs() > 0.01) {
      throw Exception('لازم cashOut + cardOut يساوي قيمة الترجيع');
    }

    final now = DateTime.now();
    final actor = auth.actorInfo;

    final payloadSale = r.copyWith(
      type: SaleType.refund,
      refSaleId: orig.id,
      refInvoiceNumber: orig.invoiceNumber,
      shiftId: shiftId,
      performedBy: actor,
      performedById: (actor['id'] ?? '').toString(),
      performedByName: (actor['name'] ?? actor['username'] ?? '').toString(),
      status: InvoiceStatus.completed,
      isSaved: true,
      isDeleted: false,
      saleDate: now,
      completedAt: now,
      // money out:
      cashOut: refundCashOut.value,
      cardOut: refundCardOut.value,
      // نظف التأمين والخصم:
      insuranceDiscount: 0,
      insuranceCompanyId: null,
      insuranceCompanyName: null,
      discount: 0,
      // paymentMethod هنا ممكن نخليه cash لو cashOut>0 وإلا card (اختياري)
      paymentMethod: refundCardOut.value > 0 ? PaymentMethod.card : PaymentMethod.cash,
      total: 0, // لا تعامليها كزبون يدفع
      subtotal: total,
    ).recalculate();

    final doc = salesCollection.doc();
    await doc.set(payloadSale.copyWith(id: doc.id).toMap(), SetOptions(merge: true));

    // ✅ رجّع المخزون
    await _restoreInventoryStockForRefund(payloadSale);

    // ✅ سجّل على الشفت: هذا “نقص” في الكاش/البطاقة
    if (refundCashOut.value > 0) {
      await shiftCtrl.registerSaleOnShift(
        total: refundCashOut.value,
        method: PaymentMethod.cash,
        isRefund: true,
      );
    }
    if (refundCardOut.value > 0) {
      await shiftCtrl.registerSaleOnShift(
        total: refundCardOut.value,
        method: PaymentMethod.card,
        isRefund: true,
      );
    }

    // (اختياري) audit log
    await _logRefundSale(
      saleId: doc.id,
      refundSale: payloadSale,
      originalSale: orig,
      shiftId: shiftId,
    );

    // Reset UI
    toggleRefundMode(); // يطلع من الوضع
    return payloadSale.copyWith(id: doc.id);
  }
  Future<void> _restoreInventoryStockForRefund(Sale refund) async {
    final inventoryController = Get.find<InventoryController>();

    for (final item in refund.items) {
      final medicine = inventoryController.getMedicineById(item.medicineId);
      if (medicine == null) continue;

      int pkg = medicine.quantity;
      int pcs = medicine.pieceQuantity ?? 0;
      final units = medicine.unitsPerPackage ?? 0;

      if (item.sellAsPiece) {
        if (units <= 0) throw Exception('unitsPerPackage غير محدد للدواء ${medicine.name}');
        final totalPieces = pcs + (pkg * units);
        final newTotal = totalPieces + item.quantity;

        pkg = newTotal ~/ units;
        pcs = newTotal % units;
      } else {
        pkg = pkg + item.quantity;
      }

      await inventoryController.updateStock(
        id: medicine.id,
        newPackageQty: pkg,
        newPieceQty: pcs,
      );
    }
  }
  final RxList<String> completedInvoiceSuggestions = <String>[].obs;

  Future<void> loadRecentCompletedInvoices({int limit = 50}) async {
    final qs = await salesCollection
        .where('isDeleted', isEqualTo: false)
        .where('status', isEqualTo: 'completed')
        .orderBy('saleDate', descending: true)
        .limit(limit)
        .get();

    completedInvoiceSuggestions.assignAll(
      qs.docs.map((d) => (d.data() as Map<String, dynamic>)['invoiceNumber'].toString()).toList(),
    );
  }

  // =============================
  // Optional UI widget
  // =============================
  Widget buildInsuranceDropdown() {
    return Obx(() {
      if (insuranceCompanies.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            isLoading.value ? 'جاري التحميل...' : 'لا توجد شركات تأمين',
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }

      return DropdownButtonFormField<InsuranceCompany>(
        value: selectedInsuranceCompany.value,
        items: insuranceCompanies.map((company) {
          return DropdownMenuItem<InsuranceCompany>(
            value: company,
            child: Text('${company.name} (تغطية ${company.discountPercentage}%)'),
          );
        }).toList(),
        onChanged: (company) => selectInsuranceCompany(company),
        decoration: InputDecoration(
          labelText: 'شركة التأمين (جزء على الشركة)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}
