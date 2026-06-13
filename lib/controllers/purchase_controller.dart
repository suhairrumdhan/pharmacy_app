import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/purchase_model.dart';
import '../models/inventory_model.dart';
import '../services/search_index_service.dart';
import 'auth_controller.dart';
import 'finance_controller.dart';
import 'inventory_controller.dart';
import 'supplier_controller.dart';
import '../services/audit_log_service.dart';

import '../services/financial_transaction_service.dart';

class PurchaseStockEntry {
  final String medicineId;
  final String medicineName;

  /// quantity في Medicine
  final int packageQty;

  /// pieceQuantity في Medicine
  final int pieceQty;

  /// في الجملة = سعر شراء العبوة
  /// في القطاعي = سعر شراء القطعة
  final double purchasePrice;

  /// سعر بيع العبوة
  final double? sellingPrice;

  /// عدد القطع داخل العبوة
  final int? unitsPerPackage;

  /// هل الصنف يبيع بالقطعة
  final bool? sellByPiece;

  /// سعر بيع القطعة
  final double? piecePrice;

  final String? batchNumber;
  final DateTime? expiryDate;
  final String? barcode;
  final String? supplier;

  const PurchaseStockEntry({
    required this.medicineId,
    required this.medicineName,
    this.packageQty = 0,
    this.pieceQty = 0,
    required this.purchasePrice,
    this.sellingPrice,
    this.unitsPerPackage,
    this.sellByPiece,
    this.piecePrice,
    this.batchNumber,
    this.expiryDate,
    this.barcode,
    this.supplier,
  });

  double get lineSubtotal {
    final qty = packageQty > 0 ? packageQty : pieceQty;
    return qty * purchasePrice;
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'packageQty': packageQty,
      'pieceQty': pieceQty,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'unitsPerPackage': unitsPerPackage,
      'sellByPiece': sellByPiece,
      'piecePrice': piecePrice,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'barcode': barcode,
      'supplier': supplier,
    };
  }
}

class PurchaseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService = AuditLogService();
  AuthController get _auth => _authCtrl;

  Map<String, dynamic> get _actor =>
      Map<String, dynamic>.from(_auth.actorInfo);

  void _ensureCan(String permission, String message) {
    if (!_auth.can(permission)) {
      throw Exception(message);
    }
  }

  /// =========================
  /// Data
  /// =========================
  final RxList<PurchaseInvoice> invoices = <PurchaseInvoice>[].obs;
  final RxList<PurchaseInvoice> filteredInvoices = <PurchaseInvoice>[].obs;

  /// =========================
  /// Analytics
  /// =========================
  final RxDouble totalPurchasesThisMonth = 0.0.obs;
  final RxDouble totalPurchasesThisYear = 0.0.obs;
  final RxDouble totalDue = 0.0.obs;
  final RxMap<String, double> supplierBalance = <String, double>{}.obs;

  /// =========================
  /// Alerts
  /// =========================
  final RxList<Map<String, dynamic>> purchaseAlerts = <Map<String, dynamic>>[].obs;

  /// =========================
  /// UI State
  /// =========================
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<PaymentStatus?> paymentFilter = Rx<PaymentStatus?>(null);

  late AuthController _authCtrl;
  late InventoryController _inventoryCtrl;
  late SupplierController _supplierCtrl;

  String _lastLoadedPharmacyId = '';

  @override
  void onInit() {
    super.onInit();

    _authCtrl = Get.find<AuthController>();
    _inventoryCtrl = Get.find<InventoryController>();
    _supplierCtrl = Get.find<SupplierController>();

    ever(_authCtrl.pharmacyData, (_) {
      final pid = _pharmacyId;
      if (pid.isNotEmpty && pid != _lastLoadedPharmacyId) {
        _lastLoadedPharmacyId = pid;
        loadInvoices();
      }
    });

    if (_pharmacyId.isNotEmpty) {
      _lastLoadedPharmacyId = _pharmacyId;
      loadInvoices();
    }

    ever(_inventoryCtrl.medicines, (_) {
      _generatePurchaseAlerts();
    });
  }

  /// =========================
  /// Getters
  /// =========================
  String get _pharmacyId => _authCtrl.pharmacyId;
  String get _currentUserId => _authCtrl.actorInfo['id'] ?? '';

  bool get canCreateInvoice => _authCtrl.can('purchases.create');
  bool get canViewInvoices => _authCtrl.can('purchases.view');
  bool get canMakePayment => _authCtrl.can('purchases.payment');
  bool get canDeleteInvoice => _authCtrl.can('purchases.delete');



  CollectionReference<Map<String, dynamic>> get _suppliersCollection {
    return _firestore
        .collection('pharmacies')
        .doc(_pharmacyId)
        .collection('suppliers');
  }

  CollectionReference<Map<String, dynamic>> get _invoicesCollection {
    return _firestore
        .collection('pharmacies')
        .doc(_pharmacyId)
        .collection('purchase_invoices');
  }

  CollectionReference<Map<String, dynamic>> get _medicinesCollection {
    return _firestore
        .collection('pharmacies')
        .doc(_pharmacyId)
        .collection('medicines');
  }
  Future<void> _logCreatePurchaseInvoice({
    required PurchaseInvoice invoice,
    required List<PurchaseStockEntry> stockEntries,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: _pharmacyId,
        action: AuditActions.createPurchaseInvoice,
        module: AuditModules.purchases,
        targetType: AuditTargetTypes.purchase,
        targetId: invoice.id ?? '',
        targetName: invoice.invoiceNumber,
        performedBy: _actor,
        details: {
          'note': 'تم إنشاء فاتورة مشتريات',
          'newValues': {
            'invoiceNumber': invoice.invoiceNumber,
            'supplierId': invoice.supplierId,
            'supplierName': invoice.supplierName,
            'itemsCount': invoice.items.length,
            'stockEntriesCount': stockEntries.length,
            'subtotal': invoice.subtotal,
            'discount': invoice.discount,
            'total': invoice.total,
            'paymentStatus': invoice.paymentStatus.name,
            'dueDate': invoice.dueDate?.toIso8601String(),
            'referenceNumber': invoice.referenceNumber,
            'receivedDate': invoice.receivedDate?.toIso8601String(),
            'createdBy': invoice.createdBy,
          },
        },
        entityPath: 'pharmacies/$_pharmacyId/purchase_invoices/${invoice.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (create_purchase_invoice): $e');
    }
  }

  Future<void> recalculateSupplierFinancials() async {
    if (_pharmacyId.isEmpty) return;

    try {
      final now = DateTime.now();

      final invoicesSnapshot = await _invoicesCollection.get();

      final Map<String, double> totalPurchasesBySupplier = {};
      final Map<String, double> totalPaidBySupplier = {};
      final Map<String, double> outstandingBySupplier = {};
      final Map<String, double> overdueBySupplier = {};
      final Map<String, int> unpaidCountBySupplier = {};
      final Map<String, int> overdueCountBySupplier = {};
      final Map<String, DateTime> lastPurchaseBySupplier = {};
      final Map<String, DateTime> lastPaymentBySupplier = {};

      for (final doc in invoicesSnapshot.docs) {
        final invoice = PurchaseInvoice.fromMap(doc.data(), doc.id);

        final supplierId = invoice.supplierId.trim();
        if (supplierId.isEmpty) continue;

        totalPurchasesBySupplier[supplierId] =
            (totalPurchasesBySupplier[supplierId] ?? 0.0) + invoice.total;

        totalPaidBySupplier[supplierId] =
            (totalPaidBySupplier[supplierId] ?? 0.0) + invoice.paid;

        final remaining = invoice.remaining;

        if (remaining > 0) {
          outstandingBySupplier[supplierId] =
              (outstandingBySupplier[supplierId] ?? 0.0) + remaining;

          unpaidCountBySupplier[supplierId] =
              (unpaidCountBySupplier[supplierId] ?? 0) + 1;

          if (invoice.dueDate != null && invoice.dueDate!.isBefore(now)) {
            overdueBySupplier[supplierId] =
                (overdueBySupplier[supplierId] ?? 0.0) + remaining;

            overdueCountBySupplier[supplierId] =
                (overdueCountBySupplier[supplierId] ?? 0) + 1;
          }
        }

        final invoiceDate = invoice.invoiceDate;
        final currentLastPurchase = lastPurchaseBySupplier[supplierId];

        if (currentLastPurchase == null ||
            invoiceDate.isAfter(currentLastPurchase)) {
          lastPurchaseBySupplier[supplierId] = invoiceDate;
        }

        if (invoice.paid > 0) {
          final currentLastPayment = lastPaymentBySupplier[supplierId];
          final paymentDate = invoice.postedAt ?? invoice.updatedAt ?? invoice.invoiceDate;

          if (currentLastPayment == null ||
              paymentDate.isAfter(currentLastPayment)) {
            lastPaymentBySupplier[supplierId] = paymentDate;
          }
        }
      }

      final allSupplierIds = <String>{
        ...totalPurchasesBySupplier.keys,
        ...totalPaidBySupplier.keys,
        ...outstandingBySupplier.keys,
        ...overdueBySupplier.keys,
      };

      if (allSupplierIds.isEmpty) return;

      final batch = _firestore.batch();

      for (final supplierId in allSupplierIds) {
        final supplierRef = _suppliersCollection.doc(supplierId);

        final totalPurchases = totalPurchasesBySupplier[supplierId] ?? 0.0;
        final totalPaid = totalPaidBySupplier[supplierId] ?? 0.0;
        final outstanding = outstandingBySupplier[supplierId] ?? 0.0;
        final overdue = overdueBySupplier[supplierId] ?? 0.0;

        batch.set(
          supplierRef,
          {
            'totalPurchases': totalPurchases,
            'totalPaid': totalPaid,
            'totalDue': outstanding,
            'currentBalance': outstanding,
            'outstandingBalance': outstanding,
            'overdueBalance': overdue,
            'unpaidInvoicesCount': unpaidCountBySupplier[supplierId] ?? 0,
            'overdueInvoicesCount': overdueCountBySupplier[supplierId] ?? 0,
            'lastPurchaseDate': lastPurchaseBySupplier[supplierId] != null
                ? Timestamp.fromDate(lastPurchaseBySupplier[supplierId]!)
                : null,
            'lastPaymentDate': lastPaymentBySupplier[supplierId] != null
                ? Timestamp.fromDate(lastPaymentBySupplier[supplierId]!)
                : null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await _supplierCtrl.fetchSuppliers();

      debugPrint('✅ Supplier financials recalculated successfully');
    } catch (e, st) {
      debugPrint('❌ recalculateSupplierFinancials error: $e');
      debugPrint('$st');
    }
  }
  Future<void> _logPurchasePayment({
    required PurchaseInvoice oldInvoice,
    required PurchaseInvoice newInvoice,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: _pharmacyId,
        action: AuditActions.purchasePayment,
        module: AuditModules.purchases,
        targetType: AuditTargetTypes.purchase,
        targetId: newInvoice.id ?? '',
        targetName: newInvoice.invoiceNumber,
        performedBy: _actor,
        details: {
          'note': 'تم تسديد دفعة على فاتورة مشتريات',
          'oldValues': {
            'paid': oldInvoice.paid,
            'remaining': oldInvoice.remaining,
            'paymentStatus': oldInvoice.paymentStatus.name,
          },
          'newValues': {
            'paid': newInvoice.paid,
            'remaining': newInvoice.remaining,
            'paymentStatus': newInvoice.paymentStatus.name,
            'paymentAmount': amount,
            'paymentMethod': paymentMethod,
          },
        },
        entityPath: 'pharmacies/$_pharmacyId/purchase_invoices/${newInvoice.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (purchase_payment): $e');
    }
  }

  Future<void> _logDeletePurchaseInvoice({
    required PurchaseInvoice invoice,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: _pharmacyId,
        action: AuditActions.deletePurchaseInvoice,
        module: AuditModules.purchases,
        targetType: AuditTargetTypes.purchase,
        targetId: invoice.id ?? '',
        targetName: invoice.invoiceNumber,
        performedBy: _actor,
        details: {
          'note': 'تم حذف فاتورة مشتريات',
          'deletedSnapshot': {
            'invoiceNumber': invoice.invoiceNumber,
            'supplierId': invoice.supplierId,
            'supplierName': invoice.supplierName,
            'itemsCount': invoice.items.length,
            'subtotal': invoice.subtotal,
            'discount': invoice.discount,
            'total': invoice.total,
            'paid': invoice.paid,
            'remaining': invoice.remaining,
            'paymentStatus': invoice.paymentStatus.name,
            'referenceNumber': invoice.referenceNumber,
          },
        },
        entityPath: 'pharmacies/$_pharmacyId/purchase_invoices/${invoice.id}',
      );
    } catch (e) {
      debugPrint('❌ audit log error (delete_purchase_invoice): $e');
    }
  }
  /// =========================
  /// Load Invoices
  /// =========================
  Future<void> loadInvoices() async {
    if (!canViewInvoices) return;
    if (_pharmacyId.isEmpty) return;

    try {
      isLoading.value = true;

      final snapshot = await _invoicesCollection
          .orderBy('invoiceDate', descending: true)
          .get();

      final data = snapshot.docs.map((doc) {
        return PurchaseInvoice.fromMap(doc.data(), doc.id);
      }).toList();

      invoices.assignAll(data);
      _applyFilters();
      _calculateFinancialMetrics();
      _generatePurchaseAlerts();
    } catch (e) {
      debugPrint('خطأ loadInvoices: $e');
      Get.snackbar('خطأ', 'فشل في تحميل فواتير المشتريات');
    } finally {
      isLoading.value = false;
    }
  }

  /// =======================================================
  /// Backward-compatible
  /// لو عندك أماكن قديمة تستعمل createPurchaseInvoice
  /// =======================================================
  Future<void> createPurchaseInvoice({
    required String supplierId,
    required String supplierName,
    required List<PurchaseItem> items,
    double discount = 0.0,
    String? referenceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? notes,
  }) async {
    final stockEntries = items.map((item) {
      return PurchaseStockEntry(
        medicineId: item.medicineId,
        medicineName: item.medicineName,
        packageQty: item.quantity,
        pieceQty: 0,
        purchasePrice: item.price,
        batchNumber: item.batchNumber,
        expiryDate: item.expiryDate,
        supplier: supplierName,
      );
    }).toList();

    await createPurchaseInvoiceAdvanced(
      supplierId: supplierId,
      supplierName: supplierName,
      items: items,
      stockEntries: stockEntries,
      discount: discount,
      referenceNumber: referenceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      notes: notes,
    );
  }

  /// =======================================================
  /// Advanced Create
  /// هذا هو الأساس الصحيح مع توافق المخزون
  /// =======================================================
  Future<void> createPurchaseInvoiceAdvanced({
    required String supplierId,
    required String supplierName,
    required List<PurchaseItem> items,
    required List<PurchaseStockEntry> stockEntries,
    double discount = 0.0,
    String? referenceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? notes,
  }) async {


    _ensureCan('purchases.create', 'ليس لديك صلاحية إنشاء فاتورة مشتريات');
    if (_pharmacyId.isEmpty) {
      Get.snackbar('تنبيه', 'معرف الصيدلية غير متوفر');
      return;
    }

    if (items.isEmpty) {
      Get.snackbar('تنبيه', 'الفاتورة فارغة');
      return;
    }

    if (stockEntries.isEmpty) {
      Get.snackbar('تنبيه', 'لا توجد بيانات مخزون');
      return;
    }

    try {
      isLoading.value = true;

      final safeDiscount = discount < 0 ? 0.0 : discount;
      final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.subtotal);
      final total = (subtotal - safeDiscount).clamp(0.0, double.infinity);

      final invoiceNumber = await _generateInvoiceNumber();
      final now = DateTime.now();

      /// 1) نحدث المخزون أولاً
      await _applyInventoryUpdates(stockEntries);

      /// 2) بعد نجاح تحديث المخزون نحفظ الفاتورة
      final invoice = PurchaseInvoice(
        invoiceNumber: invoiceNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        items: items,
        invoiceDate: invoiceDate ?? now,
        receivedDate: now,
        subtotal: subtotal,
        discount: safeDiscount,
        total: total,
        paymentStatus: PaymentStatus.unpaid,
        dueDate: dueDate,
        notes: notes,
        referenceNumber: referenceNumber,
        createdBy: _currentUserId,
      );

      final docRef = await _invoicesCollection.add({
        ...invoice.toMap(),
        'stockEntries': stockEntries.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final txId = await FinancialTransactionService.instance.registerPurchaseInvoice(
        pharmacyId: _pharmacyId,
        invoiceId: docRef.id,
        invoiceNumber: invoice.invoiceNumber,
        amount: total,
        supplierId: supplierId,
        supplierName: supplierName,
        createdBy: _currentUserId,
      );

      await docRef.update({
        'financialPosted': true,
        'financialTransactionId': txId,
        'postedAt': FieldValue.serverTimestamp(),
      });

      final newInvoice = invoice.copyWith(
        id: docRef.id,
        financialPosted: true,
        financialTransactionId: txId,
        postedAt: DateTime.now(),
      );

      await _logCreatePurchaseInvoice(
        invoice: newInvoice,
        stockEntries: stockEntries,
      );

      invoices.insert(0, newInvoice);

      _applyFilters();
      _calculateFinancialMetrics();
      _generatePurchaseAlerts();
      await recalculateSupplierFinancials();
      Get.snackbar(
        'نجاح',
        'تم إنشاء فاتورة المشتريات رقم $invoiceNumber وتحديث المخزون',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('خطأ createPurchaseInvoiceAdvanced: $e');
      Get.snackbar(
        'خطأ',
        'فشل في إنشاء الفاتورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// =======================================================
  /// Generate Invoice Number
  /// =======================================================
  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';

    try {
      final prefix = 'PINV-$ym-';

      final snapshot = await _invoicesCollection
          .where('invoiceNumber', isGreaterThanOrEqualTo: prefix)
          .where('invoiceNumber', isLessThan: 'PINV-$ym-\uf8ff')
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return '${prefix}0001';
      }

      final lastInvoiceNumber = snapshot.docs.first.data()['invoiceNumber']?.toString() ?? '';
      final parts = lastInvoiceNumber.split('-');
      final lastSeq = parts.isNotEmpty ? int.tryParse(parts.last) ?? 0 : 0;
      final newSeq = (lastSeq + 1).toString().padLeft(4, '0');

      return '$prefix$newSeq';
    } catch (_) {
      final fallback = now.millisecondsSinceEpoch.toString().substring(8);
      return 'PINV-$ym-$fallback';
    }
  }

  /// =======================================================
  /// Inventory Updates
  /// مطابق تمامًا لـ Medicine
  /// =======================================================
  Future<void> _applyInventoryUpdates(List<PurchaseStockEntry> entries) async {
    if (entries.isEmpty) return;

    final WriteBatch batch = _firestore.batch();
    final now = DateTime.now();
    final Map<String, Medicine> updatedLocals = {};

    for (final entry in entries) {
      final med = _inventoryCtrl.getMedicineById(entry.medicineId);
      if (med == null) {
        throw Exception('الصنف غير موجود في المخزون: ${entry.medicineName}');
      }

      final bool isPackagePurchase = entry.packageQty > 0;
      final bool isPiecePurchase = entry.pieceQty > 0;

      if (!isPackagePurchase && !isPiecePurchase) {
        throw Exception('لا توجد كمية صالحة للصنف: ${entry.medicineName}');
      }

      final int newPackageQty = med.quantity + entry.packageQty;
      final int newPieceQty = med.pieceQuantity + entry.pieceQty;

      final int? finalUnitsPerPackage = entry.unitsPerPackage ?? med.unitsPerPackage;
      final bool finalSellByPiece = entry.sellByPiece ?? med.sellByPiece;

      double? finalSellingPrice = entry.sellingPrice ?? med.sellingPrice;
      double? finalPiecePrice = entry.piecePrice ?? med.piecePrice;

      /// شراء جملة => purchasePrice هو سعر شراء العبوة
      /// شراء قطاعي => purchasePrice هو سعر شراء القطعة
      final double finalPurchasePrice =
      entry.purchasePrice > 0 ? entry.purchasePrice : (med.purchasePrice ?? 0);

      if (finalSellByPiece &&
          (finalPiecePrice == null || finalPiecePrice <= 0) &&
          finalUnitsPerPackage != null &&
          finalUnitsPerPackage > 0 &&
          finalSellingPrice != null &&
          finalSellingPrice > 0) {
        finalPiecePrice = finalSellingPrice / finalUnitsPerPackage;
      }

      final updated = med.copyWith(
        quantity: newPackageQty,
        pieceQuantity: newPieceQty,
        purchasePrice: finalPurchasePrice,
        sellingPrice: finalSellingPrice,
        unitsPerPackage: finalUnitsPerPackage,
        sellByPiece: finalSellByPiece,
        piecePrice: finalPiecePrice,
        supplier: (entry.supplier != null && entry.supplier!.trim().isNotEmpty)
            ? entry.supplier!.trim()
            : med.supplier,
        barcode: (entry.barcode != null && entry.barcode!.trim().isNotEmpty)
            ? entry.barcode!.trim()
            : med.barcode,
        expiryDate: entry.expiryDate ?? med.expiryDate,
        lastUpdated: now,
      );

      final docRef = _medicinesCollection.doc(entry.medicineId);
      batch.update(docRef, {
        'quantity': updated.quantity,
        'pieceQuantity': updated.pieceQuantity,
        'purchasePrice': updated.purchasePrice,
        'sellingPrice': updated.sellingPrice,
        'unit': updated.unit?.name,
        'unitsPerPackage': updated.unitsPerPackage,
        'sellByPiece': updated.sellByPiece,
        'piecePrice': updated.piecePrice,
        'supplier': updated.supplier,
        'barcode': updated.barcode,
        'expiryDate': updated.expiryDate?.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      updatedLocals[entry.medicineId] = updated;
    }

    await batch.commit();

    /// تحديث محلي فوري بدون إعادة تحميل كاملة
    if (updatedLocals.isNotEmpty) {
      final meds = _inventoryCtrl.medicines.toList();

      for (int i = 0; i < meds.length; i++) {
        final replacement = updatedLocals[meds[i].id];
        if (replacement != null) {
          meds[i] = replacement;
        }
      }

      _inventoryCtrl.medicines.assignAll(meds);
      _inventoryCtrl.filteredMedicines.assignAll(meds);
      _inventoryCtrl.searchMedicines(_inventoryCtrl.searchQuery.value);
      /// ✅ حمّل بيانات الصيدلية الأحدث دائمًا قبل تحديث الـ index
      await _inventoryCtrl.loadPharmacyData();

      final freshPharmacyData = Map<String, dynamic>.from(_inventoryCtrl.pharmacyData);

      /// ✅ تحديث الـ search index لكل صنف تم تعديله
      final searchIndexService = SearchIndexService();

      for (final updatedMedicine in updatedLocals.values) {
        await searchIndexService.createOrUpdateIndex(
          pharmacyId: _pharmacyId,
          pharmacyData: freshPharmacyData,
          medicine: updatedMedicine,
        );
      }
    }
  }
  /// =======================================================
  /// Payments
  /// =======================================================
// في purchase_controller.dart - داخل class PurchaseController

  Future<void> makePayment(
      String invoiceId,
      double amount,
      String paymentMethod,
      ) async {
    _ensureCan('purchases.payment', 'ليس لديك صلاحية تسديد فواتير المشتريات');

    if (amount <= 0) {
      Get.snackbar('تنبيه', 'أدخل مبلغ صحيح');
      return;
    }

    try {
      final index = invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index < 0) {
        Get.snackbar('تنبيه', 'الفاتورة غير موجودة');
        return;
      }

      final invoice = invoices[index];
      final remainingBeforePayment = invoice.remaining;

      if (remainingBeforePayment <= 0) {
        Get.snackbar('تنبيه', 'الفاتورة مسددة بالكامل');
        return;
      }

      if (amount > remainingBeforePayment) {
        Get.snackbar('خطأ', 'المبلغ أكبر من المتبقي');
        return;
      }

      final newPaid = invoice.paid + amount;

      PaymentStatus newStatus;
      if (newPaid >= invoice.total) {
        newStatus = PaymentStatus.paid;
      } else if (newPaid > 0) {
        newStatus = PaymentStatus.partiallyPaid;
      } else {
        newStatus = PaymentStatus.unpaid;
      }

      final txId = await FinancialTransactionService.instance.registerSupplierPayment(
        pharmacyId: _pharmacyId,
        supplierId: invoice.supplierId,
        supplierName: invoice.supplierName,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceId: invoice.id,
        createdBy: _currentUserId,
      );

      final updatedInvoice = invoice.copyWith(
        paid: newPaid,
        paymentStatus: newStatus,
        paymentMethod: paymentMethod,
        remainingAmount: (invoice.total - newPaid).clamp(0.0, double.infinity),
        financialPosted: true,
        postedAt: DateTime.now(),
      );

      await _invoicesCollection.doc(invoiceId).update({
        'paid': newPaid,
        'paymentStatus': newStatus.name,
        'paymentMethod': paymentMethod,
        'remainingAmount': updatedInvoice.remaining,
        'lastPaymentTransactionId': txId,
        'lastPaidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      invoices[index] = updatedInvoice;

      await _logPurchasePayment(
        oldInvoice: invoice,
        newInvoice: updatedInvoice,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      _applyFilters();
      _calculateFinancialMetrics();
      _generatePurchaseAlerts();
      await recalculateSupplierFinancials();
      Get.snackbar(
        'نجاح',
        'تم تسديد ${amount.toStringAsFixed(2)} د.ل',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تسديد الدفعة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
// دالة مساعدة لحساب رقم الدفعة
  String _getPaymentNumber(PurchaseInvoice invoice) {
    // هنا يمكنك تخزين عدد الدفعات في الـ invoice نفسه
    // لكن كمثال بسيط:
    if (invoice.paid <= 0) return 'الأولى';
    if (invoice.paid < invoice.total) return 'الثانية';
    return 'الأولى';
  }
  /// =======================================================
  /// Delete
  /// مبدئيًا حذف الفاتورة لا يعكس المخزون
  /// =======================================================
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      _ensureCan('purchases.delete', 'ليس لديك صلاحية حذف فواتير المشتريات');

      final invoice = invoices.firstWhereOrNull((inv) => inv.id == invoiceId);
      if (invoice == null) {
        Get.snackbar('تنبيه', 'الفاتورة غير موجودة');
        return;
      }

      await _invoicesCollection.doc(invoiceId).delete();

      await _logDeletePurchaseInvoice(
        invoice: invoice,
      );

      invoices.removeWhere((inv) => inv.id == invoiceId);
      _applyFilters();
      _calculateFinancialMetrics();
      _generatePurchaseAlerts();
      await recalculateSupplierFinancials();
      Get.snackbar(
        'نجاح',
        'تم حذف الفاتورة',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف الفاتورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  /// =======================================================
  /// Search / Filter
  /// =======================================================
  void search(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByPaymentStatus(PaymentStatus? status) {
    paymentFilter.value = status;
    _applyFilters();
  }

  void clearFilters() {
    searchQuery.value = '';
    paymentFilter.value = null;
    _applyFilters();
  }

  void _applyFilters() {
    List<PurchaseInvoice> result = invoices.toList();

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((inv) {
        final number = inv.invoiceNumber.toLowerCase();
        final supplier = inv.supplierName.toLowerCase();
        final ref = inv.referenceNumber?.toLowerCase() ?? '';
        final notes = inv.notes?.toLowerCase() ?? '';
        final itemNames = inv.items.map((e) => e.medicineName.toLowerCase()).join(' | ');

        return number.contains(q) ||
            supplier.contains(q) ||
            ref.contains(q) ||
            notes.contains(q) ||
            itemNames.contains(q);
      }).toList();
    }

    if (paymentFilter.value != null) {
      result = result.where((inv) => inv.paymentStatus == paymentFilter.value).toList();
    }

    filteredInvoices.assignAll(result);
  }

  /// =======================================================
  /// Financial Metrics
  /// =======================================================
  void _calculateFinancialMetrics() {
    final now = DateTime.now();

    totalPurchasesThisMonth.value = invoices
        .where((inv) => inv.invoiceDate.month == now.month && inv.invoiceDate.year == now.year)
        .fold(0.0, (sum, inv) => sum + inv.total);

    totalPurchasesThisYear.value = invoices
        .where((inv) => inv.invoiceDate.year == now.year)
        .fold(0.0, (sum, inv) => sum + inv.total);

    totalDue.value = invoices
        .where((inv) => inv.paymentStatus != PaymentStatus.paid)
        .fold(0.0, (sum, inv) => sum + inv.remaining);

    supplierBalance.clear();
    for (final inv in invoices.where((inv) => inv.remaining > 0)) {
      supplierBalance[inv.supplierName] =
          (supplierBalance[inv.supplierName] ?? 0.0) + inv.remaining;
    }
  }

  /// =======================================================
  /// Alerts
  /// =======================================================
  void _generatePurchaseAlerts() {
    final List<Map<String, dynamic>> alerts = [];
    final now = DateTime.now();

    for (final med in _inventoryCtrl.lowStockMedicines.take(10)) {
      alerts.add({
        'type': 'warning',
        'title': '📦 يحتاج طلب',
        'message':
        '${med.name} - المخزون ${med.quantity} | الحد الأدنى ${med.minStockLevel ?? 0}',
        'action': 'order',
        'medicineId': med.id,
        'medicineName': med.name,
        'priority': 'high',
      });
    }

    for (final inv in invoices.where((inv) =>
    inv.remaining > 0 &&
        inv.dueDate != null &&
        inv.dueDate!.isBefore(now.add(const Duration(days: 7))))) {
      final daysLeft = inv.dueDate!.difference(now).inDays;

      alerts.add({
        'type': daysLeft < 0 ? 'danger' : 'info',
        'title': daysLeft < 0 ? '⚠️ فاتورة متأخرة' : '💰 فاتورة مستحقة',
        'message':
        '${inv.supplierName} - ${inv.invoiceNumber} | ${inv.remaining.toStringAsFixed(2)} د.ل '
            '${daysLeft < 0 ? 'متأخرة بـ ${-daysLeft} يوم' : 'متبقي $daysLeft يوم'}',
        'invoiceId': inv.id,
        'priority': daysLeft < 0 ? 'urgent' : 'normal',
      });
    }

    final recentInvoices = invoices
        .where((inv) => inv.invoiceDate.isAfter(now.subtract(const Duration(days: 30))))
        .take(10);

    for (final inv in recentInvoices) {
      for (final item in inv.items) {
        if (item.expiryDate != null &&
            item.expiryDate!.isBefore(now.add(const Duration(days: 90)))) {
          alerts.add({
            'type': 'info',
            'title': '⏳ صلاحية قصيرة',
            'message':
            '${item.medicineName} - تنتهي ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year} '
                '(فاتورة ${inv.invoiceNumber})',
            'invoiceId': inv.id,
            'priority': 'normal',
          });
          break;
        }
      }
    }

    alerts.sort((a, b) {
      const order = {'urgent': 0, 'high': 1, 'normal': 2};
      return (order[a['priority']] ?? 3).compareTo(order[b['priority']] ?? 3);
    });

    purchaseAlerts.assignAll(alerts);
  }

  /// =======================================================
  /// Reports / Stats
  /// =======================================================
  Map<String, dynamic> getQuickReport() {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);

    final thisMonthTotal = totalPurchasesThisMonth.value;
    final lastMonthTotal = invoices
        .where((inv) =>
    inv.invoiceDate.month == prevMonth.month &&
        inv.invoiceDate.year == prevMonth.year)
        .fold(0.0, (sum, inv) => sum + inv.total);

    final change = lastMonthTotal == 0
        ? 0.0
        : ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;

    final supplierTotals = <String, double>{};
    for (final inv in invoices) {
      supplierTotals[inv.supplierName] =
          (supplierTotals[inv.supplierName] ?? 0.0) + inv.total;
    }

    final topSuppliers = supplierTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'thisMonth': thisMonthTotal,
      'lastMonth': lastMonthTotal,
      'change': change,
      'trend': change >= 0 ? 'up' : 'down',
      'totalDue': totalDue.value,
      'totalInvoices': invoices.length,
      'topSupplier': topSuppliers.isNotEmpty ? topSuppliers.first.key : 'لا يوجد',
      'paidInvoices': invoices.where((inv) => inv.paymentStatus == PaymentStatus.paid).length,
      'unpaidInvoices': invoices.where((inv) => inv.paymentStatus != PaymentStatus.paid).length,
    };
  }

  PurchaseInvoice? getInvoiceById(String id) {
    try {
      return invoices.firstWhere((inv) => inv.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'totalPurchasesMonth': totalPurchasesThisMonth.value,
      'totalPurchasesYear': totalPurchasesThisYear.value,
      'totalDue': totalDue.value,
      'invoicesCount': invoices.length,
      'suppliersCount': invoices.map((inv) => inv.supplierId).toSet().length,
      'alertsCount': purchaseAlerts.length,
    };
  }
}