// lib/models/financial_transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum FinancialTransactionType {
  sale,
  refund,
  purchaseInvoice,
  supplierPayment,
  expense,
  salaryPayment,
  insuranceClaim,
  insuranceCollection,
  cashAdjustment,
  bankAdjustment,
  inventoryLoss,
  openingBalance,
  transfer,
}

enum FinancialAccountType {
  cashbox,
  bank,
  salesRevenue,
  insuranceReceivable,
  supplierPayable,
  inventory,
  operatingExpense,
  payrollExpense,
  inventoryLoss,
  adjustment,
}

enum FinancialDirection {
  inflow,
  outflow,
  receivable,
  payable,
  neutral,
}

class FinancialTransactionModel {
  final String id;
  final String pharmacyId;

  final FinancialTransactionType type;
  final FinancialAccountType accountType;
  final FinancialDirection direction;

  final double amount;
  final String currency;

  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? referenceId;
  final String? referenceNumber;
  final String? referenceCollection;

  final String? title;
  final String? description;
  final String? notes;

  final String? paymentMethod;

  final String? shiftId;

  final String? supplierId;
  final String? supplierName;

  final String? insuranceCompanyId;
  final String? insuranceCompanyName;

  final String? employeeId;
  final String? employeeName;

  final String createdBy;
  final Map<String, dynamic>? createdByActor;

  final bool isPosted;
  final bool isVoided;
  final DateTime? postedAt;
  final DateTime? voidedAt;
  final String? voidReason;

  final Map<String, dynamic>? metadata;

// Remove 'const' keyword from constructor
  FinancialTransactionModel({
    this.id = '',
    required this.pharmacyId,
    required this.type,
    required this.accountType,
    required this.direction,
    required this.amount,
    this.currency = 'LYD',
    required this.transactionDate,
    DateTime? createdAt,
    this.updatedAt,
    this.referenceId,
    this.referenceNumber,
    this.referenceCollection,
    this.title,
    this.description,
    this.notes,
    this.paymentMethod,
    this.shiftId,
    this.supplierId,
    this.supplierName,
    this.insuranceCompanyId,
    this.insuranceCompanyName,
    this.employeeId,
    this.employeeName,
    required this.createdBy,
    this.createdByActor,
    this.isPosted = true,
    this.isVoided = false,
    this.postedAt,
    this.voidedAt,
    this.voidReason,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now(); // ✅ Now works

  bool get affectsCash => accountType == FinancialAccountType.cashbox;
  bool get affectsBank => accountType == FinancialAccountType.bank;
  bool get isIncome => direction == FinancialDirection.inflow;
  bool get isOutflow => direction == FinancialDirection.outflow;
  bool get isActive => !isVoided;

  double get signedAmount {
    switch (direction) {
      case FinancialDirection.inflow:
      case FinancialDirection.receivable:
        return amount;
      case FinancialDirection.outflow:
      case FinancialDirection.payable:
        return -amount;
      case FinancialDirection.neutral:
        return 0.0;
    }
  }

  factory FinancialTransactionModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return FinancialTransactionModel(
      id: id,
      pharmacyId: map['pharmacyId']?.toString() ?? '',
      type: _transactionTypeFromString(map['type']),
      accountType: _accountTypeFromString(map['accountType']),
      direction: _directionFromString(map['direction']),
      amount: _toDouble(map['amount']),
      currency: map['currency']?.toString() ?? 'LYD',
      transactionDate: _parseDate(map['transactionDate']) ?? DateTime.now(),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']),
      referenceId: map['referenceId']?.toString(),
      referenceNumber: map['referenceNumber']?.toString(),
      referenceCollection: map['referenceCollection']?.toString(),
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      notes: map['notes']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      shiftId: map['shiftId']?.toString(),
      supplierId: map['supplierId']?.toString(),
      supplierName: map['supplierName']?.toString(),
      insuranceCompanyId: map['insuranceCompanyId']?.toString(),
      insuranceCompanyName: map['insuranceCompanyName']?.toString(),
      employeeId: map['employeeId']?.toString(),
      employeeName: map['employeeName']?.toString(),
      createdBy: map['createdBy']?.toString() ?? '',
      createdByActor: map['createdByActor'] is Map
          ? Map<String, dynamic>.from(map['createdByActor'])
          : null,
      isPosted: map['isPosted'] == null ? true : map['isPosted'] == true,
      isVoided: map['isVoided'] == true,
      postedAt: _parseDate(map['postedAt']),
      voidedAt: _parseDate(map['voidedAt']),
      voidReason: map['voidReason']?.toString(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'type': type.name,
      'accountType': accountType.name,
      'direction': direction.name,
      'amount': amount,
      'currency': currency,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'referenceId': referenceId,
      'referenceNumber': referenceNumber,
      'referenceCollection': referenceCollection,
      'title': title,
      'description': description,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'shiftId': shiftId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'insuranceCompanyId': insuranceCompanyId,
      'insuranceCompanyName': insuranceCompanyName,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'createdBy': createdBy,
      'createdByActor': createdByActor,
      'isPosted': isPosted,
      'isVoided': isVoided,
      'postedAt': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
      'voidedAt': voidedAt != null ? Timestamp.fromDate(voidedAt!) : null,
      'voidReason': voidReason,
      'metadata': metadata,
    };
  }

  FinancialTransactionModel copyWith({
    String? id,
    String? pharmacyId,
    FinancialTransactionType? type,
    FinancialAccountType? accountType,
    FinancialDirection? direction,
    double? amount,
    String? currency,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? referenceId,
    String? referenceNumber,
    String? referenceCollection,
    String? title,
    String? description,
    String? notes,
    String? paymentMethod,
    String? shiftId,
    String? supplierId,
    String? supplierName,
    String? insuranceCompanyId,
    String? insuranceCompanyName,
    String? employeeId,
    String? employeeName,
    String? createdBy,
    Map<String, dynamic>? createdByActor,
    bool? isPosted,
    bool? isVoided,
    DateTime? postedAt,
    DateTime? voidedAt,
    String? voidReason,
    Map<String, dynamic>? metadata,
  }) {
    return FinancialTransactionModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      type: type ?? this.type,
      accountType: accountType ?? this.accountType,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      referenceId: referenceId ?? this.referenceId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      referenceCollection: referenceCollection ?? this.referenceCollection,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shiftId: shiftId ?? this.shiftId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      insuranceCompanyId: insuranceCompanyId ?? this.insuranceCompanyId,
      insuranceCompanyName: insuranceCompanyName ?? this.insuranceCompanyName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      createdBy: createdBy ?? this.createdBy,
      createdByActor: createdByActor ?? this.createdByActor,
      isPosted: isPosted ?? this.isPosted,
      isVoided: isVoided ?? this.isVoided,
      postedAt: postedAt ?? this.postedAt,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
      metadata: metadata ?? this.metadata,
    );
  }

  FinancialTransactionModel voidTransaction({
    required String reason,
    DateTime? date,
  }) {
    return copyWith(
      isVoided: true,
      voidReason: reason,
      voidedAt: date ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static FinancialTransactionType _transactionTypeFromString(dynamic value) {
    final v = value?.toString() ?? '';
    return FinancialTransactionType.values.firstWhere(
          (e) => e.name == v,
      orElse: () => FinancialTransactionType.expense,
    );
  }

  static FinancialAccountType _accountTypeFromString(dynamic value) {
    final v = value?.toString() ?? '';
    return FinancialAccountType.values.firstWhere(
          (e) => e.name == v,
      orElse: () => FinancialAccountType.adjustment,
    );
  }

  static FinancialDirection _directionFromString(dynamic value) {
    final v = value?.toString() ?? '';
    return FinancialDirection.values.firstWhere(
          (e) => e.name == v,
      orElse: () => FinancialDirection.neutral,
    );
  }
}