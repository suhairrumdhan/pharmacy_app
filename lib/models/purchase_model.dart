import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  unpaid,        // غير مدفوع
  partiallyPaid, // مدفوع جزئياً
  paid           // مدفوع بالكامل
}

class PurchaseInvoice {
  final String id;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final List<PurchaseItem> items;

  final DateTime invoiceDate;
  final DateTime? receivedDate;

  final double subtotal;
  final double discount;
  final double total;
  final double paid;
  final PaymentStatus paymentStatus;
  final DateTime? dueDate;

  /// =========================
  /// Financial fields - new
  /// =========================
  final String? status; // draft / received / cancelled
  final String? paymentMethod; // cash / card / bank / mixed
  final double? cashPaid;
  final double? bankPaid;
  final double? remainingAmount;

  final String? financialTransactionId;
  final bool financialPosted;
  final DateTime? postedAt;

  final String? notes;
  final String? referenceNumber;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PurchaseInvoice({
    this.id = '',
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.invoiceDate,
    this.receivedDate,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.paid = 0.0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.dueDate,
    this.status = 'received',
    this.paymentMethod,
    this.cashPaid,
    this.bankPaid,
    this.remainingAmount,
    this.financialTransactionId,
    this.financialPosted = false,
    this.postedAt,
    this.notes,
    this.referenceNumber,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remaining {
    final value = remainingAmount ?? (total - paid);
    return value.clamp(0.0, double.infinity);
  }

  bool get isFullyPaid => remaining <= 0;
  bool get isOverdue =>
      remaining > 0 && dueDate != null && dueDate!.isBefore(DateTime.now());

  int get totalItems => items.length;

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get safeSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get effectiveTotal {
    final computed = (safeSubtotal - discount).clamp(0.0, double.infinity);
    return total > 0 ? total : computed;
  }

  double get effectiveCashPaid {
    if (cashPaid != null) return cashPaid!;
    if ((paymentMethod ?? '').toLowerCase() == 'cash') return paid;
    return 0.0;
  }

  double get effectiveBankPaid {
    if (bankPaid != null) return bankPaid!;
    final method = (paymentMethod ?? '').toLowerCase();
    if (method == 'card' || method == 'bank' || method == 'transfer') {
      return paid;
    }
    return 0.0;
  }

  PurchaseInvoice recalculate() {
    final computedSubtotal =
    items.fold(0.0, (sum, item) => sum + item.subtotal);

    final safeDiscount = discount.clamp(0.0, computedSubtotal);

    final computedTotal =
    (computedSubtotal - safeDiscount).clamp(0.0, double.infinity);

    final safePaid = paid.clamp(0.0, computedTotal);

    PaymentStatus computedStatus;
    if (safePaid >= computedTotal && computedTotal > 0) {
      computedStatus = PaymentStatus.paid;
    } else if (safePaid > 0) {
      computedStatus = PaymentStatus.partiallyPaid;
    } else {
      computedStatus = PaymentStatus.unpaid;
    }

    return copyWith(
      subtotal: computedSubtotal,
      total: computedTotal,
      paid: safePaid,
      paymentStatus: computedStatus,
      remainingAmount: (computedTotal - safePaid).clamp(0.0, double.infinity),
    );
  }

  PurchaseInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? supplierId,
    String? supplierName,
    List<PurchaseItem>? items,
    DateTime? invoiceDate,
    DateTime? receivedDate,
    double? subtotal,
    double? discount,
    double? total,
    double? paid,
    PaymentStatus? paymentStatus,
    DateTime? dueDate,
    String? status,
    String? paymentMethod,
    double? cashPaid,
    double? bankPaid,
    double? remainingAmount,
    String? financialTransactionId,
    bool? financialPosted,
    DateTime? postedAt,
    String? notes,
    String? referenceNumber,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearFinancialLink = false,
    bool clearPaymentMethod = false,
    bool clearNotes = false,
    bool clearReferenceNumber = false,
  }) {
    return PurchaseInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      receivedDate: receivedDate ?? this.receivedDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentMethod:
      clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      cashPaid: cashPaid ?? this.cashPaid,
      bankPaid: bankPaid ?? this.bankPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      financialTransactionId: clearFinancialLink
          ? null
          : (financialTransactionId ?? this.financialTransactionId),
      financialPosted: financialPosted ?? this.financialPosted,
      postedAt: clearFinancialLink ? null : (postedAt ?? this.postedAt),
      notes: clearNotes ? null : (notes ?? this.notes),
      referenceNumber:
      clearReferenceNumber ? null : (referenceNumber ?? this.referenceNumber),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final computed = recalculate();

    return {
      'invoiceNumber': computed.invoiceNumber,
      'supplierId': computed.supplierId,
      'supplierName': computed.supplierName,
      'items': computed.items.map((e) => e.toMap()).toList(),
      'invoiceDate': Timestamp.fromDate(computed.invoiceDate),
      'receivedDate': computed.receivedDate != null
          ? Timestamp.fromDate(computed.receivedDate!)
          : null,
      'subtotal': computed.subtotal,
      'discount': computed.discount,
      'total': computed.total,
      'paid': computed.paid,
      'paymentStatus': computed.paymentStatus.name,
      'dueDate': computed.dueDate != null
          ? Timestamp.fromDate(computed.dueDate!)
          : null,

      // New financial fields
      'status': computed.status,
      'paymentMethod': computed.paymentMethod,
      'cashPaid': computed.cashPaid,
      'bankPaid': computed.bankPaid,
      'remainingAmount': computed.remainingAmount,
      'financialTransactionId': computed.financialTransactionId,
      'financialPosted': computed.financialPosted,
      'postedAt': computed.postedAt != null
          ? Timestamp.fromDate(computed.postedAt!)
          : null,

      'notes': computed.notes,
      'referenceNumber': computed.referenceNumber,
      'createdBy': computed.createdBy,
      'createdAt': Timestamp.fromDate(computed.createdAt),
      'updatedAt': computed.updatedAt != null
          ? Timestamp.fromDate(computed.updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory PurchaseInvoice.fromMap(Map<String, dynamic> map, String id) {
    // دالة مساعدة لتحويل أي نوع تاريخ إلى DateTime
    DateTime? _toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return PurchaseInvoice(
      id: id,
      invoiceNumber: map['invoiceNumber']?.toString() ?? '',
      supplierId: map['supplierId']?.toString() ?? '',
      supplierName: map['supplierName']?.toString() ?? '',
      items: (map['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => PurchaseItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      invoiceDate: _toDateTime(map['invoiceDate']) ?? DateTime.now(),
      receivedDate: _toDateTime(map['receivedDate']),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paid: (map['paid'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == (map['paymentStatus'] ?? 'unpaid'),
        orElse: () => PaymentStatus.unpaid,
      ),
      dueDate: _toDateTime(map['dueDate']),
      status: map['status']?.toString() ?? 'received',
      paymentMethod: map['paymentMethod']?.toString(),
      cashPaid: (map['cashPaid'] as num?)?.toDouble(),
      bankPaid: (map['bankPaid'] as num?)?.toDouble(),
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble(),
      financialTransactionId: map['financialTransactionId']?.toString(),
      financialPosted: map['financialPosted'] == true,
      postedAt: _toDateTime(map['postedAt']),
      notes: map['notes']?.toString(),
      referenceNumber: map['referenceNumber']?.toString(),
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }


}


class PurchaseItem {
  final String medicineId;
  final String medicineName;

  /// الكمية المشتراة
  final int quantity;

  /// سعر شراء الوحدة
  final double price;

  final DateTime? expiryDate;
  final String? batchNumber;

  /// =========================
  /// New financial / inventory snapshot fields
  /// =========================

  /// سعر البيع وقت الشراء للمقارنة والربحية
  final double? sellingPriceSnapshot;

  /// تكلفة القطعة الواحدة لو الدواء يباع بالقطعة
  final double? pieceCost;

  /// عدد القطع داخل العبوة
  final int? unitsPerPackage;

  /// كمية مجانية من المورد
  final int? freeQuantity;

  /// خصم على هذا الصنف فقط
  final double? itemDiscount;

  /// ربط مباشر بالمورد
  final String? supplierId;
  final String? supplierName;

  PurchaseItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.price,
    this.expiryDate,
    this.batchNumber,
    this.sellingPriceSnapshot,
    this.pieceCost,
    this.unitsPerPackage,
    this.freeQuantity,
    this.itemDiscount,
    this.supplierId,
    this.supplierName,
  });

  int get totalQuantityWithFree => quantity + (freeQuantity ?? 0);

  double get grossSubtotal => price * quantity;

  double get discountValue {
    final discount = itemDiscount ?? 0.0;
    return discount.clamp(0.0, grossSubtotal);
  }

  double get subtotal => (grossSubtotal - discountValue).clamp(0.0, double.infinity);

  double get effectiveUnitCost {
    final totalQty = totalQuantityWithFree;
    if (totalQty <= 0) return price;
    return subtotal / totalQty;
  }

  double get effectivePieceCost {
    if (pieceCost != null && pieceCost! > 0) return pieceCost!;
    final units = unitsPerPackage ?? 0;
    if (units <= 0) return 0.0;
    return effectiveUnitCost / units;
  }

  PurchaseItem copyWith({
    String? medicineId,
    String? medicineName,
    int? quantity,
    double? price,
    DateTime? expiryDate,
    String? batchNumber,
    double? sellingPriceSnapshot,
    double? pieceCost,
    int? unitsPerPackage,
    int? freeQuantity,
    double? itemDiscount,
    String? supplierId,
    String? supplierName,
    bool clearExpiryDate = false,
    bool clearBatchNumber = false,
    bool clearSupplier = false,
  }) {
    return PurchaseItem(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      batchNumber: clearBatchNumber ? null : (batchNumber ?? this.batchNumber),
      sellingPriceSnapshot: sellingPriceSnapshot ?? this.sellingPriceSnapshot,
      pieceCost: pieceCost ?? this.pieceCost,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'price': price,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'batchNumber': batchNumber,

      // New fields
      'sellingPriceSnapshot': sellingPriceSnapshot,
      'pieceCost': pieceCost,
      'unitsPerPackage': unitsPerPackage,
      'freeQuantity': freeQuantity,
      'itemDiscount': itemDiscount,
      'supplierId': supplierId,
      'supplierName': supplierName,

      // Calculated snapshot
      'grossSubtotal': grossSubtotal,
      'discountValue': discountValue,
      'subtotal': subtotal,
      'effectiveUnitCost': effectiveUnitCost,
      'effectivePieceCost': effectivePieceCost,
      'totalQuantityWithFree': totalQuantityWithFree,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    // دالة مساعدة لتحويل أي نوع تاريخ إلى DateTime
    DateTime? _toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return PurchaseItem(
      medicineId: map['medicineId']?.toString() ?? '',
      medicineName: map['medicineName']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      expiryDate: _toDateTime(map['expiryDate']), // ✅ تعديل هنا
      batchNumber: map['batchNumber']?.toString(),
      sellingPriceSnapshot: (map['sellingPriceSnapshot'] as num?)?.toDouble(),
      pieceCost: (map['pieceCost'] as num?)?.toDouble(),
      unitsPerPackage: (map['unitsPerPackage'] as num?)?.toInt(),
      freeQuantity: (map['freeQuantity'] as num?)?.toInt(),
      itemDiscount: (map['itemDiscount'] as num?)?.toDouble(),
      supplierId: map['supplierId']?.toString(),
      supplierName: map['supplierName']?.toString(),
    );
  }

}