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

  // === متغيرات الحالة ===
  final RxBool isLoading = false.obs;
  final Rx<FinanceOverview> overview = FinanceOverview.empty().obs;

  // === تغيير مهم: استخدام RxList مباشرة من Firebase ===
  final RxList<ExpenseItem> expenses = <ExpenseItem>[].obs;

  // === متغيرات البحث والتصفية ===
  final searchController = TextEditingController();
  final RxList<ExpenseItem> filteredExpenses = <ExpenseItem>[].obs;

  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;

  // === Stream للاستماع للتغييرات في الوقت الفعلي ===
  Stream<QuerySnapshot>? _expensesStream;

  String get _pharmacyId => _authCtrl.pharmacyId;

  // === Collections References ===
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

    // مراقبة التغييرات في قائمة المصروفات
    ever(expenses, (_) => filterExpenses(searchController.text));

    ever(_authCtrl.pharmacyData, (_) {
      if (_pharmacyId.isNotEmpty) {
        _setupExpensesListener(); // إعداد المستمع للمصروفات
        loadFinanceData();
      }
    });

    if (_pharmacyId.isNotEmpty) {
      _setupExpensesListener();
      loadFinanceData();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // === مستمع للتغييرات في المصروفات (Real-time updates) ===
  void _setupExpensesListener() {
    _expensesStream = _expensesCollection
        .orderBy('date', descending: true)
        .snapshots();

    _expensesStream?.listen((snapshot) {
      final data = snapshot.docs
          .map((doc) => ExpenseItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      expenses.assignAll(data);
      filterExpenses(searchController.text);
    }, onError: (error) {
      debugPrint('Error listening to expenses: $error');
    });
  }

  // === وظيفة تحميل البيانات الرئيسية ===
  Future<void> loadFinanceData() async {
    if (_pharmacyId.isEmpty) return;

    try {
      isLoading.value = true;

      // تحميل بيانات المشتريات
      await _purchaseCtrl.loadInvoices();

      // جلب بيانات المبيعات
      final salesSnapshot = await _salesCollection.get();

      // جلب بيانات الموظفين والرواتب
      final employeesSnapshot = await _employeesCollection.get();
      final salaryPaymentsSnapshot = await _salaryPaymentsCollection.get();

      final salesDocs = salesSnapshot.docs.map((e) => e.data()).toList();
      final employeeDocs = employeesSnapshot.docs.map((e) => e.data()).toList();
      final salaryPaymentDocs = salaryPaymentsSnapshot.docs.map((e) => e.data()).toList();

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final currentYear = now.year;

      // حساب المبيعات
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

      // حساب المصروفات (الآن من البيانات الحقيقية)
      double expensesMonth = 0;
      double expensesYear = 0;
      double cashOut = 0;
      double bankOut = 0;

      for (final exp in expenses) { // expenses الآن من Firebase
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

      // بيانات المشتريات من PurchaseController
      final purchasesMonth = _purchaseCtrl.totalPurchasesThisMonth.value;
      final purchasesYear = _purchaseCtrl.totalPurchasesThisYear.value;
      final dueSuppliers = _purchaseCtrl.totalDue.value;

      // حساب الرواتب
      final payroll = _buildPayrollSummary(
        employeeDocs: employeeDocs,
        salaryPaymentDocs: salaryPaymentDocs,
        month: now.month,
        year: now.year,
      );

      cashOut += payroll.paidSalariesThisMonth;

      // حساب الأرباح
      final netProfitMonth = salesMonth - purchasesMonth - expensesMonth - payroll.totalMonthlySalaries;
      final netProfitYear = salesYear - purchasesYear - expensesYear;

      // بناء الاتجاه الشهري
      final trend = _buildMonthlyTrend(
        salesDocs: salesDocs,
        purchaseInvoices: _purchaseCtrl.invoices.toList(),
        expensesList: expenses.toList(), // من Firebase
        year: selectedYear.value,
      );

      // تحديث الـ Overview
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

  // === وظائف المصروفات (CRUD Operations) ===

  // إضافة مصروف جديد
  Future<void> addExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      await _expensesCollection.add({
        'title': title,
        'category': category,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _authCtrl.userId,
      });

      Get.snackbar(
        'نجاح',
        'تمت إضافة المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إضافة المصروف: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // تحديث مصروف
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
      await _expensesCollection.doc(expenseId).update({
        'title': title,
        'category': category,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _authCtrl.userId,
      });

      Get.snackbar(
        'نجاح',
        'تم تحديث المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحديث المصروف',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // حذف مصروف
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expensesCollection.doc(expenseId).delete();

      Get.snackbar(
        'نجاح',
        'تم حذف المصروف بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر حذف المصروف',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // === وظائف البحث والتصفية ===
  void filterExpenses(String query) {
    if (query.isEmpty) {
      filteredExpenses.value = List.from(expenses);
    } else {
      final searchLower = query.toLowerCase();
      filteredExpenses.value = expenses.where((expense) {
        return expense.title.toLowerCase().contains(searchLower) ||
            expense.category.toLowerCase().contains(searchLower) ||
            expense.paymentMethod.toLowerCase().contains(searchLower) ||
            (expense.notes?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
  }

  double getFilteredExpensesTotal() {
    return filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getTotalExpenses() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getTotalExpensesForMonth(int month, int year) {
    return expenses
        .where((e) => e.date.month == month && e.date.year == year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getTotalExpensesForYear(int year) {
    return expenses
        .where((e) => e.date.year == year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // === وظائف تحليل البيانات ===
  List<Map<String, dynamic>> getTopExpenseCategories(int limit) {
    final Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((entry) {
      return {
        'name': entry.key,
        'total': entry.value,
        'percentage': (entry.value / getTotalExpenses()) * 100,
      };
    }).toList();
  }

  Map<String, double> getExpensesByPaymentMethod() {
    final Map<String, double> result = {};

    for (final expense in expenses) {
      result[expense.paymentMethod] =
          (result[expense.paymentMethod] ?? 0) + expense.amount;
    }

    return result;
  }

  Map<int, double> getMonthlyExpensesForYear(int year) {
    final Map<int, double> result = {};

    for (int i = 1; i <= 12; i++) {
      result[i] = 0;
    }

    for (final expense in expenses) {
      if (expense.date.year == year) {
        result[expense.date.month] =
            (result[expense.date.month] ?? 0) + expense.amount;
      }
    }

    return result;
  }

  // === وظائف تصدير التقارير ===
  Map<String, dynamic> generateMonthlyReport(int month, int year) {
    final monthlyExpenses = expenses
        .where((e) => e.date.month == month && e.date.year == year)
        .toList();

    final totalExpenses = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final byCategory = <String, double>{};

    for (final expense in monthlyExpenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }

    return {
      'month': month,
      'year': year,
      'totalExpenses': totalExpenses,
      'expensesCount': monthlyExpenses.length,
      'byCategory': byCategory,
      'expenses': monthlyExpenses.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> generateYearlyReport(int year) {
    final yearlyExpenses = expenses.where((e) => e.date.year == year).toList();
    final monthlyData = getMonthlyExpensesForYear(year);

    return {
      'year': year,
      'totalExpenses': getTotalExpensesForYear(year),
      'expensesCount': yearlyExpenses.length,
      'monthlyData': monthlyData,
      'topCategories': getTopExpenseCategories(5),
      'byPaymentMethod': getExpensesByPaymentMethod(),
    };
  }

  Future<void> exportReportAsPDF(int year) async {
    // TODO: تنفيذ تصدير PDF
    Get.snackbar(
      'تصدير التقرير',
      'جاري تجهيز تقرير PDF لعام $year...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> exportReportAsExcel(int year) async {
    // TODO: تنفيذ تصدير Excel
    Get.snackbar(
      'تصدير التقرير',
      'جاري تجهيز تقرير Excel لعام $year...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  // === وظائف المساعدة ===
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

  void changeMonth(int month) {
    selectedMonth.value = month;
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