import 'package:cloud_firestore/cloud_firestore.dart';

enum UnitType {
  piece,
  strip,
  box,
  bottle,
  ml,
}

class Medicine {
  // ===== Required Fields =====
  final String id;             // معرف فريد
  final String name;           // الاسم التجاري
  final String scientificName; // الاسم العلمي
  final int quantity;          // الكمية الموجودة

  // ===== Optional Fields =====
  String? description;
  String? category;

  double? purchasePrice;
  double? sellingPrice;

  UnitType? unit;          // وحدة القياس الموحّدة
  int? unitsPerPackage;    // عدد الحبات أو الشرائط داخل العبوة

  bool? sellByStrip;
  int? stripsPerBox;
  double? stripPrice;

  int? minStockLevel;
  String? supplier;

  DateTime? expiryDate;
  String? barcode;

  String? imageUrl; // <<< الصورة اختيارية

  DateTime? lastUpdated;

  Medicine({
    // Required
    required this.id,
    required this.name,
    required this.scientificName,
    required this.quantity,

    // Optional
    this.description,
    this.category,
    this.purchasePrice,
    this.sellingPrice,
    this.unit,
    this.unitsPerPackage,
    this.sellByStrip,
    this.stripsPerBox,
    this.stripPrice,
    this.minStockLevel,
    this.supplier,
    this.expiryDate,
    this.barcode,
    this.imageUrl,
    this.lastUpdated,
  });

  // ===== Computed Properties =====
  bool get isLowStock =>
      (minStockLevel != null) ? quantity <= minStockLevel! : false;

  bool get isExpired =>
      expiryDate != null ? expiryDate!.isBefore(DateTime.now()) : false;

  // ===== From Map =====
  factory Medicine.fromMap(Map<String, dynamic> data) {
    return Medicine(
      id: data['id']?.toString() ?? "", // FIXED: Handle null
      name: data['name']?.toString() ?? "", // FIXED: Handle null
      scientificName: data['scientificName']?.toString() ?? "", // FIXED: Handle null
      quantity: (data['quantity'] ?? 0).toInt(),

      description: data['description']?.toString(),
      category: data['category']?.toString(),
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),

      unit: data['unit'] != null
          ? UnitType.values.firstWhere(
            (e) => e.name == data['unit']?.toString(),
        orElse: () => UnitType.piece,
      )
          : null,

      unitsPerPackage: data['unitsPerPackage']?.toInt(),
      sellByStrip: data['sellByStrip'] ?? false,
      stripsPerBox: data['stripsPerBox']?.toInt(),
      stripPrice: (data['stripPrice'] ?? 0).toDouble(),

      minStockLevel: data['minStockLevel']?.toInt(),
      supplier: data['supplier']?.toString(),

      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['expiryDate'].toString()))
          : null,

      barcode: data['barcode']?.toString(),
      imageUrl: data['imageUrl']?.toString(),

      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(data['lastUpdated'].toString()))
          : DateTime.now(),
    );
  }


  Medicine copyWith({
    String? id,
    String? name,
    String? scientificName,
    int? quantity,
    String? description,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    UnitType? unit,
    int? unitsPerPackage,
    bool? sellByStrip,
    int? stripsPerBox,
    double? stripPrice,
    int? minStockLevel,
    String? supplier,
    DateTime? expiryDate,
    String? barcode,
    String? imageUrl,
    DateTime? lastUpdated,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unit: unit ?? this.unit,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      sellByStrip: sellByStrip ?? this.sellByStrip,
      stripsPerBox: stripsPerBox ?? this.stripsPerBox,
      stripPrice: stripPrice ?? this.stripPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      supplier: supplier ?? this.supplier,
      expiryDate: expiryDate ?? this.expiryDate,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ===== To Map =====
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'quantity': quantity,

      'description': description,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'unit': unit?.name,
      'unitsPerPackage': unitsPerPackage,
      'sellByStrip': sellByStrip ?? false,
      'stripsPerBox': stripsPerBox,
      'stripPrice': stripPrice,
      'minStockLevel': minStockLevel,
      'supplier': supplier,
      'expiryDate': expiryDate?.toIso8601String(),
      'barcode': barcode,
      'imageUrl': imageUrl,
      'lastUpdated': lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}