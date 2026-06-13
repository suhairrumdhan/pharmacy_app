import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String roleId;
  final String roleDisplay;
  final String contractType;
  final DateTime hiringDate;
  final Map<String, bool> permissionOverrides;
  final bool hasCustomPermissions;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> createdBy;
  final DateTime? updatedAt;
  final Map<String, dynamic>? updatedBy;
  final String? password;
  final String? idCardImageUrl;
  final String? certificateImageUrl;

  // =========================
  // Financial / HR fields
  // =========================
  final double? baseSalary;
  final String? salaryType; // monthly / daily / hourly
  final double? hourlyRate;
  final double? salesCommissionPercent;
  final double? advancesBalance;
  final double? deductionsBalance;
  final double? totalPaidSalary;
  final bool affectsFinance;
  final String? nationalId;
  final String? bankAccount;

  Employee({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.roleId,
    required this.roleDisplay,
    required this.contractType,
    required this.hiringDate,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.password,
    this.idCardImageUrl,
    this.certificateImageUrl,
    Map<String, bool>? permissionOverrides,
    bool? hasCustomPermissions,
    this.baseSalary,
    this.salaryType,
    this.hourlyRate,
    this.salesCommissionPercent,
    this.advancesBalance,
    this.deductionsBalance,
    this.totalPaidSalary,
    this.affectsFinance = true,
    this.nationalId,
    this.bankAccount,
  })  : permissionOverrides = permissionOverrides ?? <String, bool>{},
        hasCustomPermissions = hasCustomPermissions ?? false;

  factory Employee.fromMap(String id, Map<String, dynamic> data) {
    try {
      final idCardUrl = data['idCardImageUrl']?.toString();
      final certificateUrl = data['certificateImageUrl']?.toString();

      final parsedRoleId =
      _parseString(data['roleId'], defaultValue: 'pharmacist');

      return Employee(
        id: id,
        name: _parseString(data['name']),
        username: _parseString(data['username']),
        phone: _parseString(data['phone']),
        roleId: parsedRoleId,
        roleDisplay: _parseString(
          data['roleDisplay'],
          defaultValue: _defaultRoleDisplay(parsedRoleId),
        ),
        contractType:
        _parseString(data['contractType'], defaultValue: 'دوام كامل'),
        hiringDate: _parseDateTime(data['hiringDate']),
        isActive: data['isActive'] == true,
        createdAt: _parseDateTime(data['createdAt']),
        createdBy: _parseMap(data['createdBy']),
        updatedAt: _parseOptionalDateTime(data['updatedAt']),
        updatedBy: _parseOptionalMap(data['updatedBy']),
        password: data['password']?.toString(),
        permissionOverrides:
        _parsePermissionOverrides(data['permissionOverrides']),
        hasCustomPermissions: data['hasCustomPermissions'] == true,
        idCardImageUrl: idCardUrl,
        certificateImageUrl: certificateUrl,

        baseSalary: _parseOptionalDouble(data['baseSalary']),
        salaryType: data['salaryType']?.toString(),
        hourlyRate: _parseOptionalDouble(data['hourlyRate']),
        salesCommissionPercent:
        _parseOptionalDouble(data['salesCommissionPercent']),
        advancesBalance: _parseOptionalDouble(data['advancesBalance']),
        deductionsBalance: _parseOptionalDouble(data['deductionsBalance']),
        totalPaidSalary: _parseOptionalDouble(data['totalPaidSalary']),
        affectsFinance:
        data['affectsFinance'] == null ? true : data['affectsFinance'] == true,
        nationalId: data['nationalId']?.toString(),
        bankAccount: data['bankAccount']?.toString(),
      );
    } catch (_) {
      final parsedRoleId =
      _parseString(data['roleId'], defaultValue: 'pharmacist');

      return Employee(
        id: id,
        name: _parseString(data['name']),
        username: _parseString(data['username']),
        phone: _parseString(data['phone']),
        roleId: parsedRoleId,
        roleDisplay: _parseString(
          data['roleDisplay'],
          defaultValue: _defaultRoleDisplay(parsedRoleId),
        ),
        contractType:
        _parseString(data['contractType'], defaultValue: 'دوام كامل'),
        hiringDate: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: {},
        updatedAt: null,
        updatedBy: null,
        password: data['password']?.toString(),
        permissionOverrides:
        _parsePermissionOverrides(data['permissionOverrides']),
        hasCustomPermissions: data['hasCustomPermissions'] == true,
        idCardImageUrl: data['idCardImageUrl']?.toString(),
        certificateImageUrl: data['certificateImageUrl']?.toString(),

        baseSalary: _parseOptionalDouble(data['baseSalary']),
        salaryType: data['salaryType']?.toString(),
        hourlyRate: _parseOptionalDouble(data['hourlyRate']),
        salesCommissionPercent:
        _parseOptionalDouble(data['salesCommissionPercent']),
        advancesBalance: _parseOptionalDouble(data['advancesBalance']),
        deductionsBalance: _parseOptionalDouble(data['deductionsBalance']),
        totalPaidSalary: _parseOptionalDouble(data['totalPaidSalary']),
        affectsFinance:
        data['affectsFinance'] == null ? true : data['affectsFinance'] == true,
        nationalId: data['nationalId']?.toString(),
        bankAccount: data['bankAccount']?.toString(),
      );
    }
  }

  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
        return Map<String, bool>.from(
          value.map(
                (key, value) => MapEntry(key.toString(), value == true),
          ),
        );
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  static String _defaultRoleDisplay(String roleId) {
    switch (roleId) {
      case 'admin':
        return 'إداري';
      case 'pharmacist':
        return 'صيدلي';
      case 'cashier':
        return 'محاسب';
      default:
        return 'موظف';
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'roleId': roleId,
      'roleDisplay': roleDisplay,
      'contractType': contractType,
      'hiringDate': Timestamp.fromDate(hiringDate),
      'isActive': isActive,
      'permissionOverrides': permissionOverrides,
      'hasCustomPermissions': hasCustomPermissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,

      // Financial / HR fields
      'baseSalary': baseSalary,
      'salaryType': salaryType,
      'hourlyRate': hourlyRate,
      'salesCommissionPercent': salesCommissionPercent,
      'advancesBalance': advancesBalance,
      'deductionsBalance': deductionsBalance,
      'totalPaidSalary': totalPaidSalary,
      'affectsFinance': affectsFinance,
      'nationalId': nationalId,
      'bankAccount': bankAccount,
    };

    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    if (updatedBy != null) {
      map['updatedBy'] = updatedBy;
    }
    if (password != null) {
      map['password'] = password;
    }
    if (idCardImageUrl != null && idCardImageUrl!.isNotEmpty) {
      map['idCardImageUrl'] = idCardImageUrl;
    }
    if (certificateImageUrl != null && certificateImageUrl!.isNotEmpty) {
      map['certificateImageUrl'] = certificateImageUrl;
    }

    return map;
  }

  Employee copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? roleId,
    String? roleDisplay,
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
    String? idCardImageUrl,
    String? certificateImageUrl,
    double? baseSalary,
    String? salaryType,
    double? hourlyRate,
    double? salesCommissionPercent,
    double? advancesBalance,
    double? deductionsBalance,
    double? totalPaidSalary,
    bool? affectsFinance,
    String? nationalId,
    String? bankAccount,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      roleDisplay: roleDisplay ?? this.roleDisplay,
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
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      certificateImageUrl: certificateImageUrl ?? this.certificateImageUrl,
      baseSalary: baseSalary ?? this.baseSalary,
      salaryType: salaryType ?? this.salaryType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      salesCommissionPercent:
      salesCommissionPercent ?? this.salesCommissionPercent,
      advancesBalance: advancesBalance ?? this.advancesBalance,
      deductionsBalance: deductionsBalance ?? this.deductionsBalance,
      totalPaidSalary: totalPaidSalary ?? this.totalPaidSalary,
      affectsFinance: affectsFinance ?? this.affectsFinance,
      nationalId: nationalId ?? this.nationalId,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }

  double get effectiveSalary => baseSalary ?? 0.0;
  double get effectiveAdvances => advancesBalance ?? 0.0;
  double get effectiveDeductions => deductionsBalance ?? 0.0;

  double get netSalaryEstimate {
    return (effectiveSalary - effectiveDeductions)
        .clamp(0.0, double.infinity);
  }

  bool get hasFinancialProfile => affectsFinance && effectiveSalary > 0;

  bool get isHourlyEmployee =>
      (salaryType ?? '').toLowerCase().trim() == 'hourly';

  bool get isMonthlyEmployee =>
      (salaryType ?? '').toLowerCase().trim() == 'monthly';

  @override
  String toString() {
    return 'Employee('
        'id: $id, '
        'name: $name, '
        'username: $username, '
        'roleId: $roleId, '
        'roleDisplay: $roleDisplay, '
        'isActive: $isActive, '
        'baseSalary: $baseSalary, '
        'salaryType: $salaryType, '
        'idCardImageUrl: $idCardImageUrl, '
        'certificateImageUrl: $certificateImageUrl'
        ')';
  }

  bool get hasIdCard => idCardImageUrl != null && idCardImageUrl!.isNotEmpty;

  bool get hasCertificate =>
      certificateImageUrl != null && certificateImageUrl!.isNotEmpty;

  String? get idCardFileName {
    if (idCardImageUrl == null || idCardImageUrl!.isEmpty) return null;
    try {
      final uri = Uri.parse(idCardImageUrl!);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'ملف_الهوية';
    } catch (_) {
      return 'ملف_الهوية';
    }
  }

  String? get certificateFileName {
    if (certificateImageUrl == null || certificateImageUrl!.isEmpty) {
      return null;
    }
    try {
      final uri = Uri.parse(certificateImageUrl!);
      return uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'ملف_الشهادة';
    } catch (_) {
      return 'ملف_الشهادة';
    }
  }
}