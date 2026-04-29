import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;

  // ===== Core =====
  final String action;
  final String module;
  final String status;
  final String source;

  // ===== Context =====
  final String pharmacyId;

  // ===== Target =====
  final String targetType;
  final String targetId;
  final String? targetName;

  // ===== Actor =====
  final Map<String, dynamic> performedBy;

  // ===== Details =====
  final Map<String, dynamic> details;

  // ===== Optional =====
  final String? entityPath;

  // ===== Time =====
  final DateTime? createdAt;
  final DateTime? timestamp;

  const AuditLogModel({
    required this.id,
    required this.action,
    required this.module,
    required this.status,
    required this.source,
    required this.pharmacyId,
    required this.targetType,
    required this.targetId,
    this.targetName,
    required this.performedBy,
    required this.details,
    this.entityPath,
    this.createdAt,
    this.timestamp,
  });

  // =============================
  // 🔁 toMap for create/update
  // =============================
  Map<String, dynamic> toMap({
    bool includeServerTimestamps = false,
  }) {
    return {
      'action': action,
      'module': module,
      'status': status,
      'source': source,
      'pharmacyId': pharmacyId,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'performedBy': performedBy,
      'details': details,
      'entityPath': entityPath,
      'createdAt': includeServerTimestamps
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : null),
      'timestamp': includeServerTimestamps
          ? FieldValue.serverTimestamp()
          : (timestamp != null ? Timestamp.fromDate(timestamp!) : null),
    }..removeWhere((key, value) => value == null);
  }

  // =============================
  // 🔁 create payload فقط للإنشاء
  // =============================
  Map<String, dynamic> toCreateMap() {
    return {
      'action': action,
      'module': module,
      'status': status,
      'source': source,
      'pharmacyId': pharmacyId,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'performedBy': performedBy,
      'details': details,
      'entityPath': entityPath,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    }..removeWhere((key, value) => value == null);
  }

  // =============================
  // 🔄 fromMap
  // =============================
  factory AuditLogModel.fromMap(String id, Map<String, dynamic> map) {
    return AuditLogModel(
      id: id,
      action: (map['action'] ?? '').toString(),
      module: (map['module'] ?? '').toString(),
      status: (map['status'] ?? 'success').toString(),
      source: (map['source'] ?? 'desktop').toString(),
      pharmacyId: (map['pharmacyId'] ?? '').toString(),
      targetType: (map['targetType'] ?? '').toString(),
      targetId: (map['targetId'] ?? '').toString(),
      targetName: map['targetName']?.toString(),
      performedBy: _parseMap(map['performedBy']),
      details: _parseMap(map['details']),
      entityPath: map['entityPath']?.toString(),
      createdAt: _parseDateTime(map['createdAt']),
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  // =============================
  // 🛠 copyWith
  // =============================
  AuditLogModel copyWith({
    String? id,
    String? action,
    String? module,
    String? status,
    String? source,
    String? pharmacyId,
    String? targetType,
    String? targetId,
    String? targetName,
    Map<String, dynamic>? performedBy,
    Map<String, dynamic>? details,
    String? entityPath,
    DateTime? createdAt,
    DateTime? timestamp,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      action: action ?? this.action,
      module: module ?? this.module,
      status: status ?? this.status,
      source: source ?? this.source,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      performedBy: performedBy ?? this.performedBy,
      details: details ?? this.details,
      entityPath: entityPath ?? this.entityPath,
      createdAt: createdAt ?? this.createdAt,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // =============================
  // 🧠 Helpers
  // =============================
  String get formattedTime {
    final d = timestamp ?? createdAt;
    if (d == null) return '';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get actionLabel {
    switch (action) {
      case 'create_employee':
        return 'إضافة موظف';
      case 'update_employee':
        return 'تعديل موظف';
      case 'delete_employee':
        return 'حذف موظف';
      case 'toggle_employee_status':
        return 'تغيير حالة موظف';
      case 'create_sale':
        return 'إنشاء فاتورة';
      case 'refund_sale':
        return 'إرجاع فاتورة';
      case 'create_order':
        return 'إنشاء طلب';
      case 'update_order_status':
        return 'تحديث حالة طلب';
      case 'open_shift':
        return 'فتح وردية';
      case 'close_shift':
        return 'إغلاق وردية';
      case 'update_settings':
        return 'تحديث الإعدادات';
      case 'create_purchase_invoice':
        return 'إنشاء فاتورة مشتريات';
      case 'purchase_payment':
        return 'تسديد فاتورة مشتريات';
      case 'delete_purchase_invoice':
        return 'حذف فاتورة مشتريات';
      case 'create_supplier':
        return 'إضافة مورد';
      case 'update_supplier':
        return 'تعديل مورد';
      case 'delete_supplier':
        return 'حذف مورد';
      case 'create_insurance_company':
        return 'إضافة شركة تأمين';
      case 'update_insurance_company':
        return 'تعديل شركة تأمين';
      case 'delete_insurance_company':
        return 'حذف شركة تأمين';
      case 'create_medicine':
        return 'إضافة دواء';
      case 'update_medicine':
        return 'تعديل دواء';
      case 'delete_medicine':
        return 'حذف دواء';
      case 'adjust_medicine_stock':
        return 'تعديل المخزون';
      case 'import_medicines':
        return 'استيراد أدوية';
      case 'bulk_update_medicines':
        return 'تحديث جماعي للمخزون';
      default:
        return action;
    }
  }

  String get moduleLabel {
    switch (module) {
      case 'employees':
        return 'الموظفين';
      case 'sales':
        return 'المبيعات';
      case 'orders':
        return 'الطلبات';
      case 'inventory':
        return 'المخزون';
      case 'purchases':
        return 'المشتريات';
      case 'shifts':
        return 'الورديات';
      case 'settings':
        return 'الإعدادات';
      case 'insurance':
        return 'التأمين';
      default:
        return module;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'success':
        return 'نجاح';
      case 'failed':
        return 'فشل';
      case 'warning':
        return 'تحذير';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'desktop':
        return 'سطح المكتب';
      case 'mobile_user':
        return 'تطبيق المستخدم';
      case 'mobile_pharmacy':
        return 'تطبيق الصيدلية';
      case 'system':
        return 'النظام';
      case 'api':
        return 'API';
      default:
        return source;
    }
  }

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isWarning => status == 'warning';
  bool get isCancelled => status == 'cancelled';

  bool get hasTargetName => targetName != null && targetName!.trim().isNotEmpty;
  bool get hasDetails => details.isNotEmpty;
  bool get hasEntityPath => entityPath != null && entityPath!.trim().isNotEmpty;

  // =============================
  // 🛠 Safe parsers
  // =============================
  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(value as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
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

  @override
  String toString() {
    return 'AuditLogModel('
        'id: $id, '
        'action: $action, '
        'module: $module, '
        'status: $status, '
        'source: $source, '
        'pharmacyId: $pharmacyId, '
        'targetType: $targetType, '
        'targetId: $targetId, '
        'targetName: $targetName, '
        'performedBy: $performedBy, '
        'details: $details, '
        'entityPath: $entityPath, '
        'createdAt: $createdAt, '
        'timestamp: $timestamp'
        ')';
  }
}