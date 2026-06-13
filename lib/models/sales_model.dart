// lib/models/sales_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// =========================
/// Helpers
/// =========================
double _asDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

DateTime _parseDateTime(dynamic v, {DateTime? fallback}) {
  if (v == null) return fallback ?? DateTime.now();

  if (v is Timestamp) return v.toDate();

  if (v is String) {
    final dt = DateTime.tryParse(v);
    return dt ?? (fallback ?? DateTime.now());
  }

  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());

  if (v is Map) {
    final seconds = v['_seconds'] ?? v['seconds'];
    if (seconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
  }

  return fallback ?? DateTime.now();
}

/// =========================
/// Enums
/// =========================
enum InvoiceStatus { pending, completed, cancelled }
enum SaleType { sale, refund }


SaleType _saleTypeFromString(dynamic v, {SaleType fallback = SaleType.sale}) {
  final s = (v ?? '').toString().toLowerCase().trim();
  if (s == 'refund') return SaleType.refund;
  return SaleType.sale;
}
/// ✅ PaymentMethod هنا معناها "طريقة دفع الزبون" فقط
/// insurance موجود فقط للتوافق مع الداتا القديمة (Legacy)
enum PaymentMethod {
  cash('نقدي'),
  card('معاملة مصرفية'),
  insurance('تأمين'); // legacy only

  final String arabicName;
  const PaymentMethod(this.arabicName);

  static PaymentMethod fromString(dynamic value) {
    final v = (value ?? '').toString().toLowerCase().trim();
    switch (v) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'insurance':
        return PaymentMethod.insurance;
      default:
        return PaymentMethod.cash;
    }
  }
}

InvoiceStatus _statusFromString(dynamic value,
    {InvoiceStatus fallback = InvoiceStatus.pending}) {
  final v = (value ?? '').toString().toLowerCase().trim();
  switch (v) {
    case 'pending':
      return InvoiceStatus.pending;
    case 'completed':
      return InvoiceStatus.completed;
    case 'cancelled':
      return InvoiceStatus.cancelled;
    default:
      return fallback;
  }
}

/// =========================
/// SaleItem (Immutable + Safe)
/// =========================
@immutable
@immutable
class SaleItem {
  final String medicineId;
  final String name;
  final String? scientificName;
  final String? barcode;

  /// سعر وحدة البيع وقت الفاتورة: قطعة أو علبة
  final double unitPrice;

  /// تكلفة وحدة البيع وقت الفاتورة: قطعة أو علبة
  final double? unitCost;

  /// عدد الوحدات المباعة
  final int quantity;

  /// true = بيع بالقطعة | false = بيع بالعلبة
  final bool sellAsPiece;

  /// Snapshot من المخزون وقت البيع
  final int? unitsPerPackageSnapshot;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? supplierId;
  final String? supplierName;

  /// خصم بالنسبة المئوية 0 - 100
  final double? discountPercentage;

  /// خصم بمبلغ ثابت
  final double? discountAmount;

  const SaleItem({
    required this.medicineId,
    required this.name,
    this.scientificName,
    this.barcode,
    required this.unitPrice,
    this.unitCost,
    required this.quantity,
    required this.sellAsPiece,
    this.unitsPerPackageSnapshot,
    this.batchNumber,
    this.expiryDate,
    this.supplierId,
    this.supplierName,
    this.discountPercentage,
    this.discountAmount,
  });

  double get subtotal => unitPrice * quantity;

  double get discountValue {
    final sub = subtotal;
    if (sub <= 0) return 0.0;

    if (discountAmount != null) {
      return discountAmount!.clamp(0.0, sub);
    }

    if (discountPercentage != null) {
      return (sub * discountPercentage! / 100).clamp(0.0, sub);
    }

    return 0.0;
  }

  double get total => (subtotal - discountValue).clamp(0.0, double.infinity);

  /// تكلفة العنصر كامل
  double get totalCost => ((unitCost ?? 0.0) * quantity).clamp(0.0, double.infinity);

  /// ربح العنصر بعد الخصم
  double get grossProfit => (total - totalCost);

  /// هامش ربح العنصر
  double get grossMarginPercent {
    if (total <= 0) return 0.0;
    return (grossProfit / total) * 100;
  }

  String get displayName => sellAsPiece ? '$name (قطعة)' : name;

  SaleItem copyWith({
    String? medicineId,
    String? name,
    String? scientificName,
    String? barcode,
    double? unitPrice,
    double? unitCost,
    int? quantity,
    bool? sellAsPiece,
    int? unitsPerPackageSnapshot,
    String? batchNumber,
    DateTime? expiryDate,
    String? supplierId,
    String? supplierName,
    double? discountPercentage,
    double? discountAmount,
    bool clearDiscount = false,
    bool clearCost = false,
    bool clearBatch = false,
    bool clearSupplier = false,
  }) {
    return SaleItem(
      medicineId: medicineId ?? this.medicineId,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      barcode: barcode ?? this.barcode,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: clearCost ? null : (unitCost ?? this.unitCost),
      quantity: quantity ?? this.quantity,
      sellAsPiece: sellAsPiece ?? this.sellAsPiece,
      unitsPerPackageSnapshot:
      unitsPerPackageSnapshot ?? this.unitsPerPackageSnapshot,
      batchNumber: clearBatch ? null : (batchNumber ?? this.batchNumber),
      expiryDate: clearBatch ? null : (expiryDate ?? this.expiryDate),
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      discountPercentage:
      clearDiscount ? null : (discountPercentage ?? this.discountPercentage),
      discountAmount:
      clearDiscount ? null : (discountAmount ?? this.discountAmount),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'name': name,
      'scientificName': scientificName,
      'barcode': barcode,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'quantity': quantity,
      'sellAsPiece': sellAsPiece,
      'unitsPerPackageSnapshot': unitsPerPackageSnapshot,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'totalCost': totalCost,
      'grossProfit': grossProfit,
      'grossMarginPercent': grossMarginPercent,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    final unitPrice = _asDouble(map['unitPrice']);
    final quantity = _asInt(map['quantity'], fallback: 1);

    final dp = map['discountPercentage'];
    final da = map['discountAmount'];

    final discountPercentage = dp != null ? _asDouble(dp) : null;
    final discountAmount = da != null ? _asDouble(da) : null;

    final normalizedDiscountPercentage =
    discountAmount != null ? null : discountPercentage;

    return SaleItem(
      medicineId: (map['medicineId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      scientificName: _asString(map['scientificName']),
      barcode: _asString(map['barcode']),
      unitPrice: unitPrice,
      unitCost: map['unitCost'] == null ? null : _asDouble(map['unitCost']),
      quantity: quantity <= 0 ? 1 : quantity,
      sellAsPiece: (map['sellAsPiece'] ?? false) == true,
      unitsPerPackageSnapshot: map['unitsPerPackageSnapshot'] == null
          ? null
          : _asInt(map['unitsPerPackageSnapshot']),
      batchNumber: _asString(map['batchNumber']),
      expiryDate: map['expiryDate'] == null ? null : _parseDateTime(map['expiryDate']),
      supplierId: _asString(map['supplierId']),
      supplierName: _asString(map['supplierName']),
      discountPercentage: normalizedDiscountPercentage,
      discountAmount: discountAmount,
    );
  }
}

class Sale {
  String id;

  final String invoiceNumber;
  final String pharmacyId;

  final String? employeeId;
  final String? employeeName;

  final String? shiftId;

  final Map<String, dynamic>? performedBy;
  final String? performedById;
  final String? performedByName;

  final String? deviceId;

  final String source;
  final String? orderId;
  final String? orderNumber;

  final List<SaleItem> items;

  final double subtotal;

  /// خصم فاتورة بمبلغ ثابت
  final double? discount;

  /// مبلغ على شركة التأمين
  final double? insuranceDiscount;
  final String? insuranceCompanyId;
  final String? insuranceCompanyName;

  /// مبلغ الزبون بعد الخصم والتأمين
  final double total;

  final PaymentMethod paymentMethod;
  final String? paymentDetails;

  final String? customerName;
  final String? customerPhone;
  final String? notes;

  final DateTime saleDate;
  final DateTime createdAt;

  final bool isDeleted;

  final InvoiceStatus status;
  final bool isSaved;
  final DateTime? completedAt;

  final SaleType type;
  final String? refSaleId;
  final String? refInvoiceNumber;

  /// Money out في حالة الترجيع
  final double cashOut;
  final double cardOut;

  /// =========================
  /// Financial snapshot fields
  /// =========================

  /// إجمالي تكلفة البضاعة المباعة
  final double? cogsTotal;

  /// إجمالي الربح = صافي قيمة الأصناف - COGS
  final double? grossProfit;

  /// صافي الربح المبدئي قبل المصاريف العامة
  final double? netProfit;

  /// المبلغ المدفوع فعليًا من الزبون
  final double? paidAmount;

  /// المتبقي على الزبون إن وجد
  final double? remainingAmount;

  /// الداخل للكاش
  final double? cashIn;

  /// الداخل للبطاقة/المصرف
  final double? cardIn;

  /// مطالبة التأمين
  final double? insuranceClaimAmount;

  /// ربط لاحق مع financial_transactions
  final String? financialTransactionId;
  final bool financialPosted;
  final DateTime? postedAt;

  Sale({
    this.id = '',
    required this.invoiceNumber,
    required this.pharmacyId,
    this.employeeId,
    this.employeeName,
    this.shiftId,
    this.performedBy,
    this.performedById,
    this.performedByName,
    this.deviceId,
    this.source = 'pos',
    this.orderId,
    this.orderNumber,
    required this.items,
    required this.subtotal,
    this.discount,
    this.insuranceDiscount,
    this.insuranceCompanyId,
    this.insuranceCompanyName,
    required this.total,
    required this.paymentMethod,
    this.paymentDetails,
    this.customerName,
    this.customerPhone,
    this.notes,
    required this.saleDate,
    DateTime? createdAt,
    this.isDeleted = false,
    this.status = InvoiceStatus.pending,
    this.isSaved = false,
    this.completedAt,
    this.type = SaleType.sale,
    this.refSaleId,
    this.refInvoiceNumber,
    this.cashOut = 0.0,
    this.cardOut = 0.0,
    this.cogsTotal,
    this.grossProfit,
    this.netProfit,
    this.paidAmount,
    this.remainingAmount,
    this.cashIn,
    this.cardIn,
    this.insuranceClaimAmount,
    this.financialTransactionId,
    this.financialPosted = false,
    this.postedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Sale.empty({
    required String pharmacyId,
    required String? employeeId,
    required String? employeeName,
  }) {
    final now = DateTime.now();
    return Sale(
      invoiceNumber: Sale.generateInvoiceNumber(),
      pharmacyId: pharmacyId,
      employeeId: employeeId,
      employeeName: employeeName,
      source: 'pos',
      orderId: null,
      orderNumber: null,
      items: const [],
      subtotal: 0.0,
      total: 0.0,
      paymentMethod: PaymentMethod.cash,
      saleDate: now,
      createdAt: now,
      status: InvoiceStatus.pending,
      isSaved: false,
      type: SaleType.sale,
      refSaleId: null,
      refInvoiceNumber: null,
      cashOut: 0.0,
      cardOut: 0.0,
      cogsTotal: 0.0,
      grossProfit: 0.0,
      netProfit: 0.0,
      paidAmount: 0.0,
      remainingAmount: 0.0,
      cashIn: 0.0,
      cardIn: 0.0,
      insuranceClaimAmount: 0.0,
      financialPosted: false,
      financialTransactionId: null,
      postedAt: null,
    );
  }

  Sale recalculate() {
    final itemsSubtotal = items.fold(0.0, (sum, item) => sum + item.total);

    final computedCogs = items.fold(
      0.0,
          (sum, item) => sum + item.totalCost,
    );

    if (type == SaleType.refund) {
      final refundOut = (cashOut + cardOut).clamp(0.0, double.infinity);

      return copyWith(
        subtotal: itemsSubtotal,
        total: 0.0,
        discount: 0.0,
        clearInsurance: true,
        cogsTotal: computedCogs,
        grossProfit: -computedCogs,
        netProfit: -refundOut,
        paidAmount: 0.0,
        remainingAmount: 0.0,
        cashIn: 0.0,
        cardIn: 0.0,
        insuranceClaimAmount: 0.0,
      );
    }

    final invoiceDiscount = (discount ?? 0.0).clamp(0.0, itemsSubtotal);

    final remainingAfterInvoiceDiscount =
    (itemsSubtotal - invoiceDiscount).clamp(0.0, double.infinity);

    final companyBilled =
    (insuranceDiscount ?? 0.0).clamp(0.0, remainingAfterInvoiceDiscount);

    final computedCustomerTotal =
    (remainingAfterInvoiceDiscount - companyBilled)
        .clamp(0.0, double.infinity);

    final computedGrossProfit =
    (remainingAfterInvoiceDiscount - computedCogs);

    final computedPaidAmount = computedCustomerTotal;

    final computedCashIn =
    customerPaymentMethod == PaymentMethod.cash ? computedPaidAmount : 0.0;

    final computedCardIn =
    customerPaymentMethod == PaymentMethod.card ? computedPaidAmount : 0.0;

    return copyWith(
      subtotal: itemsSubtotal,
      total: computedCustomerTotal,
      cogsTotal: computedCogs,
      grossProfit: computedGrossProfit,
      netProfit: computedGrossProfit,
      paidAmount: computedPaidAmount,
      remainingAmount: 0.0,
      cashIn: computedCashIn,
      cardIn: computedCardIn,
      insuranceClaimAmount: companyBilled,
    );
  }

  bool get hasInsurance =>
      (insuranceCompanyId ?? '').trim().isNotEmpty &&
          (insuranceDiscount ?? 0) > 0;

  double get companyBilledAmount =>
      hasInsurance ? (insuranceDiscount ?? 0.0).clamp(0.0, double.infinity) : 0.0;

  double get customerPaidAmount =>
      type == SaleType.refund ? 0.0 : total.clamp(0.0, double.infinity);

  double get refundPaidOut =>
      type == SaleType.refund
          ? (cashOut + cardOut).clamp(0.0, double.infinity)
          : 0.0;

  PaymentMethod get customerPaymentMethod =>
      paymentMethod == PaymentMethod.insurance ? PaymentMethod.cash : paymentMethod;

  double get effectiveCogs =>
      cogsTotal ?? items.fold(0.0, (sum, item) => sum + item.totalCost);

  double get effectiveGrossProfit =>
      grossProfit ?? ((subtotal - (discount ?? 0.0)) - effectiveCogs);

  double get effectiveCashIn {
    if (type == SaleType.refund) return 0.0;
    if (cashIn != null) return cashIn!;
    return customerPaymentMethod == PaymentMethod.cash ? total : 0.0;
  }

  double get effectiveCardIn {
    if (type == SaleType.refund) return 0.0;
    if (cardIn != null) return cardIn!;
    return customerPaymentMethod == PaymentMethod.card ? total : 0.0;
  }

  Sale copyWith({
    String? id,
    String? invoiceNumber,
    String? pharmacyId,
    String? employeeId,
    String? employeeName,
    String? shiftId,
    Map<String, dynamic>? performedBy,
    String? performedById,
    String? performedByName,
    String? deviceId,
    String? source,
    String? orderId,
    String? orderNumber,
    List<SaleItem>? items,
    double? subtotal,
    double? discount,
    double? insuranceDiscount,
    String? insuranceCompanyId,
    String? insuranceCompanyName,
    double? total,
    PaymentMethod? paymentMethod,
    String? paymentDetails,
    String? customerName,
    String? customerPhone,
    String? notes,
    DateTime? saleDate,
    DateTime? createdAt,
    bool? isDeleted,
    InvoiceStatus? status,
    bool? isSaved,
    DateTime? completedAt,
    SaleType? type,
    String? refSaleId,
    String? refInvoiceNumber,
    double? cashOut,
    double? cardOut,
    double? cogsTotal,
    double? grossProfit,
    double? netProfit,
    double? paidAmount,
    double? remainingAmount,
    double? cashIn,
    double? cardIn,
    double? insuranceClaimAmount,
    String? financialTransactionId,
    bool? financialPosted,
    DateTime? postedAt,
    bool clearInsurance = false,
    bool clearPaymentDetails = false,
    bool clearCustomerName = false,
    bool clearCustomerPhone = false,
    bool clearNotes = false,
    bool clearFinancialLink = false,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      shiftId: shiftId ?? this.shiftId,
      performedBy: performedBy ?? this.performedBy,
      performedById: performedById ?? this.performedById,
      performedByName: performedByName ?? this.performedByName,
      deviceId: deviceId ?? this.deviceId,
      source: source ?? this.source,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? List<SaleItem>.from(this.items),
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      insuranceDiscount:
      clearInsurance ? null : (insuranceDiscount ?? this.insuranceDiscount),
      insuranceCompanyId:
      clearInsurance ? null : (insuranceCompanyId ?? this.insuranceCompanyId),
      insuranceCompanyName:
      clearInsurance ? null : (insuranceCompanyName ?? this.insuranceCompanyName),
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDetails:
      clearPaymentDetails ? null : (paymentDetails ?? this.paymentDetails),
      customerName: clearCustomerName ? null : (customerName ?? this.customerName),
      customerPhone: clearCustomerPhone ? null : (customerPhone ?? this.customerPhone),
      notes: clearNotes ? null : (notes ?? this.notes),
      saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      isSaved: isSaved ?? this.isSaved,
      completedAt: completedAt ?? this.completedAt,
      type: type ?? this.type,
      refSaleId: refSaleId ?? this.refSaleId,
      refInvoiceNumber: refInvoiceNumber ?? this.refInvoiceNumber,
      cashOut: cashOut ?? this.cashOut,
      cardOut: cardOut ?? this.cardOut,
      cogsTotal: cogsTotal ?? this.cogsTotal,
      grossProfit: grossProfit ?? this.grossProfit,
      netProfit: netProfit ?? this.netProfit,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      cashIn: cashIn ?? this.cashIn,
      cardIn: cardIn ?? this.cardIn,
      insuranceClaimAmount:
      insuranceClaimAmount ?? this.insuranceClaimAmount,
      financialTransactionId: clearFinancialLink
          ? null
          : (financialTransactionId ?? this.financialTransactionId),
      financialPosted: financialPosted ?? this.financialPosted,
      postedAt: clearFinancialLink ? null : (postedAt ?? this.postedAt),
    );
  }

  Sale addItem(SaleItem item) => copyWith(items: [...items, item]).recalculate();

  Sale updateItem(int index, SaleItem newItem) {
    if (index < 0 || index >= items.length) return this;
    final newItems = [...items];
    newItems[index] = newItem;
    return copyWith(items: newItems).recalculate();
  }

  Sale removeItemAt(int index) {
    if (index < 0 || index >= items.length) return this;
    final newItems = [...items]..removeAt(index);
    return copyWith(items: newItems).recalculate();
  }

  Map<String, dynamic> toMap() {
    final computed = recalculate();
    return {
      'invoiceNumber': computed.invoiceNumber,
      'pharmacyId': computed.pharmacyId,
      'employeeId': computed.employeeId,
      'employeeName': computed.employeeName,
      'shiftId': computed.shiftId,
      'performedBy': computed.performedBy,
      'performedById': computed.performedById,
      'performedByName': computed.performedByName,
      'deviceId': computed.deviceId,
      'source': computed.source,
      'orderId': computed.orderId,
      'orderNumber': computed.orderNumber,
      'items': computed.items.map((e) => e.toMap()).toList(),
      'subtotal': computed.subtotal,
      'discount': computed.discount,
      'insuranceDiscount': computed.insuranceDiscount,
      'insuranceCompanyId': computed.insuranceCompanyId,
      'insuranceCompanyName': computed.insuranceCompanyName,
      'total': computed.total,
      'paymentMethod': computed.paymentMethod.name,
      'paymentDetails': computed.paymentDetails,
      'customerName': computed.customerName,
      'customerPhone': computed.customerPhone,
      'notes': computed.notes,
      'saleDate': Timestamp.fromDate(computed.saleDate),
      'createdAt': Timestamp.fromDate(computed.createdAt),
      'completedAt':
      computed.completedAt != null ? Timestamp.fromDate(computed.completedAt!) : null,
      'status': computed.status.name,
      'isSaved': computed.isSaved,
      'isDeleted': computed.isDeleted,
      'type': computed.type.name,
      'refSaleId': computed.refSaleId,
      'refInvoiceNumber': computed.refInvoiceNumber,
      'cashOut': computed.cashOut,
      'cardOut': computed.cardOut,

      // Financial snapshot
      'cogsTotal': computed.cogsTotal,
      'grossProfit': computed.grossProfit,
      'netProfit': computed.netProfit,
      'paidAmount': computed.paidAmount,
      'remainingAmount': computed.remainingAmount,
      'cashIn': computed.cashIn,
      'cardIn': computed.cardIn,
      'insuranceClaimAmount': computed.insuranceClaimAmount,
      'financialTransactionId': computed.financialTransactionId,
      'financialPosted': computed.financialPosted,
      'postedAt':
      computed.postedAt != null ? Timestamp.fromDate(computed.postedAt!) : null,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final itemsList = (rawItems is List)
        ? rawItems
        .whereType<Map>()
        .map((e) => SaleItem.fromMap(Map<String, dynamic>.from(e)))
        .toList()
        : <SaleItem>[];

    final status = map.containsKey('status')
        ? _statusFromString(map['status'])
        : InvoiceStatus.completed;

    final isSaved = map.containsKey('isSaved') ? (map['isSaved'] == true) : true;

    final saleDate = _parseDateTime(map['saleDate']);
    final createdAt = _parseDateTime(map['createdAt'], fallback: saleDate);

    DateTime? completedAt;
    if (map['completedAt'] != null) {
      completedAt = _parseDateTime(map['completedAt']);
    } else if (status == InvoiceStatus.completed) {
      completedAt = saleDate;
    }

    Map<String, dynamic>? performedBy;
    if (map['performedBy'] is Map) {
      performedBy = Map<String, dynamic>.from(map['performedBy']);
    }

    final sale = Sale(
      id: (map['id'] ?? '').toString(),
      invoiceNumber: (map['invoiceNumber'] ?? '').toString(),
      pharmacyId: (map['pharmacyId'] ?? '').toString(),
      employeeId: _asString(map['employeeId']),
      employeeName: _asString(map['employeeName']),
      shiftId: _asString(map['shiftId']),
      performedBy: performedBy,
      performedById:
      _asString(map['performedById']) ?? _asString(performedBy?['id']),
      performedByName: _asString(map['performedByName']) ??
          _asString(performedBy?['name']) ??
          _asString(performedBy?['username']),
      deviceId: _asString(map['deviceId']),
      source: _asString(map['source']) ?? 'pos',
      orderId: _asString(map['orderId']),
      orderNumber: _asString(map['orderNumber']),
      items: itemsList,
      subtotal: _asDouble(map['subtotal']),
      discount: map['discount'] == null ? null : _asDouble(map['discount']),
      insuranceDiscount:
      map['insuranceDiscount'] == null ? null : _asDouble(map['insuranceDiscount']),
      insuranceCompanyId: _asString(map['insuranceCompanyId']),
      insuranceCompanyName: _asString(map['insuranceCompanyName']),
      total: _asDouble(map['total']),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod']),
      paymentDetails: _asString(map['paymentDetails']),
      customerName: _asString(map['customerName']),
      customerPhone: _asString(map['customerPhone']),
      notes: _asString(map['notes']),
      saleDate: saleDate,
      createdAt: createdAt,
      isDeleted: map['isDeleted'] == true,
      status: status,
      isSaved: isSaved,
      completedAt: completedAt,
      type: _saleTypeFromString(map['type']),
      refSaleId: _asString(map['refSaleId']),
      refInvoiceNumber: _asString(map['refInvoiceNumber']),
      cashOut: _asDouble(map['cashOut']),
      cardOut: _asDouble(map['cardOut']),

      cogsTotal: map['cogsTotal'] == null ? null : _asDouble(map['cogsTotal']),
      grossProfit:
      map['grossProfit'] == null ? null : _asDouble(map['grossProfit']),
      netProfit: map['netProfit'] == null ? null : _asDouble(map['netProfit']),
      paidAmount:
      map['paidAmount'] == null ? null : _asDouble(map['paidAmount']),
      remainingAmount: map['remainingAmount'] == null
          ? null
          : _asDouble(map['remainingAmount']),
      cashIn: map['cashIn'] == null ? null : _asDouble(map['cashIn']),
      cardIn: map['cardIn'] == null ? null : _asDouble(map['cardIn']),
      insuranceClaimAmount: map['insuranceClaimAmount'] == null
          ? null
          : _asDouble(map['insuranceClaimAmount']),
      financialTransactionId: _asString(map['financialTransactionId']),
      financialPosted: map['financialPosted'] == true,
      postedAt: map['postedAt'] == null ? null : _parseDateTime(map['postedAt']),
    );

    return sale.recalculate();
  }

  Map<String, dynamic> toLocalMap() {
    final computed = recalculate();
    return {
      'id': computed.id,
      'invoiceNumber': computed.invoiceNumber,
      'pharmacyId': computed.pharmacyId,
      'employeeId': computed.employeeId,
      'employeeName': computed.employeeName,
      'shiftId': computed.shiftId,
      'performedBy': computed.performedBy,
      'performedById': computed.performedById,
      'performedByName': computed.performedByName,
      'deviceId': computed.deviceId,
      'source': computed.source,
      'orderId': computed.orderId,
      'orderNumber': computed.orderNumber,
      'items': computed.items.map((e) => e.toMap()).toList(),
      'subtotal': computed.subtotal,
      'discount': computed.discount,
      'insuranceDiscount': computed.insuranceDiscount,
      'insuranceCompanyId': computed.insuranceCompanyId,
      'insuranceCompanyName': computed.insuranceCompanyName,
      'total': computed.total,
      'paymentMethod': computed.paymentMethod.name,
      'paymentDetails': computed.paymentDetails,
      'customerName': computed.customerName,
      'customerPhone': computed.customerPhone,
      'notes': computed.notes,
      'saleDate': computed.saleDate.toIso8601String(),
      'createdAt': computed.createdAt.toIso8601String(),
      'completedAt': computed.completedAt?.toIso8601String(),
      'status': computed.status.name,
      'isSaved': computed.isSaved,
      'isDeleted': computed.isDeleted,
      'type': computed.type.name,
      'refSaleId': computed.refSaleId,
      'refInvoiceNumber': computed.refInvoiceNumber,
      'cashOut': computed.cashOut,
      'cardOut': computed.cardOut,

      // Financial snapshot
      'cogsTotal': computed.cogsTotal,
      'grossProfit': computed.grossProfit,
      'netProfit': computed.netProfit,
      'paidAmount': computed.paidAmount,
      'remainingAmount': computed.remainingAmount,
      'cashIn': computed.cashIn,
      'cardIn': computed.cardIn,
      'insuranceClaimAmount': computed.insuranceClaimAmount,
      'financialTransactionId': computed.financialTransactionId,
      'financialPosted': computed.financialPosted,
      'postedAt': computed.postedAt?.toIso8601String(),
    };
  }

  factory Sale.fromLocalMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final itemsList = (rawItems is List)
        ? rawItems
        .whereType<Map>()
        .map((e) => SaleItem.fromMap(Map<String, dynamic>.from(e)))
        .toList()
        : <SaleItem>[];

    final status =
    _statusFromString(map['status'], fallback: InvoiceStatus.pending);

    final saleDate = _parseDateTime(map['saleDate']);
    final createdAt = _parseDateTime(map['createdAt'], fallback: saleDate);

    DateTime? completedAt;
    if (map['completedAt'] != null) {
      completedAt = _parseDateTime(map['completedAt']);
    } else if (status == InvoiceStatus.completed) {
      completedAt = saleDate;
    }

    Map<String, dynamic>? performedBy;
    if (map['performedBy'] is Map) {
      performedBy = Map<String, dynamic>.from(map['performedBy']);
    }

    final sale = Sale(
      id: (map['id'] ?? '').toString(),
      invoiceNumber: (map['invoiceNumber'] ?? '').toString(),
      pharmacyId: (map['pharmacyId'] ?? '').toString(),
      employeeId: _asString(map['employeeId']),
      employeeName: _asString(map['employeeName']),
      shiftId: _asString(map['shiftId']),
      performedBy: performedBy,
      performedById:
      _asString(map['performedById']) ?? _asString(performedBy?['id']),
      performedByName: _asString(map['performedByName']) ??
          _asString(performedBy?['name']) ??
          _asString(performedBy?['username']),
      deviceId: _asString(map['deviceId']),
      source: _asString(map['source']) ?? 'pos',
      orderId: _asString(map['orderId']),
      orderNumber: _asString(map['orderNumber']),
      items: itemsList,
      subtotal: _asDouble(map['subtotal']),
      discount: map['discount'] == null ? null : _asDouble(map['discount']),
      insuranceDiscount:
      map['insuranceDiscount'] == null ? null : _asDouble(map['insuranceDiscount']),
      insuranceCompanyId: _asString(map['insuranceCompanyId']),
      insuranceCompanyName: _asString(map['insuranceCompanyName']),
      total: _asDouble(map['total']),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod']),
      paymentDetails: _asString(map['paymentDetails']),
      customerName: _asString(map['customerName']),
      customerPhone: _asString(map['customerPhone']),
      notes: _asString(map['notes']),
      saleDate: saleDate,
      createdAt: createdAt,
      isDeleted: map['isDeleted'] == true,
      status: status,
      isSaved: map['isSaved'] == true,
      completedAt: completedAt,
      type: _saleTypeFromString(map['type']),
      refSaleId: _asString(map['refSaleId']),
      refInvoiceNumber: _asString(map['refInvoiceNumber']),
      cashOut: _asDouble(map['cashOut']),
      cardOut: _asDouble(map['cardOut']),

      cogsTotal: map['cogsTotal'] == null ? null : _asDouble(map['cogsTotal']),
      grossProfit:
      map['grossProfit'] == null ? null : _asDouble(map['grossProfit']),
      netProfit: map['netProfit'] == null ? null : _asDouble(map['netProfit']),
      paidAmount:
      map['paidAmount'] == null ? null : _asDouble(map['paidAmount']),
      remainingAmount: map['remainingAmount'] == null
          ? null
          : _asDouble(map['remainingAmount']),
      cashIn: map['cashIn'] == null ? null : _asDouble(map['cashIn']),
      cardIn: map['cardIn'] == null ? null : _asDouble(map['cardIn']),
      insuranceClaimAmount: map['insuranceClaimAmount'] == null
          ? null
          : _asDouble(map['insuranceClaimAmount']),
      financialTransactionId: _asString(map['financialTransactionId']),
      financialPosted: map['financialPosted'] == true,
      postedAt: map['postedAt'] == null ? null : _parseDateTime(map['postedAt']),
    );

    return sale.recalculate();
  }

  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final y = now.year.toString().substring(2);
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');

    final rand =
    (now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    return 'INV-$y$m$d-$rand';
  }

  String get invoiceSummary =>
      'فاتورة #$invoiceNumber - ${items.length} أصناف - إجمالي الزبون: ${total.toStringAsFixed(2)}';

  String get paymentStatus => customerPaymentMethod.arabicName;
}