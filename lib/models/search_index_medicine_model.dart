import 'package:cloud_firestore/cloud_firestore.dart';

class SearchIndexMedicine {
  final String id;

  final String pharmacyId;
  final String medicineId;

  final String pharmacyName;
  final String status;
  final bool is24Hours;
  final bool isOnline;

  final double latitude;
  final double longitude;

  final List<String> acceptedInsuranceCodes;

  final String medicineName;
  final String scientificName;

  final String? category;
  final String? supplier;
  final String? barcode;

  final String? unit;
  final int? unitsPerPackage;

  final double? sellingPrice;
  final double? piecePrice;
  final bool sellByPiece;

  final int quantity;
  final int pieceQuantity;

  final bool available;
  final bool isExpired;
  final bool isLowStock;

  final DateTime? expiryDate;
  final DateTime? lastUpdated;

  final String? imageUrl;

  SearchIndexMedicine({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    required this.pharmacyName,
    required this.status,
    required this.is24Hours,
    required this.isOnline,
    required this.latitude,
    required this.longitude,
    required this.acceptedInsuranceCodes,
    required this.medicineName,
    required this.scientificName,
    this.category,
    this.supplier,
    this.barcode,
    this.unit,
    this.unitsPerPackage,
    this.sellingPrice,
    this.piecePrice,
    required this.sellByPiece,
    required this.quantity,
    required this.pieceQuantity,
    required this.available,
    required this.isExpired,
    required this.isLowStock,
    this.expiryDate,
    this.lastUpdated,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'medicineId': medicineId,

      'pharmacyName': pharmacyName,
      'status': status,
      'is24Hours': is24Hours,
      'isOnline': isOnline,

      'latitude': latitude,
      'longitude': longitude,

      'acceptedInsuranceCodes': acceptedInsuranceCodes,

      'medicineName': medicineName,
      'scientificName': scientificName,

      'category': category,
      'supplier': supplier,
      'barcode': barcode,

      'unit': unit,
      'unitsPerPackage': unitsPerPackage,

      'sellingPrice': sellingPrice,
      'piecePrice': piecePrice,
      'sellByPiece': sellByPiece,

      'quantity': quantity,
      'pieceQuantity': pieceQuantity,

      'available': available,
      'isExpired': isExpired,
      'isLowStock': isLowStock,

      'expiryDate': expiryDate?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),

      'imageUrl': imageUrl,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}