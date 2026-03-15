import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/finance_model.dart';
import 'auth_controller.dart';
import 'purchase_controller.dart';

class FinanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AuthController _authCtrl;
  late PurchaseController _purchaseCtrl;

  final RxBool isLoading = false.obs;
  final Rx<FinanceOverview> overview = FinanceOverview.empty().obs;
  final RxList<ExpenseItem> expenses = <ExpenseItem>[].obs;

  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;

  String get _pharmacyId => _authCtrl.pharmacyId;

  CollectionReference<Map<String, dynamic>> get _salesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('sales');

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('expenses');

  CollectionReference<Map<String, dynamic>> get _employeesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('employees');

  CollectionReference<Map<String, dynamic>> get _salaryPaymentsCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('salary_payments');

  @override
  void onInit() {
    super.onInit();
    _authCtrl = Get.find<AuthController>();
    _purchaseCtrl = Get.find<PurchaseController>();

    ever(_authCtrl.pharmacyData, (_) {
      if (_pharmacyId.isNotEmpty) {
        loadFinanceData();
      }
    });

    if (_pharmacyId.isNotEmpty) {
      loadFinanceData();
    }
  }

  Future<void> loadFinanceData() async {
    if (_pharmacyId.isEmpty) return;

    try {
      isLoading.value = true;

      await _purchaseCtrl.loadInvoices();
      await _loadExpenses();

      final salesSnapshot = await _salesCollection.get();
      final employeesSnapshot = await _employeesCollection.get();
      final salaryPaymentsSnapshot = await _salaryPaymentsCollection.get();

      final salesDocs = salesSnapshot.docs.map((e) => e.data()).toList();
      final employeeDocs = employeesSnapshot.docs.map((e) => e.data()).toList();
      final salaryPaymentDocs = salaryPaymentsSnapshot.docs.map((e) => e.data()).toList();

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final currentYear = now.year;

      double salesMonth = 0;
      double salesYear = 0;
      double receivables = 0;

      double cashIn = 0;
      double bankIn = 0;

      for (final sale in salesDocs) {
        final date = _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']) ?? now;
        final total = _toDouble(sale['total']);
        final paid = _toDouble(sale['paidAmount'] ?? sale['paid']);
        final paymentMethod = '${sale['paymentMethod'] ?? 'cash'}'.toLowerCase();

        if (date.year == currentYear) {
          salesYear += total;
        }

        if (date.year == currentMonth.year && date.month == currentMonth.month) {
          salesMonth += total;
        }

        final remaining = (total - paid).clamp(0.0, double.infinity);
        receivables += remaining;

        if (paymentMethod.contains('cash')) {
          cashIn += paid > 0 ? paid : total;
        } else {
          bankIn += paid > 0 ? paid : total;
        }
      }

      double expensesMonth = 0;
      double expensesYear = 0;
      double cashOut = 0;
      double bankOut = 0;

      for (final exp in expenses) {
        if (exp.date.year == currentYear) {
          expensesYear += exp.amount;
        }

        if (exp.date.year == currentMonth.year && exp.date.month == currentMonth.month) {
          expensesMonth += exp.amount;
        }

        if (exp.paymentMethod.toLowerCase() == 'cash') {
          cashOut += exp.amount;
        } else {
          bankOut += exp.amount;
        }
      }

      final purchasesMonth = _purchaseCtrl.totalPurchasesThisMonth.value;
      final purchasesYear = _purchaseCtrl.totalPurchasesThisYear.value;
      final dueSuppliers = _purchaseCtrl.totalDue.value;

      final payroll = _buildPayrollSummary(
        employeeDocs: employeeDocs,
        salaryPaymentDocs: salaryPaymentDocs,
        month: now.month,
        year: now.year,
      );

      cashOut += payroll.paidSalariesThisMonth;

      final netProfitMonth = salesMonth - purchasesMonth - expensesMonth - payroll.totalMonthlySalaries;
      final netProfitYear = salesYear - purchasesYear - expensesYear;

      final trend = _buildMonthlyTrend(
        salesDocs: salesDocs,
        purchaseInvoices: _purchaseCtrl.invoices.toList(),
        expensesList: expenses.toList(),
        year: selectedYear.value,
      );

      overview.value = FinanceOverview(
        totalSalesMonth: salesMonth,
        totalSalesYear: salesYear,
        totalPurchasesMonth: purchasesMonth,
        totalPurchasesYear: purchasesYear,
        totalExpensesMonth: expensesMonth,
        totalExpensesYear: expensesYear,
        totalDueSuppliers: dueSuppliers,
        totalReceivables: receivables,
        netProfitMonth: netProfitMonth,
        netProfitYear: netProfitYear,
        cashIn: cashIn,
        cashOut: cashOut,
        bankIn: bankIn,
        bankOut: bankOut,
        payroll: payroll,
        monthlyTrend: trend,
      );
    } catch (e) {
      debugPrint('FinanceController loadFinanceData error: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل البيانات المالية',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadExpenses() async {
    final snapshot = await _expensesCollection.orderBy('date', descending: true).get();
    final data = snapshot.docs.map((e) => ExpenseItem.fromMap(e.data(), e.id)).toList();
    expenses.assignAll(data);
  }

  Future<void> addExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final item = ExpenseItem(
        id: '',
        title: title,
        category: category,
        amount: amount,
        date: date,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      await _expensesCollection.add({
        ...item.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadFinanceData();

      Get.snackbar(
        'نجاح',
        'تمت إضافة المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إضافة المصروف',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  PayrollSummary _buildPayrollSummary({
    required List<Map<String, dynamic>> employeeDocs,
    required List<Map<String, dynamic>> salaryPaymentDocs,
    required int month,
    required int year,
  }) {
    double monthlySalaries = 0;
    double paidThisMonth = 0;

    for (final emp in employeeDocs) {
      final active = emp['isActive'] ?? true;
      if (active == false) continue;
      monthlySalaries += _toDouble(emp['salary'] ?? emp['monthlySalary']);
    }

    for (final p in salaryPaymentDocs) {
      final date = _parseDate(p['date']) ?? _parseDate(p['paidAt']);
      if (date == null) continue;
      if (date.year == year && date.month == month) {
        paidThisMonth += _toDouble(p['amount']);
      }
    }

    final unpaid = (monthlySalaries - paidThisMonth).clamp(0.0, double.infinity);

    return PayrollSummary(
      employeesCount: employeeDocs.where((e) => (e['isActive'] ?? true) == true).length,
      totalMonthlySalaries: monthlySalaries,
      paidSalariesThisMonth: paidThisMonth,
      unpaidSalariesThisMonth: unpaid,
    );
  }

  List<MonthlyPoint> _buildMonthlyTrend({
    required List<Map<String, dynamic>> salesDocs,
    required List<dynamic> purchaseInvoices,
    required List<ExpenseItem> expensesList,
    required int year,
  }) {
    const labels = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final List<MonthlyPoint> result = List.generate(
      12,
          (i) => MonthlyPoint.empty(labels[i]),
    );

    for (final sale in salesDocs) {
      final date = _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']);
      if (date == null || date.year != year) continue;
      final idx = date.month - 1;
      final total = _toDouble(sale['total']);
      result[idx] = result[idx].copyWith(
        sales: result[idx].sales + total,
      );
    }

    for (final inv in purchaseInvoices) {
      final date = inv.invoiceDate;
      if (date.year != year) continue;
      final idx = date.month - 1;
      result[idx] = result[idx].copyWith(
        purchases: result[idx].purchases + inv.total,
      );
    }

    for (final exp in expensesList) {
      if (exp.date.year != year) continue;
      final idx = exp.date.month - 1;
      result[idx] = result[idx].copyWith(
        expenses: result[idx].expenses + exp.amount,
      );
    }

    for (int i = 0; i < result.length; i++) {
      result[i] = result[i].copyWith(
        profit: result[i].sales - result[i].purchases - result[i].expenses,
      );
    }

    return result;
  }

  void changeYear(int year) {
    selectedYear.value = year;
    loadFinanceData();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse('$value');
  }
}