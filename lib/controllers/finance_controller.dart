import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/finance_model.dart';
import '../services/audit_log_service.dart';

import '../services/financial_transaction_service.dart';
import 'auth_controller.dart';
import 'purchase_controller.dart';

class FinanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService = AuditLogService();

  late AuthController _authCtrl;
  late PurchaseController _purchaseCtrl;

  final RxBool isLoading = false.obs;
  final Rx<FinanceDashboard> dashboard = FinanceDashboard.empty().obs;

  final RxList<ExpenseItem> expenses = <ExpenseItem>[].obs;
  final RxList<ExpenseItem> filteredExpenses = <ExpenseItem>[].obs;

  final searchController = TextEditingController();

  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSubscription;

  String get _pharmacyId => _authCtrl.pharmacyId;

  CollectionReference<Map<String, dynamic>> get _salesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('sales');

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('expenses');

  CollectionReference<Map<String, dynamic>> get _employeesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('employees');

  CollectionReference<Map<String, dynamic>> get _salaryPaymentsCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('salary_payments');

  CollectionReference<Map<String, dynamic>> get _medicinesCollection =>
      _firestore.collection('pharmacies').doc(_pharmacyId).collection('medicines');

  Map<String, dynamic> get _actor =>
      Map<String, dynamic>.from(_authCtrl.actorInfo);

  bool get canViewFinance => _authCtrl.can('finance.view');
  bool get canViewExpenses => _authCtrl.can('finance.expenses.view');
  bool get canCreateExpense => _authCtrl.can('finance.expenses.create');
  bool get canUpdateExpense => _authCtrl.can('finance.expenses.update');
  bool get canDeleteExpense => _authCtrl.can('finance.expenses.delete');
  bool get canExportReports => _authCtrl.can('finance.export');

  @override
  void onInit() {
    super.onInit();

    _authCtrl = Get.find<AuthController>();
    _purchaseCtrl = Get.find<PurchaseController>();

    ever(expenses, (_) {
      filterExpenses(searchController.text);
      _refreshExpenseDrivenDashboardSections();
    });

    ever(_authCtrl.pharmacyData, (_) async {
      if (_pharmacyId.isEmpty) return;
      _setupExpensesListener();
      await loadFinanceData();
    });

    if (_pharmacyId.isNotEmpty) {
      _setupExpensesListener();
      loadFinanceData();
    }
  }

  @override
  void onClose() {
    _expensesSubscription?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _ensureCan(String permission, String message) {
    if (!_authCtrl.can(permission)) {
      throw Exception(message);
    }
  }

  Future<void> _logCreateExpense(ExpenseItem expense) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: _pharmacyId,
        action: AuditActions.createExpense,
        module: AuditModules.finance,
        targetType: AuditTargetTypes.expense,
        targetId: expense.id,
        targetName: expense.title,
        performedBy: _actor,
        details: {
          'note': 'تم إنشاء مصروف جديد',
          'newValues': expense.toMap(),
        },
        entityPath: 'pharmacies/$_pharmacyId/expenses/${expense.id}',
      );
    } catch (e) {
      debugPrint('audit create_expense error: $e');
    }
  }

  Future<void> _logUpdateExpense({
    required ExpenseItem oldExpense,
    required ExpenseItem newExpense,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: _pharmacyId,
        action: AuditActions.updateExpense,
        module: AuditModules.finance,
        targetType: AuditTargetTypes.expense,
        targetId: newExpense.id,
        targetName: newExpense.title,
        performedBy: _actor,
        details: {
          'note': 'تم تحديث المصروف',
          'oldValues': oldExpense.toMap(),
          'newValues': newExpense.toMap(),
        },
        entityPath: 'pharmacies/$_pharmacyId/expenses/${newExpense.id}',
      );
    } catch (e) {
      debugPrint('audit update_expense error: $e');
    }
  }

  Future<void> _logDeleteExpense(ExpenseItem expense) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: _pharmacyId,
        action: AuditActions.deleteExpense,
        module: AuditModules.finance,
        targetType: AuditTargetTypes.expense,
        targetId: expense.id,
        targetName: expense.title,
        performedBy: _actor,
        details: {
          'note': 'تم حذف المصروف',
          'deletedSnapshot': expense.toMap(),
        },
        entityPath: 'pharmacies/$_pharmacyId/expenses/${expense.id}',
      );
    } catch (e) {
      debugPrint('audit delete_expense error: $e');
    }
  }

  void _setupExpensesListener() {
    _expensesSubscription?.cancel();

    if (!canViewExpenses || _pharmacyId.isEmpty) {
      expenses.clear();
      filteredExpenses.clear();
      return;
    }

    _expensesSubscription = _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        final data = snapshot.docs
            .map((doc) => ExpenseItem.fromMap(doc.data(), doc.id))
            .toList();

        expenses.assignAll(data);
      },
      onError: (error) {
        debugPrint('Error listening to expenses: $error');
      },
    );
  }

  Future<void> loadFinanceData() async {
    if (!canViewFinance || _pharmacyId.isEmpty) {
      dashboard.value = FinanceDashboard.empty();
      expenses.clear();
      filteredExpenses.clear();
      return;
    }

    try {
      isLoading.value = true;

      await _purchaseCtrl.loadInvoices();

      final salesFuture = _salesCollection.get();
      final employeesFuture = _employeesCollection.get();
      final salaryPaymentsFuture = _salaryPaymentsCollection.get();
      final medicinesFuture = _medicinesCollection.get();

      final results = await Future.wait([
        salesFuture,
        employeesFuture,
        salaryPaymentsFuture,
        medicinesFuture,
      ]);

      final salesSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final employeesSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final salaryPaymentsSnapshot =
      results[2] as QuerySnapshot<Map<String, dynamic>>;
      final medicinesSnapshot = results[3] as QuerySnapshot<Map<String, dynamic>>;

      final salesDocs = salesSnapshot.docs.map((e) => e.data()).toList();
      final employeeDocs = employeesSnapshot.docs.map((e) => e.data()).toList();
      final salaryPaymentDocs =
      salaryPaymentsSnapshot.docs.map((e) => e.data()).toList();
      final medicineDocs = medicinesSnapshot.docs.map((e) => e.data()).toList();

      final now = DateTime.now();
      final currentYear = selectedYear.value;
      final currentMonth = selectedMonth.value;

      final period = FinancePeriod(
        year: currentYear,
        month: currentMonth,
      );

      final sales = _buildSalesSummary(
        salesDocs: salesDocs,
        year: currentYear,
        month: currentMonth,
      );

      final payroll = _buildPayrollSummary(
        employeeDocs: employeeDocs,
        salaryPaymentDocs: salaryPaymentDocs,
        month: currentMonth,
        year: currentYear,
      );

      final expenseSummary = _buildExpenseSummary(
        expensesList: expenses.toList(),
        year: currentYear,
        month: currentMonth,
      );

      final cogsMonth = _calculateCogsForPeriod(
        salesDocs: salesDocs,
        year: currentYear,
        month: currentMonth,
      );

      final cash = _buildCashSummary(
        salesDocs: salesDocs,
        expensesList: expenses.toList(),
        salaryPaymentDocs: salaryPaymentDocs,
        year: currentYear,
        month: currentMonth,
      );

      final bank = _buildBankSummary(
        salesDocs: salesDocs,
        expensesList: expenses.toList(),
        salaryPaymentDocs: salaryPaymentDocs,
        year: currentYear,
        month: currentMonth,
      );

      final workingCapital = _buildWorkingCapitalSummary(
        salesDocs: salesDocs,
        purchaseInvoices: _purchaseCtrl.invoices.toList(),
        availableLiquidity: cash.closingBalance + bank.closingBalance,
      );

      final inventory = _buildInventoryFinancialSummary(
        medicineDocs: medicineDocs,
        cogsForPeriod: cogsMonth,
      );

      final profitability = _buildProfitabilitySummary(
        netSales: sales.netSales,
        cogs: cogsMonth,
        operatingExpenses: expenseSummary.operatingExpenses,
        payrollExpenses: payroll.totalMonthlySalaries,
        otherExpenses: expenseSummary.otherExpenses,
      );

      final trend = _buildMonthlyTrend(
        salesDocs: salesDocs,
        purchaseInvoices: _purchaseCtrl.invoices.toList(),
        expensesList: expenses.toList(),
        salaryPaymentDocs: salaryPaymentDocs,
        year: currentYear,
      );

      dashboard.value = FinanceDashboard(
        period: period,
        sales: sales,
        profitability: profitability,
        cash: cash,
        bank: bank,
        workingCapital: workingCapital,
        payroll: payroll,
        expenses: expenseSummary,
        inventory: inventory,
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

  void changeYear(int year) {
    selectedYear.value = year;
    loadFinanceData();
  }

  void changeMonth(int month) {
    selectedMonth.value = month;
    loadFinanceData();
  }

  void filterExpenses(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      filteredExpenses.assignAll(expenses);
      return;
    }

    filteredExpenses.assignAll(
      expenses.where((expense) {
        return expense.title.toLowerCase().contains(q) ||
            expense.category.toLowerCase().contains(q) ||
            (expense.notes?.toLowerCase().contains(q) ?? false) ||
            expense.paymentMethod.toLowerCase().contains(q);
      }).toList(),
    );
  }

  Future<void> addExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? notes,
    String? shiftId,
  }) async {
    try {
      _ensureCan('finance.expenses.create', 'ليس لديك صلاحية إضافة المصروفات');

      if (title.trim().isEmpty) {
        throw Exception('عنوان المصروف مطلوب');
      }
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }

      final docRef = _expensesCollection.doc();
      final createdBy = _authCtrl.userId;

      final payload = {
        'title': title.trim(),
        'category': category.trim(),
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'shiftId': shiftId,
        'financialPosted': false,
        'financialTransactionId': null,
        'postedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'updatedBy': createdBy,
      };

      await docRef.set(payload);

      final txId = await FinancialTransactionService.instance.registerExpense(
        pharmacyId: _pharmacyId,
        amount: amount,
        title: title.trim(),
        createdBy: createdBy!,
        description: notes,
        referenceId: docRef.id,
        shiftId: shiftId,
      );

      await docRef.update({
        'financialPosted': true,
        'financialTransactionId': txId,
        'postedAt': FieldValue.serverTimestamp(),
      });

      final createdExpense = ExpenseItem(
        id: docRef.id,
        title: title.trim(),
        category: category.trim(),
        amount: amount,
        date: date,
        paymentMethod: paymentMethod,
        notes: notes,
        createdBy: createdBy,
        updatedBy: createdBy,
        referenceId: txId,
        sourceModule: 'finance',
      );

      await _logCreateExpense(createdExpense);

      Get.snackbar(
        'نجاح',
        'تمت إضافة المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      await loadFinanceData();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إضافة المصروف: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


  Future<void> updateExpense({
    required String expenseId,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      _ensureCan('finance.expenses.update', 'ليس لديك صلاحية تعديل المصروفات');

      final oldExpense = expenses.firstWhereOrNull((e) => e.id == expenseId);
      if (oldExpense == null) {
        throw Exception('المصروف غير موجود');
      }

      final updatedExpense = oldExpense.copyWith(
        title: title.trim(),
        category: category.trim(),
        amount: amount,
        date: date,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      await _expensesCollection.doc(expenseId).update({
        'title': title.trim(),
        'category': category.trim(),
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _authCtrl.userId,
      });

      await _logUpdateExpense(
        oldExpense: oldExpense,
        newExpense: updatedExpense,
      );

      Get.snackbar(
        'نجاح',
        'تم تحديث المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadFinanceData();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحديث المصروف: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      _ensureCan('finance.expenses.delete', 'ليس لديك صلاحية حذف المصروفات');

      final expense = expenses.firstWhereOrNull((e) => e.id == expenseId);
      if (expense == null) {
        throw Exception('المصروف غير موجود');
      }

      await _expensesCollection.doc(expenseId).delete();
      await _logDeleteExpense(expense);

      Get.snackbar(
        'نجاح',
        'تم حذف المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadFinanceData();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر حذف المصروف: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  double getTotalExpenses() {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double getFilteredExpensesTotal() {
    return filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double getTotalExpensesForMonth(int month, int year) {
    return expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Map<String, dynamic>> getTopExpenseCategories([int limit = 5]) {
    final Map<String, double> totals = {};

    for (final expense in filteredExpenses.isNotEmpty ? filteredExpenses : expenses) {
      totals.update(
        expense.category,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final result = totals.entries
        .map((e) => {
      'name': e.key,
      'total': e.value,
    })
        .toList();

    result.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    if (result.length <= limit) return result;
    return result.take(limit).toList();
  }

  Map<String, double> getExpensesByPaymentMethod() {
    final Map<String, double> result = {};

    for (final expense in expenses) {
      result.update(
        expense.paymentMethod,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return result;
  }

  Map<String, dynamic> buildFinancialSnapshot() {
    final d = dashboard.value;

    return {
      'period': {
        'year': d.period.year,
        'month': d.period.month,
      },
      'sales': {
        'grossSales': d.sales.grossSales,
        'netSales': d.sales.netSales,
        'invoicesCount': d.sales.invoicesCount,
        'averageInvoiceValue': d.sales.averageInvoiceValue,
      },
      'profitability': {
        'grossProfit': d.profitability.grossProfit,
        'netProfit': d.profitability.netProfit,
        'grossMarginPercent': d.profitability.grossMarginPercent,
        'netMarginPercent': d.profitability.netMarginPercent,
      },
      'cash': {
        'closingBalance': d.cash.closingBalance,
        'netCashFlow': d.cash.netCashFlow,
      },
      'bank': {
        'closingBalance': d.bank.closingBalance,
        'netFlow': d.bank.netFlow,
      },
      'workingCapital': {
        'accountsReceivable': d.workingCapital.accountsReceivable,
        'accountsPayable': d.workingCapital.accountsPayable,
        'liquidityCoverageRatio': d.workingCapital.liquidityCoverageRatio,
      },
      'expenses': {
        'totalExpenses': d.expenses.totalExpenses,
        'topCategories': getTopExpenseCategories(5),
        'byPaymentMethod': getExpensesByPaymentMethod(),
      },
    };
  }

  Future<void> exportReportAsPDF(int year) async {
    Get.snackbar(
      'تصدير التقرير',
      'جاري تجهيز تقرير PDF لعام $year',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> exportReportAsExcel(int year) async {
    Get.snackbar(
      'تصدير التقرير',
      'جاري تجهيز تقرير Excel لعام $year',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _refreshExpenseDrivenDashboardSections() {
    if (!canViewFinance) return;

    final current = dashboard.value;
    final periodYear = current.period.year;
    final periodMonth = current.period.month ?? DateTime.now().month;

    final expenseSummary = _buildExpenseSummary(
      expensesList: expenses.toList(),
      year: periodYear,
      month: periodMonth,
    );

    final cash = _buildCashSummary(
      salesDocs: const [],
      expensesList: expenses.toList(),
      salaryPaymentDocs: const [],
      year: periodYear,
      month: periodMonth,
      existingInflows: current.cash.inflows,
      existingOpeningBalance: current.cash.openingBalance,
    );

    final bank = _buildBankSummary(
      salesDocs: const [],
      expensesList: expenses.toList(),
      salaryPaymentDocs: const [],
      year: periodYear,
      month: periodMonth,
      existingInflows: current.bank.inflows,
      existingOpeningBalance: current.bank.openingBalance,
    );

    final profitability = _buildProfitabilitySummary(
      netSales: current.sales.netSales,
      cogs: current.profitability.cogs,
      operatingExpenses: expenseSummary.operatingExpenses,
      payrollExpenses: current.payroll.totalMonthlySalaries,
      otherExpenses: expenseSummary.otherExpenses,
    );

    dashboard.value = FinanceDashboard(
      period: current.period,
      sales: current.sales,
      profitability: profitability,
      cash: cash,
      bank: bank,
      workingCapital: current.workingCapital,
      payroll: current.payroll,
      expenses: expenseSummary,
      inventory: current.inventory,
      monthlyTrend: current.monthlyTrend,
    );
  }

  SalesSummary _buildSalesSummary({
    required List<Map<String, dynamic>> salesDocs,
    required int year,
    required int month,
  }) {
    double grossSales = 0;
    double salesDiscounts = 0;
    double netSales = 0;
    double cashSales = 0;
    double cardSales = 0;
    double creditSales = 0;
    double insuranceBilled = 0;
    double insuranceCollected = 0;
    double receivablesCreated = 0;
    double receivablesCollected = 0;
    int invoicesCount = 0;

    double previousNetSales = 0;
    final previousPeriod = _previousPeriod(year, month);

    for (final sale in salesDocs) {
      final date =
          _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']);
      if (date == null) continue;

      final total = _toDouble(sale['total']);
      final discount = _toDouble(
        sale['discount'] ?? sale['totalDiscount'] ?? sale['discountAmount'],
      );
      final insuranceDiscount = _toDouble(
        sale['insuranceDiscount'] ?? sale['insuranceAmount'],
      );
      final paid = _toDouble(sale['paidAmount'] ?? sale['paid']);
      final paymentMethod = '${sale['paymentMethod'] ?? 'cash'}'.toLowerCase();

      final remaining = (total - paid).clamp(0.0, double.infinity);

      if (date.year == year && date.month == month) {
        invoicesCount += 1;
        grossSales += total + discount + insuranceDiscount;
        salesDiscounts += discount;
        netSales += total;
        insuranceBilled += insuranceDiscount;
        receivablesCreated += remaining;

        if (_isCashMethod(paymentMethod)) {
          cashSales += paid > 0 ? paid : total;
        } else if (_isBankMethod(paymentMethod)) {
          cardSales += paid > 0 ? paid : total;
        } else {
          creditSales += total;
        }

        if (paid > 0 && remaining > 0) {
          receivablesCollected += paid;
        }

        if (insuranceDiscount > 0 && paid > 0) {
          insuranceCollected += paid;
        }
      }

      if (date.year == previousPeriod.year && date.month == previousPeriod.month) {
        previousNetSales += total;
      }
    }

    final averageInvoiceValue = invoicesCount <= 0.0 ? 0.0 : netSales / invoicesCount;
    final salesGrowthPercent = previousNetSales <= 0.0
        ? (netSales > 0.0 ? 100.0 : 0.0)
        : ((netSales - previousNetSales) / previousNetSales) * 100.0;

    return SalesSummary(
      grossSales: grossSales,
      salesDiscounts: salesDiscounts,
      netSales: netSales,
      cashSales: cashSales,
      cardSales: cardSales,
      creditSales: creditSales,
      insuranceBilled: insuranceBilled,
      insuranceCollected: insuranceCollected,
      receivablesCreated: receivablesCreated,
      receivablesCollected: receivablesCollected,
      invoicesCount: invoicesCount,
      averageInvoiceValue: averageInvoiceValue,
      salesGrowthPercent: salesGrowthPercent,
    );
  }

  ProfitabilitySummary _buildProfitabilitySummary({
    required double netSales,
    required double cogs,
    required double operatingExpenses,
    required double payrollExpenses,
    required double otherExpenses,
  }) {
    final grossProfit = netSales - cogs;
    final operatingProfit = grossProfit - operatingExpenses - payrollExpenses;
    final netProfit = operatingProfit - otherExpenses;

    double ratio(double a, double b) => b <= 0 ? 0 : (a / b) * 100;

    return ProfitabilitySummary(
      netSales: netSales,
      cogs: cogs,
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
      payrollExpenses: payrollExpenses,
      otherExpenses: otherExpenses,
      operatingProfit: operatingProfit,
      netProfit: netProfit,
      grossMarginPercent: ratio(grossProfit, netSales),
      netMarginPercent: ratio(netProfit, netSales),
      expenseRatioPercent: ratio(operatingExpenses + otherExpenses, netSales),
      payrollRatioPercent: ratio(payrollExpenses, netSales),
    );
  }

  CashSummary _buildCashSummary({
    required List<Map<String, dynamic>> salesDocs,
    required List<ExpenseItem> expensesList,
    required List<Map<String, dynamic>> salaryPaymentDocs,
    required int year,
    required int month,
    double existingInflows = 0,
    double existingOpeningBalance = 0,
  }) {
    double inflows = existingInflows;
    double outflows = 0;

    for (final sale in salesDocs) {
      final date =
          _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']);
      if (date == null || date.year != year || date.month != month) continue;

      final paymentMethod = '${sale['paymentMethod'] ?? 'cash'}';
      if (_isCashMethod(paymentMethod)) {
        inflows += _toDouble(sale['paidAmount'] ?? sale['paid'] ?? sale['total']);
      }
    }

    for (final expense in expensesList) {
      if (expense.date.year == year &&
          expense.date.month == month &&
          _isCashMethod(expense.paymentMethod)) {
        outflows += expense.amount;
      }
    }

    for (final payment in salaryPaymentDocs) {
      final date = _parseDate(payment['date']) ?? _parseDate(payment['paidAt']);
      if (date == null || date.year != year || date.month != month) continue;

      final method = '${payment['paymentMethod'] ?? 'cash'}';
      if (_isCashMethod(method)) {
        outflows += _toDouble(payment['amount']);
      }
    }

    final netCashFlow = inflows - outflows;
    final closingBalance = existingOpeningBalance + netCashFlow;

    return CashSummary(
      openingBalance: existingOpeningBalance,
      inflows: inflows,
      outflows: outflows,
      closingBalance: closingBalance,
      netCashFlow: netCashFlow,
    );
  }

  BankSummary _buildBankSummary({
    required List<Map<String, dynamic>> salesDocs,
    required List<ExpenseItem> expensesList,
    required List<Map<String, dynamic>> salaryPaymentDocs,
    required int year,
    required int month,
    double existingInflows = 0,
    double existingOpeningBalance = 0,
  }) {
    double inflows = existingInflows;
    double outflows = 0;

    for (final sale in salesDocs) {
      final date =
          _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']);
      if (date == null || date.year != year || date.month != month) continue;

      final paymentMethod = '${sale['paymentMethod'] ?? 'cash'}';
      if (_isBankMethod(paymentMethod)) {
        inflows += _toDouble(sale['paidAmount'] ?? sale['paid'] ?? sale['total']);
      }
    }

    for (final expense in expensesList) {
      if (expense.date.year == year &&
          expense.date.month == month &&
          _isBankMethod(expense.paymentMethod)) {
        outflows += expense.amount;
      }
    }

    for (final payment in salaryPaymentDocs) {
      final date = _parseDate(payment['date']) ?? _parseDate(payment['paidAt']);
      if (date == null || date.year != year || date.month != month) continue;

      final method = '${payment['paymentMethod'] ?? 'cash'}';
      if (_isBankMethod(method)) {
        outflows += _toDouble(payment['amount']);
      }
    }

    final netFlow = inflows - outflows;
    final closingBalance = existingOpeningBalance + netFlow;

    return BankSummary(
      openingBalance: existingOpeningBalance,
      inflows: inflows,
      outflows: outflows,
      closingBalance: closingBalance,
      netFlow: netFlow,
    );
  }

  WorkingCapitalSummary _buildWorkingCapitalSummary({
    required List<Map<String, dynamic>> salesDocs,
    required List<dynamic> purchaseInvoices,
    required double availableLiquidity,
  }) {
    double accountsReceivable = 0;
    double overdueReceivables = 0;
    double accountsPayable = 0;
    double overduePayables = 0;
    double supplierDueSoon = 0;

    final now = DateTime.now();

    for (final sale in salesDocs) {
      final total = _toDouble(sale['total']);
      final paid = _toDouble(sale['paidAmount'] ?? sale['paid']);
      final remaining = (total - paid).clamp(0.0, double.infinity);

      if (remaining <= 0) continue;

      accountsReceivable += remaining;

      final dueDate = _parseDate(sale['dueDate']);
      if (dueDate != null) {
        if (dueDate.isBefore(now)) {
          overdueReceivables += remaining;
        } else if (dueDate.difference(now).inDays <= 7) {
          // optional slot if needed later
        }
      }
    }

    for (final invoice in purchaseInvoices) {
      final total = _readDouble(invoice, const [
        'total',
        'grandTotal',
        'invoiceTotal',
      ]);
      final paid = _readDouble(invoice, const [
        'paidAmount',
        'paid',
        'amountPaid',
      ]);
      final due = _readDouble(invoice, const [
        'remainingAmount',
        'dueAmount',
        'balanceDue',
      ]);

      double remaining = due > 0 ? due : (total - paid).clamp(0.0, double.infinity);
      if (remaining <= 0) continue;

      accountsPayable += remaining;

      final dueDate = _readDate(invoice, const ['dueDate']);
      if (dueDate != null) {
        if (dueDate.isBefore(now)) {
          overduePayables += remaining;
        }
        if (dueDate.difference(now).inDays <= 7) {
          supplierDueSoon += remaining;
        }
      }
    }

    final liquidityCoverageRatio =
    accountsPayable <= 0.0 ? 0.0 : availableLiquidity / accountsPayable;

    return WorkingCapitalSummary(
      accountsReceivable: accountsReceivable,
      overdueReceivables: overdueReceivables,
      accountsPayable: accountsPayable,
      overduePayables: overduePayables,
      supplierDueSoon: supplierDueSoon,
      liquidityCoverageRatio: liquidityCoverageRatio,
    );
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
    final paymentRatePercent =
    monthlySalaries <= 0.0 ? 0.0 : (paidThisMonth / monthlySalaries) * 100;

    return PayrollSummary(
      employeesCount:
      employeeDocs.where((e) => (e['isActive'] ?? true) == true).length,
      totalMonthlySalaries: monthlySalaries,
      paidSalariesThisMonth: paidThisMonth,
      unpaidSalariesThisMonth: unpaid,
      paymentRatePercent: paymentRatePercent,
    );
  }

  ExpenseSummary _buildExpenseSummary({
    required List<ExpenseItem> expensesList,
    required int year,
    required int month,
  }) {
    double totalExpenses = 0;
    double operatingExpenses = 0;
    double payrollExpenses = 0;
    double otherExpenses = 0;

    final Map<String, double> byCategory = {};
    final prev = _previousPeriod(year, month);
    double previousPeriodTotal = 0;

    for (final exp in expensesList) {
      if (exp.date.year == year && exp.date.month == month) {
        totalExpenses += exp.amount;
        byCategory.update(
          exp.category,
              (value) => value + exp.amount,
          ifAbsent: () => exp.amount,
        );

        if (_isPayrollCategory(exp.category)) {
          payrollExpenses += exp.amount;
        } else if (_isOperatingCategory(exp.category)) {
          operatingExpenses += exp.amount;
        } else {
          otherExpenses += exp.amount;
        }
      }

      if (exp.date.year == prev.year && exp.date.month == prev.month) {
        previousPeriodTotal += exp.amount;
      }
    }

    final expensesGrowthPercent = previousPeriodTotal <= 0.0
        ? (totalExpenses > 0.0 ? 100.0 : 0.0)
        : ((totalExpenses - previousPeriodTotal) / previousPeriodTotal) * 100;

    return ExpenseSummary(
      totalExpenses: totalExpenses,
      operatingExpenses: operatingExpenses,
      payrollExpenses: payrollExpenses,
      otherExpenses: otherExpenses,
      byCategory: byCategory,
      expensesGrowthPercent: expensesGrowthPercent,
    );
  }

  InventoryFinancialSummary _buildInventoryFinancialSummary({
    required List<Map<String, dynamic>> medicineDocs,
    required double cogsForPeriod,
  }) {
    double inventoryValueAtCost = 0;
    double inventoryValueAtRetail = 0;
    double deadStockValue = 0;
    double lowStockRiskValue = 0;

    for (final med in medicineDocs) {
      final quantity = _toDouble(med['quantity']);
      final pieceQuantity = _toDouble(med['pieceQuantity']);
      final totalUnits = quantity > 0 ? quantity : pieceQuantity;

      final cost = _toDouble(
        med['purchasePrice'] ?? med['buyingPrice'] ?? med['costPrice'],
      );
      final retail = _toDouble(
        med['sellingPrice'] ?? med['price'] ?? med['retailPrice'],
      );

      final itemCostValue = totalUnits * cost;
      final itemRetailValue = totalUnits * retail;

      inventoryValueAtCost += itemCostValue;
      inventoryValueAtRetail += itemRetailValue;

      if ((med['isExpired'] ?? false) == true) {
        deadStockValue += itemCostValue;
      }

      if ((med['isLowStock'] ?? false) == true) {
        lowStockRiskValue += itemCostValue;
      }
    }

    final estimatedGrossMarginValue =
        inventoryValueAtRetail - inventoryValueAtCost;
    final turnoverRate =
    inventoryValueAtCost <= 0.0 ? 0.0 : cogsForPeriod / inventoryValueAtCost;

    return InventoryFinancialSummary(
      inventoryValueAtCost: inventoryValueAtCost,
      inventoryValueAtRetail: inventoryValueAtRetail,
      estimatedGrossMarginValue: estimatedGrossMarginValue,
      deadStockValue: deadStockValue,
      lowStockRiskValue: lowStockRiskValue,
      turnoverRate: turnoverRate,
    );
  }

  List<MonthlyFinancePoint> _buildMonthlyTrend({
    required List<Map<String, dynamic>> salesDocs,
    required List<dynamic> purchaseInvoices,
    required List<ExpenseItem> expensesList,
    required List<Map<String, dynamic>> salaryPaymentDocs,
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

    final result = List.generate(
      12,
          (i) => MonthlyFinancePoint.empty(labels[i]),
    );

    for (int month = 1; month <= 12; month++) {
      final sales = _buildSalesSummary(
        salesDocs: salesDocs,
        year: year,
        month: month,
      );

      final expenseSummary = _buildExpenseSummary(
        expensesList: expensesList,
        year: year,
        month: month,
      );

      final payroll = _buildPayrollSummary(
        employeeDocs: const [],
        salaryPaymentDocs: salaryPaymentDocs,
        month: month,
        year: year,
      );

      final cogs = _calculateCogsForPeriod(
        salesDocs: salesDocs,
        year: year,
        month: month,
      );

      final profitability = _buildProfitabilitySummary(
        netSales: sales.netSales,
        cogs: cogs,
        operatingExpenses: expenseSummary.operatingExpenses,
        payrollExpenses: payroll.paidSalariesThisMonth,
        otherExpenses: expenseSummary.otherExpenses,
      );

      final cashFlow = _calculateNetFlowForMonth(
        salesDocs: salesDocs,
        expensesList: expensesList,
        salaryPaymentDocs: salaryPaymentDocs,
        year: year,
        month: month,
      );

      result[month - 1] = MonthlyFinancePoint(
        label: labels[month - 1],
        netSales: sales.netSales,
        cogs: cogs,
        grossProfit: profitability.grossProfit,
        expenses: expenseSummary.totalExpenses,
        payroll: payroll.paidSalariesThisMonth,
        netProfit: profitability.netProfit,
        cashFlow: cashFlow,
      );
    }

    return result;
  }

  double _calculateCogsForPeriod({
    required List<Map<String, dynamic>> salesDocs,
    required int year,
    required int month,
  }) {
    double cogs = 0;

    for (final sale in salesDocs) {
      final date =
          _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']);
      if (date == null || date.year != year || date.month != month) continue;

      final items = _asList(sale['items']);
      for (final item in items) {
        if (item is! Map) continue;

        final quantity = _readDouble(item, const [
          'quantity',
          'qty',
          'count',
        ]);
        final cost = _readDouble(item, const [
          'purchasePrice',
          'buyingPrice',
          'costPrice',
          'unitCost',
        ]);

        cogs += quantity * cost;
      }
    }

    return cogs;
  }

  double _calculateNetFlowForMonth({
    required List<Map<String, dynamic>> salesDocs,
    required List<ExpenseItem> expensesList,
    required List<Map<String, dynamic>> salaryPaymentDocs,
    required int year,
    required int month,
  }) {
    double inflow = 0;
    double outflow = 0;

    for (final sale in salesDocs) {
      final date =
          _parseDate(sale['createdAt']) ?? _parseDate(sale['saleDate']);
      if (date == null || date.year != year || date.month != month) continue;

      inflow += _toDouble(sale['paidAmount'] ?? sale['paid'] ?? sale['total']);
    }

    for (final expense in expensesList) {
      if (expense.date.year == year && expense.date.month == month) {
        outflow += expense.amount;
      }
    }

    for (final payment in salaryPaymentDocs) {
      final date = _parseDate(payment['date']) ?? _parseDate(payment['paidAt']);
      if (date == null || date.year != year || date.month != month) continue;

      outflow += _toDouble(payment['amount']);
    }

    return inflow - outflow;
  }

  bool _isCashMethod(String method) {
    final m = method.toLowerCase().trim();
    return m == 'cash' || m == 'كاش' || m == 'نقدي';
  }

  bool _isBankMethod(String method) {
    final m = method.toLowerCase().trim();
    return m == 'card' ||
        m == 'bank' ||
        m == 'bank_transfer' ||
        m == 'transfer' ||
        m == 'معاملة مصرفية' ||
        m == 'بنك' ||
        m == 'تحويل';
  }

  bool _isPayrollCategory(String category) {
    final c = category.trim().toLowerCase();
    return c == 'رواتب' || c == 'payroll' || c == 'salary' || c == 'salaries';
  }

  bool _isOperatingCategory(String category) {
    const operating = {
      'إيجار',
      'فواتير',
      'صيانة',
      'تسويق',
      'تأمين',
      'نثريات',
      'rent',
      'utilities',
      'maintenance',
      'marketing',
      'insurance',
      'office',
      'operations',
    };

    return operating.contains(category.trim()) ||
        operating.contains(category.trim().toLowerCase());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);

    if (value is Map<String, dynamic>) {
      if (value.containsKey('_seconds')) {
        final seconds = value['_seconds'];
        if (seconds is int) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    }

    return null;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  double _readDouble(dynamic map, List<String> keys) {
    if (map is! Map) return 0;

    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = _toDouble(map[key]);
        if (value != 0) return value;
      }
    }
    return 0;
  }

  DateTime? _readDate(dynamic map, List<String> keys) {
    if (map is! Map) return null;

    for (final key in keys) {
      if (map.containsKey(key)) {
        final date = _parseDate(map[key]);
        if (date != null) return date;
      }
    }
    return null;
  }

  ({int year, int month}) _previousPeriod(int year, int month) {
    if (month == 1) {
      return (year: year - 1, month: 12);
    }
    return (year: year, month: month - 1);
  }
}