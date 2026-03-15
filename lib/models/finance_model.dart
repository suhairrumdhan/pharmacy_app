import 'package:flutter/foundation.dart';

@immutable
class MonthlyPoint {
  final String label;
  final double sales;
  final double purchases;
  final double expenses;
  final double profit;

  const MonthlyPoint({
    required this.label,
    required this.sales,
    required this.purchases,
    required this.expenses,
    required this.profit,
  });

  factory MonthlyPoint.empty(String label) {
    return MonthlyPoint(
      label: label,
      sales: 0,
      purchases: 0,
      expenses: 0,
      profit: 0,
    );
  }

  MonthlyPoint copyWith({
    String? label,
    double? sales,
    double? purchases,
    double? expenses,
    double? profit,
  }) {
    return MonthlyPoint(
      label: label ?? this.label,
      sales: sales ?? this.sales,
      purchases: purchases ?? this.purchases,
      expenses: expenses ?? this.expenses,
      profit: profit ?? this.profit,
    );
  }
}

@immutable
class PayrollSummary {
  final int employeesCount;
  final double totalMonthlySalaries;
  final double paidSalariesThisMonth;
  final double unpaidSalariesThisMonth;

  const PayrollSummary({
    required this.employeesCount,
    required this.totalMonthlySalaries,
    required this.paidSalariesThisMonth,
    required this.unpaidSalariesThisMonth,
  });

  double get paymentRate {
    if (totalMonthlySalaries <= 0) return 0;
    return (paidSalariesThisMonth / totalMonthlySalaries) * 100;
  }

  factory PayrollSummary.empty() {
    return const PayrollSummary(
      employeesCount: 0,
      totalMonthlySalaries: 0,
      paidSalariesThisMonth: 0,
      unpaidSalariesThisMonth: 0,
    );
  }

  PayrollSummary copyWith({
    int? employeesCount,
    double? totalMonthlySalaries,
    double? paidSalariesThisMonth,
    double? unpaidSalariesThisMonth,
  }) {
    return PayrollSummary(
      employeesCount: employeesCount ?? this.employeesCount,
      totalMonthlySalaries: totalMonthlySalaries ?? this.totalMonthlySalaries,
      paidSalariesThisMonth: paidSalariesThisMonth ?? this.paidSalariesThisMonth,
      unpaidSalariesThisMonth: unpaidSalariesThisMonth ?? this.unpaidSalariesThisMonth,
    );
  }
}

@immutable
class FinanceOverview {
  final double totalSalesMonth;
  final double totalSalesYear;
  final double totalPurchasesMonth;
  final double totalPurchasesYear;
  final double totalExpensesMonth;
  final double totalExpensesYear;
  final double totalDueSuppliers;
  final double totalReceivables;
  final double netProfitMonth;
  final double netProfitYear;
  final double cashIn;
  final double cashOut;
  final double bankIn;
  final double bankOut;
  final PayrollSummary payroll;
  final List<MonthlyPoint> monthlyTrend;

  const FinanceOverview({
    required this.totalSalesMonth,
    required this.totalSalesYear,
    required this.totalPurchasesMonth,
    required this.totalPurchasesYear,
    required this.totalExpensesMonth,
    required this.totalExpensesYear,
    required this.totalDueSuppliers,
    required this.totalReceivables,
    required this.netProfitMonth,
    required this.netProfitYear,
    required this.cashIn,
    required this.cashOut,
    required this.bankIn,
    required this.bankOut,
    required this.payroll,
    required this.monthlyTrend,
  });

  factory FinanceOverview.empty() {
    return FinanceOverview(
      totalSalesMonth: 0,
      totalSalesYear: 0,
      totalPurchasesMonth: 0,
      totalPurchasesYear: 0,
      totalExpensesMonth: 0,
      totalExpensesYear: 0,
      totalDueSuppliers: 0,
      totalReceivables: 0,
      netProfitMonth: 0,
      netProfitYear: 0,
      cashIn: 0,
      cashOut: 0,
      bankIn: 0,
      bankOut: 0,
      payroll: PayrollSummary.empty(),
      monthlyTrend: const [],
    );
  }

  double get cashBalance => cashIn - cashOut;
  double get bankBalance => bankIn - bankOut;

  FinanceOverview copyWith({
    double? totalSalesMonth,
    double? totalSalesYear,
    double? totalPurchasesMonth,
    double? totalPurchasesYear,
    double? totalExpensesMonth,
    double? totalExpensesYear,
    double? totalDueSuppliers,
    double? totalReceivables,
    double? netProfitMonth,
    double? netProfitYear,
    double? cashIn,
    double? cashOut,
    double? bankIn,
    double? bankOut,
    PayrollSummary? payroll,
    List<MonthlyPoint>? monthlyTrend,
  }) {
    return FinanceOverview(
      totalSalesMonth: totalSalesMonth ?? this.totalSalesMonth,
      totalSalesYear: totalSalesYear ?? this.totalSalesYear,
      totalPurchasesMonth: totalPurchasesMonth ?? this.totalPurchasesMonth,
      totalPurchasesYear: totalPurchasesYear ?? this.totalPurchasesYear,
      totalExpensesMonth: totalExpensesMonth ?? this.totalExpensesMonth,
      totalExpensesYear: totalExpensesYear ?? this.totalExpensesYear,
      totalDueSuppliers: totalDueSuppliers ?? this.totalDueSuppliers,
      totalReceivables: totalReceivables ?? this.totalReceivables,
      netProfitMonth: netProfitMonth ?? this.netProfitMonth,
      netProfitYear: netProfitYear ?? this.netProfitYear,
      cashIn: cashIn ?? this.cashIn,
      cashOut: cashOut ?? this.cashOut,
      bankIn: bankIn ?? this.bankIn,
      bankOut: bankOut ?? this.bankOut,
      payroll: payroll ?? this.payroll,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
    );
  }
}

@immutable
class ExpenseItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String? notes;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.notes,
  });

  factory ExpenseItem.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseItem(
      id: id,
      title: (map['title'] ?? '').toString(),
      category: (map['category'] ?? 'عام').toString(),
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse('${map['amount']}') ?? 0,
      date: DateTime.tryParse('${map['date']}') ?? DateTime.now(),
      paymentMethod: (map['paymentMethod'] ?? 'cash').toString(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}