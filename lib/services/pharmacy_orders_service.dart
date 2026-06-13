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
  Future<void> markOrderReadyWithInvoice({
    required String orderId,
    required String saleId,
    required String invoiceNumber,
    required String changedById,
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
      'status': 'ready',
      'label': 'جاهز',
      'changedById': changedById,
      'changedByType': 'pharmacy',
      'note': note,
      'changedAt': Timestamp.now(),
    });

    await docRef.update({
      'status': 'ready',
      'statusLabel': 'جاهز',
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'invoicedAt': FieldValue.serverTimestamp(),
      'readyAt': FieldValue.serverTimestamp(),
      'statusHistory': history,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }



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
}