// lib/models/supplier_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  String id;
  String name;
  String contactPerson;
  String phone;
  String address;
  List<String> suppliedMedications; // أسماء الأدوية الموردة
  DateTime contractStartDate;
  DateTime? contractEndDate;
  String status; // فعال، متوقف، معلق
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

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
  })  : suppliedMedications = suppliedMedications ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Supplier.fromMap(Map<String, dynamic> map, String id) {
    // دالة مساعدة لتحويل التواريخ من Timestamp أو String
    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();

      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('❌ Error parsing DateTime from String: $value');
          return DateTime.now();
        }
      } else if (value is DateTime) {
        return value;
      }

      print('⚠️ Unknown date type: ${value.runtimeType}, value: $value');
      return DateTime.now();
    }

    // دالة مساعدة لتحويل contractEndDate (يمكن أن تكون null)
    DateTime? _parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      return _parseDateTime(value);
    }

    // دالة مساعدة لتحويل المصفوفة
    List<String> _parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    return Supplier(
      id: id,
      name: map['name']?.toString() ?? '',
      contactPerson: map['contactPerson']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      suppliedMedications: _parseStringList(map['suppliedMedications']),
      contractStartDate: _parseDateTime(map['contractStartDate']),
      contractEndDate: _parseNullableDateTime(map['contractEndDate']),
      status: map['status']?.toString() ?? 'فعال',
      notes: map['notes']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }


  Map<String, dynamic> toMap() {
    // تحويل التواريخ إلى String للتخزين في Firestore
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'address': address,
      'suppliedMedications': suppliedMedications,
      'contractStartDate': contractStartDate.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    );
  }
  // دالة إضافية لتنسيق التاريخ بشكل جميل
  String get formattedContractStartDate {
    return '${contractStartDate.day}/${contractStartDate.month}/${contractStartDate.year}';
  }

  String? get formattedContractEndDate {
    if (contractEndDate == null) return null;
    return '${contractEndDate!.day}/${contractEndDate!.month}/${contractEndDate!.year}';
  }

  // دالة للتحقق إذا كان العقد منتهي
  bool get isContractExpired {
    if (contractEndDate == null) return false;
    return contractEndDate!.isBefore(DateTime.now());
  }

  // دالة للتحقق إذا كان العقد سينتهي قريباً (خلال 30 يوم)
  bool get isContractExpiringSoon {
    if (contractEndDate == null) return false;
    final now = DateTime.now();
    final difference = contractEndDate!.difference(now);
    return difference.inDays <= 30 && !isContractExpired;
  }
}