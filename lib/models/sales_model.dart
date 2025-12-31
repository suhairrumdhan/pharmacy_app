// lib/models/sales_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SaleItem {
  String medicineId;
  String name;
  String? scientificName;
  String? barcode;
  double unitPrice; // السعر الفعلي للوحدة أو القطعة
  int quantity;
  double? discountPercentage;
  double? discountAmount;
  bool sellAsPiece; // true لو البيع بالقطعة، false لو بالعلبة
  double total;

  SaleItem({
    required this.medicineId,
    required this.name,
    this.scientificName,
    this.barcode,
    required this.unitPrice,
    required this.quantity,
    this.discountPercentage,
    this.discountAmount,
    required this.sellAsPiece, // لازم تحدد عند الإنشاء
    required this.total,
  }){
    calculateTotal(); // احسب المجموع مباشرة عند الإنشاء
  }

  void calculateTotal() {
    total = unitPrice * quantity;
    if (discountAmount != null) total -= discountAmount!;
    else if (discountPercentage != null) {
      total -= unitPrice * quantity * discountPercentage! / 100;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'name': name,
      'scientificName': scientificName,
      'barcode': barcode,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'sellAsPiece': sellAsPiece,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      medicineId: map['medicineId'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'],
      barcode: map['barcode'],
      unitPrice: (map['unitPrice'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      sellAsPiece: map['sellAsPiece'] ?? false,
      total: (map['total'] as num).toDouble(),
    );
  }
}

enum PaymentMethod {
  cash('نقدي'),
  card('بطاقة'),
  insurance('تأمين');

  final String arabicName;
  const PaymentMethod(this.arabicName);

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash': return PaymentMethod.cash;
      case 'card': return PaymentMethod.card;
      case 'insurance': return PaymentMethod.insurance;
      default: return PaymentMethod.cash;
    }
  }
}

class Sale {
  String id;
  String invoiceNumber;
  String pharmacyId;
  String? employeeId;
  String? employeeName;
  List<SaleItem> items;
  double subtotal;
  double? discount;
  double? insuranceDiscount;
  String? insuranceCompanyId;
  String? insuranceCompanyName;
  double total;
  PaymentMethod paymentMethod;
  String? paymentDetails;
  String? customerName;
  String? customerPhone;
  String? notes;
  DateTime saleDate;
  DateTime createdAt;
  bool isDeleted;

  Sale({
    this.id = '',
    required this.invoiceNumber,
    required this.pharmacyId,
    this.employeeId,
    this.employeeName,
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
  }) : createdAt = createdAt ?? DateTime.now();

  // حساب المبلغ الإجمالي
  void calculateTotal() {
    subtotal = items.fold(0.0, (sum, item) => sum + item.total);

    // تطبيق الخصم (إذا وجد)
    double discountAmount = discount ?? 0.0;

    // تطبيق خصم التأمين (إذا وجد)
    double insuranceAmount = insuranceDiscount ?? 0.0;

    total = subtotal - discountAmount - insuranceAmount;
    if (total < 0) total = 0;
  }

  // إضافة صنف جديد
  void addItem(SaleItem item) {
    items.add(item);
    calculateTotal();
  }

  // تحديث كمية صنف
  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < items.length) {
      final item = items[index];
      item.quantity = quantity;
      final effectivePrice = item.sellAsPiece ? item.unitPrice / item.quantity : item.unitPrice; // لو عندك piecePrice, استعمليها
      item.total = effectivePrice * quantity;

      if (item.discountAmount != null) {
        item.total -= item.discountAmount!;
      } else if (item.discountPercentage != null) {
        item.total -= effectivePrice * quantity * item.discountPercentage! / 100;
      }
      calculateTotal();
    }
  }

  // حذف صنف
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      calculateTotal();
    }
  }

  Map<String, dynamic> toMap() {
    calculateTotal(); // التأكد من حساب المجموع قبل الحفظ

    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'pharmacyId': pharmacyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'insuranceDiscount': insuranceDiscount,
      'insuranceCompanyId': insuranceCompanyId,
      'insuranceCompanyName': insuranceCompanyName,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'paymentDetails': paymentDetails,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'saleDate': Timestamp.fromDate(saleDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    List<SaleItem> itemsList = [];
    if (map['items'] != null && map['items'] is List) {
      itemsList = (map['items'] as List)
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return Sale(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      items: itemsList,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble(),
      insuranceDiscount: (map['insuranceDiscount'] as num?)?.toDouble(),
      insuranceCompanyId: map['insuranceCompanyId'],
      insuranceCompanyName: map['insuranceCompanyName'],
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] ?? 'cash'),
      paymentDetails: map['paymentDetails'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      notes: map['notes'],
      saleDate: (map['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // توليد رقم فاتورة تلقائي
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'INV-$year$month$day-$random';
  }

  // معلومات الفاتورة للتقرير
  String get invoiceSummary {
    return 'فاتورة #$invoiceNumber - ${items.length} أصناف - الإجمالي: ${total.toStringAsFixed(2)}';
  }

  // حالة الدفع
  String get paymentStatus {
    return paymentMethod.arabicName;
  }
}