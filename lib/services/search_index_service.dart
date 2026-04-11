import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';

class SearchIndexService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> createOrUpdateIndex({
    required String pharmacyId,
    required Map<String, dynamic> pharmacyData,
    required Medicine medicine,
  }) async {
    final indexId = "${pharmacyId}_${medicine.id}";

    final location = pharmacyData['location'] as Map<String, dynamic>?;

    final latitude = location != null
        ? _toDouble(location['latitude'])
        : _toDouble(pharmacyData['latitude']);

    final longitude = location != null
        ? _toDouble(location['longitude'])
        : _toDouble(pharmacyData['longitude']);

    final doc = {
      'pharmacyId': pharmacyId,
      'medicineId': medicine.id,

      'pharmacyName': pharmacyData['pharmacyName'] ?? '',
      'status': pharmacyData['status'] ?? '',
      'is24Hours': pharmacyData['is24Hours'] ?? false,
      'isOnline': pharmacyData['isOnline'] ?? false,

      'latitude': latitude,
      'longitude': longitude,

      'acceptedInsuranceCodes':
      List<String>.from(pharmacyData['acceptedInsuranceCodes'] ?? []),

      'medicineName': medicine.name,
      'scientificName': medicine.scientificName,
      'category': medicine.category,
      'supplier': medicine.supplier,
      'barcode': medicine.barcode,

      'unit': medicine.unit?.name,
      'unitsPerPackage': medicine.unitsPerPackage,

      'sellingPrice': medicine.sellingPrice,
      'piecePrice': medicine.piecePrice,
      'sellByPiece': medicine.sellByPiece,

      'quantity': medicine.quantity,
      'pieceQuantity': medicine.pieceQuantity,

      'available': (medicine.quantity > 0 || medicine.pieceQuantity > 0),
      'isExpired': medicine.isExpired,
      'isLowStock': medicine.isLowStock,

      'expiryDate': medicine.expiryDate?.toIso8601String(),
      'imageUrl': medicine.imageUrl,

      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('medicine_search_index')
        .doc(indexId)
        .set(doc, SetOptions(merge: true));
  }

  Future<void> deleteIndex({
    required String pharmacyId,
    required String medicineId,
  }) async {
    final indexId = "${pharmacyId}_${medicineId}";
    await _firestore
        .collection('medicine_search_index')
        .doc(indexId)
        .delete();
  }


  Future<void> rebuildPharmacyIndex({
    required String pharmacyId,
    required Map<String, dynamic> pharmacyData,
  }) async {
    final medicinesSnapshot = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('medicines')
        .get();

    for (final doc in medicinesSnapshot.docs) {
      final medicine = Medicine.fromMap(doc.data(), doc.id);
      await createOrUpdateIndex(
        pharmacyId: pharmacyId,
        pharmacyData: pharmacyData,
        medicine: medicine,
      );
    }
  }
}