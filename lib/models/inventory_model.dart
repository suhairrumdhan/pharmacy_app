import 'package:cloud_firestore/cloud_firestore.dart';

enum UnitType {
  Tablet, Capsule, Syrup, Drops, Bottle, Ampoule, Vial, Ointment, Cream, Gel, Spray, Patch, Powder, Sachet, Suppository, Inhaler, Suspension, Solution, Lotion, Strip, Tube
}

class Medicine {
  final String id;
  final String name;
  final String scientificName;
  final int quantity;

  String? description;
  String? category;

  double? purchasePrice;
  double? sellingPrice;

  UnitType? unit;
  int? unitsPerPackage;

  bool sellByPiece;
  double? piecePrice;

  int? minStockLevel;
  String? supplier;

  DateTime? expiryDate;
  String? barcode;
  String? imageUrl;

  DateTime? lastUpdated;
  final int pieceQuantity;

  /// =========================
  /// New financial fields
  /// =========================
  final double? averageCost;
  final double? lastPurchasePrice;
  final double? retailValue;
  final double? costValue;

  final String? supplierId;
  final String? supplierName;

  final bool isActive;

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
    this.pieceQuantity = 0,
    this.averageCost,
    this.lastPurchasePrice,
    this.retailValue,
    this.costValue,
    this.supplierId,
    this.supplierName,
    this.isActive = true,
  }) : scientificName =
  (scientificName != null && scientificName.isNotEmpty)
      ? scientificName
      : name {
    if (sellByPiece &&
        unitsPerPackage != null &&
        unitsPerPackage! > 0 &&
        sellingPrice != null) {
      piecePrice ??= sellingPrice! / unitsPerPackage!;
    }
  }

  bool get isLowStock =>
      (minStockLevel != null) ? quantity <= minStockLevel! : false;

  bool get isExpired =>
      expiryDate != null ? expiryDate!.isBefore(DateTime.now()) : false;

  int get totalPiecesEquivalent {
    final units = unitsPerPackage ?? 0;
    return (quantity * units) + pieceQuantity;
  }

  double get effectivePackageCost {
    if (averageCost != null && averageCost! > 0) return averageCost!;
    if (purchasePrice != null && purchasePrice! > 0) return purchasePrice!;
    if (lastPurchasePrice != null && lastPurchasePrice! > 0) {
      return lastPurchasePrice!;
    }
    return 0.0;
  }

  double get effectivePieceCost {
    final units = unitsPerPackage ?? 0;
    if (units <= 0) return 0.0;
    return effectivePackageCost / units;
  }

  double get effectiveSellingPrice => sellingPrice ?? 0.0;

  double get effectivePiecePrice {
    if (piecePrice != null && piecePrice! > 0) return piecePrice!;
    final units = unitsPerPackage ?? 0;
    if (units <= 0 || effectiveSellingPrice <= 0) return 0.0;
    return effectiveSellingPrice / units;
  }

  double get calculatedCostValue {
    final packageValue = quantity * effectivePackageCost;
    final pieceValue = pieceQuantity * effectivePieceCost;
    return (costValue ?? (packageValue + pieceValue))
        .clamp(0.0, double.infinity);
  }

  double get calculatedRetailValue {
    final packageValue = quantity * effectiveSellingPrice;
    final pieceValue = pieceQuantity * effectivePiecePrice;
    return (retailValue ?? (packageValue + pieceValue))
        .clamp(0.0, double.infinity);
  }

  double get potentialGrossProfit =>
      calculatedRetailValue - calculatedCostValue;

  double get potentialMarginPercent {
    if (calculatedRetailValue <= 0) return 0.0;
    return (potentialGrossProfit / calculatedRetailValue) * 100;
  }

  factory Medicine.fromMap(Map<String, dynamic> data, String id) {
    int safeInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    double? safeNullableDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    double safeDouble(dynamic value) =>
        double.tryParse(value?.toString() ?? '') ?? 0;

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

    final sellByPiece = data['sellByPiece'] == true;
    final units = safeInt(data['unitsPerPackage']);
    final sellingPrice = safeNullableDouble(data['sellingPrice']);

    double? piecePrice = safeNullableDouble(data['piecePrice']);
    if ((piecePrice == null || piecePrice <= 0) &&
        sellByPiece &&
        units > 0 &&
        sellingPrice != null &&
        sellingPrice > 0) {
      piecePrice = sellingPrice / units;
    }

    return Medicine(
      id: id,
      name: data['name']?.toString() ?? '',
      scientificName: data['scientificName']?.toString(),
      quantity: safeInt(data['quantity']),
      description: data['description']?.toString(),
      category: data['category']?.toString(),
      purchasePrice: safeNullableDouble(data['purchasePrice']),
      sellingPrice: sellingPrice,
      unit: safeUnit(data['unit']?.toString()),
      unitsPerPackage: units,
      sellByPiece: sellByPiece,
      piecePrice: piecePrice,
      pieceQuantity: safeInt(data['pieceQuantity']),
      minStockLevel: safeInt(data['minStockLevel']),
      supplier: data['supplier']?.toString(),
      expiryDate: parseDate(data['expiryDate']),
      barcode: data['barcode']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      lastUpdated: parseDate(data['lastUpdated']) ?? DateTime.now(),

      // New fields
      averageCost: safeNullableDouble(data['averageCost']),
      lastPurchasePrice: safeNullableDouble(data['lastPurchasePrice']),
      retailValue: safeNullableDouble(data['retailValue']),
      costValue: safeNullableDouble(data['costValue']),
      supplierId: data['supplierId']?.toString(),
      supplierName: data['supplierName']?.toString(),
      isActive: data['isActive'] == null ? true : data['isActive'] == true,
    );
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? scientificName,
    int? quantity,
    int? pieceQuantity,
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
    double? averageCost,
    double? lastPurchasePrice,
    double? retailValue,
    double? costValue,
    String? supplierId,
    String? supplierName,
    bool? isActive,
    bool clearSupplierLink = false,
  }) {
    final int? finalUnits = unitsPerPackage ?? this.unitsPerPackage;
    final double? finalSelling = sellingPrice ?? this.sellingPrice;
    final bool finalSellByPiece = sellByPiece ?? this.sellByPiece;
    double? finalPiecePrice = piecePrice ?? this.piecePrice;

    if (finalSellByPiece &&
        finalUnits != null &&
        finalUnits > 0 &&
        finalSelling != null &&
        finalSelling > 0 &&
        (finalPiecePrice == null || finalPiecePrice <= 0)) {
      finalPiecePrice = finalSelling / finalUnits;
    }

    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: (scientificName != null && scientificName.isNotEmpty)
          ? scientificName
          : (name ?? this.name),
      quantity: quantity ?? this.quantity,
      pieceQuantity: pieceQuantity ?? this.pieceQuantity,
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
      averageCost: averageCost ?? this.averageCost,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      retailValue: retailValue ?? this.retailValue,
      costValue: costValue ?? this.costValue,
      supplierId: clearSupplierLink ? null : (supplierId ?? this.supplierId),
      supplierName:
      clearSupplierLink ? null : (supplierName ?? this.supplierName),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    final map = {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'quantity': quantity,
      'description': description,
      'pieceQuantity': pieceQuantity,
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

      // New financial fields
      'averageCost': averageCost,
      'lastPurchasePrice': lastPurchasePrice,
      'retailValue': calculatedRetailValue,
      'costValue': calculatedCostValue,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'isActive': isActive,
    };

    if (forFirestore) {
      map['lastUpdated'] = lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp();
    } else {
      map['lastUpdated'] =
          lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String();
    }

    return map;
  }

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, scientificName: $scientificName, quantity: $quantity, unit: ${unit?.name}, sellByPiece: $sellByPiece, piecePrice: $piecePrice)';
  }
}