// models/employee_model.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';

enum Permission {
  // إدارة الطلبات
  viewOrders,
  editOrders,
  deleteOrders,
  updateOrderStatus,

  // إدارة المنتجات
  viewProducts,
  addProducts,
  editProducts,
  deleteProducts,
  manageInventory,

  // إدارة العملاء
  viewCustomers,
  editCustomers,

  // إدارة التقارير
  viewReports,
  generateReports,

  // إدارة الموظفين
  viewEmployees,
  addEmployees,
  editEmployees,
  deleteEmployees,
  manageRoles,

  // إدارة الإعدادات
  viewSettings,
  editSettings,

  // إدارة المبيعات
  processSales,
  viewSalesHistory,

  // إدارة الخصومات
  applyDiscounts,
  managePromotions,

  // صلاحيات خاصة
  manageAll,
  pharmacyOwner,
}

class PharmacyEmployee {
  final String id;
  final String pharmacyId;
  final String fullName;
  final String username;
  final String encryptedPassword;
  final String email; //remove this
  final String phoneNumber;
  final String roleId;
  final DateTime joinDate;
  final bool isActive;
  final Map<String, dynamic>? additionalInfo;

  PharmacyEmployee({
    required this.id,
    required this.pharmacyId,
    required this.fullName,
    required this.username,
    required this.encryptedPassword,
    required this.email,
    required this.phoneNumber,
    required this.roleId,
    required this.joinDate,
    required this.isActive,
    this.additionalInfo,
  });

  static String encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String password) {
    return encryptPassword(password) == encryptedPassword;
  }

  factory PharmacyEmployee.fromMap(Map<String, dynamic> data) {
    return PharmacyEmployee(
      id: data['id'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'] ?? '',
      encryptedPassword: data['encryptedPassword'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      roleId: data['roleId'] ?? '',
      joinDate: data['joinDate'] != null
          ? DateTime.parse(data['joinDate'])
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      additionalInfo: data['additionalInfo'] != null
          ? Map<String, dynamic>.from(data['additionalInfo'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'fullName': fullName,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'email': email,
      'phoneNumber': phoneNumber,
      'roleId': roleId,
      'joinDate': joinDate.toIso8601String(),
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  PharmacyEmployee copyWith({
    String? id,
    String? pharmacyId,
    String? fullName,
    String? username,
    String? encryptedPassword,
    String? email,
    String? phoneNumber,
    String? roleId,
    DateTime? joinDate,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
  }) {
    return PharmacyEmployee(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roleId: roleId ?? this.roleId,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

class EmployeeRole {
  final String id;
  final String pharmacyId;
  final String name;
  final String description;
  final List<Permission> permissions;
  final DateTime createdAt;
  final bool isEditable;

  EmployeeRole({
    required this.id,
    required this.pharmacyId,
    required this.name,
    required this.description,
    required this.permissions,
    required this.createdAt,
    this.isEditable = true,
  });

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<Permission> requiredPermissions) {
    return permissions.any((perm) => requiredPermissions.contains(perm));
  }

  bool hasAllPermissions(List<Permission> requiredPermissions) {
    return requiredPermissions.every((perm) => permissions.contains(perm));
  }

  factory EmployeeRole.fromMap(Map<String, dynamic> data) {
    return EmployeeRole(
      id: data['id'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      permissions: (data['permissions'] as List<dynamic>?)
          ?.map((p) => Permission.values.firstWhere(
            (e) => e.toString() == p,
        orElse: () => Permission.viewProducts,
      ))
          .toList() ??
          [Permission.viewProducts],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      isEditable: data['isEditable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'name': name,
      'description': description,
      'permissions': permissions.map((p) => p.toString()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isEditable': isEditable,
    };
  }

  EmployeeRole copyWith({
    String? id,
    String? pharmacyId,
    String? name,
    String? description,
    List<Permission>? permissions,
    DateTime? createdAt,
    bool? isEditable,
  }) {
    return EmployeeRole(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      isEditable: isEditable ?? this.isEditable,
    );
  }

  // أدوار افتراضية
  static List<EmployeeRole> getDefaultRoles(String pharmacyId) {
    final now = DateTime.now();

    return [
      EmployeeRole(
        id: 'owner',
        pharmacyId: pharmacyId,
        name: 'المالك',
        description: 'صلاحيات كاملة على النظام',
        permissions: Permission.values.toList(),
        createdAt: now,
        isEditable: false,
      ),
      EmployeeRole(
        id: 'manager',
        pharmacyId: pharmacyId,
        name: 'المدير',
        description: 'إدارة كاملة ما عدا إعدادات المالك',
        permissions: Permission.values
            .where((p) => p != Permission.pharmacyOwner)
            .toList(),
        createdAt: now,
      ),
      EmployeeRole(
        id: 'pharmacist',
        pharmacyId: pharmacyId,
        name: 'صيدلي',
        description: 'إدارة الطلبات، المنتجات، والمبيعات',
        permissions: [
          Permission.viewOrders,
          Permission.editOrders,
          Permission.updateOrderStatus,
          Permission.viewProducts,
          Permission.addProducts,
          Permission.editProducts,
          Permission.manageInventory,
          Permission.viewCustomers,
          Permission.processSales,
          Permission.viewSalesHistory,
          Permission.applyDiscounts,
        ],
        createdAt: now,
      ),
      EmployeeRole(
        id: 'assistant',
        pharmacyId: pharmacyId,
        name: 'مساعد صيدلي',
        description: 'مهام مساعدة في الطلبات والمبيعات',
        permissions: [
          Permission.viewOrders,
          Permission.updateOrderStatus,
          Permission.viewProducts,
          Permission.viewCustomers,
          Permission.processSales,
        ],
        createdAt: now,
      ),
      EmployeeRole(
        id: 'cashier',
        pharmacyId: pharmacyId,
        name: 'كاشير',
        description: 'المبيعات ومعالجة الدفعات فقط',
        permissions: [
          Permission.processSales,
          Permission.viewSalesHistory,
          Permission.applyDiscounts,
        ],
        createdAt: now,
      ),
    ];
  }
}