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

  // التواريخ
  final DateTime invoiceDate;
  final DateTime? receivedDate;

  // الحالة المالية
  final double subtotal;
  final double discount;
  final double total;
  final double paid;
  final PaymentStatus paymentStatus;
  final DateTime? dueDate;

  // معلومات إضافية
  final String? notes;
  final String? referenceNumber; // رقم الفاتورة من المورد
  final String createdBy;
  final DateTime createdAt;

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
    this.notes,
    this.referenceNumber,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // حسابات مفيدة
  double get remaining => total - paid;
  bool get isFullyPaid => remaining <= 0;
  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

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
    String? notes,
    String? referenceNumber,
    String? createdBy,
    DateTime? createdAt,
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
      notes: notes ?? this.notes,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((e) => e.toMap()).toList(),
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'receivedDate': receivedDate != null ? Timestamp.fromDate(receivedDate!) : null,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paid': paid,
      'paymentStatus': paymentStatus.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notes': notes,
      'referenceNumber': referenceNumber,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PurchaseInvoice.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseInvoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      invoiceDate: (map['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receivedDate: (map['receivedDate'] as Timestamp?)?.toDate(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      paid: (map['paid'] ?? 0.0).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == (map['paymentStatus'] ?? 'unpaid'),
        orElse: () => PaymentStatus.unpaid,
      ),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      referenceNumber: map['referenceNumber'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class PurchaseItem {
  final String medicineId;
  final String medicineName;
  final int quantity;
  final double price;        // سعر الشراء للوحدة
  final DateTime? expiryDate;
  final String? batchNumber;

  PurchaseItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.price,
    this.expiryDate,
    this.batchNumber,
  });

  double get subtotal => price * quantity;

  PurchaseItem copyWith({
    String? medicineId,
    String? medicineName,
    int? quantity,
    double? price,
    DateTime? expiryDate,
    String? batchNumber,
  }) {
    return PurchaseItem(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'price': price,
      'expiryDate': expiryDate?.toIso8601String(),
      'batchNumber': batchNumber,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      price: (map['price'] ?? 0.0).toDouble(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'].toString())
          : null,
      batchNumber: map['batchNumber']?.toString(),
    );
  }
}