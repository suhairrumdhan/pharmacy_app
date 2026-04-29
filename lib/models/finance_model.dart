import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class FinanceDashboard {
  final FinancePeriod period;
  final SalesSummary sales;
  final ProfitabilitySummary profitability;
  final CashSummary cash;
  final BankSummary bank;
  final WorkingCapitalSummary workingCapital;
  final PayrollSummary payroll;
  final ExpenseSummary expenses;
  final InventoryFinancialSummary inventory;
  final List<MonthlyFinancePoint> monthlyTrend;

  const FinanceDashboard({
    required this.period,
    required this.sales,
    required this.profitability,
    required this.cash,
    required this.bank,
    required this.workingCapital,
    required this.payroll,
    required this.expenses,
    required this.inventory,
    required this.monthlyTrend,
  });

  factory FinanceDashboard.empty() {
    return FinanceDashboard(
      period: FinancePeriod.current(),
      sales: SalesSummary.empty(),
      profitability: ProfitabilitySummary.empty(),
      cash: CashSummary.empty(),
      bank: BankSummary.empty(),
      workingCapital: WorkingCapitalSummary.empty(),
      payroll: PayrollSummary.empty(),
      expenses: ExpenseSummary.empty(),
      inventory: InventoryFinancialSummary.empty(),
      monthlyTrend: const [],
    );
  }

  FinanceDashboard copyWith({
    FinancePeriod? period,
    SalesSummary? sales,
    ProfitabilitySummary? profitability,
    CashSummary? cash,
    BankSummary? bank,
    WorkingCapitalSummary? workingCapital,
    PayrollSummary? payroll,
    ExpenseSummary? expenses,
    InventoryFinancialSummary? inventory,
    List<MonthlyFinancePoint>? monthlyTrend,
  }) {
    return FinanceDashboard(
      period: period ?? this.period,
      sales: sales ?? this.sales,
      profitability: profitability ?? this.profitability,
      cash: cash ?? this.cash,
      bank: bank ?? this.bank,
      workingCapital: workingCapital ?? this.workingCapital,
      payroll: payroll ?? this.payroll,
      expenses: expenses ?? this.expenses,
      inventory: inventory ?? this.inventory,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
    );
  }
}

@immutable
class FinancePeriod {
  final int year;
  final int? month;

  const FinancePeriod({
    required this.year,
    this.month,
  });

  factory FinancePeriod.current() {
    final now = DateTime.now();
    return FinancePeriod(
      year: now.year,
      month: now.month,
    );
  }

  FinancePeriod copyWith({
    int? year,
    int? month,
  }) {
    return FinancePeriod(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

@immutable
class SalesSummary {
  final double grossSales;
  final double salesDiscounts;
  final double netSales;
  final double cashSales;
  final double cardSales;
  final double creditSales;
  final double insuranceBilled;
  final double insuranceCollected;
  final double receivablesCreated;
  final double receivablesCollected;
  final int invoicesCount;
  final double averageInvoiceValue;
  final double salesGrowthPercent;

  const SalesSummary({
    required this.grossSales,
    required this.salesDiscounts,
    required this.netSales,
    required this.cashSales,
    required this.cardSales,
    required this.creditSales,
    required this.insuranceBilled,
    required this.insuranceCollected,
    required this.receivablesCreated,
    required this.receivablesCollected,
    required this.invoicesCount,
    required this.averageInvoiceValue,
    required this.salesGrowthPercent,
  });

  factory SalesSummary.empty() {
    return const SalesSummary(
      grossSales: 0,
      salesDiscounts: 0,
      netSales: 0,
      cashSales: 0,
      cardSales: 0,
      creditSales: 0,
      insuranceBilled: 0,
      insuranceCollected: 0,
      receivablesCreated: 0,
      receivablesCollected: 0,
      invoicesCount: 0,
      averageInvoiceValue: 0,
      salesGrowthPercent: 0,
    );
  }

  SalesSummary copyWith({
    double? grossSales,
    double? salesDiscounts,
    double? netSales,
    double? cashSales,
    double? cardSales,
    double? creditSales,
    double? insuranceBilled,
    double? insuranceCollected,
    double? receivablesCreated,
    double? receivablesCollected,
    int? invoicesCount,
    double? averageInvoiceValue,
    double? salesGrowthPercent,
  }) {
    return SalesSummary(
      grossSales: grossSales ?? this.grossSales,
      salesDiscounts: salesDiscounts ?? this.salesDiscounts,
      netSales: netSales ?? this.netSales,
      cashSales: cashSales ?? this.cashSales,
      cardSales: cardSales ?? this.cardSales,
      creditSales: creditSales ?? this.creditSales,
      insuranceBilled: insuranceBilled ?? this.insuranceBilled,
      insuranceCollected: insuranceCollected ?? this.insuranceCollected,
      receivablesCreated: receivablesCreated ?? this.receivablesCreated,
      receivablesCollected: receivablesCollected ?? this.receivablesCollected,
      invoicesCount: invoicesCount ?? this.invoicesCount,
      averageInvoiceValue: averageInvoiceValue ?? this.averageInvoiceValue,
      salesGrowthPercent: salesGrowthPercent ?? this.salesGrowthPercent,
    );
  }
}

@immutable
class ProfitabilitySummary {
  final double netSales;
  final double cogs;
  final double grossProfit;
  final double operatingExpenses;
  final double payrollExpenses;
  final double otherExpenses;
  final double operatingProfit;
  final double netProfit;
  final double grossMarginPercent;
  final double netMarginPercent;
  final double expenseRatioPercent;
  final double payrollRatioPercent;

  const ProfitabilitySummary({
    required this.netSales,
    required this.cogs,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.payrollExpenses,
    required this.otherExpenses,
    required this.operatingProfit,
    required this.netProfit,
    required this.grossMarginPercent,
    required this.netMarginPercent,
    required this.expenseRatioPercent,
    required this.payrollRatioPercent,
  });

  factory ProfitabilitySummary.empty() {
    return const ProfitabilitySummary(
      netSales: 0,
      cogs: 0,
      grossProfit: 0,
      operatingExpenses: 0,
      payrollExpenses: 0,
      otherExpenses: 0,
      operatingProfit: 0,
      netProfit: 0,
      grossMarginPercent: 0,
      netMarginPercent: 0,
      expenseRatioPercent: 0,
      payrollRatioPercent: 0,
    );
  }

  ProfitabilitySummary copyWith({
    double? netSales,
    double? cogs,
    double? grossProfit,
    double? operatingExpenses,
    double? payrollExpenses,
    double? otherExpenses,
    double? operatingProfit,
    double? netProfit,
    double? grossMarginPercent,
    double? netMarginPercent,
    double? expenseRatioPercent,
    double? payrollRatioPercent,
  }) {
    return ProfitabilitySummary(
      netSales: netSales ?? this.netSales,
      cogs: cogs ?? this.cogs,
      grossProfit: grossProfit ?? this.grossProfit,
      operatingExpenses: operatingExpenses ?? this.operatingExpenses,
      payrollExpenses: payrollExpenses ?? this.payrollExpenses,
      otherExpenses: otherExpenses ?? this.otherExpenses,
      operatingProfit: operatingProfit ?? this.operatingProfit,
      netProfit: netProfit ?? this.netProfit,
      grossMarginPercent: grossMarginPercent ?? this.grossMarginPercent,
      netMarginPercent: netMarginPercent ?? this.netMarginPercent,
      expenseRatioPercent: expenseRatioPercent ?? this.expenseRatioPercent,
      payrollRatioPercent: payrollRatioPercent ?? this.payrollRatioPercent,
    );
  }
}

@immutable
class CashSummary {
  final double openingBalance;
  final double inflows;
  final double outflows;
  final double closingBalance;
  final double netCashFlow;

  const CashSummary({
    required this.openingBalance,
    required this.inflows,
    required this.outflows,
    required this.closingBalance,
    required this.netCashFlow,
  });

  factory CashSummary.empty() {
    return const CashSummary(
      openingBalance: 0,
      inflows: 0,
      outflows: 0,
      closingBalance: 0,
      netCashFlow: 0,
    );
  }

  CashSummary copyWith({
    double? openingBalance,
    double? inflows,
    double? outflows,
    double? closingBalance,
    double? netCashFlow,
  }) {
    return CashSummary(
      openingBalance: openingBalance ?? this.openingBalance,
      inflows: inflows ?? this.inflows,
      outflows: outflows ?? this.outflows,
      closingBalance: closingBalance ?? this.closingBalance,
      netCashFlow: netCashFlow ?? this.netCashFlow,
    );
  }
}

@immutable
class BankSummary {
  final double openingBalance;
  final double inflows;
  final double outflows;
  final double closingBalance;
  final double netFlow;

  const BankSummary({
    required this.openingBalance,
    required this.inflows,
    required this.outflows,
    required this.closingBalance,
    required this.netFlow,
  });

  factory BankSummary.empty() {
    return const BankSummary(
      openingBalance: 0,
      inflows: 0,
      outflows: 0,
      closingBalance: 0,
      netFlow: 0,
    );
  }

  BankSummary copyWith({
    double? openingBalance,
    double? inflows,
    double? outflows,
    double? closingBalance,
    double? netFlow,
  }) {
    return BankSummary(
      openingBalance: openingBalance ?? this.openingBalance,
      inflows: inflows ?? this.inflows,
      outflows: outflows ?? this.outflows,
      closingBalance: closingBalance ?? this.closingBalance,
      netFlow: netFlow ?? this.netFlow,
    );
  }
}

@immutable
class WorkingCapitalSummary {
  final double accountsReceivable;
  final double overdueReceivables;
  final double accountsPayable;
  final double overduePayables;
  final double supplierDueSoon;
  final double liquidityCoverageRatio;

  const WorkingCapitalSummary({
    required this.accountsReceivable,
    required this.overdueReceivables,
    required this.accountsPayable,
    required this.overduePayables,
    required this.supplierDueSoon,
    required this.liquidityCoverageRatio,
  });

  factory WorkingCapitalSummary.empty() {
    return const WorkingCapitalSummary(
      accountsReceivable: 0,
      overdueReceivables: 0,
      accountsPayable: 0,
      overduePayables: 0,
      supplierDueSoon: 0,
      liquidityCoverageRatio: 0,
    );
  }

  WorkingCapitalSummary copyWith({
    double? accountsReceivable,
    double? overdueReceivables,
    double? accountsPayable,
    double? overduePayables,
    double? supplierDueSoon,
    double? liquidityCoverageRatio,
  }) {
    return WorkingCapitalSummary(
      accountsReceivable: accountsReceivable ?? this.accountsReceivable,
      overdueReceivables: overdueReceivables ?? this.overdueReceivables,
      accountsPayable: accountsPayable ?? this.accountsPayable,
      overduePayables: overduePayables ?? this.overduePayables,
      supplierDueSoon: supplierDueSoon ?? this.supplierDueSoon,
      liquidityCoverageRatio:
      liquidityCoverageRatio ?? this.liquidityCoverageRatio,
    );
  }
}

@immutable
class PayrollSummary {
  final int employeesCount;
  final double totalMonthlySalaries;
  final double paidSalariesThisMonth;
  final double unpaidSalariesThisMonth;
  final double paymentRatePercent;

  const PayrollSummary({
    required this.employeesCount,
    required this.totalMonthlySalaries,
    required this.paidSalariesThisMonth,
    required this.unpaidSalariesThisMonth,
    required this.paymentRatePercent,
  });

  factory PayrollSummary.empty() {
    return const PayrollSummary(
      employeesCount: 0,
      totalMonthlySalaries: 0,
      paidSalariesThisMonth: 0,
      unpaidSalariesThisMonth: 0,
      paymentRatePercent: 0,
    );
  }

  double get paymentRate => paymentRatePercent;

  PayrollSummary copyWith({
    int? employeesCount,
    double? totalMonthlySalaries,
    double? paidSalariesThisMonth,
    double? unpaidSalariesThisMonth,
    double? paymentRatePercent,
  }) {
    return PayrollSummary(
      employeesCount: employeesCount ?? this.employeesCount,
      totalMonthlySalaries:
      totalMonthlySalaries ?? this.totalMonthlySalaries,
      paidSalariesThisMonth:
      paidSalariesThisMonth ?? this.paidSalariesThisMonth,
      unpaidSalariesThisMonth:
      unpaidSalariesThisMonth ?? this.unpaidSalariesThisMonth,
      paymentRatePercent: paymentRatePercent ?? this.paymentRatePercent,
    );
  }
}

@immutable
class ExpenseSummary {
  final double totalExpenses;
  final double operatingExpenses;
  final double payrollExpenses;
  final double otherExpenses;
  final Map<String, double> byCategory;
  final double expensesGrowthPercent;

  const ExpenseSummary({
    required this.totalExpenses,
    required this.operatingExpenses,
    required this.payrollExpenses,
    required this.otherExpenses,
    required this.byCategory,
    required this.expensesGrowthPercent,
  });

  factory ExpenseSummary.empty() {
    return const ExpenseSummary(
      totalExpenses: 0,
      operatingExpenses: 0,
      payrollExpenses: 0,
      otherExpenses: 0,
      byCategory: {},
      expensesGrowthPercent: 0,
    );
  }

  ExpenseSummary copyWith({
    double? totalExpenses,
    double? operatingExpenses,
    double? payrollExpenses,
    double? otherExpenses,
    Map<String, double>? byCategory,
    double? expensesGrowthPercent,
  }) {
    return ExpenseSummary(
      totalExpenses: totalExpenses ?? this.totalExpenses,
      operatingExpenses: operatingExpenses ?? this.operatingExpenses,
      payrollExpenses: payrollExpenses ?? this.payrollExpenses,
      otherExpenses: otherExpenses ?? this.otherExpenses,
      byCategory: byCategory ?? this.byCategory,
      expensesGrowthPercent:
      expensesGrowthPercent ?? this.expensesGrowthPercent,
    );
  }
}

@immutable
class InventoryFinancialSummary {
  final double inventoryValueAtCost;
  final double inventoryValueAtRetail;
  final double estimatedGrossMarginValue;
  final double deadStockValue;
  final double lowStockRiskValue;
  final double turnoverRate;

  const InventoryFinancialSummary({
    required this.inventoryValueAtCost,
    required this.inventoryValueAtRetail,
    required this.estimatedGrossMarginValue,
    required this.deadStockValue,
    required this.lowStockRiskValue,
    required this.turnoverRate,
  });

  factory InventoryFinancialSummary.empty() {
    return const InventoryFinancialSummary(
      inventoryValueAtCost: 0,
      inventoryValueAtRetail: 0,
      estimatedGrossMarginValue: 0,
      deadStockValue: 0,
      lowStockRiskValue: 0,
      turnoverRate: 0,
    );
  }

  InventoryFinancialSummary copyWith({
    double? inventoryValueAtCost,
    double? inventoryValueAtRetail,
    double? estimatedGrossMarginValue,
    double? deadStockValue,
    double? lowStockRiskValue,
    double? turnoverRate,
  }) {
    return InventoryFinancialSummary(
      inventoryValueAtCost: inventoryValueAtCost ?? this.inventoryValueAtCost,
      inventoryValueAtRetail:
      inventoryValueAtRetail ?? this.inventoryValueAtRetail,
      estimatedGrossMarginValue:
      estimatedGrossMarginValue ?? this.estimatedGrossMarginValue,
      deadStockValue: deadStockValue ?? this.deadStockValue,
      lowStockRiskValue: lowStockRiskValue ?? this.lowStockRiskValue,
      turnoverRate: turnoverRate ?? this.turnoverRate,
    );
  }
}

@immutable
class MonthlyFinancePoint {
  final String label;
  final double netSales;
  final double cogs;
  final double grossProfit;
  final double expenses;
  final double payroll;
  final double netProfit;
  final double cashFlow;

  const MonthlyFinancePoint({
    required this.label,
    required this.netSales,
    required this.cogs,
    required this.grossProfit,
    required this.expenses,
    required this.payroll,
    required this.netProfit,
    required this.cashFlow,
  });

  factory MonthlyFinancePoint.empty(String label) {
    return MonthlyFinancePoint(
      label: label,
      netSales: 0,
      cogs: 0,
      grossProfit: 0,
      expenses: 0,
      payroll: 0,
      netProfit: 0,
      cashFlow: 0,
    );
  }

  MonthlyFinancePoint copyWith({
    String? label,
    double? netSales,
    double? cogs,
    double? grossProfit,
    double? expenses,
    double? payroll,
    double? netProfit,
    double? cashFlow,
  }) {
    return MonthlyFinancePoint(
      label: label ?? this.label,
      netSales: netSales ?? this.netSales,
      cogs: cogs ?? this.cogs,
      grossProfit: grossProfit ?? this.grossProfit,
      expenses: expenses ?? this.expenses,
      payroll: payroll ?? this.payroll,
      netProfit: netProfit ?? this.netProfit,
      cashFlow: cashFlow ?? this.cashFlow,
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

  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? referenceId;
  final String? sourceModule;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.notes,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.referenceId,
    this.sourceModule,
  });

  factory ExpenseItem.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseItem(
      id: id,
      title: (map['title'] ?? '').toString(),
      category: (map['category'] ?? 'عام').toString(),
      amount: _readDouble(map['amount']),
      date: _readDate(map['date']) ?? DateTime.now(),
      paymentMethod: (map['paymentMethod'] ?? 'cash').toString(),
      notes: map['notes']?.toString(),
      createdBy: map['createdBy']?.toString(),
      updatedBy: map['updatedBy']?.toString(),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      referenceId: map['referenceId']?.toString(),
      sourceModule: map['sourceModule']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'referenceId': referenceId,
      'sourceModule': sourceModule,
    };
  }

  ExpenseItem copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? referenceId,
    String? sourceModule,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      referenceId: referenceId ?? this.referenceId,
      sourceModule: sourceModule ?? this.sourceModule,
    );
  }

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);

    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    return null;
  }
}