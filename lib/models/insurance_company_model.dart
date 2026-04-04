// lib/models/insurance_company_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceCompany {
  String id;
  String name;
  String code; // الكود الموحد للشركة
  String contactPerson;
  String phone;
  String address;
  double discountPercentage; // نسبة الخصم
  DateTime contractStartDate;
  DateTime? contractEndDate;
  String status; // فعال، متوقف، معلق
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

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
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory InsuranceCompany.fromMap(Map<String, dynamic> map, String id) {
    // دالة مساعدة لتحويل التواريخ
    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (value is DateTime) return value;
      return DateTime.now();
    }

    DateTime? _parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      return _parseDateTime(value);
    }


    return InsuranceCompany(
      id: id,
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      contactPerson: map['contactPerson']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      contractStartDate: _parseDateTime(map['contractStartDate']),
      contractEndDate: _parseNullableDateTime(map['contractEndDate']),
      status: map['status']?.toString() ?? 'فعال',
      notes: map['notes']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
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
      'contractStartDate': contractStartDate.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // معلومات تنسيقية
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

  // التحقق من صلاحية العقد
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