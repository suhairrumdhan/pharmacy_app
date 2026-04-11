import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyOrderModel {
  final String id;

  /// المستخدم
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userEmail;

  /// المستفيد
  final String beneficiaryId;
  final String beneficiaryName;
  final String beneficiaryType; // self / family
  final String? relationLabel;

  final String? gender;
  final int? age;
  final String? bloodType;

  final List<String> allergies;
  final List<String> healthConditions;
  final List<String> currentMedications;

  final bool hasHealthData;

  /// التأمين
  final bool insuranceEnabled;
  final List<String> insuranceCompanyCodes;
  final List<String> insuranceCompanyNames;
  final List<String> insuranceCardNumbers;

  /// الأدوية
  final List<PharmacyOrderItem> medicines;

  /// الطلب
  final String status;
  final String statusLabel;

  final String? userNote;
  final String? pharmacyNote;

  final String requestSource; // manual / prescription

  final double? totalPrice;

  final String? prescriptionImageUrl;
  final String? prescriptionText;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  PharmacyOrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userEmail,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.beneficiaryType,
    this.relationLabel,
    this.gender,
    this.age,
    this.bloodType,
    this.allergies = const [],
    this.healthConditions = const [],
    this.currentMedications = const [],
    this.hasHealthData = false,
    this.insuranceEnabled = false,
    this.insuranceCompanyCodes = const [],
    this.insuranceCompanyNames = const [],
    this.insuranceCardNumbers = const [],
    this.medicines = const [],
    required this.status,
    required this.statusLabel,
    this.userNote,
    this.pharmacyNote,
    required this.requestSource,
    this.totalPrice,
    this.prescriptionImageUrl,
    this.prescriptionText,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
  });

  /// 🔥 تحويل من Firestore
  factory PharmacyOrderModel.fromFirestore(
      String id,
      Map<String, dynamic> map,
      ) {
    final user = Map<String, dynamic>.from(map['user'] ?? {});
    final beneficiary = Map<String, dynamic>.from(map['beneficiary'] ?? {});
    final insurance = Map<String, dynamic>.from(map['insurance'] ?? {});

    return PharmacyOrderModel(
      id: id,

      /// المستخدم
      userId: user['userId'] ?? '',
      userName: user['name'] ?? '',
      userPhone: user['phone'],
      userEmail: user['email'],

      /// المستفيد
      beneficiaryId: beneficiary['beneficiaryId'] ?? '',
      beneficiaryName: beneficiary['name'] ?? '',
      beneficiaryType: beneficiary['type'] ?? 'self',
      relationLabel: beneficiary['relationLabel'],

      gender: beneficiary['gender'],
      age: _toInt(beneficiary['age']),
      bloodType: beneficiary['bloodType'],

      allergies: _toStringList(beneficiary['allergies']),
      healthConditions: _toStringList(beneficiary['healthConditions']),
      currentMedications:
      _toStringList(beneficiary['currentMedications']),

      hasHealthData: beneficiary['hasHealthData'] == true,

      /// التأمين
      insuranceEnabled: insurance['enabled'] == true,
      insuranceCompanyCodes:
      _toStringList(insurance['companyCodes']),
      insuranceCompanyNames:
      _toStringList(insurance['companyNames']),
      insuranceCardNumbers:
      _toStringList(insurance['cardNumbers']),

      /// الأدوية
      medicines: (map['medicines'] as List<dynamic>? ?? [])
          .map((e) => PharmacyOrderItem.fromMap(
        Map<String, dynamic>.from(e),
      ))
          .toList(),

      /// الطلب
      status: map['status'] ?? 'pending',
      statusLabel: map['statusLabel'] ?? '',

      userNote: map['userNote'],
      pharmacyNote: map['pharmacyNote'],

      requestSource: map['requestSource'] ?? 'manual',

      totalPrice: _toDouble(map['estimatedTotalPrice']),

      prescriptionImageUrl: map['prescriptionImageUrl'],
      prescriptionText: map['prescriptionText'],

      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      completedAt: _toDate(map['completedAt']),
      cancelledAt: _toDate(map['cancelledAt']),
    );
  }

  /// 🔥 Helpers

  bool get isFamily => beneficiaryType == 'family';

  bool get hasInsurance => insuranceEnabled && insuranceCompanyCodes.isNotEmpty;

  String get primaryInsurance =>
      insuranceCompanyNames.isNotEmpty
          ? insuranceCompanyNames.first
          : '';

  int get medicinesCount => medicines.length;
}
class PharmacyOrderItem {
  final String name;
  final String? strength;
  final String? dosageForm;
  final int quantity;
  final double? price;
  final bool? available;

  PharmacyOrderItem({
    required this.name,
    this.strength,
    this.dosageForm,
    required this.quantity,
    this.price,
    this.available,
  });

  factory PharmacyOrderItem.fromMap(Map<String, dynamic> map) {
    return PharmacyOrderItem(
      name: map['requestedName'] ?? '',
      strength: map['strength'],
      dosageForm: map['dosageForm'],
      quantity: _toInt(map['quantity']) ?? 1,
      price: _toDouble(map['estimatedPrice']),
      available: map['availableAtSelection'],
    );
  }
}


DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  return DateTime.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}