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

  final String openedById;
  final String openedByName;
  final String openedByType;
  final String openedByKey;

  final String closedById;
  final String closedByName;
  final String closedByType;
  final String closedByKey;

  final double openingCash;
  final double closingCash;

  final double cashTotal;
  final double cardTotal;
  final double insuranceBilledTotal;

  final double cashRefunds;
  final double cardRefunds;

  final double shiftExpenses;
  final double supplierPayments;
  final double salaryPayments;

  final double manualCashIn;
  final double manualCashOut;

  final int salesCount;
  final int refundsCount;

  final double expectedDrawerCash;
  final double drawerDiff;

  final bool isFinanciallyClosed;
  final DateTime? financiallyClosedAt;

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
    this.cashRefunds = 0,
    this.cardRefunds = 0,
    this.shiftExpenses = 0,
    this.supplierPayments = 0,
    this.salaryPayments = 0,
    this.manualCashIn = 0,
    this.manualCashOut = 0,
    this.salesCount = 0,
    this.refundsCount = 0,
    this.expectedDrawerCash = 0,
    this.drawerDiff = 0,
    this.isFinanciallyClosed = false,
    this.financiallyClosedAt,
    this.notes,
  });

  bool get isOpen => status == ShiftStatus.open;

  double get netCashSales => cashTotal - cashRefunds;

  double get totalOutflows =>
      shiftExpenses + supplierPayments + salaryPayments + manualCashOut;

  double get totalInflows => manualCashIn;

  double get calculatedExpectedDrawerCash {
    return openingCash + netCashSales + totalInflows - totalOutflows;
  }

  double get calculatedDrawerDiff {
    return closingCash - calculatedExpectedDrawerCash;
  }

  double get grandTotal => cashTotal + cardTotal + insuranceBilledTotal;

  double get netRevenue => grandTotal - cashRefunds - cardRefunds;

  bool get hasDrawerIssue => calculatedDrawerDiff.abs() >= 0.01;

  double get effectiveExpectedDrawerCash {
    if (expectedDrawerCash > 0) return expectedDrawerCash;
    return calculatedExpectedDrawerCash;
  }

  double get effectiveDrawerDiff {
    if (drawerDiff != 0) return drawerDiff;
    return calculatedDrawerDiff;
  }

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

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static ShiftStatus _status(dynamic v) {
    final s = (v ?? '').toString();
    return s == 'open' ? ShiftStatus.open : ShiftStatus.closed;
  }

  static String _buildActorKey({
    required String type,
    required String id,
  }) {
    if (type.trim().isEmpty || id.trim().isEmpty) return '';
    return '$type:$id';
  }

  factory Shift.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    Map<String, dynamic>? openedBy;
    if (data['openedBy'] is Map) {
      openedBy = Map<String, dynamic>.from(data['openedBy']);
    }

    Map<String, dynamic>? closedBy;
    if (data['closedBy'] is Map) {
      closedBy = Map<String, dynamic>.from(data['closedBy']);
    }

    final opening = _toD(data['openingCash']);
    final cash = _toD(data['cashTotal']);
    final cashRefunds = _toD(data['cashRefunds']);
    final shiftExpenses = _toD(data['shiftExpenses']);
    final supplierPayments = _toD(data['supplierPayments']);
    final salaryPayments = _toD(data['salaryPayments']);
    final manualCashIn = _toD(data['manualCashIn']);
    final manualCashOut = _toD(data['manualCashOut']);

    final calculatedExpected =
        opening +
            cash -
            cashRefunds -
            shiftExpenses -
            supplierPayments -
            salaryPayments +
            manualCashIn -
            manualCashOut;

    final closing = _toD(data['closingCash']);

    final expected = data['expectedDrawerCash'] == null
        ? calculatedExpected
        : _toD(data['expectedDrawerCash']);

    final diff = data['drawerDiff'] == null
        ? (closing - expected)
        : _toD(data['drawerDiff']);

    final openedById = (data['openedById'] ?? openedBy?['id'] ?? '').toString();
    final openedByName =
    (data['openedByName'] ??
        openedBy?['name'] ??
        openedBy?['username'] ??
        '')
        .toString();

    final openedByType =
    (data['openedByType'] ?? openedBy?['type'] ?? '').toString();

    final openedByKey = (data['openedByKey'] ?? '').toString().isNotEmpty
        ? (data['openedByKey'] ?? '').toString()
        : _buildActorKey(type: openedByType, id: openedById);

    final closedById = (data['closedById'] ?? closedBy?['id'] ?? '').toString();
    final closedByName =
    (data['closedByName'] ??
        closedBy?['name'] ??
        closedBy?['username'] ??
        '')
        .toString();

    final closedByType =
    (data['closedByType'] ?? closedBy?['type'] ?? '').toString();

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
      cashRefunds: cashRefunds,
      cardRefunds: _toD(data['cardRefunds']),
      shiftExpenses: shiftExpenses,
      supplierPayments: supplierPayments,
      salaryPayments: salaryPayments,
      manualCashIn: manualCashIn,
      manualCashOut: manualCashOut,
      salesCount: _toI(data['salesCount']),
      refundsCount: _toI(data['refundsCount']),
      expectedDrawerCash: expected,
      drawerDiff: diff,
      isFinanciallyClosed: data['isFinanciallyClosed'] == true,
      financiallyClosedAt: _ts(data['financiallyClosedAt']),
      notes: data['notes']?.toString(),
    );
  }
}