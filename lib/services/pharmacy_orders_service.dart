import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyOrdersService {
  PharmacyOrdersService._();

  static final PharmacyOrdersService instance =
  PharmacyOrdersService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  /// =========================
  /// Get orders stream
  /// =========================
  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersStream(
      String pharmacyId) {
    return _ordersRef
        .where('pharmacy.pharmacyId', isEqualTo: pharmacyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// Update status
  /// =========================
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String statusLabel,
    required String changedById,
    required String changedByType,
    String? note,
  }) async {
    final docRef = _ordersRef.doc(orderId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('الطلب غير موجود');
    }

    final data = doc.data() ?? {};
    final history = (data['statusHistory'] as List<dynamic>? ?? []).map((e) {
      return Map<String, dynamic>.from(e as Map);
    }).toList();

    history.add({
      'status': newStatus,
      'label': statusLabel,
      'changedById': changedById,
      'changedByType': changedByType,
      'note': note,
      'changedAt': Timestamp.now(),
    });

    final updateMap = <String, dynamic>{
      'status': newStatus,
      'statusLabel': statusLabel,
      'statusHistory': history,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == 'reviewing') {
      updateMap['reviewedAt'] = FieldValue.serverTimestamp();
    }

    if (newStatus == 'completed') {
      updateMap['completedAt'] = FieldValue.serverTimestamp();
    }

    if (newStatus == 'cancelled') {
      updateMap['cancelledAt'] = FieldValue.serverTimestamp();
    }

    await docRef.update(updateMap);
  }

  /// =========================
  /// Update pharmacy note
  /// =========================
  Future<void> updatePharmacyNote({
    required String orderId,
    required String note,
  }) async {
    await _ordersRef.doc(orderId).update({
      'pharmacyNote': note.trim().isEmpty ? null : note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}