import 'package:cloud_firestore/cloud_firestore.dart';

enum ShiftStatus { open, closed }

class Shift {
  final String id;
  final String pharmacyId;

  final ShiftStatus status;

  final DateTime? openedAt;
  final DateTime? closedAt;

  final Map<String, dynamic>? openedBy;
  final Map<String, dynamic>? closedBy;

  final double openingCash;
  final double closingCash;

  // Totals (مبيعات)
  final double cashTotal;
  final double cardTotal;

  // ✅ Insurance smart totals
  final double insuranceBilledTotal;     // فواتير تأمين
  final double insuranceCollectedTotal;  // محصّل من التأمين
  final double insurancePendingTotal;    // متبقي على التأمين

  final int salesCount;
  final int refundsCount;

  // Drawer check
  final double expectedDrawerCash; // openingCash + cashTotal
  final double drawerDiff;         // closingCash - expectedDrawerCash

  final String? notes;

  Shift({
    required this.id,
    required this.pharmacyId,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.openedBy,
    this.closedBy,
    this.openingCash = 0,
    this.closingCash = 0,
    this.cashTotal = 0,
    this.cardTotal = 0,
    this.insuranceBilledTotal = 0,
    this.insuranceCollectedTotal = 0,
    this.insurancePendingTotal = 0,
    this.salesCount = 0,
    this.refundsCount = 0,
    this.expectedDrawerCash = 0,
    this.drawerDiff = 0,
    this.notes,
  });

  bool get isOpen => status == ShiftStatus.open;

  // ✅ الإجمالي الحقيقي للـ POS (كاش + بطاقة + فواتير التأمين)
  double get grandTotal => cashTotal + cardTotal + insuranceBilledTotal;

  factory Shift.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    ShiftStatus parseStatus(dynamic v) {
      final s = (v ?? '').toString();
      return (s == 'open') ? ShiftStatus.open : ShiftStatus.closed;
    }

    DateTime? tsToDate(dynamic v) => v is Timestamp ? v.toDate() : null;

    double toD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int toI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final opening = toD(data['openingCash']);
    final cash = toD(data['cashTotal']);

    // drawer calc (قديمة وجديدة)
    final expectedRaw = data['expectedDrawerCash'];
    final expectedFixed = expectedRaw == null ? (opening + cash) : toD(expectedRaw);

    final closing = toD(data['closingCash']);
    final diffRaw = data['drawerDiff'];
    final diffFixed = diffRaw == null ? (closing - expectedFixed) : toD(diffRaw);

    // insurance smart calc
    final billed = toD(data['insuranceBilledTotal'] ?? data['insuranceTotal']); // دعم قديم
    final collected = toD(data['insuranceCollectedTotal']);
    final pendingRaw = data['insurancePendingTotal'];
    final pending = pendingRaw == null ? (billed - collected) : toD(pendingRaw);

    return Shift(
      id: doc.id,
      pharmacyId: (data['pharmacyId'] ?? '').toString(),
      status: parseStatus(data['status']),
      openedAt: tsToDate(data['openedAt']),
      closedAt: tsToDate(data['closedAt']),
      openedBy: (data['openedBy'] is Map) ? Map<String, dynamic>.from(data['openedBy']) : null,
      closedBy: (data['closedBy'] is Map) ? Map<String, dynamic>.from(data['closedBy']) : null,
      openingCash: opening,
      closingCash: closing,
      cashTotal: cash,
      cardTotal: toD(data['cardTotal']),
      insuranceBilledTotal: billed,
      insuranceCollectedTotal: collected,
      insurancePendingTotal: pending,
      salesCount: toI(data['salesCount']),
      refundsCount: toI(data['refundsCount']),
      expectedDrawerCash: expectedFixed,
      drawerDiff: diffFixed,
      notes: data['notes']?.toString(),
    );
  }
}
