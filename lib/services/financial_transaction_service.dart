import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/financial_transaction_model.dart';

class FinancialTransactionService {
  FinancialTransactionService._();

  static final instance = FinancialTransactionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String pharmacyId) {
    return _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('financial_transactions');
  }

  /// =========================
  /// Generic Create
  /// =========================

  Future<String> createTransaction(
      FinancialTransactionModel transaction,
      ) async {
    final ref = _collection(transaction.pharmacyId).doc();

    final model = transaction.copyWith(
      id: ref.id,
      updatedAt: DateTime.now(),
    );

    await ref.set(model.toMap());

    return ref.id;
  }

  /// =========================
  /// Sale Transaction
  /// =========================

  Future<String> registerSale({
    required String pharmacyId,
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    required String paymentMethod,
    required String createdBy,
    String? shiftId,
    String? employeeId,
    String? employeeName,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.sale,
      accountType: FinancialAccountType.salesRevenue,
      direction: FinancialDirection.inflow,
      amount: amount,
      transactionDate: DateTime.now(),
      referenceId: invoiceId,
      referenceNumber: invoiceNumber,
      referenceCollection: 'sales',
      paymentMethod: paymentMethod,
      shiftId: shiftId,
      employeeId: employeeId,
      employeeName: employeeName,
      createdBy: createdBy,
      title: 'عملية بيع',
      description: 'تسجيل فاتورة بيع',
      metadata: {
        'source': 'pos',
      },
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Refund Transaction
  /// =========================

  Future<String> registerRefund({
    required String pharmacyId,
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    required String paymentMethod,
    required String createdBy,
    String? shiftId,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.refund,
      accountType: FinancialAccountType.cashbox,
      direction: FinancialDirection.outflow,
      amount: amount,
      transactionDate: DateTime.now(),
      referenceId: invoiceId,
      referenceNumber: invoiceNumber,
      referenceCollection: 'sales',
      paymentMethod: paymentMethod,
      shiftId: shiftId,
      createdBy: createdBy,
      title: 'مرتجع بيع',
      description: 'استرجاع فاتورة',
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Expense Transaction
  /// =========================

  Future<String> registerExpense({
    required String pharmacyId,
    required double amount,
    required String title,
    required String createdBy,
    String? description,
    String? referenceId,
    String? shiftId,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.expense,
      accountType: FinancialAccountType.operatingExpense,
      direction: FinancialDirection.outflow,
      amount: amount,
      transactionDate: DateTime.now(),
      referenceId: referenceId,
      referenceCollection: 'expenses',
      shiftId: shiftId,
      createdBy: createdBy,
      title: title,
      description: description,
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Purchase Invoice
  /// =========================

  Future<String> registerPurchaseInvoice({
    required String pharmacyId,
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    required String supplierId,
    required String supplierName,
    required String createdBy,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.purchaseInvoice,
      accountType: FinancialAccountType.inventory,
      direction: FinancialDirection.payable,
      amount: amount,
      transactionDate: DateTime.now(),
      referenceId: invoiceId,
      referenceNumber: invoiceNumber,
      referenceCollection: 'purchase_invoices',
      supplierId: supplierId,
      supplierName: supplierName,
      createdBy: createdBy,
      title: 'فاتورة شراء',
      description: 'إضافة مخزون من المورد',
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Supplier Payment
  /// =========================

  Future<String> registerSupplierPayment({
    required String pharmacyId,
    required String supplierId,
    required String supplierName,
    required double amount,
    required String createdBy,
    String? paymentMethod,
    String? referenceId,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.supplierPayment,
      accountType: FinancialAccountType.supplierPayable,
      direction: FinancialDirection.outflow,
      amount: amount,
      transactionDate: DateTime.now(),
      supplierId: supplierId,
      supplierName: supplierName,
      paymentMethod: paymentMethod,
      referenceId: referenceId,
      createdBy: createdBy,
      title: 'دفعة مورد',
      description: 'سداد مستحقات المورد',
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Salary Payment
  /// =========================

  Future<String> registerSalaryPayment({
    required String pharmacyId,
    required String employeeId,
    required String employeeName,
    required double amount,
    required String createdBy,
    String? shiftId,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.salaryPayment,
      accountType: FinancialAccountType.payrollExpense,
      direction: FinancialDirection.outflow,
      amount: amount,
      transactionDate: DateTime.now(),
      employeeId: employeeId,
      employeeName: employeeName,
      shiftId: shiftId,
      createdBy: createdBy,
      title: 'راتب موظف',
      description: 'دفع راتب موظف',
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Insurance Claim
  /// =========================

  Future<String> registerInsuranceClaim({
    required String pharmacyId,
    required String insuranceCompanyId,
    required String insuranceCompanyName,
    required double amount,
    required String invoiceId,
    required String invoiceNumber,
    required String createdBy,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.insuranceClaim,
      accountType: FinancialAccountType.insuranceReceivable,
      direction: FinancialDirection.receivable,
      amount: amount,
      transactionDate: DateTime.now(),
      insuranceCompanyId: insuranceCompanyId,
      insuranceCompanyName: insuranceCompanyName,
      referenceId: invoiceId,
      referenceNumber: invoiceNumber,
      referenceCollection: 'sales',
      createdBy: createdBy,
      title: 'مطالبة تأمين',
      description: 'فاتورة مغطاة بالتأمين',
    );

    return createTransaction(tx);
  }


  /// =========================
  /// Insurance Collection
  /// =========================

  Future<String> registerInsuranceCollection({
    required String pharmacyId,
    required String insuranceCompanyId,
    required String insuranceCompanyName,
    required double amount,
    required String createdBy,
    String? paymentMethod,
    String? referenceId,
    String? referenceNumber,
    String? shiftId,
    String? notes,
  }) async {
    final tx = FinancialTransactionModel(
      pharmacyId: pharmacyId,
      type: FinancialTransactionType.insuranceCollection,
      accountType: FinancialAccountType.insuranceReceivable,
      direction: FinancialDirection.inflow,
      amount: amount,
      transactionDate: DateTime.now(),
      insuranceCompanyId: insuranceCompanyId,
      insuranceCompanyName: insuranceCompanyName,
      referenceId: referenceId,
      referenceNumber: referenceNumber,
      referenceCollection: 'insurance_collections',
      paymentMethod: paymentMethod,
      shiftId: shiftId,
      createdBy: createdBy,
      title: 'تحصيل تأمين',
      description: 'تحصيل مستحقات من شركة التأمين',
      notes: notes,
    );

    return createTransaction(tx);
  }

  /// =========================
  /// Void Transaction
  /// =========================

  Future<void> voidTransaction({
    required String pharmacyId,
    required String transactionId,
    required String reason,
  }) async {
    final ref = _collection(pharmacyId).doc(transactionId);

    await ref.update({
      'isVoided': true,
      'voidReason': reason,
      'voidedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// Stream Transactions
  /// =========================

  Stream<List<FinancialTransactionModel>> watchTransactions({
    required String pharmacyId,
    int limit = 100,
  }) {
    return _collection(pharmacyId)
        .orderBy('transactionDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => FinancialTransactionModel.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .toList(),
    );
  }

  /// =========================
  /// Totals
  /// =========================

  Future<double> calculateNetCashFlow({
    required String pharmacyId,
  }) async {
    final snapshot = await _collection(pharmacyId).get();

    double total = 0;

    for (final doc in snapshot.docs) {
      final tx = FinancialTransactionModel.fromMap(
        doc.data(),
        doc.id,
      );

      if (tx.isVoided) continue;

      total += tx.signedAmount;
    }

    return total;
  }
}