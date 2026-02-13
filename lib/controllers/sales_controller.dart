// lib/controllers/sales_controller.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // قائمة الفواتير حسب الموظف (pending + completed)
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

  // =============================
  // Getters: invoices
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
      // انتظر auth جاهز
      final authController = Get.find<AuthController>();
      while (!authController.isPharmacyLoaded.value) {
        await Future.delayed(const Duration(milliseconds: 80));
      }

      // تأكد InventoryController موجود
      Get.find<InventoryController>();

      // حمل بيانات الموظف + التأمين + الفواتير
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

      // 1) completed from Firebase
      final querySnapshot = await salesCollection
          .where('employeeId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final sale = Sale.fromMap({'id': doc.id, ...data})
              .copyWith(id: doc.id, status: InvoiceStatus.completed, isSaved: true)
              .recalculate();

          _userInvoices[uid]!.add(sale);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل فاتورة من Firebase: $e');
        }
      }

      // 2) pending from Local
      await _loadPendingInvoicesFromLocal(uid);

      // 3) sort: pending أولاً ثم completed بالأحدث
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

          final exists = _userInvoices[uid]!.any((inv) => inv.invoiceNumber == sale.invoiceNumber);
          if (!exists) _userInvoices[uid]!.add(sale.recalculate());
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
    final uid = invoice.employeeId ?? _currentEmployeeId;
    if (uid.isEmpty) return;

    _userInvoices.putIfAbsent(uid, () => []);

    final idx = _userInvoices[uid]!.indexWhere((i) => i.invoiceNumber == invoice.invoiceNumber);
    if (idx >= 0) {
      _userInvoices[uid]![idx] = invoice.recalculate();
    } else {
      _userInvoices[uid]!.add(invoice.recalculate());
    }

    if (invoice.status == InvoiceStatus.pending) {
      _savePendingInvoicesToLocal();
    }
  }

  void _removeInvoiceFromUserList(String invoiceNumber) {
    final uid = _currentEmployeeId;
    if (!_userInvoices.containsKey(uid)) return;

    _userInvoices[uid]!.removeWhere((inv) => inv.invoiceNumber == invoiceNumber);
    _savePendingInvoicesToLocal();
  }

  void _setCurrentSale(Sale sale) {
    currentSale.value = sale.recalculate();

    // reset cash
    cashReceived.value = 0.0;
    changeAmount.value = 0.0;

    // insurance selection
    if (currentSale.value.insuranceCompanyId != null) {
      selectedInsuranceCompany.value = insuranceCompanies.firstWhereOrNull(
            (c) => c.id == currentSale.value.insuranceCompanyId,
      );
    } else {
      selectedInsuranceCompany.value = null;
    }

    // customer fields
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
    _saveCurrentInvoice();

    final newInvoice = Sale.empty(
      pharmacyId: pharmacyId,
      employeeId: _currentEmployeeId,
      employeeName: currentSale.value.employeeName,
    );

    _addOrReplaceInvoice(newInvoice);
    _setCurrentSale(newInvoice);

    Get.snackbar('فاتورة جديدة', 'تم إنشاء فاتورة #${newInvoice.invoiceNumber}',
        duration: const Duration(seconds: 2));
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

    Get.defaultDialog(
      title: 'حذف الفاتورة',
      middleText: 'هل تريد حذف فاتورة #${sale.invoiceNumber}؟',
      textConfirm: 'نعم',
      textCancel: 'لا',
      onConfirm: () {
        _removeInvoiceFromUserList(sale.invoiceNumber);
        Get.back();

        if (activeInvoices.isEmpty) {
          _createNewEmptyInvoice();
        } else {
          _loadInvoice(0);
        }

        update();
        _safeSnackbar('تم الحذف', 'تم حذف الفاتورة بنجاح');
      },
    );
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
    // completed: عرض فقط
    _setCurrentSale(invoice);

    if (invoice.status == InvoiceStatus.completed) {
      Get.snackbar('فاتورة مكتملة', 'هذه فاتورة مكتملة - للعرض فقط',
          duration: const Duration(seconds: 2));
    }
  }

  void switchToInvoice(Sale invoice) {
    // لو invoice pending: نحاول نجيبه من activeInvoices
    final idx = activeInvoices.indexWhere((i) => i.invoiceNumber == invoice.invoiceNumber);
    if (idx >= 0) {
      _loadInvoice(idx);
      return;
    }
    // غير ذلك: عرض
    loadInvoiceForEditing(invoice);
  }

  // =============================
  // Add / Update / Remove items (COMPATIBLE with model)
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

    // تحقق مخزون (علب فقط - حالياً)
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

    // تحقق مخزون (علب فقط)
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

    // خصم التأمين نسبة من subtotal الحالي (بعد خصومات الأصناف إن وجدت)
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
  Future<bool> saveSale() async {
    final sale = currentSale.value;

    if (sale.items.isEmpty) {
      _safeSnackbar('فاتورة فارغة', 'أضف منتجات للفاتورة أولاً');
      return false;
    }

    try {
      isLoading.value = true;

      await _updateInventoryStockForSale(sale);

      final now = DateTime.now();

      // تنظيف حقول العملاء (خليها null لو فاضية)
      final customerName = customerNameController.text.trim();
      final customerPhone = customerPhoneController.text.trim();
      final notes = notesController.text.trim();

      final completedSale = sale.copyWith(
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

      await doc.set(saved.toMap());

      // تحديث القائمة
      _addOrReplaceInvoice(saved);

      await _logSaleActivity(saved);

      // تحديث التخزين المحلي (pending فقط)
      await _savePendingInvoicesToLocal();

      // فاتورة جديدة
      createNewInvoice();

      _safeSnackbar('تم الحفظ', 'تم حفظ الفاتورة بنجاح');
      return true;
    } catch (e, st) {
      debugPrint('❌ saveSale error: $e');
      debugPrint('$st');
      _safeSnackbar('خطأ', 'فشل في حفظ الفاتورة: $e');
      return false;
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

      // 🔹 بيع بالقطعة
      if (item.sellAsPiece) {

        if (unitsPerPackage <= 0) {
          throw Exception(
              'لا يمكن البيع بالقطعة لأن unitsPerPackage غير محدد للدواء ${medicine.name}'
          );
        }

        final int totalPieces =
            currentPieceQty + (currentPackageQty * unitsPerPackage);

        final int newTotalPieces = totalPieces - item.quantity;

        if (newTotalPieces < 0) {
          throw Exception('مخزون غير كافي للدواء ${medicine.name}');
        }

        newPackageQty = newTotalPieces ~/ unitsPerPackage;
        newPieceQty = newTotalPieces % unitsPerPackage;

      }
      // 🔹 بيع باكو
      else {
        newPackageQty = currentPackageQty - item.quantity;

        if (newPackageQty < 0) {
          throw Exception('مخزون غير كافي للدواء ${medicine.name}');
        }
      }

      await inventoryController.updateStock(
        id: medicine.id,
        newPackageQty: newPackageQty,
        newPieceQty: newPieceQty,
      );
    }
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
  // Stats / Reports
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
  // Optional UI widget (keep if you want)
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
