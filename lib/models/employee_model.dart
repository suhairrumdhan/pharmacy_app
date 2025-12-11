

import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  String id;                // UUID
  String name;              // الاسم
  String username;          // اسم المستخدم
  String password;              // الرمز الوظيفي
  String phone;             // رقم الهاتف
  String role;              // الدور أو الوظيفة
  DateTime hiringDate;      // تاريخ التعيين
  String contractType;      // نوع العقد (دوام كامل - دوام جزئي - متعاون)
  String status;            // حالة الموظف (نشط - موقوف - مستقيل)
  String idCardUrl;         // صورة البطاقة الشخصية
  List<String> certificatesUrls;   // مرفقات الشهادات
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;           // أرشفة منطقية

  Employee({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.phone,
    required this.role,
    required this.hiringDate,
    required this.contractType,
    required this.status,
    required this.idCardUrl,
    required this.certificatesUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  // من Map
  factory Employee.fromMap(String id, Map<String, dynamic> data) {
    return Employee(
      id: id,
      name: data['name'],
      username: data['username'],
      password: data['password'],
      phone: data['phone'],
      role: data['role'],
      hiringDate: (data['hiringDate'] as Timestamp).toDate(),
      contractType: data['contractType'],
      status: data['status'],
      idCardUrl: data['idCardUrl'] ?? '',
      certificatesUrls: List<String>.from(data['certificatesUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // إلى Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'password': password,
      'phone': phone,
      'role': role,
      'hiringDate': hiringDate,
      'contractType': contractType,
      'status': status,
      'idCardUrl': idCardUrl,
      'certificatesUrls': certificatesUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }
  // أضف هذه الدالة في الكلاس Employee في المودل
  Employee copyWith({
    String? name,
    String? username,
    String? password,
    String? phone,
    String? role,
    DateTime? hiringDate,
    String? contractType,
    String? status,
    String? idCardUrl,
    List<String>? certificatesUrls,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      hiringDate: hiringDate ?? this.hiringDate,
      contractType: contractType ?? this.contractType,
      status: status ?? this.status,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      certificatesUrls: certificatesUrls ?? this.certificatesUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted,
    );
  }
}

