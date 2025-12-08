import 'package:cloud_firestore/cloud_firestore.dart';

enum UnitType {
  Tablet, Capsule, Syrup, Drops, Bottle, Ampoule, Vial, Ointment, Cream, Gel, Spray, Patch, Powder, Sachet, Suppository, Inhaler, Suspension, Solution, Lotion, Strip, Tube
}

class Medicine {
  // ===== Required Fields =====
  final String id;
  final String name;
  final String scientificName; // سيتم استخدام الاسم التجاري إذا فارغ
  final int quantity;

  // ===== Optional Fields =====
  String? description;
  String? category;

  double? purchasePrice;
  double? sellingPrice;

  UnitType? unit;
  int? unitsPerPackage;

  bool sellByPiece; // بدل sellByStrip
  double? piecePrice; // سعر القطعة محسوب أو مخصص

  int? minStockLevel;
  String? supplier;

  DateTime? expiryDate;
  String? barcode;
  String? imageUrl;

  DateTime? lastUpdated;
  Medicine({
    required this.id,
    required this.name,
    String? scientificName,
    required this.quantity,
    this.description,
    this.category,
    this.purchasePrice,
    this.sellingPrice,
    this.unit,
    this.unitsPerPackage,
    this.sellByPiece = false,
    this.piecePrice,
    this.minStockLevel,
    this.supplier,
    this.expiryDate,
    this.barcode,
    this.imageUrl,
    this.lastUpdated,
  }) : scientificName = (scientificName != null && scientificName.isNotEmpty) ? scientificName : name {
    // إذا البيع بالقطعة true، اجعل السعر محسوب تلقائيًا
    if (sellByPiece && unitsPerPackage != null && sellingPrice != null) {
      this.piecePrice ??= sellingPrice! / unitsPerPackage!;
    }
  }


  // ===== Computed Properties =====
  bool get isLowStock => (minStockLevel != null) ? quantity <= minStockLevel! : false;
  bool get isExpired => expiryDate != null ? expiryDate!.isBefore(DateTime.now()) : false;

  // ===== From Map =====
  factory Medicine.fromMap(Map<String, dynamic> data) {
    int safeInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    double safeDouble(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;

    UnitType? safeUnit(String? value) {
      if (value == null) return null;
      return UnitType.values.firstWhere(
            (e) => e.name == value,
        orElse: () => UnitType.Tablet,
      );
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value.toString());
    }

    bool sellByPiece = data['sellByPiece'] ?? false;
    int? units = safeInt(data['unitsPerPackage']);
    double? sellingPrice = safeDouble(data['sellingPrice']);
    double? piecePrice;
    if (sellByPiece && units > 0 && sellingPrice > 0) {
      piecePrice = sellingPrice / units;
    }

    return Medicine(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      scientificName: data['scientificName']?.toString(),
      quantity: safeInt(data['quantity']),
      description: data['description']?.toString(),
      category: data['category']?.toString(),
      purchasePrice: safeDouble(data['purchasePrice']),
      sellingPrice: sellingPrice,
      unit: safeUnit(data['unit']?.toString()),
      unitsPerPackage: units,
      sellByPiece: sellByPiece,
      piecePrice: piecePrice,
      minStockLevel: safeInt(data['minStockLevel']),
      supplier: data['supplier']?.toString(),
      expiryDate: parseDate(data['expiryDate']),
      barcode: data['barcode']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      lastUpdated: parseDate(data['lastUpdated']) ?? DateTime.now(),
    );
  }

  // ===== Copy With =====
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
    bool? sellByPiece,
    double? piecePrice,
    int? minStockLevel,
    String? supplier,
    DateTime? expiryDate,
    String? barcode,
    String? imageUrl,
    DateTime? lastUpdated,
  }) {
    int? finalUnits = unitsPerPackage ?? this.unitsPerPackage;
    double? finalSelling = sellingPrice ?? this.sellingPrice;
    bool finalSellByPiece = sellByPiece ?? this.sellByPiece;
    double? finalPiecePrice = piecePrice ?? this.piecePrice;

    if (finalSellByPiece && finalUnits != null && finalSelling != null) {
      finalPiecePrice ??= finalSelling / finalUnits;
    }

    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName?.isNotEmpty == true ? scientificName : (name ?? this.name),
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: finalSelling,
      unit: unit ?? this.unit,
      unitsPerPackage: finalUnits,
      sellByPiece: finalSellByPiece,
      piecePrice: finalPiecePrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      supplier: supplier ?? this.supplier,
      expiryDate: expiryDate ?? this.expiryDate,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ===== To Map =====
  Map<String, dynamic> toMap({bool forFirestore = false}) {
    final map = {
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
      'sellByPiece': sellByPiece,
      'piecePrice': piecePrice,
      'minStockLevel': minStockLevel,
      'supplier': supplier,
      'expiryDate': expiryDate?.toIso8601String(),
      'barcode': barcode,
      'imageUrl': imageUrl,
    };

    if (forFirestore) {
      map['lastUpdated'] = lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp();
    } else {
      map['lastUpdated'] = lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String();
    }

    return map;
  }

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, scientificName: $scientificName, quantity: $quantity, unit: ${unit?.name}, sellByPiece: $sellByPiece, piecePrice: $piecePrice)';
  }
}
