import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/sales_model.dart';
import 'auth_controller.dart';
import 'sales_controller.dart';
import 'inventory_controller.dart';
import 'finance_controller.dart';
import 'purchase_controller.dart';
import 'shift_controller.dart';
import 'employee_controller.dart';
import 'supplier_controller.dart';

class DashboardController extends GetxController {
  // Core controllers
  late final AuthController _authCtrl;
  late final SalesController _salesCtrl;
  late final InventoryController _inventoryCtrl;
  late final FinanceController _financeCtrl;
  late final PurchaseController _purchaseCtrl;
  late final ShiftController _shiftCtrl;
  late final EmployeeController _employeeCtrl;

  // ========== Loading States ==========
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // ========== Key Metrics ==========
  final RxDouble todaySales = 0.0.obs;
  final RxDouble todayProfit = 0.0.obs;
  final RxDouble todayExpenses = 0.0.obs;
  final RxInt todayTransactions = 0.obs;

  final RxDouble monthSales = 0.0.obs;
  final RxDouble monthProfit = 0.0.obs;
  final RxDouble monthExpenses = 0.0.obs;
  final RxInt monthTransactions = 0.obs;

  final RxDouble yearSales = 0.0.obs;
  final RxDouble yearProfit = 0.0.obs;
  final RxDouble yearExpenses = 0.0.obs;

  // ========== Financial Health ==========
  final RxDouble cashInHand = 0.0.obs;
  final RxDouble cashInBank = 0.0.obs;
  final RxDouble receivablesTotal = 0.0.obs;
  final RxDouble payablesTotal = 0.0.obs;
  final RxDouble netCashFlow = 0.0.obs;

  // ========== Inventory Health ==========
  final RxInt totalProducts = 0.obs;
  final RxInt lowStockCount = 0.obs;
  final RxInt expiredCount = 0.obs;
  final RxInt expiringSoonCount = 0.obs;
  final RxDouble inventoryValue = 0.0.obs;
  final RxDouble potentialRevenue = 0.0.obs;

  // ========== Staff & Operations ==========
  final RxInt activeEmployees = 0.obs;
  final RxInt openShifts = 0.obs;
  final RxInt pendingInvoices = 0.obs;
  final RxInt activeSuppliers = 0.obs;

  // ========== Chart Data ==========
  final RxList<DashboardChartPoint> salesTrend = <DashboardChartPoint>[].obs;
  final RxList<DashboardChartPoint> profitTrend = <DashboardChartPoint>[].obs;
  final RxList<CategoryExpense> topExpenses = <CategoryExpense>[].obs;
  final RxList<TopProduct> topSellingProducts = <TopProduct>[].obs;
  final RxList<LowStockAlert> lowStockAlerts = <LowStockAlert>[].obs;
  final RxList<DuePaymentAlert> duePayments = <DuePaymentAlert>[].obs;

  // ========== Time Range Selection ==========
  final Rx<DashboardTimeRange> selectedTimeRange = DashboardTimeRange.week.obs;
  final Rx<DateTime> customStartDate = DateTime.now().obs;
  final Rx<DateTime> customEndDate = DateTime.now().obs;

  // ========== Pharmacy Info ==========
  final RxString pharmacyName = ''.obs;
  final RxString pharmacyAddress = ''.obs;
  final RxString pharmacyPhone = ''.obs;
  final RxBool is24Hours = false.obs;
  final RxBool isOnline = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initControllers();
    _setupListeners();
  }

  void _initControllers() {
    try {
      _authCtrl = Get.find<AuthController>();
      _salesCtrl = Get.find<SalesController>();
      _inventoryCtrl = Get.find<InventoryController>();
      _financeCtrl = Get.find<FinanceController>();
      _purchaseCtrl = Get.find<PurchaseController>();
      _shiftCtrl = Get.find<ShiftController>();
      _employeeCtrl = Get.find<EmployeeController>();

      // Load pharmacy info
      _loadPharmacyInfo();

      // Initial load
      refreshDashboard();
    } catch (e) {
      print('Error initializing DashboardController: $e');
    }
  }

  void _setupListeners() {
    // Listen to changes in pharmacy data
    ever(_authCtrl.pharmacyData, (_) {
      _loadPharmacyInfo();
    });

    // Auto-refresh every 5 minutes if needed
    ever(isLoading, (_) {
      if (!isLoading.value) {
        // You could implement periodic refresh here
      }
    });
  }

  void _loadPharmacyInfo() {
    final data = _authCtrl.pharmacyData;
    if (data.isNotEmpty) {
      pharmacyName.value = data['pharmacyName'] ?? 'غير معروف';
      pharmacyAddress.value = data['address'] ?? '';
      pharmacyPhone.value = data['phone'] ?? '';
      is24Hours.value = data['is24Hours'] ?? false;
      isOnline.value = data['isOnline'] ?? false;
    }
  }

  // ========== Main Refresh Method ==========
  Future<void> refreshDashboard() async {
    if (isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      isLoading.value = true;

      // Load all data in parallel
      await Future.wait([
        _loadTodayMetrics(),
        _loadMonthMetrics(),
        _loadYearMetrics(),
        _loadFinancialHealth(),
        _loadInventoryHealth(),
        _loadStaffMetrics(),
        _loadChartData(),
        _loadAlerts(),
        _loadTopExpenses(),  // <-- أضف هذا السطر

      ]);

    } catch (e, stackTrace) {
      print('Error refreshing dashboard: $e');
      print(stackTrace);
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ========== Today's Metrics ==========
  Future<void> _loadTodayMetrics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Get today's sales
      final todaySalesList = await _salesCtrl.getSalesReport(startOfDay, endOfDay);
      final completedToday = todaySalesList.where((s) =>
      s.status == InvoiceStatus.completed && !s.isDeleted
      ).toList();

      double salesTotal = 0;
      double profitTotal = 0;

      for (final sale in completedToday) {
        // Customer paid portion
        final customerPaid = _getCustomerPaid(sale);
        salesTotal += customerPaid;

        // Calculate profit (simplified - you may want to enhance this)
        final cost = sale.items.fold<double>(0, (sum, item) {
          final medicine = _inventoryCtrl.getMedicineById(item.medicineId);
          final purchasePrice = medicine?.purchasePrice ?? 0;
          return sum + (item.quantity * purchasePrice);
        });

        profitTotal += (customerPaid - cost);
      }

      // Get today's expenses from FinanceController
      double expensesTotal = 0;
      if (_financeCtrl.expenses.isNotEmpty) {
        expensesTotal = _financeCtrl.expenses
            .where((e) =>
        e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
            .fold(0.0, (sum, e) => sum + e.amount);
      }

      todaySales.value = salesTotal;
      todayProfit.value = profitTotal;
      todayExpenses.value = expensesTotal;
      todayTransactions.value = completedToday.length;

    } catch (e) {
      print('Error loading today metrics: $e');
    }
  }

// ========== Month Metrics ==========
  Future<void> _loadMonthMetrics() async {
    try {
      final dashboard = _financeCtrl.dashboard.value;
      final now = DateTime.now();

      monthSales.value = dashboard.sales.netSales;
      monthExpenses.value = dashboard.expenses.totalExpenses;
      monthProfit.value = dashboard.profitability.netProfit;

      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthSalesList =
      await _salesCtrl.getSalesReport(startOfMonth, endOfMonth);
      monthTransactions.value = monthSalesList.length;
    } catch (e) {
      print('Error loading month metrics: $e');
    }
  }

// ========== Year Metrics ==========
  Future<void> _loadYearMetrics() async {
    try {
      final dashboard = _financeCtrl.dashboard.value;
      final trend = dashboard.monthlyTrend;

      double sales = 0;
      double expenses = 0;
      double profit = 0;

      for (final point in trend) {
        sales += point.netSales;
        expenses += point.expenses + point.payroll;
        profit += point.netProfit;
      }

      yearSales.value = sales;
      yearExpenses.value = expenses;
      yearProfit.value = profit;
    } catch (e) {
      print('Error loading year metrics: $e');
    }
  }

// ========== Financial Health ==========
  Future<void> _loadFinancialHealth() async {
    try {
      final dashboard = _financeCtrl.dashboard.value;

      cashInHand.value = dashboard.cash.closingBalance;
      cashInBank.value = dashboard.bank.closingBalance;
      receivablesTotal.value = dashboard.workingCapital.accountsReceivable;
      payablesTotal.value = dashboard.workingCapital.accountsPayable;
      netCashFlow.value =
          dashboard.cash.netCashFlow + dashboard.bank.netFlow;
    } catch (e) {
      print('Error loading financial health: $e');
    }
  }

  // ========== Inventory Health ==========
  Future<void> _loadInventoryHealth() async {
    try {
      totalProducts.value = _inventoryCtrl.uniqueMedicinesCount;
      lowStockCount.value = _inventoryCtrl.lowStockCount;
      expiredCount.value = _inventoryCtrl.expiredCount;
      expiringSoonCount.value = _inventoryCtrl.expiringSoonMedicines.length;
      inventoryValue.value = _inventoryCtrl.totalInventoryValue;
      potentialRevenue.value = _inventoryCtrl.totalInventorySellingValue;

      // Get top selling products (you may need to implement this in SalesController)
      await _loadTopSellingProducts();

    } catch (e) {
      print('Error loading inventory health: $e');
    }
  }

  // ========== Staff Metrics ==========
  Future<void> _loadStaffMetrics() async {
    try {
      activeEmployees.value = _employeeCtrl.employees.where((e) => e.isActive).length;
      openShifts.value = _shiftCtrl.shifts.where((s) => s.status == 'open').length;

      // Get pending invoices count
      pendingInvoices.value = _salesCtrl.activeInvoices.length;

      // Get active suppliers count
      activeSuppliers.value = _purchaseCtrl.invoices
          .map((i) => i.supplierId)
          .toSet()
          .length;

    } catch (e) {
      print('Error loading staff metrics: $e');
    }
  }

  // ========== Chart Data ==========
  Future<void> _loadChartData() async {
    try {
      final now = DateTime.now();
      final List<DashboardChartPoint> salesPoints = [];
      final List<DashboardChartPoint> profitPoints = [];

      switch (selectedTimeRange.value) {
        case DashboardTimeRange.week:
        // Last 7 days
          for (int i = 6; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            final daySales = await _getSalesForDay(date);
            final dayExpenses = await _getExpensesForDay(date);

            salesPoints.add(DashboardChartPoint(
              label: DateFormat('E', 'ar').format(date),
              value: daySales,
            ));

            profitPoints.add(DashboardChartPoint(
              label: DateFormat('E', 'ar').format(date),
              value: daySales - dayExpenses,
            ));
          }
          break;

        case DashboardTimeRange.month:
        // Last 30 days or by week
          final weeks = (now.day / 7).ceil();
          for (int i = weeks - 1; i >= 0; i--) {
            final endDate = now.subtract(Duration(days: i * 7));
            final startDate = endDate.subtract(const Duration(days: 6));

            double weekSales = 0;
            double weekExpenses = 0;

            for (int d = 0; d < 7; d++) {
              final date = startDate.add(Duration(days: d));
              if (date.isAfter(now)) continue;

              weekSales += await _getSalesForDay(date);
              weekExpenses += await _getExpensesForDay(date);
            }

            salesPoints.add(DashboardChartPoint(
              label: 'أسبوع ${weeks - i}',
              value: weekSales,
            ));

            profitPoints.add(DashboardChartPoint(
              label: 'أسبوع ${weeks - i}',
              value: weekSales - weekExpenses,
            ));
          }
          break;

        case DashboardTimeRange.year:
        // Last 12 months
          for (int i = 11; i >= 0; i--) {
            final date = DateTime(now.year, now.month - i, 1);
            final monthSales = await _getSalesForMonth(date);
            final monthExpenses = await _getExpensesForMonth(date);

            salesPoints.add(DashboardChartPoint(
              label: DateFormat('MMM', 'ar').format(date),
              value: monthSales,
            ));

            profitPoints.add(DashboardChartPoint(
              label: DateFormat('MMM', 'ar').format(date),
              value: monthSales - monthExpenses,
            ));
          }
          break;

        case DashboardTimeRange.custom:
        // Custom range logic
          final days = customEndDate.value.difference(customStartDate.value).inDays;
          if (days <= 31) {
            // Show daily
            for (int i = 0; i <= days; i++) {
              final date = customStartDate.value.add(Duration(days: i));
              final daySales = await _getSalesForDay(date);

              salesPoints.add(DashboardChartPoint(
                label: DateFormat('d/M', 'ar').format(date),
                value: daySales,
              ));
            }
          } else {
            // Show monthly
            // Implementation similar to year view but filtered by custom range
          }
          break;
      }

      salesTrend.value = salesPoints;
      profitTrend.value = profitPoints;

    } catch (e) {
      print('Error loading chart data: $e');
    }
  }

  // ========== Top Expenses ==========
// ========== Top Expenses ==========
  Future<void> _loadTopExpenses() async {
    try {
      final expensesByCategory = <String, double>{};
      final now = DateTime.now();

      for (final expense in _financeCtrl.expenses) {
        // فلترة مصروفات الشهر الحالي فقط
        if (expense.date.year == now.year && expense.date.month == now.month) {
          expensesByCategory[expense.category] =
              (expensesByCategory[expense.category] ?? 0) + expense.amount;
        }
      }

      final sorted = expensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      topExpenses.value = sorted.take(10).map((e) => CategoryExpense(
        category: e.key,
        amount: e.value,
      )).toList();

      topExpenses.forEach((e) {
        print('- ${e.category}: ${e.amount}');
      });

    } catch (e) {
      print('Error loading top expenses: $e');
    }
  }
  // ========== Top Selling Products ==========
  Future<void> _loadTopSellingProducts() async {
    try {
      final productSales = <String, TopProduct>{};
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final monthSales = await _salesCtrl.getSalesReport(startOfMonth, now);

      for (final sale in monthSales) {
        for (final item in sale.items) {
          if (productSales.containsKey(item.medicineId)) {
            final existing = productSales[item.medicineId]!;
            productSales[item.medicineId] = existing.copyWith(
              quantity: existing.quantity + item.quantity,
              revenue: existing.revenue + (item.quantity * item.unitPrice),
            );
          } else {
            productSales[item.medicineId] = TopProduct(
              id: item.medicineId,
              name: item.name,
              quantity: item.quantity,
              revenue: item.quantity * item.unitPrice,
            );
          }
        }
      }

      final sorted = productSales.values.toList()
        ..sort((a, b) => b.quantity.compareTo(a.quantity));

      topSellingProducts.value = sorted.take(10).toList();

    } catch (e) {
      print('Error loading top selling products: $e');
    }
  }

  // ========== Alerts ==========
  Future<void> _loadAlerts() async {
    try {
      // Low stock alerts
      final lowStock = _inventoryCtrl.lowStockMedicines.take(5).map((m) => LowStockAlert(
        medicineId: m.id,
        medicineName: m.name,
        currentStock: m.quantity,
        minLevel: m.minStockLevel ?? 0,
      )).toList();

      lowStockAlerts.value = lowStock;

      // Due payments
      final dueList = _purchaseCtrl.invoices
          .where((inv) =>
      inv.remaining > 0 &&
          inv.dueDate != null &&
          inv.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7))))
          .take(5)
          .map((inv) => DuePaymentAlert(
        invoiceId: inv.id,
        invoiceNumber: inv.invoiceNumber,
        supplierName: inv.supplierName,
        amount: inv.remaining,
        dueDate: inv.dueDate!,
      )).toList();

      duePayments.value = dueList;

    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  // ========== Helper Methods ==========
  double _getCustomerPaid(Sale sale) {
    if (sale.insuranceDiscount != null && sale.insuranceDiscount! > 0) {
      return sale.total - sale.insuranceDiscount!;
    }
    return sale.total;
  }

  Future<double> _getSalesForDay(DateTime day) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final sales = await _salesCtrl.getSalesReport(start, end);
      return sales.fold<double>(0, (sum, s) => sum + _getCustomerPaid(s));
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getExpensesForDay(DateTime day) async {
    try {
      final expenses = await _financeCtrl.expenses; // 🔥 هذا هو المهم

      return expenses
          .where((e) =>
      e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day)
          .fold<double>(0.0, (sum, e) => sum + e.amount); // 🔥 حددنا النوع
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getSalesForMonth(DateTime month) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final sales = await _salesCtrl.getSalesReport(start, end);
      return sales.fold<double>(0, (sum, s) => sum + _getCustomerPaid(s));
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getExpensesForMonth(DateTime month) async {
    try {
      final expenses = await _financeCtrl.expenses; // 🔥 مهم جدًا

      return expenses
          .where((e) =>
      e.date.year == month.year &&
          e.date.month == month.month)
          .fold<double>(0.0, (sum, e) => sum + e.amount);
    } catch (e) {
      return 0;
    }
  }

  // ========== Public Methods ==========
  void changeTimeRange(DashboardTimeRange range) {
    selectedTimeRange.value = range;
    _loadChartData();
  }

  void setCustomRange(DateTime start, DateTime end) {
    customStartDate.value = start;
    customEndDate.value = end;
    selectedTimeRange.value = DashboardTimeRange.custom;
    _loadChartData();
  }

  Map<String, dynamic> getQuickStats() {
    return {
      'todaySales': todaySales.value,
      'todayProfit': todayProfit.value,
      'monthSales': monthSales.value,
      'monthProfit': monthProfit.value,
      'cashInHand': cashInHand.value,
      'receivables': receivablesTotal.value,
      'payables': payablesTotal.value,
      'lowStockCount': lowStockCount.value,
      'expiredCount': expiredCount.value,
      'activeEmployees': activeEmployees.value,
    };
  }

  double get profitMargin {
    if (monthSales.value == 0) return 0;
    return (monthProfit.value / monthSales.value) * 100;
  }

  String get formattedPharmacyName => pharmacyName.value;
  String get formattedAddress => pharmacyAddress.value;
}

// ========== Supporting Models ==========
enum DashboardTimeRange {
  week,
  month,
  year,
  custom,
}

class DashboardChartPoint {
  final String label;
  final double value;

  DashboardChartPoint({
    required this.label,
    required this.value,
  });
}

class CategoryExpense {
  final String category;
  final double amount;

  CategoryExpense({
    required this.category,
    required this.amount,
  });
}

class TopProduct {
  final String id;
  final String name;
  final int quantity;
  final double revenue;

  TopProduct({
    required this.id,
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  TopProduct copyWith({
    String? id,
    String? name,
    int? quantity,
    double? revenue,
  }) {
    return TopProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      revenue: revenue ?? this.revenue,
    );
  }
}

class LowStockAlert {
  final String medicineId;
  final String medicineName;
  final int currentStock;
  final int minLevel;

  LowStockAlert({
    required this.medicineId,
    required this.medicineName,
    required this.currentStock,
    required this.minLevel,
  });

  bool get isCritical => currentStock == 0;
  String get status {
    if (currentStock == 0) return 'نفذ بالكامل';
    if (currentStock <= minLevel / 2) return 'منخفض جداً';
    return 'منخفض';
  }
}

class DuePaymentAlert {
  final String invoiceId;
  final String invoiceNumber;
  final String supplierName;
  final double amount;
  final DateTime dueDate;

  DuePaymentAlert({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.supplierName,
    required this.amount,
    required this.dueDate,
  });

  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => daysRemaining < 0;
  String get status {
    if (isOverdue) return 'متأخر';
    if (daysRemaining <= 2) return 'حرج';
    return 'قريب';
  }
}