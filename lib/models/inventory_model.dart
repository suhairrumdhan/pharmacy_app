class Medicine {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final int minStockLevel;
  final String supplier;
  final DateTime expiryDate;
  final String barcode;
  final DateTime lastUpdated;

  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.minStockLevel,
    required this.supplier,
    required this.expiryDate,
    required this.barcode,
    required this.lastUpdated,
  });

  bool get isLowStock => quantity <= minStockLevel;
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  factory Medicine.fromMap(Map<String, dynamic> data) {
    return Medicine(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      minStockLevel: data['minStockLevel'] ?? 5,
      supplier: data['supplier'] ?? '',
      expiryDate: DateTime.parse(data['expiryDate']),
      barcode: data['barcode'] ?? '',
      lastUpdated: DateTime.parse(data['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'minStockLevel': minStockLevel,
      'supplier': supplier,
      'expiryDate': expiryDate.toIso8601String(),
      'barcode': barcode,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class InventoryAlert {
  final String type; // low_stock, expired, etc.
  final String message;
  final DateTime date;
  final bool isRead;

  InventoryAlert({
    required this.type,
    required this.message,
    required this.date,
    this.isRead = false,
  });
}