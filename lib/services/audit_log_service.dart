import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

abstract class AuditActions {
  static const createEmployee = 'create_employee';
  static const updateEmployee = 'update_employee';
  static const deleteEmployee = 'delete_employee';
  static const toggleEmployeeStatus = 'toggle_employee_status';

  static const createExpense = 'create_expense';
  static const updateExpense = 'update_expense';
  static const deleteExpense = 'delete_expense';
  static const exportFinanceReport = 'export_finance_report';

  static const createSale = 'create_sale';
  static const refundSale = 'refund_sale';

  static const createOrder = 'create_order';
  static const updateOrderStatus = 'update_order_status';

  static const openShift = 'open_shift';
  static const closeShift = 'close_shift';
  static const closeShiftByAdmin = 'close_shift_by_admin';

  static const updateSettings = 'update_settings';
  static const createPurchaseInvoice = 'create_purchase_invoice';
  static const purchasePayment = 'purchase_payment';
  static const deletePurchaseInvoice = 'delete_purchase_invoice';

  static const createSupplier = 'create_supplier';
  static const updateSupplier = 'update_supplier';
  static const deleteSupplier = 'delete_supplier';

  // ✅ أضيفي هذه
  static const createInsuranceCompany = 'create_insurance_company';
  static const updateInsuranceCompany = 'update_insurance_company';
  static const deleteInsuranceCompany = 'delete_insurance_company';

  static const createMedicine = 'create_medicine';
  static const updateMedicine = 'update_medicine';
  static const deleteMedicine = 'delete_medicine';
  static const adjustMedicineStock = 'adjust_medicine_stock';
  static const importMedicines = 'import_medicines';
  static const bulkUpdateMedicines = 'bulk_update_medicines';
}

abstract class AuditModules {
  static const employees = 'employees';
  static const sales = 'sales';
  static const inventory = 'inventory';
  static const orders = 'orders';
  static const purchases = 'purchases';
  static const shifts = 'shifts';
  static const settings = 'settings';
  static const insurance = 'insurance';
  static const suppliers = 'suppliers';
  static const finance = 'finance';
}

abstract class AuditStatus {
  static const success = 'success';
  static const failed = 'failed';
  static const warning = 'warning';
  static const cancelled = 'cancelled';
}

abstract class AuditSources {
  static const desktop = 'desktop';
  static const mobileUser = 'mobile_user';
  static const mobilePharmacy = 'mobile_pharmacy';
  static const system = 'system';
  static const api = 'api';
}

abstract class AuditTargetTypes {
  static const employee = 'employee';
  static const order = 'order';
  static const sale = 'sale';
  static const medicine = 'medicine';
  static const purchase = 'purchase';
  static const shift = 'shift';
  static const settings = 'settings';
  static const insuranceCompany = 'insurance_company';
  static const supplier = 'supplier';
  static const expense = 'expense';
  static const financeReport = 'finance_report';
}

class AuditLogService {
  AuditLogService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logsRef(String pharmacyId) {
    return _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('audit_logs');
  }

  Future<void> log({
    required String pharmacyId,
    required String action,
    required String module,
    required String status,
    required String source,
    required String targetType,
    required String targetId,
    String? targetName,
    required Map<String, dynamic> performedBy,
    Map<String, dynamic>? details,
    String? entityPath,
  }) async {
    final doc = _logsRef(pharmacyId).doc();

    final model = AuditLogModel(
      id: doc.id,
      action: action,
      module: module,
      status: status,
      source: source,
      pharmacyId: pharmacyId,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      performedBy: performedBy,
      details: details ?? const {},
      entityPath: entityPath,
      createdAt: null,
      timestamp: null,
    );

    await doc.set(model.toCreateMap());
  }

  Future<void> logSuccess({
    required String pharmacyId,
    required String action,
    required String module,
    required String targetType,
    required String targetId,
    String? targetName,
    required Map<String, dynamic> performedBy,
    Map<String, dynamic>? details,
    String? entityPath,
    String source = AuditSources.desktop,
  }) async {
    await log(
      pharmacyId: pharmacyId,
      action: action,
      module: module,
      status: AuditStatus.success,
      source: source,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      performedBy: performedBy,
      details: details,
      entityPath: entityPath,
    );
  }

  Future<void> logFailure({
    required String pharmacyId,
    required String action,
    required String module,
    required String targetType,
    required String targetId,
    String? targetName,
    required Map<String, dynamic> performedBy,
    Map<String, dynamic>? details,
    String? entityPath,
    String source = AuditSources.desktop,
  }) async {
    await log(
      pharmacyId: pharmacyId,
      action: action,
      module: module,
      status: AuditStatus.failed,
      source: source,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      performedBy: performedBy,
      details: details,
      entityPath: entityPath,
    );
  }

  Stream<List<AuditLogModel>> watchLogs(String pharmacyId) {
    return _logsRef(pharmacyId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => AuditLogModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<List<AuditLogModel>> fetchLogs({
    required String pharmacyId,
    int limit = 100,
  }) async {
    final snapshot = await _logsRef(pharmacyId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AuditLogModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}