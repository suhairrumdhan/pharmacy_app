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

  // ✅ basics (للفلترة/العرض)
  final String openedById;
  final String openedByName;

  // ✅ NEW (محكم للنظام الجديد)
  final String openedByType; // owner/employee
  final String openedByKey;  // owner:<uid> OR employee:<docId>

  final String closedById;
  final String closedByName;
  final String closedByType;
  final String closedByKey;

  final double openingCash;
  final double closingCash;

  final double cashTotal;
  final double cardTotal;

  // ✅ التأمين (فواتير على الشركة - مش داخل الدرج)
  final double insuranceBilledTotal;

  final int salesCount;
  final int refundsCount;

  final double expectedDrawerCash;
  final double drawerDiff;

  final String? notes;

  Shift({
    required this.id,
    required this.pharmacyId,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.openedBy,
    this.closedBy,

    this.openedById = '',
    this.openedByName = '',
    this.openedByType = '',
    this.openedByKey = '',

    this.closedById = '',
    this.closedByName = '',
    this.closedByType = '',
    this.closedByKey = '',

    this.openingCash = 0,
    this.closingCash = 0,
    this.cashTotal = 0,
    this.cardTotal = 0,
    this.insuranceBilledTotal = 0,
    this.salesCount = 0,
    this.refundsCount = 0,
    this.expectedDrawerCash = 0,
    this.drawerDiff = 0,
    this.notes,
  });

  bool get isOpen => status == ShiftStatus.open;

  double get grandTotal => cashTotal + cardTotal + insuranceBilledTotal;

  static double _toD(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toI(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;

  static ShiftStatus _status(dynamic v) {
    final s = (v ?? '').toString();
    return s == 'open' ? ShiftStatus.open : ShiftStatus.closed;
  }

  /// ✅ يحاول يبني actorKey من type + id لو key مش موجود
  static String _buildActorKey({required String type, required String id}) {
    if (type.trim().isEmpty || id.trim().isEmpty) return '';
    return '$type:$id';
  }

  factory Shift.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    Map<String, dynamic>? openedBy;
    if (data['openedBy'] is Map) openedBy = Map<String, dynamic>.from(data['openedBy']);

    Map<String, dynamic>? closedBy;
    if (data['closedBy'] is Map) closedBy = Map<String, dynamic>.from(data['closedBy']);

    final opening = _toD(data['openingCash']);
    final cash = _toD(data['cashTotal']);

    final expected = data['expectedDrawerCash'] == null
        ? (opening + cash)
        : _toD(data['expectedDrawerCash']);

    final closing = _toD(data['closingCash']);
    final diff = data['drawerDiff'] == null
        ? (closing - expected)
        : _toD(data['drawerDiff']);

    // =========================
    // ✅ Opened By (Back-compat)
    // =========================
    final openedById = (data['openedById'] ?? openedBy?['id'] ?? '').toString();
    final openedByName = (data['openedByName'] ?? openedBy?['name'] ?? openedBy?['username'] ?? '').toString();

    final openedByType = (data['openedByType'] ?? openedBy?['type'] ?? '').toString();
    final openedByKey = (data['openedByKey'] ?? '').toString().isNotEmpty
        ? (data['openedByKey'] ?? '').toString()
        : _buildActorKey(type: openedByType, id: openedById);

    // =========================
    // ✅ Closed By (Back-compat)
    // =========================
    final closedById = (data['closedById'] ?? closedBy?['id'] ?? '').toString();
    final closedByName = (data['closedByName'] ?? closedBy?['name'] ?? closedBy?['username'] ?? '').toString();
    final closedByType = (data['closedByType'] ?? closedBy?['type'] ?? '').toString();

    final closedByKey = (data['closedByKey'] ?? '').toString().isNotEmpty
        ? (data['closedByKey'] ?? '').toString()
        : _buildActorKey(type: closedByType, id: closedById);

    return Shift(
      id: doc.id,
      pharmacyId: (data['pharmacyId'] ?? '').toString(),
      status: _status(data['status']),
      openedAt: _ts(data['openedAt']),
      closedAt: _ts(data['closedAt']),
      openedBy: openedBy,
      closedBy: closedBy,

      openedById: openedById,
      openedByName: openedByName,
      openedByType: openedByType,
      openedByKey: openedByKey,

      closedById: closedById,
      closedByName: closedByName,
      closedByType: closedByType,
      closedByKey: closedByKey,

      openingCash: opening,
      closingCash: closing,
      cashTotal: cash,
      cardTotal: _toD(data['cardTotal']),
      insuranceBilledTotal: _toD(data['insuranceBilledTotal']),
      salesCount: _toI(data['salesCount']),
      refundsCount: _toI(data['refundsCount']),
      expectedDrawerCash: expected,
      drawerDiff: diff,
      notes: data['notes']?.toString(),
    );
  }
}