// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../controllers/finance_controller.dart';
import '../../models/finance_model.dart';
import 'expenses_page.dart';

class FinanceConstants {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color softBlue = Color(0xFFEAF3FF);
  static const Color teal = Color(0xFF00897B);
  static const Color green = Color(0xFF43A047);
  static const Color orange = Color(0xFFEF6C00);
  static const Color deepOrange = Color(0xFFD84315);
  static const Color purple = Color(0xFF6A1B9A);

  static const List<String> months = [
    'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون',
    'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
  ];

  static const String currency = 'د.ل';
}

// ============= الدوال المساعدة العامة =============
String formatMoney(dynamic value) {
  if (value == null) return '0 ${FinanceConstants.currency}';

  double numValue;
  if (value is String) {
    numValue = double.tryParse(value) ?? 0;
  } else if (value is int) {
    numValue = value.toDouble();
  } else if (value is double) {
    numValue = value;
  } else {
    return '0 ${FinanceConstants.currency}';
  }

  return '${numValue.toStringAsFixed(2)} ${FinanceConstants.currency}';
}

String calculateProfitPercentage(dynamic profit, dynamic sales) {
  double profitValue = 0;
  double salesValue = 0;

  if (profit is String) profitValue = double.tryParse(profit) ?? 0;
  else if (profit is double) profitValue = profit;
  else if (profit is int) profitValue = profit.toDouble();

  if (sales is String) salesValue = double.tryParse(sales) ?? 0;
  else if (sales is double) salesValue = sales;
  else if (sales is int) salesValue = sales.toDouble();

  if (salesValue <= 0) return '0%';
  final percentage = (profitValue / salesValue * 100);
  return '${percentage.toStringAsFixed(1)}%';
}

double getValueForIndex(int index, dynamic data) {
  switch (index) {
    case 0: return toDouble(data.totalSalesMonth);
    case 1: return toDouble(data.totalPurchasesMonth);
    case 2: return toDouble(data.netProfitMonth);
    case 3: return toDouble(data.totalExpensesMonth);
    case 4: return toDouble(data.totalDueSuppliers);
    case 5: return toDouble(data.totalReceivables);
    default: return 0;
  }
}

double toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}


Widget buildInfoRow(String label, String value, Color color, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget buildLiquiditySection(dynamic data) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      buildInfoRow('الداخل كاش', formatMoney(data.cashIn), Colors.green),
      buildInfoRow('الخارج كاش', formatMoney(data.cashOut), Colors.red),
      const Divider(height: 16),
      buildInfoRow('رصيد الكاش التقريبي', formatMoney(data.cashBalance), FinanceConstants.primaryBlue, isBold: true),
      const SizedBox(height: 8),
      buildInfoRow('الداخل بنك/بطاقة', formatMoney(data.bankIn), Colors.green),
      buildInfoRow('الخارج بنك/بطاقة', formatMoney(data.bankOut), Colors.red),
      const Divider(height: 16),
      buildInfoRow('رصيد البنك التقريبي', formatMoney(data.bankBalance), FinanceConstants.primaryBlue, isBold: true),
    ],
  );
}

Widget buildPayrollSection(dynamic payroll) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      buildInfoRow('عدد الموظفين', '${payroll.employeesCount}', FinanceConstants.primaryBlue),
      buildInfoRow('إجمالي الرواتب', formatMoney(payroll.totalMonthlySalaries), Colors.black87),
      buildInfoRow('المدفوع', formatMoney(payroll.paidSalariesThisMonth), Colors.green),
      buildInfoRow('المتبقي', formatMoney(payroll.unpaidSalariesThisMonth), Colors.red),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: (payroll.paymentRate / 100).clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(FinanceConstants.primaryBlue),
        ),
      ),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'نسبة السداد: ${payroll.paymentRate.toStringAsFixed(1)}%',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

Widget buildAnnualSummarySection(dynamic data) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      buildInfoRow('مبيعات السنة', formatMoney(data.totalSalesYear), Colors.green),
      buildInfoRow('مشتريات السنة', formatMoney(data.totalPurchasesYear), Colors.orange),
      buildInfoRow('مصروفات السنة', formatMoney(data.totalExpensesYear), Colors.red),
      const Divider(height: 16),
      buildInfoRow('صافي السنة', formatMoney(data.netProfitYear), FinanceConstants.primaryBlue, isBold: true),
    ],
  );
}
// =================================================

class FinancePage extends GetView<FinanceController> {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,  // خلفية بيضاء للصفحة
      body: SafeArea(
        child: Obx(() {
          final data = controller.overview.value;

          return RefreshIndicator(
            onRefresh: controller.loadFinanceData,
            child: controller.isLoading.value && data.monthlyTrend.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== HEADER SECTION ==========
                  _HeaderSection(
                    year: controller.selectedYear.value,
                    onRefresh: controller.loadFinanceData,
                    onYearChanged: controller.changeYear,
                    onExport: _exportReport,
                  ),
                  const SizedBox(height: 12),
                  // بطاقات المؤشرات المالية
                  _CompactPanel(
                    title: '',
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int cardsPerRow = constraints.maxWidth > 800 ? 3:
                        constraints.maxWidth > 500 ? 2 : 1;

                        double cardWidth = (constraints.maxWidth - (cardsPerRow - 1) * 12) / cardsPerRow;

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatCard(
                              title: 'مبيعات الشهر',
                              icon: Icons.point_of_sale_rounded,
                              color: FinanceConstants.primaryBlue,
                              value: formatMoney(data.totalSalesMonth),
                              width: cardWidth,
                            ),
                            _buildStatCard(
                              title: 'مشتريات الشهر',
                              icon: Icons.shopping_cart_checkout_rounded,
                              color: FinanceConstants.teal,
                              value: formatMoney(data.totalPurchasesMonth),
                              width: cardWidth,
                            ),
                            _buildStatCard(
                              title: 'مصروفات الشهر',
                              icon: Icons.receipt_long_rounded,
                              color: FinanceConstants.orange,
                              value: formatMoney(data.totalExpensesMonth),
                              width: cardWidth,
                            ),
                            _buildStatCard(
                              title: 'ذمم الموردين',
                              icon: Icons.account_balance_wallet_rounded,
                              color: FinanceConstants.deepOrange,
                              value: formatMoney(data.totalDueSuppliers),
                              width: cardWidth,
                            ),
                            _buildStatCard(
                              title: 'المستحقات لك',
                              icon: Icons.payments_rounded,
                              color: FinanceConstants.purple,
                              value: formatMoney(data.totalReceivables),
                              width: cardWidth,
                            ),
                            _buildStatCard(
                              title: 'صافي الربح',
                              icon: Icons.trending_up_rounded,
                              color: FinanceConstants.green,
                              value: formatMoney(data.netProfitMonth),
                              percentage: calculateProfitPercentage(data.netProfitMonth, data.totalSalesMonth),
                              width: cardWidth,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ========== MAIN ROW ==========
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        return Column(
                          children: [
                            // اليسار
                            _CompactPanel(
                              title: 'السيولة',
                              child: _buildLiquiditySection(data),
                            ),
                            const SizedBox(height: 12),
                            _CompactPanel(
                              title: 'الرواتب',
                              child: _buildPayrollSection(data.payroll),
                            ),
                            const SizedBox(height: 12),
                            _CompactPanel(
                              title: 'ملخص سنوي',
                              child: _buildAnnualSummarySection(data),
                            ),
                            const SizedBox(height: 20),
                            // اليمين
                            _CompactPanel(
                              title: 'تحليل المصروفات',
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 500) {
                                    return Column(
                                      children: [
                                        SizedBox(
                                          height: 200,
                                          child: controller.expenses.isEmpty
                                              ? const Center(child: Text('لا توجد بيانات'))
                                              : ExpensesPieChart(
                                            expenses: controller.expenses,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildExpenseCategoriesList(controller),
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: SizedBox(
                                            height: 220,
                                            child: controller.expenses.isEmpty
                                                ? const Center(child: Text('لا توجد بيانات'))
                                                : ExpensesPieChart(
                                              expenses: controller.expenses,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 4,
                                          child: SizedBox(
                                            height: 220,
                                            child: _buildExpenseCategoriesList(controller),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            _CompactPanel(
                              title: 'الاتجاه الشهري',
                              child: SizedBox(
                                height: 280,
                                child: data.monthlyTrend.isEmpty
                                    ? const Center(child: Text('لا توجد بيانات'))
                                    : MonthlyFinanceChart(
                                  monthlyTrend: data.monthlyTrend,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العمود الأيسر: السيولة + الرواتب + الملخص السنوي
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _CompactPanel(
                                    title: 'السيولة',
                                    child: _buildLiquiditySection(data),
                                  ),
                                  const SizedBox(height: 12),
                                  _CompactPanel(
                                    title: 'الرواتب',
                                    child: _buildPayrollSection(data.payroll),
                                  ),
                                  const SizedBox(height: 12),
                                  _CompactPanel(
                                    title: 'ملخص سنوي',
                                    child: _buildAnnualSummarySection(data),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // العمود الأيمن: تحليل المصروفات + الاتجاه الشهري
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _CompactPanel(
                                    title: 'تحليل المصروفات',
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        if (constraints.maxWidth < 500) {
                                          return Column(
                                            children: [
                                              SizedBox(
                                                height: 200,
                                                child: controller.expenses.isEmpty
                                                    ? const Center(child: Text('لا توجد بيانات'))
                                                    : ExpensesPieChart(
                                                  expenses: controller.expenses,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              _buildExpenseCategoriesList(controller),
                                            ],
                                          );
                                        } else {
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 6,
                                                child: SizedBox(
                                                  height: 220,
                                                  child: controller.expenses.isEmpty
                                                      ? const Center(child: Text('لا توجد بيانات'))
                                                      : ExpensesPieChart(
                                                    expenses: controller.expenses,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 4,
                                                child: SizedBox(
                                                  height: 220,
                                                  child: _buildExpenseCategoriesList(controller),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  _CompactPanel(
                                    title: 'الاتجاه الشهري',
                                    child: SizedBox(
                                      height: 280,
                                      child: data.monthlyTrend.isEmpty
                                          ? const Center(child: Text('لا توجد بيانات'))
                                          : MonthlyFinanceChart(
                                        monthlyTrend: data.monthlyTrend,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
// ========== HELPER METHODS ==========



  Widget _buildLiquiditySection(FinanceOverview data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildLiquidityRow(
            'النقدية',
            data.cashIn,
            data.cashOut,
            data.cashBalance,
            Icons.money_rounded,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildLiquidityRow(
            'البنك',
            data.bankIn,
            data.bankOut,
            data.bankBalance,
            Icons.account_balance_rounded,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityRow(String label, double incoming, double outgoing, double balance, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'وارد: ${formatMoney(incoming)}',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'صادر: ${formatMoney(outgoing)}',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: balance >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            formatMoney(balance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollSection(PayrollSummary payroll) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildPayrollInfoRow('عدد الموظفين', payroll.employeesCount.toString(), Icons.people_rounded),
          const SizedBox(height: 12),
          _buildPayrollInfoRow('إجمالي الرواتب', formatMoney(payroll.totalMonthlySalaries), Icons.attach_money_rounded),
          const SizedBox(height: 12),
          _buildPayrollInfoRow('المدفوع', formatMoney(payroll.paidSalariesThisMonth), Icons.check_circle_rounded, color: Colors.green),
          const SizedBox(height: 12),
          _buildPayrollInfoRow('المتبقي', formatMoney(payroll.unpaidSalariesThisMonth), Icons.access_time_rounded, color: Colors.orange),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: payroll.paymentRate / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              payroll.paymentRate >= 80 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'نسبة الدفع: ${payroll.paymentRate.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnualSummarySection(FinanceOverview data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildAnnualSummaryRow('إجمالي المبيعات', formatMoney(data.totalSalesYear), Icons.trending_up, Colors.blue),
          const SizedBox(height: 12),
          _buildAnnualSummaryRow('إجمالي المشتريات', formatMoney(data.totalPurchasesYear), Icons.shopping_cart, Colors.teal),
          const SizedBox(height: 12),
          _buildAnnualSummaryRow('إجمالي المصروفات', formatMoney(data.totalExpensesYear), Icons.receipt, Colors.orange),
          const Divider(height: 20),
          _buildAnnualSummaryRow('صافي الربح السنوي', formatMoney(data.netProfitYear), Icons.assessment, Colors.green, isBold: true),
        ],
      ),
    );
  }

  Widget _buildAnnualSummaryRow(String label, String value, IconData icon, Color color, {bool isBold = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 15 : 14,
            color: isBold ? color : null,
          ),
        ),
      ],
    );
  }


  Widget _buildExpensesTable(List<ExpenseItem> expenses, BuildContext context) {
    if (MediaQuery.of(context).size.width < 600) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length > 5 ? 5 : expenses.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final e = expenses[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: getCategoryColor(e.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_rounded,
                color: getCategoryColor(e.category),
                size: 20,
              ),
            ),
            title: Text(
              e.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${e.category} • ${e.paymentMethod}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatMoney(e.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columnSpacing: 20,
          horizontalMargin: 8,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('العنوان')),
            DataColumn(label: Text('الفئة')),
            DataColumn(label: Text('المبلغ')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('طريقة الدفع')),
          ],
          rows: expenses.take(8).map((e) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getCategoryColor(e.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.category,
                      style: TextStyle(
                        color: getCategoryColor(e.category),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatMoney(e.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                DataCell(
                  Text(e.paymentMethod),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }
  }

// ========== UTILITY FUNCTIONS ==========

  String formatMoney(double value) {
    return ' د.ل ${value.toStringAsFixed(2)} '; // عدل حسب العملة المفضلة
  }

  double? calculateProfitPercentage(double profit, double sales) {
    if (sales == 0) return null;
    return (profit / sales) * 100;
  }

// ========== HELPER METHODS ==========

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    double? percentage,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: _StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        percentage: percentage != null ? '${percentage.toStringAsFixed(1)}%' : null,
      ),
    );
  }

  Widget _buildExpenseCategoriesList(dynamic controller) {
    final categories = controller.getTopExpenseCategories(5);
    if (categories.isEmpty) {
      return const Center(child: Text('لا توجد فئات'));
    }

    final totalExpenses = controller.getFilteredExpensesTotal();

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryName = category['name'] as String;
        final categoryTotal = category['total'] as double;
        final percentage = totalExpenses > 0 ? (categoryTotal / totalExpenses) * 100 : 0;

        return Row(
          children: [
            // استخدام نفس دالة الألوان الموحدة
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: getCategoryColor(categoryName),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text(
              formatMoney(categoryTotal),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              '  (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }
  void _exportReport() {
    Get.dialog(
      AlertDialog(
        title: const Text('تصدير التقرير'),
        content: const Text('اختر صيغة التقرير:'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'نجاح',
                'تم تصدير التقرير بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'نجاح',
                'تم تصدير التقرير بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int year;
  final VoidCallback onRefresh;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onExport;

  const _HeaderSection({
    required this.year,
    required this.onRefresh,
    required this.onYearChanged,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
            Colors.lightBlue.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الشؤون المالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'متابعة المبيعات، المشتريات، المصروفات، الذمم والرواتب',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButton<int>(
              value: year,
              underline: const SizedBox(),
              items: List.generate(6, (index) {
                final y = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: y,
                  child: Text('$y'),
                );
              }),
              onChanged: (v) {
                if (v != null) onYearChanged(v);
              },
            ),
          ),
          const SizedBox(width: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {
                Get.dialog(
                  const ExpensesDialog(),
                  barrierDismissible: true, // يمكن إغلاقه بالنقر خارج الديالوج
                );
              },
              icon: const Icon(
                Iconsax.setting_2,
                color: Color(0xFF1565C0),
              ),
              tooltip: 'إدارة المصروفات',
            ),
          ) ,
          const SizedBox(width: 10),

          IconButton(
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 5),

          IconButton(
            onPressed: onExport,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
            ),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _StatCardData {
  final String title;
  final IconData icon;
  final Color color;

  const _StatCardData(this.title, this.icon, this.color);
}

class _CompactPanel extends StatelessWidget {
  final String title;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const _CompactPanel({
    required this.title,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // تدرج أزرق للبطاقات كما طلبت
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? percentage;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                percentage!,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// نسخة محسنة من ExpensesPieChart مع ألوان متناسقة
class ExpensesPieChart extends StatelessWidget {
  final List<ExpenseItem> expenses;

  const ExpensesPieChart({
    super.key,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _calculateCategoryTotals();
    final total = categoryTotals.values.fold(0.0, (sum, item) => sum + item);

    if (total == 0) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    // ترتيب الفئات تنازلياً
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.map((entry) {
      final percentage = (entry.value / total) * 100;
      if (percentage < 1) return null; // تجاهل الفئات الصغيرة جداً

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        color: getCategoryColor(entry.key),
        radius: 80,
        titlePositionPercentageOffset: 0.6,
      );
    }).whereType<PieChartSectionData>().toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // يمكن إضافة تفاعل هنا
          },
        ),
      ),
    );
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }
}// دالة مساعدة خارجية للاستخدام في أماكن أخرى
class MonthlyFinanceChart extends StatelessWidget {
  final List<MonthlyPoint> monthlyTrend;

  const MonthlyFinanceChart({
    super.key,
    required this.monthlyTrend,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = _getMaxY();
    final lastIndex = monthlyTrend.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 10,
          children: const [
            _ChartLegend(color: FinanceConstants.primaryBlue, label: 'المبيعات'),
            _ChartLegend(color: FinanceConstants.teal, label: 'المشتريات'),
            _ChartLegend(color: FinanceConstants.orange, label: 'المصروفات'),
            _ChartLegend(color: Colors.green, label: 'الربح / الخسارة'),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: _getMinProfit(),
              maxY: maxY,
              clipData: const FlClipData.all(),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Colors.grey.shade400,
                    strokeWidth: 1.2,
                    dashArray: [6, 4],
                  ),
                ],
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY <= 0 ? 100 : maxY / 5,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: maxY <= 0 ? 100 : maxY / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 ||
                          index >= FinanceConstants.months.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          FinanceConstants.months[index],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.blue.shade100),
                  bottom: BorderSide(color: Colors.blue.shade100),
                  top: BorderSide.none,
                  right: BorderSide.none,
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.all(10),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      String label = '';

                      if (spot.barIndex == 0) label = 'المبيعات';
                      if (spot.barIndex == 1) label = 'المشتريات';
                      if (spot.barIndex == 2) label = 'المصروفات';
                      if (spot.barIndex == 3) label = 'الربح / الخسارة';

                      return LineTooltipItem(
                        '$label\n${spot.y.toStringAsFixed(2)} ${FinanceConstants.currency}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                _buildLine(
                  data: monthlyTrend.map((e) => e.sales).toList(),
                  color: FinanceConstants.primaryBlue,
                ),
                _buildLine(
                  data: monthlyTrend.map((e) => e.purchases).toList(),
                  color: FinanceConstants.teal,
                ),
                _buildLine(
                  data: monthlyTrend.map((e) => e.expenses).toList(),
                  color: FinanceConstants.orange,
                ),
                _buildProfitLine(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine({
    required List<double> data,
    required Color color,
  }) {
    final spots = List.generate(
      data.length,
          (index) => FlSpot(index.toDouble(), data[index]),
    );

    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        cutOffY: 0,
        applyCutOffY: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
      spots: spots,
    );
  }

  LineChartBarData _buildProfitLine() {
    final spots = List.generate(
      monthlyTrend.length,
          (index) => FlSpot(index.toDouble(), monthlyTrend[index].profit),
    );

    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      gradient: LinearGradient(
        colors: monthlyTrend.map((e) {
          return e.profit >= 0 ? Colors.green : Colors.red;
        }).toList(),
      ),
      belowBarData: BarAreaData(
        show: true,
        cutOffY: 0,
        applyCutOffY: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (monthlyTrend.last.profit >= 0
                ? Colors.green
                : Colors.red)
                .withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
      spots: spots,
    );
  }

  double _getMaxY() {
    double maxValue = 0;

    for (final item in monthlyTrend) {
      if (item.sales > maxValue) maxValue = item.sales;
      if (item.purchases > maxValue) maxValue = item.purchases;
      if (item.expenses > maxValue) maxValue = item.expenses;
    }

    if (maxValue <= 0) return 100;

    return maxValue * 1.2;
  }

  double _getMinProfit() {
    double minProfit = 0;

    for (final item in monthlyTrend) {
      if (item.profit < minProfit) {
        minProfit = item.profit;
      }
    }

    if (minProfit >= 0) return 0;

    return minProfit * 1.2;
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
class FinanceColors {
  // الألوان الأساسية المتناسقة مع الأزرق
  static const Color primaryBlue = Color(0xFF1976D2); // أزرق غامق
  static const Color lightBlue = Color(0xFF42A5F5);   // أزرق فاتح
  static const Color skyBlue = Color(0xFF4FC3F7);     // سماوي
  static const Color cyan = Color(0xFF26C6DA);        // سيان
  static const Color teal = Color(0xFF26A69A);        // تيل
  static const Color green = Color(0xFF66BB6A);       // أخضر
  static const Color lightGreen = Color(0xFF9CCC65);  // أخضر فاتح
  static const Color indigo = Color(0xFF5C6BC0);      // نيلي
  static const Color blueGrey = Color(0xFF78909C);    // أزرق رمادي

  // ألوان داعمة خفيفة للتباين (تجنّب ألوان قوية خارجة عن التدرج)
  static const Color deepPurple = Color(0xFF7E57C2);  // بنفسجي غامق
  static const Color lime = Color(0xFFD4E157);        // ليموني فاتح
}

// ========== دالة موحدة للألوان مع تدرجات متناسقة ==========
Color getCategoryColor(String category) {
  switch (category) {
    case 'رواتب':
    case 'الرواتب':
      return FinanceColors.lightBlue;

    case 'إيجار':
      return FinanceColors.indigo;

    case 'فواتير':
    case 'كهرباء':
      return FinanceColors.primaryBlue;

    case 'مخزون':
    case 'أدوية':
      return FinanceColors.green;
    case 'مستلزمات':
      return FinanceColors.lightGreen;

    case 'صيانة':
      return FinanceColors.blueGrey;

    case 'تسويق':
    case 'دعاية':
      return FinanceColors.deepPurple;

    case 'نقل':
    case 'مواصلات':
      return FinanceColors.teal;

    case 'تأمين':
      return FinanceColors.indigo;

    case 'ضرائب':
    case 'رسوم':
      return FinanceColors.lime;

    case 'مشتريات':
      return FinanceColors.cyan;

    case 'إدارية':
    case 'إدارة':
      return FinanceColors.blueGrey;

    default:
      return _getHarmoniousColor(category);
  }
}

// دالة توليد ألوان متناسقة مع التدرج الأزرق-الأخضر
Color _getHarmoniousColor(String category) {
  final harmoniousColors = [
    FinanceColors.primaryBlue,
    FinanceColors.lightBlue,
    FinanceColors.skyBlue,
    FinanceColors.cyan,
    FinanceColors.teal,
    FinanceColors.green,
    FinanceColors.lightGreen,
    FinanceColors.indigo,
    FinanceColors.blueGrey,
    FinanceColors.deepPurple,
    FinanceColors.lime,
  ];

  final index = category.hashCode.abs() % harmoniousColors.length;
  return harmoniousColors[index];
}