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

class SalesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FocusNode searchFocusNode = FocusNode();

  // المفتاح لحفظ الفواتير المؤقتة محلياً
  static const String _pendingInvoicesKey = 'pending_invoices_';

  // ✅ مفاتيح ثابتة للهيستوري (حل مشكلة اليوم/الكل/المدة عند المالك)
  static const String _kPharmacyHistory = '__pharmacy__';
  static const String _kMyHistory = '__my_history__';

  // قائمة الفواتير حسب المفتاح (pending + completed)
  final RxMap<String, List<Sale>> _userInvoices = <String, List<Sale>>{}.obs;

  // مؤشر تنقل الفاتورة
  final RxInt currentInvoiceIndex = 0.obs;

  // الفاتورة الحالية
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

  // باقي المتغيرات
  final RxList<Medicine> searchResults = <Medicine>[].obs;
  final RxList<InsuranceCompany> insuranceCompanies = <InsuranceCompany>[].obs;
  final Rx<InsuranceCompany?> selectedInsuranceCompany = Rx<InsuranceCompany?>(null);

  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  // optional
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

  CollectionReference get salesCollection {
    final id = pharmacyId;
    if (id.isEmpty) throw Exception('لم يتم تحديد الصيدلية');
    return _firestore.collection('pharmacies').doc(id).collection('sales');
  }

  String get _currentEmployeeId => currentSale.value.employeeId ?? '';

  // ✅ هل المستخدم الحالي مالك؟
  bool get isOwnerView {
    try {
      final auth = Get.find<AuthController>();
      return auth.actorInfo['type'] == 'owner';
    } catch (_) {
      return false;
    }
  }

  // =============================
  // ✅ Getter جديد: مصدر الهيستوري للديالوج
  // =============================
  List<Sale> get historyInvoices {
    if (isOwnerView) return _userInvoices[_kPharmacyHistory] ?? [];
    return _userInvoices[_kMyHistory] ?? [];
  }

  // =============================
  // Getters (قديمة) - نخليهم زي ما هم لواجهة المبيعات النشطة
  // =============================
  List<Sale> get allUserInvoices {
    final uid = _currentEmployeeId;
    return _userInvoices[uid] ?? [];
  }

  List<Sale> get activeInvoices {
    final uid = _currentEmployeeId;
    return (_userInvoices[uid] ?? []).where((i) => i.status == InvoiceStatus.pending).toList();
  }

  List<Sale> get completedInvoices {
    final uid = _currentEmployeeId;
    return (_userInvoices[uid] ?? []).where((i) => i.status == InvoiceStatus.completed).toList();
  }

  List<Sale> get allInvoices => allUserInvoices;

  List<Sale> get userCompletedInvoices {
    final uid = _currentEmployeeId;
    return (_userInvoices[uid] ?? [])
        .where((inv) => inv.status == InvoiceStatus.completed && inv.employeeId == uid)
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

      final updated = currentSale.value.copyWith(
        employeeId: actorInfo['id']?.toString(),
        employeeName: actorInfo['name']?.toString(),
        pharmacyId: actorInfo['pharmacyId']?.toString() ?? pharmacyId,
      ).recalculate();

      currentSale.value = updated;
    } catch (e) {
      _employeeDataInitialized = false;
      _setFallbackData();
    }
  }

  void _setFallbackData() {
    final user = _auth.currentUser;
    final uid = user?.uid ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    final email = user?.email ?? '';
    final nameFromEmail = email.contains('@') ? email.split('@').first : 'موظف';

    currentSale.value = currentSale.value.copyWith(
      employeeId: uid,
      employeeName: nameFromEmail.isNotEmpty ? nameFromEmail : 'موظف',
      pharmacyId: pharmacyId,
    ).recalculate();
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
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return;

    try {
      isLoading.value = true;

      _userInvoices.putIfAbsent(uid, () => []);
      _userInvoices[uid]!.clear();

      // ✅ completed from Firebase (orderBy saleDate بدل createdAt)
      final querySnapshot = await salesCollection
          .where('employeeId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('saleDate', descending: true)
          .get();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final sale = Sale.fromMap({'id': doc.id, ...data})
              .copyWith(id: doc.id)
              .recalculate();
          _userInvoices[uid]!.add(sale);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل فاتورة من Firebase: $e');
        }
      }

      // pending from Local
      await _loadPendingInvoicesFromLocal(uid);

      // sort: pending أولاً ثم completed بالأحدث
      _userInvoices[uid]!.sort((a, b) {
        if (a.status == InvoiceStatus.pending && b.status != InvoiceStatus.pending) return -1;
        if (a.status != InvoiceStatus.pending && b.status == InvoiceStatus.pending) return 1;
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
  // ✅ Owner history (ALL / RANGE) - تخزين ثابت في __pharmacy__
  // =============================
// =============================
// ✅ تعديل loadHistoryAllForOwner
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

// =============================
// ✅ إضافة دالة مساعدة للتأكد من وجود بيانات
// =============================
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

  // للتصحيح - اعرض محتوى الهيستوري
  void debugPrintHistory() {
    debugPrint('🔍 isOwnerView: $isOwnerView');
    debugPrint('🔍 _kPharmacyHistory: ${_userInvoices[_kPharmacyHistory]?.length ?? 0} فاتورة');
    debugPrint('🔍 _kMyHistory: ${_userInvoices[_kMyHistory]?.length ?? 0} فاتورة');
    debugPrint('🔍 uid $_currentEmployeeId: ${_userInvoices[_currentEmployeeId]?.length ?? 0} فاتورة');
  }
  // =============================
// ✅ تعديل loadHistoryByRange للموظف
// =============================
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
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDay))
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDay))
          .orderBy('saleDate', descending: true);

      // إذا كان employeeId محدد (للمالك)
      if (employeeId != null && employeeId.isNotEmpty) {
        q = q.where('employeeId', isEqualTo: employeeId);
      }
      // إذا لم يتم تحديد employeeId وليس مالك → نفلتر للموظف الحالي
      else if (!isOwnerView) {
        q = q.where('employeeId', isEqualTo: _currentEmployeeId);
      }

      final qs = await q.get();

      final list = qs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Sale.fromMap({'id': doc.id, ...data})
            .copyWith(id: doc.id)
            .recalculate();
      }).toList();

      // ✅ تخزين في المفتاح المناسب
      if (isOwnerView) {
        _userInvoices[_kPharmacyHistory] = list;
      } else {
        _userInvoices[_kMyHistory] = list;
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

  Future<void> _loadPendingInvoicesFromLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pendingInvoicesKey$uid';
      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) return;

      final List<dynamic> jsonList = json.decode(jsonString);

      for (final raw in jsonList) {
        if (raw is! Map) continue;

        try {
          final sale = Sale.fromLocalMap(Map<String, dynamic>.from(raw));
          if (sale.status != InvoiceStatus.pending) continue;

          final exists = (_userInvoices[uid] ?? []).any((inv) => inv.invoiceNumber == sale.invoiceNumber);
          if (!exists) {
            _userInvoices.putIfAbsent(uid, () => []);
            _userInvoices[uid]!.add(sale.recalculate());
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحويل فاتورة محلية: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الفواتير المؤقتة المحلية: $e');
    }
  }

  Future<void> _savePendingInvoicesToLocal() async {
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pendingInvoicesKey$uid';

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
    final userId = invoice.employeeId ?? '';
    if (userId.isEmpty) return;

    final list = List<Sale>.from(_userInvoices[userId] ?? const <Sale>[]);

    // ✅ لو الفاتورة مكتملة، امسح أي نسخة pending بنفس الرقم
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

    _userInvoices[userId] = list;
    _userInvoices.refresh();
  }

  void _removeInvoiceFromUserList(String invoiceNumber) {
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return;
    final list = List<Sale>.from(_userInvoices[uid] ?? const <Sale>[]);
    list.removeWhere((inv) => inv.invoiceNumber == invoiceNumber);
    _userInvoices[uid] = list;
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
      employeeId: _currentEmployeeId,
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
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return;

    final current = currentSale.value;

    if (!current.isSaved && current.status == InvoiceStatus.pending) {
      _addOrReplaceInvoice(current.recalculate());
    } else {
      final list = List<Sale>.from(_userInvoices[uid] ?? const <Sale>[]);
      list.removeWhere((inv) =>
      inv.invoiceNumber == current.invoiceNumber &&
          inv.status == InvoiceStatus.pending);
      _userInvoices[uid] = list;
      _userInvoices.refresh();
    }

    final newInvoice = Sale.empty(
      pharmacyId: pharmacyId,
      employeeId: uid,
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

    final currentIndex = invoices.indexWhere((inv) => inv.invoiceNumber == currentSale.value.invoiceNumber);
    final nextIndex = (currentIndex + 1) % invoices.length;
    _loadInvoice(nextIndex);
  }

  void switchToPreviousInvoice() {
    final invoices = activeInvoices;
    if (invoices.isEmpty) return;

    _saveCurrentInvoice();

    final currentIndex = invoices.indexWhere((inv) => inv.invoiceNumber == currentSale.value.invoiceNumber);
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
    final idx = activeInvoices.indexWhere((i) => i.invoiceNumber == invoice.invoiceNumber);
    if (idx >= 0) {
      _loadInvoice(idx);
      return;
    }
    loadInvoiceForEditing(invoice);
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

    if (!sellAsPiece && medicine.quantity < quantity) {
      _safeSnackbar('مخزون غير كافي', 'المخزون المتوفر: ${medicine.quantity} فقط');
      return;
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

    if (!item.sellAsPiece) {
      final inventory = Get.find<InventoryController>();
      final med = inventory.getMedicineById(item.medicineId);
      if (med != null && med.quantity < newQuantity) {
        _safeSnackbar('مخزون غير كافي', 'المخزون المتوفر: ${med.quantity} فقط');
        return;
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

  void selectInsuranceCompany(InsuranceCompany? company) {
    final sale = currentSale.value;
    if (sale.isSaved || sale.status == InvoiceStatus.completed) return;

    if (company == null) {
      selectedInsuranceCompany.value = null;
      currentSale.value = sale.copyWith(
        insuranceCompanyId: null,
        insuranceCompanyName: null,
        insuranceDiscount: null,
        paymentMethod: PaymentMethod.cash,
      ).recalculate();
      _saveCurrentInvoice();
      return;
    }

    selectedInsuranceCompany.value = company;

    final sub = sale.recalculate().subtotal;
    final insuranceValue = (sub * company.discountPercentage / 100);

    currentSale.value = sale.copyWith(
      insuranceCompanyId: company.id,
      insuranceCompanyName: company.name,
      insuranceDiscount: insuranceValue,
      paymentMethod: PaymentMethod.insurance,
    ).recalculate();

    _saveCurrentInvoice();
  }

  void changePaymentMethod(PaymentMethod method) {
    final sale = currentSale.value;
    if (sale.isSaved || sale.status == InvoiceStatus.completed) return;

    if (method != PaymentMethod.insurance) {
      selectedInsuranceCompany.value = null;
      currentSale.value = sale.copyWith(
        paymentMethod: method,
        insuranceCompanyId: null,
        insuranceCompanyName: null,
        insuranceDiscount: null,
      ).recalculate();
    } else {
      currentSale.value = sale.copyWith(paymentMethod: method).recalculate();
    }

    _saveCurrentInvoice();
  }

  void setCashReceived(double amount) {
    cashReceived.value = amount;
    final diff = amount - currentSale.value.total;
    changeAmount.value = diff < 0 ? 0.0 : diff;
  }

  // =============================
  // Save sale to Firebase
  // =============================
  Future<Sale?> completeSaleAndPrint() async {
    final shiftCtrl = Get.find<ShiftController>();
    final auth = Get.find<AuthController>();

    shiftCtrl.ensureActiveShiftOrThrow();
    final shiftId = shiftCtrl.activeShift.value!.id;

    final sale = currentSale.value;
    if (sale.items.isEmpty) throw Exception('السلة فارغة');
    if (sale.isSaved) throw Exception('هذه الفاتورة محفوظة مسبقاً');

    final saved = await saveSale(
      shiftId: shiftId,
      performedBy: auth.actorInfo,
    );

    if (saved == null) {
      throw Exception('فشل حفظ الفاتورة');
    }

    await shiftCtrl.registerSaleOnShift(
      total: saved.total,
      method: saved.paymentMethod,
      isRefund: false,
    );

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
    if (sale.items.isEmpty) {
      return null;
    }

    if (sale.isSaved || sale.status == InvoiceStatus.completed) {
      _safeSnackbar('غير مسموح', 'هذه الفاتورة محفوظة مسبقاً');
      return null;
    }

    try {
      isLoading.value = true;

      final recalculated = sale.recalculate();
      await _updateInventoryStockForSale(recalculated);

      final now = DateTime.now();
      final customerName = customerNameController.text.trim();
      final customerPhone = customerPhoneController.text.trim();
      final notes = notesController.text.trim();

      final completedSale = recalculated.copyWith(
        customerName: customerName.isEmpty ? null : customerName,
        customerPhone: customerPhone.isEmpty ? null : customerPhone,
        notes: notes.isEmpty ? null : notes,
        saleDate: now,
        status: InvoiceStatus.completed,
        completedAt: now,
        isSaved: true,
        isDeleted: false,
      ).recalculate();

      final doc = salesCollection.doc();
      final saved = completedSale.copyWith(id: doc.id);

      final payload = saved.toMap();

      // ✅ الأفضل: createdAt لو مش موجود
      payload['createdAt'] ??= FieldValue.serverTimestamp();

      if (shiftId != null) payload['shiftId'] = shiftId;
      if (performedBy != null) payload['performedBy'] = performedBy;

      await doc.set(payload);

      _addOrReplaceInvoice(saved);
      currentSale.value = saved;

      await _logSaleActivity(saved);

      final userId = saved.employeeId ?? '';
      await _removePendingInvoiceByNumber(userId, saved.invoiceNumber);

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
          throw Exception('لا يمكن البيع بالقطعة لأن unitsPerPackage غير محدد للدواء ${medicine.name}');
        }

        final int totalPieces = currentPieceQty + (currentPackageQty * unitsPerPackage);
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

  Future<void> _removePendingInvoiceByNumber(String userId, String invoiceNumber) async {
    if (userId.isEmpty) return;

    final list = List<Sale>.from(_userInvoices[userId] ?? const <Sale>[]);

    list.removeWhere((inv) =>
    inv.invoiceNumber == invoiceNumber &&
        inv.status == InvoiceStatus.pending);

    _userInvoices[userId] = list;
    _userInvoices.refresh();

    await _savePendingInvoicesToLocal();
  }

  Future<void> _logSaleActivity(Sale savedSale) async {
    try {
      final authController = Get.find<AuthController>();
      final actor = authController.currentEmployee.value;

      String employeeName = savedSale.employeeName ?? 'موظف';
      String employeeId = savedSale.employeeId ?? (_auth.currentUser?.uid ?? '');

      if (actor != null && actor is Map<String, dynamic>) {
        employeeName = actor['name']?.toString() ?? employeeName;
        employeeId = actor['id']?.toString() ?? employeeId;
      }

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('audit_logs')
          .add({
        'action': 'create_sale',
        'targetId': savedSale.id,
        'invoiceNumber': savedSale.invoiceNumber,
        'totalAmount': savedSale.total,
        'itemsCount': savedSale.items.length,
        'performedBy': employeeName,
        'userId': employeeId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ audit log error: $e');
    }
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
          .map((doc) => Sale.fromMap({'id': doc.id, ...doc.data() as Map<String, dynamic>}).copyWith(id: doc.id))
          .toList();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب التقرير: $e');
      return [];
    }
  }

  Future<Sale?> getSaleByInvoiceNumber(String invoiceNumber) async {
    try {
      final querySnapshot = await salesCollection
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Sale.fromMap({'id': doc.id, ...doc.data() as Map<String, dynamic>}).copyWith(id: doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteSale(String saleId) async {
    try {
      await salesCollection.doc(saleId).update({'isDeleted': true});
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
  DateTime _startOfNextDay(DateTime d) => DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<List<Sale>> fetchMySalesForDay(DateTime day) async {
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return [];

    final start = _startOfDay(day);
    final end = _startOfNextDay(day);

    final qs = await salesCollection
        .where('employeeId', isEqualTo: uid)
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
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return;

    try {
      isLoading.value = true;

      final todayFromFirebase = await fetchMySalesForDay(DateTime.now());

      final merged = <Sale>[];
      merged.addAll(todayFromFirebase);

      if (includeLocalPending) {
        await _loadPendingInvoicesFromLocal(uid);
        merged.addAll(activeInvoices);
      }

      final byNumber = <String, Sale>{};
      for (final s in merged) {
        byNumber[s.invoiceNumber] = s;
      }

      final list = byNumber.values.toList();
      list.sort((a, b) {
        if (a.status == InvoiceStatus.pending && b.status != InvoiceStatus.pending) return -1;
        if (a.status != InvoiceStatus.pending && b.status == InvoiceStatus.pending) return 1;
        return b.saleDate.compareTo(a.saleDate);
      });

      // ✅ نخزن في __my_history__ بدل uid
      _userInvoices[_kMyHistory] = list;
      _userInvoices.refresh();
      update();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyHistoryAll() async {
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return;

    try {
      isLoading.value = true;

      final qs = await salesCollection
          .where('employeeId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('saleDate', descending: true)
          .get();

      final list = qs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Sale.fromMap({'id': doc.id, ...data}).copyWith(id: doc.id).recalculate();
      }).toList();

      await _loadPendingInvoicesFromLocal(uid);
      list.addAll(activeInvoices);

      final byNumber = <String, Sale>{};
      for (final s in list) {
        byNumber[s.invoiceNumber] = s;
      }

      final merged = byNumber.values.toList();
      merged.sort((a, b) {
        if (a.status == InvoiceStatus.pending && b.status != InvoiceStatus.pending) return -1;
        if (a.status != InvoiceStatus.pending && b.status == InvoiceStatus.pending) return 1;
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

    final pendingItems = activeInvoices.fold<int>(0, (sum, inv) => sum + inv.items.length);
    final completedAmount = completedInvoices.fold<double>(0.0, (sum, inv) => sum + inv.total);

    return {
      'totalInvoices': totalCount,
      'pendingInvoices': pendingCount,
      'completedInvoices': completedCount,
      'pendingItems': pendingItems,
      'completedAmount': completedAmount,
    };
  }

  Future<Map<String, dynamic>> getTodaySalesStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final sales = await getSalesReport(startOfDay, endOfDay);

      final totalSales = sales.length;
      final totalAmount = sales.fold(0.0, (sum, sale) => sum + sale.total);

      final cashSales = sales.where((s) => s.paymentMethod == PaymentMethod.cash).length;
      final cardSales = sales.where((s) => s.paymentMethod == PaymentMethod.card).length;
      final insuranceSales = sales.where((s) => s.paymentMethod == PaymentMethod.insurance).length;

      return {
        'totalSales': totalSales,
        'totalAmount': totalAmount,
        'cashSales': cashSales,
        'cardSales': cardSales,
        'insuranceSales': insuranceSales,
        'averageSale': totalSales > 0 ? totalAmount / totalSales : 0.0,
      };
    } catch (_) {
      return {
        'totalSales': 0,
        'totalAmount': 0.0,
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
    final uid = _currentEmployeeId;
    if (uid.isEmpty) return false;
    final start = _startOfDay(day);
    final key = '${uid}_${start.year}${start.month.toString().padLeft(2,'0')}${start.day.toString().padLeft(2,'0')}';

    final doc = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('dailyClosings')
        .doc(key)
        .get();

    return doc.exists;
  }

  Future<Map<String, dynamic>> closeMyDay() async {
    final uid = _currentEmployeeId;
    if (uid.isEmpty) throw Exception('employeeId فارغ');

    final now = DateTime.now();
    final start = _startOfDay(now);
    final key = '${uid}_${start.year}${start.month.toString().padLeft(2,'0')}${start.day.toString().padLeft(2,'0')}';

    final alreadyClosed = await isDayClosedForMe(now);
    if (alreadyClosed) {
      throw Exception('تم إقفال هذا اليوم مسبقاً');
    }

    final todaySales = await fetchMySalesForDay(now);
    final completed = todaySales.where((s) =>
    s.status == InvoiceStatus.completed &&
        s.isDeleted == false &&
        s.isSaved == true
    ).toList();

    double cashTotal = 0, cardTotal = 0, insTotal = 0;
    for (final s in completed) {
      switch (s.paymentMethod) {
        case PaymentMethod.cash: cashTotal += s.total; break;
        case PaymentMethod.card: cardTotal += s.total; break;
        case PaymentMethod.insurance: insTotal += s.total; break;
      }
    }
    final grandTotal = cashTotal + cardTotal + insTotal;

    final payload = {
      'pharmacyId': pharmacyId,
      'employeeId': uid,
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
      addMedicineToSale(results.first);
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
      final allMedicines = inventoryController.medicines;

      final q = query.toLowerCase();
      final results = allMedicines.where((medicine) {
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

  Future<List<Medicine>> searchMedicinesWithSuggestions(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return [];
    }

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();
      final allMedicines = inventoryController.medicines;

      final q = query.toLowerCase();

      final results = allMedicines.where((medicine) {
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
        final aStarts = a.name.toLowerCase().startsWith(q) || a.scientificName.toLowerCase().startsWith(q);
        final bStarts = b.name.toLowerCase().startsWith(q) || b.scientificName.toLowerCase().startsWith(q);
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
        addMedicineToSale(medicine);
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
      return;
    }

    if (isBarcodeInput(query)) {
      await handleSmartSearch(query);
    } else {
      await searchMedicines(query);
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
            child: Text('${company.name} (خصم ${company.discountPercentage}%)'),
          );
        }).toList(),
        onChanged: (company) => selectInsuranceCompany(company),
        decoration: InputDecoration(
          labelText: 'شركة التأمين',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}