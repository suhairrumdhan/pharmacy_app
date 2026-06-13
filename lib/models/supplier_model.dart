// lib/models/supplier_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  String id;
  String name;
  String contactPerson;
  String phone;
  String address;
  List<String> suppliedMedications;
  DateTime contractStartDate;
  DateTime? contractEndDate;
  String status;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  /// =========================
  /// Financial fields
  /// =========================
  final double? openingBalance;
  final double? currentBalance;
  final double? totalPurchases;
  final double? totalPaid;
  final double? totalDue;
  final int? paymentTermDays;
  final String? taxNumber;

  /// Supplier ledger summary
  final double outstandingBalance;
  final double overdueBalance;

  final DateTime? lastPurchaseDate;
  final DateTime? lastPaymentDate;

  final int unpaidInvoicesCount;
  final int overdueInvoicesCount;

  Supplier({
    this.id = '',
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.address,
    List<String>? suppliedMedications,
    required this.contractStartDate,
    this.contractEndDate,
    this.status = 'فعال',
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.openingBalance,
    this.currentBalance,
    this.totalPurchases,
    this.totalPaid,
    this.totalDue,
    this.paymentTermDays,
    this.taxNumber,
    this.outstandingBalance = 0.0,
    this.overdueBalance = 0.0,
    this.lastPurchaseDate,
    this.lastPaymentDate,
    this.unpaidInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
  })  : suppliedMedications = suppliedMedications ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get effectiveOpeningBalance => openingBalance ?? 0.0;
  double get effectiveTotalPurchases => totalPurchases ?? 0.0;
  double get effectiveTotalPaid => totalPaid ?? 0.0;

  double get calculatedBalance {
    if (currentBalance != null) return currentBalance!;
    return (effectiveOpeningBalance + effectiveTotalPurchases - effectiveTotalPaid)
        .clamp(0.0, double.infinity);
  }

  double get calculatedDue {
    if (totalDue != null) return totalDue!;
    if (outstandingBalance > 0) return outstandingBalance;
    return calculatedBalance;
  }

  bool get hasDue => calculatedDue > 0;
  bool get hasOverdue => overdueBalance > 0 || overdueInvoicesCount > 0;
  bool get isActive => status == 'فعال';

  factory Supplier.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return Supplier(
      id: id,
      name: map['name']?.toString() ?? '',
      contactPerson: map['contactPerson']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      suppliedMedications: parseStringList(map['suppliedMedications']),
      contractStartDate: parseDateTime(map['contractStartDate']),
      contractEndDate: parseNullableDateTime(map['contractEndDate']),
      status: map['status']?.toString() ?? 'فعال',
      notes: map['notes']?.toString() ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      openingBalance: parseNullableDouble(map['openingBalance']),
      currentBalance: parseNullableDouble(map['currentBalance']),
      totalPurchases: parseNullableDouble(map['totalPurchases']),
      totalPaid: parseNullableDouble(map['totalPaid']),
      totalDue: parseNullableDouble(map['totalDue']),
      paymentTermDays: parseNullableInt(map['paymentTermDays']),
      taxNumber: map['taxNumber']?.toString(),
      outstandingBalance: parseDouble(map['outstandingBalance']),
      overdueBalance: parseDouble(map['overdueBalance']),
      lastPurchaseDate: parseNullableDateTime(map['lastPurchaseDate']),
      lastPaymentDate: parseNullableDateTime(map['lastPaymentDate']),
      unpaidInvoicesCount: parseInt(map['unpaidInvoicesCount']),
      overdueInvoicesCount: parseInt(map['overdueInvoicesCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'address': address,
      'suppliedMedications': suppliedMedications,
      'contractStartDate': Timestamp.fromDate(contractStartDate),
      'contractEndDate':
      contractEndDate != null ? Timestamp.fromDate(contractEndDate!) : null,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      // Financial fields
      'openingBalance': openingBalance,
      'currentBalance': calculatedBalance,
      'totalPurchases': totalPurchases,
      'totalPaid': totalPaid,
      'totalDue': calculatedDue,
      'paymentTermDays': paymentTermDays,
      'taxNumber': taxNumber,

      // Supplier ledger summary
      'outstandingBalance': calculatedDue,
      'overdueBalance': overdueBalance,
      'lastPurchaseDate':
      lastPurchaseDate != null ? Timestamp.fromDate(lastPurchaseDate!) : null,
      'lastPaymentDate':
      lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'unpaidInvoicesCount': unpaidInvoicesCount,
      'overdueInvoicesCount': overdueInvoicesCount,
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? address,
    List<String>? suppliedMedications,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? openingBalance,
    double? currentBalance,
    double? totalPurchases,
    double? totalPaid,
    double? totalDue,
    int? paymentTermDays,
    String? taxNumber,
    double? outstandingBalance,
    double? overdueBalance,
    DateTime? lastPurchaseDate,
    DateTime? lastPaymentDate,
    int? unpaidInvoicesCount,
    int? overdueInvoicesCount,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      suppliedMedications: suppliedMedications ?? this.suppliedMedications,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPaid: totalPaid ?? this.totalPaid,
      totalDue: totalDue ?? this.totalDue,
      paymentTermDays: paymentTermDays ?? this.paymentTermDays,
      taxNumber: taxNumber ?? this.taxNumber,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      overdueBalance: overdueBalance ?? this.overdueBalance,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      unpaidInvoicesCount: unpaidInvoicesCount ?? this.unpaidInvoicesCount,
      overdueInvoicesCount: overdueInvoicesCount ?? this.overdueInvoicesCount,
    );
  }

  String get formattedContractStartDate {
    return '${contractStartDate.day}/${contractStartDate.month}/${contractStartDate.year}';
  }

  String? get formattedContractEndDate {
    if (contractEndDate == null) return null;
    return '${contractEndDate!.day}/${contractEndDate!.month}/${contractEndDate!.year}';
  }

  bool get isContractExpired {
    if (contractEndDate == null) return false;
    return contractEndDate!.isBefore(DateTime.now());
  }

  bool get isContractExpiringSoon {
    if (contractEndDate == null) return false;
    final now = DateTime.now();
    final diff = contractEndDate!.difference(now).inDays;
    return diff >= 0 && diff <= 30;
  }
}