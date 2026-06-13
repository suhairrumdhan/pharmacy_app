// lib/models/insurance_company_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceCompany {
  String id;
  String name;
  String code;
  String contactPerson;
  String phone;
  String address;
  double discountPercentage;
  DateTime contractStartDate;
  DateTime? contractEndDate;
  String status;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  /// =========================
  /// New financial fields
  /// =========================
  final double? openingReceivable;
  final double? currentReceivable;
  final double? totalClaims;
  final double? totalCollected;
  final double? totalRejected;
  final int? paymentTermDays;
  final String? claimPolicyNotes;

  InsuranceCompany({
    this.id = '',
    required this.name,
    required this.code,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.discountPercentage,
    required this.contractStartDate,
    this.contractEndDate,
    this.status = 'فعال',
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.openingReceivable,
    this.currentReceivable,
    this.totalClaims,
    this.totalCollected,
    this.totalRejected,
    this.paymentTermDays,
    this.claimPolicyNotes,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get effectiveOpeningReceivable => openingReceivable ?? 0.0;
  double get effectiveTotalClaims => totalClaims ?? 0.0;
  double get effectiveTotalCollected => totalCollected ?? 0.0;
  double get effectiveTotalRejected => totalRejected ?? 0.0;

  double get calculatedReceivable {
    if (currentReceivable != null) return currentReceivable!;
    return (effectiveOpeningReceivable +
        effectiveTotalClaims -
        effectiveTotalCollected -
        effectiveTotalRejected)
        .clamp(0.0, double.infinity);
  }

  bool get hasReceivable => calculatedReceivable > 0;
  bool get isActive => status == 'فعال';

  factory InsuranceCompany.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      return parseDateTime(value);
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return InsuranceCompany(
      id: id,
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      contactPerson: map['contactPerson']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      discountPercentage:
      (map['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      contractStartDate: parseDateTime(map['contractStartDate']),
      contractEndDate: parseNullableDateTime(map['contractEndDate']),
      status: map['status']?.toString() ?? 'فعال',
      notes: map['notes']?.toString() ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),

      // New financial fields
      openingReceivable: parseDouble(map['openingReceivable']),
      currentReceivable: parseDouble(map['currentReceivable']),
      totalClaims: parseDouble(map['totalClaims']),
      totalCollected: parseDouble(map['totalCollected']),
      totalRejected: parseDouble(map['totalRejected']),
      paymentTermDays: parseInt(map['paymentTermDays']),
      claimPolicyNotes: map['claimPolicyNotes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code.trim().toUpperCase(),
      'contactPerson': contactPerson,
      'phone': phone,
      'address': address,
      'discountPercentage': discountPercentage,
      'contractStartDate': Timestamp.fromDate(contractStartDate),
      'contractEndDate':
      contractEndDate != null ? Timestamp.fromDate(contractEndDate!) : null,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      // New financial fields
      'openingReceivable': openingReceivable,
      'currentReceivable': calculatedReceivable,
      'totalClaims': totalClaims,
      'totalCollected': totalCollected,
      'totalRejected': totalRejected,
      'paymentTermDays': paymentTermDays,
      'claimPolicyNotes': claimPolicyNotes,
    };
  }

  InsuranceCompany copyWith({
    String? id,
    String? name,
    String? code,
    String? contactPerson,
    String? phone,
    String? address,
    double? discountPercentage,
    String? status,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? openingReceivable,
    double? currentReceivable,
    double? totalClaims,
    double? totalCollected,
    double? totalRejected,
    int? paymentTermDays,
    String? claimPolicyNotes,
  }) {
    return InsuranceCompany(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      status: status ?? this.status,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openingReceivable: openingReceivable ?? this.openingReceivable,
      currentReceivable: currentReceivable ?? this.currentReceivable,
      totalClaims: totalClaims ?? this.totalClaims,
      totalCollected: totalCollected ?? this.totalCollected,
      totalRejected: totalRejected ?? this.totalRejected,
      paymentTermDays: paymentTermDays ?? this.paymentTermDays,
      claimPolicyNotes: claimPolicyNotes ?? this.claimPolicyNotes,
    );
  }

  String get formattedContractStartDate {
    return '${contractStartDate.day}/${contractStartDate.month}/${contractStartDate.year}';
  }

  String? get formattedContractEndDate {
    if (contractEndDate == null) return null;
    return '${contractEndDate!.day}/${contractEndDate!.month}/${contractEndDate!.year}';
  }

  String get formattedDiscount {
    return '${discountPercentage.toStringAsFixed(1)}%';
  }

  bool get isContractExpired {
    if (contractEndDate == null) return false;
    return contractEndDate!.isBefore(DateTime.now());
  }

  bool get isContractExpiringSoon {
    if (contractEndDate == null) return false;
    final now = DateTime.now();
    final difference = contractEndDate!.difference(now);
    return difference.inDays <= 30 && !isContractExpired;
  }
}