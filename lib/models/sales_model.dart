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

/// ✅ PaymentMethod هنا معناها "طريقة دفع الزبون" فقط
/// insurance موجود فقط للتوافق مع الداتا القديمة (Legacy)
enum PaymentMethod {
  cash('نقدي'),
  card('بطاقة'),
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
class SaleItem {
  final String medicineId;
  final String name;
  final String? scientificName;
  final String? barcode;

  /// سعر وحدة البيع (قطعة أو علبة)
  final double unitPrice;

  /// عدد الوحدات المباعة
  final int quantity;

  /// true = بيع بالقطعة | false = بيع بالعلبة
  final bool sellAsPiece;

  /// خصم بالنسبة المئوية (0 - 100)
  final double? discountPercentage;

  /// خصم بمبلغ ثابت
  final double? discountAmount;

  const SaleItem({
    required this.medicineId,
    required this.name,
    this.scientificName,
    this.barcode,
    required this.unitPrice,
    required this.quantity,
    required this.sellAsPiece,
    this.discountPercentage,
    this.discountAmount,
  });

  double get subtotal => unitPrice * quantity;

  double get discountValue {
    final sub = subtotal;
    if (sub <= 0) return 0.0;

    if (discountAmount != null) {
      return discountAmount!.clamp(0, sub);
    }
    if (discountPercentage != null) {
      return (sub * discountPercentage! / 100).clamp(0, sub);
    }
    return 0.0;
  }

  double get total => (subtotal - discountValue).clamp(0, double.infinity);

  String get displayName => sellAsPiece ? '$name (قطعة)' : name;

  SaleItem copyWith({
    String? medicineId,
    String? name,
    String? scientificName,
    String? barcode,
    double? unitPrice,
    int? quantity,
    bool? sellAsPiece,
    double? discountPercentage,
    double? discountAmount,
    bool clearDiscount = false,
  }) {
    return SaleItem(
      medicineId: medicineId ?? this.medicineId,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      barcode: barcode ?? this.barcode,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      sellAsPiece: sellAsPiece ?? this.sellAsPiece,
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
      'quantity': quantity,
      'sellAsPiece': sellAsPiece,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
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
    (discountAmount != null) ? null : discountPercentage;

    return SaleItem(
      medicineId: (map['medicineId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      scientificName: _asString(map['scientificName']),
      barcode: _asString(map['barcode']),
      unitPrice: unitPrice,
      quantity: quantity <= 0 ? 1 : quantity,
      sellAsPiece: (map['sellAsPiece'] ?? false) == true,
      discountPercentage: normalizedDiscountPercentage,
      discountAmount: discountAmount,
    );
  }
}

/// =========================
/// Sale (Invoice)
/// =========================
/// ✅ التأمين هنا يمثل "جزء على الشركة" في insuranceDiscount
/// ✅ total هنا يمثل "اللي يدفعه الزبون فعلاً"
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

  final List<SaleItem> items;

  final double subtotal;

  /// خصم فاتورة (مبلغ ثابت)
  final double? discount;

  /// ✅ insuranceDiscount = مبلغ على الشركة (Company billed)
  final double? insuranceDiscount;
  final String? insuranceCompanyId;
  final String? insuranceCompanyName;

  /// ✅ total = مبلغ الزبون بعد الخصومات وبعد جزء الشركة
  final double total;

  /// ✅ طريقة دفع الزبون فقط (cash/card)
  /// insurance legacy فقط
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
      items: const [],
      subtotal: 0.0,
      total: 0.0,
      paymentMethod: PaymentMethod.cash,
      saleDate: now,
      createdAt: now,
      status: InvoiceStatus.pending,
      isSaved: false,
    );
  }

  /// =========================
  /// Calculations (Pure)
  /// =========================
  Sale recalculate() {
    final itemsSubtotal = items.fold(0.0, (sum, item) => sum + item.total);

    final invoiceDiscount = (discount ?? 0.0).clamp(0.0, itemsSubtotal);
    final remainingAfterInvoiceDiscount =
    (itemsSubtotal - invoiceDiscount).clamp(0.0, double.infinity);

    final companyBilled =
    (insuranceDiscount ?? 0.0).clamp(0.0, remainingAfterInvoiceDiscount);

    final computedCustomerTotal =
    (remainingAfterInvoiceDiscount - companyBilled).clamp(0.0, double.infinity);

    return copyWith(
      subtotal: itemsSubtotal,
      total: computedCustomerTotal,
    );
  }

  /// =========================
  /// Convenience getters
  /// =========================
  bool get hasInsurance =>
      (insuranceCompanyId ?? '').trim().isNotEmpty && (insuranceDiscount ?? 0) > 0;

  double get companyBilledAmount =>
      hasInsurance ? (insuranceDiscount ?? 0.0).clamp(0.0, double.infinity) : 0.0;

  double get customerPaidAmount => total.clamp(0.0, double.infinity);

  /// ✅ طريقة دفع الزبون (مع Back-compat)
  PaymentMethod get customerPaymentMethod =>
      paymentMethod == PaymentMethod.insurance ? PaymentMethod.cash : paymentMethod;

  /// =========================
  /// CopyWith (Deep)
  /// =========================
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
      items: items ?? List<SaleItem>.from(this.items),
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      insuranceDiscount: insuranceDiscount ?? this.insuranceDiscount,
      insuranceCompanyId: insuranceCompanyId ?? this.insuranceCompanyId,
      insuranceCompanyName: insuranceCompanyName ?? this.insuranceCompanyName,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      isSaved: isSaved ?? this.isSaved,
      completedAt: completedAt ?? this.completedAt,
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

  /// =========================
  /// Serialization (Firebase)
  /// =========================
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
      'completedAt': computed.completedAt != null
          ? Timestamp.fromDate(computed.completedAt!)
          : null,
      'status': computed.status.name,
      'isSaved': computed.isSaved,
      'isDeleted': computed.isDeleted,
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
      performedById: _asString(map['performedById']) ?? _asString(performedBy?['id']),
      performedByName: _asString(map['performedByName']) ??
          _asString(performedBy?['name']) ??
          _asString(performedBy?['username']),
      deviceId: _asString(map['deviceId']),
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
    );

    return sale.recalculate();
  }

  /// =========================
  /// Local (SharedPreferences / JSON safe)
  /// =========================
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

    final status = _statusFromString(map['status'], fallback: InvoiceStatus.pending);

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
      performedById: _asString(map['performedById']) ?? _asString(performedBy?['id']),
      performedByName: _asString(map['performedByName']) ??
          _asString(performedBy?['name']) ??
          _asString(performedBy?['username']),
      deviceId: _asString(map['deviceId']),
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