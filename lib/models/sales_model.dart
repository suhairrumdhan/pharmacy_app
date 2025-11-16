class Sale {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<SaleItem> items;
  final double totalAmount;
  final double discount;
  final double tax;
  final double finalAmount;
  final DateTime saleDate;
  final String paymentMethod;
  final String status;

  Sale({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.finalAmount,
    required this.saleDate,
    required this.paymentMethod,
    required this.status,
  });

  factory Sale.fromMap(Map<String, dynamic> data) {
    return Sale(
      id: data['id'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: (data['items'] as List).map((item) => SaleItem.fromMap(item)).toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      finalAmount: (data['finalAmount'] ?? 0).toDouble(),
      saleDate: DateTime.parse(data['saleDate']),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      status: data['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'discount': discount,
      'tax': tax,
      'finalAmount': finalAmount,
      'saleDate': saleDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'status': status,
    };
  }
}

class SaleItem {
  final String medicineId;
  final String medicineName;
  final int quantity;
  final double price;
  final double total;

  SaleItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory SaleItem.fromMap(Map<String, dynamic> data) {
    return SaleItem(
      medicineId: data['medicineId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}

class SalesSummary {
  final double todaySales;
  final double weeklySales;
  final double monthlySales;
  final int totalTransactions;
  final double averageSale;

  SalesSummary({
    required this.todaySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.totalTransactions,
    required this.averageSale,
  });
}