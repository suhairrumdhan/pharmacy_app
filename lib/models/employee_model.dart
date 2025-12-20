import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String roleId; // For permission lookup
  final String contractType;
  final DateTime hiringDate;
  final Map<String, bool> permissionOverrides; // Employee-specific overrides
  final bool hasCustomPermissions; // Flag to enable/disable custom permissions
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> createdBy;
  final DateTime? updatedAt;
  final Map<String, dynamic>? updatedBy;
  final String? password;
  final String? idCardUrl; // رابط صورة البطاقة
  final String? certificateUrl; // رابط الشهادة
  final List<String> certificatesUrls; // قائمة روابط الشهادات (إذا متعددة)

  Employee({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.roleId,
    required this.contractType,
    required this.hiringDate,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.password,
    this.idCardUrl,
    this.certificateUrl,
    List<String>? certificatesUrls,
    Map<String, bool>? permissionOverrides,
    bool? hasCustomPermissions, // إضافة معامل اختياري
  }) :
        permissionOverrides = permissionOverrides ?? {},
        certificatesUrls = certificatesUrls ?? [],
        hasCustomPermissions = hasCustomPermissions ?? false; // القيمة الافتراضية

  factory Employee.fromMap(String id, Map<String, dynamic> data) {
    try {
      return Employee(
        id: id,
        name: _parseString(data['name']),
        username: _parseString(data['username']),
        phone: _parseString(data['phone']),
        roleId: _parseString(data['roleId']), // تأكد من وجود هذا الحقل
        contractType: _parseString(data['contractType'], defaultValue: 'دوام كامل'),
        hiringDate: _parseDateTime(data['hiringDate']),
        isActive: data['isActive'] == true,
        createdAt: _parseDateTime(data['createdAt']),
        createdBy: _parseMap(data['createdBy']),
        updatedAt: _parseOptionalDateTime(data['updatedAt']),
        updatedBy: _parseOptionalMap(data['updatedBy']),
        password: data['password']?.toString(),
        permissionOverrides: _parsePermissionOverrides(data['permissionOverrides']),
        hasCustomPermissions: data['hasCustomPermissions'] == true,
        idCardUrl: data['idCardUrl']?.toString(),
        certificateUrl: data['certificateUrl']?.toString(),
        certificatesUrls: _parseStringList(data['certificatesUrls']),
      );
    } catch (e, stackTrace) {
      print('Error parsing Employee with id $id: $e');
      print('Data: $data');
      print('Stack trace: $stackTrace');

      // Fallback employee with safe defaults
      return Employee(
        id: id,
        name: _parseString(data['name']),
        username: _parseString(data['username']),
        phone: _parseString(data['phone']),
        roleId: _parseString(data['roleId'], defaultValue: 'pharmacist'), // قيمة افتراضية آمنة
        contractType: _parseString(data['contractType'], defaultValue: 'دوام كامل'),
        hiringDate: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: {},
      );
    }
  }

  // Helper methods for safe parsing
  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value == null) return {};
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic>? _parseOptionalMap(dynamic value) {
    if (value == null) return null;
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }

  static Map<String, bool> _parsePermissionOverrides(dynamic value) {
    if (value == null) return {};
    try {
      if (value is Map) {
        return Map<String, bool>.from(value.map(
                (key, value) => MapEntry(key.toString(), value == true)
        ));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    try {
      if (value is List) {
        return List<String>.from(value.map((e) => e.toString()));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'roleId': roleId,
      'contractType': contractType,
      'hiringDate': Timestamp.fromDate(hiringDate),
      'isActive': isActive,
      'permissionOverrides': permissionOverrides,
      'hasCustomPermissions': hasCustomPermissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (password != null) 'password': password,
      if (idCardUrl != null) 'idCardUrl': idCardUrl,
      if (certificateUrl != null) 'certificateUrl': certificateUrl,
      if (certificatesUrls.isNotEmpty) 'certificatesUrls': certificatesUrls,
    };
  }

  // دالة copyWith لإنشاء نسخة معدلة من الكائن
  Employee copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? roleId,
    String? contractType,
    DateTime? hiringDate,
    bool? isActive,
    Map<String, bool>? permissionOverrides,
    bool? hasCustomPermissions,
    DateTime? createdAt,
    Map<String, dynamic>? createdBy,
    DateTime? updatedAt,
    Map<String, dynamic>? updatedBy,
    String? password,
    String? idCardUrl,
    String? certificateUrl,
    List<String>? certificatesUrls,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      contractType: contractType ?? this.contractType,
      hiringDate: hiringDate ?? this.hiringDate,
      isActive: isActive ?? this.isActive,
      permissionOverrides: permissionOverrides ?? this.permissionOverrides,
      hasCustomPermissions: hasCustomPermissions ?? this.hasCustomPermissions,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      password: password ?? this.password,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      certificatesUrls: certificatesUrls ?? this.certificatesUrls,
    );
  }

  @override
  String toString() {
    return 'Employee(id: $id, name: $name, username: $username, roleId: $roleId, hasCustomPermissions: $hasCustomPermissions, isActive: $isActive)';
  }
}