// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../models/finance_model.dart';

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

class FinancePage extends GetView<FinanceController> {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final data = controller.overview.value;
            final searchController = controller.searchController;

            return RefreshIndicator(
              onRefresh: controller.loadFinanceData,
              child: controller.isLoading.value && data.monthlyTrend.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _HeaderSection(
                    year: controller.selectedYear.value,
                    onRefresh: controller.loadFinanceData,
                    onYearChanged: controller.changeYear,
                    onExport: _exportReport,
                  ),
                  const SizedBox(height: 20),

                  const _SectionTitle(
                    title: 'الملخص المالي',
                    subtitle: 'نظرة عامة على أهم المؤشرات الحالية',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        title: 'مبيعات الشهر',
                        value: _money(data.totalSalesMonth),
                        icon: Icons.point_of_sale_rounded,
                        color: FinanceConstants.primaryBlue,
                      ),
                      _StatCard(
                        title: 'مشتريات الشهر',
                        value: _money(data.totalPurchasesMonth),
                        icon: Icons.shopping_cart_checkout_rounded,
                        color: FinanceConstants.teal,
                      ),
                      _StatCard(
                        title: 'صافي الربح الشهري',
                        value: _money(data.netProfitMonth),
                        icon: Icons.trending_up_rounded,
                        color: FinanceConstants.green,
                        percentage: _calculateProfitPercentage(
                            data.netProfitMonth,
                            data.totalSalesMonth
                        ),
                      ),
                      _StatCard(
                        title: 'مصروفات الشهر',
                        value: _money(data.totalExpensesMonth),
                        icon: Icons.receipt_long_rounded,
                        color: FinanceConstants.orange,
                      ),
                      _StatCard(
                        title: 'ذمم الموردين',
                        value: _money(data.totalDueSuppliers),
                        icon: Icons.account_balance_wallet_rounded,
                        color: FinanceConstants.deepOrange,
                      ),
                      _StatCard(
                        title: 'الذمم المستحقة لك',
                        value: _money(data.totalReceivables),
                        icon: Icons.payments_rounded,
                        color: FinanceConstants.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _Panel(
                              title: 'السيولة والحسابات',
                              child: Column(
                                children: [
                                  _InfoRow('الداخل كاش', _money(data.cashIn), Colors.green),
                                  _InfoRow('الخارج كاش', _money(data.cashOut), Colors.red),
                                  const Divider(),
                                  _InfoRow(
                                    'رصيد الكاش التقريبي',
                                    _money(data.cashBalance),
                                    FinanceConstants.primaryBlue,
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    'الداخل بنك/بطاقة',
                                    _money(data.bankIn),
                                    Colors.green,
                                  ),
                                  _InfoRow(
                                    'الخارج بنك/بطاقة',
                                    _money(data.bankOut),
                                    Colors.red,
                                  ),
                                  const Divider(),
                                  _InfoRow(
                                    'رصيد البنك التقريبي',
                                    _money(data.bankBalance),
                                    FinanceConstants.primaryBlue,
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Panel(
                              title: 'الاتجاه الشهري',
                              child: data.monthlyTrend.isEmpty
                                  ? const SizedBox(
                                height: 320,
                                child: Center(
                                  child: Text('لا توجد بيانات لعرض الرسم البياني'),
                                ),
                              )
                                  : SizedBox(
                                height: 320,
                                child: MonthlyFinanceChart(
                                  monthlyTrend: data.monthlyTrend,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _Panel(
                              title: 'الرواتب',
                              child: Column(
                                children: [
                                  _InfoRow(
                                    'عدد الموظفين',
                                    '${data.payroll.employeesCount}',
                                    FinanceConstants.primaryBlue,
                                  ),
                                  _InfoRow(
                                    'إجمالي الرواتب الشهرية',
                                    _money(data.payroll.totalMonthlySalaries),
                                    Colors.black87,
                                  ),
                                  _InfoRow(
                                    'المدفوع هذا الشهر',
                                    _money(data.payroll.paidSalariesThisMonth),
                                    Colors.green,
                                  ),
                                  _InfoRow(
                                    'المتبقي هذا الشهر',
                                    _money(data.payroll.unpaidSalariesThisMonth),
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      value: (data.payroll.paymentRate / 100)
                                          .clamp(0.0, 1.0),
                                      minHeight: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation(
                                        FinanceConstants.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'نسبة السداد: ${data.payroll.paymentRate.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Panel(
                              title: 'ملخص سنوي',
                              child: Column(
                                children: [
                                  _InfoRow(
                                    'مبيعات السنة',
                                    _money(data.totalSalesYear),
                                    Colors.green,
                                  ),
                                  _InfoRow(
                                    'مشتريات السنة',
                                    _money(data.totalPurchasesYear),
                                    Colors.orange,
                                  ),
                                  _InfoRow(
                                    'مصروفات السنة',
                                    _money(data.totalExpensesYear),
                                    Colors.red,
                                  ),
                                  const Divider(),
                                  _InfoRow(
                                    'صافي السنة',
                                    _money(data.netProfitYear),
                                    FinanceConstants.primaryBlue,
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _Panel(
                          title: 'توزيع المصروفات',
                          child: controller.expenses.isEmpty
                              ? const SizedBox(
                            height: 250,
                            child: Center(
                              child: Text('لا توجد بيانات لعرض الرسم البياني'),
                            ),
                          )
                              : SizedBox(
                            height: 250,
                            child: ExpensesPieChart(
                              expenses: controller.expenses,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Panel(
                          title: 'أعلى 5 فئات',
                          child: Column(
                            children: controller.getTopExpenseCategories(5)
                                .map((category) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(category['name']),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category['name'],
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    _money(category['total']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'آخر المصروفات',
                    subtitle: 'أحدث الحركات المالية التشغيلية',
                  ),
                  const SizedBox(height: 12),

                  _Panel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'بحث في المصروفات...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: FinanceConstants.softBlue,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (value) => controller.filterExpenses(value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: FinanceConstants.softBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'الإجمالي: ${_money(controller.getFilteredExpensesTotal())}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(() {
                          final filteredExpenses = controller.filteredExpenses;

                          if (filteredExpenses.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('لا توجد مصروفات مطابقة للبحث')),
                            );
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(FinanceConstants.softBlue),
                              columns: const [
                                DataColumn(label: Text('العنوان')),
                                DataColumn(label: Text('الفئة')),
                                DataColumn(label: Text('المبلغ')),
                                DataColumn(label: Text('التاريخ')),
                                DataColumn(label: Text('طريقة الدفع')),
                              ],
                              rows: filteredExpenses.take(8).map((e) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(e.title)),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(e.category).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        e.category,
                                        style: TextStyle(
                                          color: _getCategoryColor(e.category),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )),
                                    DataCell(Text(
                                      _money(e.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                    DataCell(
                                      Text(
                                        '${e.date.year}/${e.date.month.toString().padLeft(2, '0')}/${e.date.day.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                    DataCell(Text(e.paymentMethod)),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  static String _money(double v) => '${v.toStringAsFixed(2)} ${FinanceConstants.currency}';

  static String _calculateProfitPercentage(double profit, double sales) {
    if (sales <= 0) return '0%';
    final percentage = (profit / sales * 100);
    return '%${percentage.toStringAsFixed(1)}';
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
              // تصدير PDF
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
              // تصدير Excel
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

  Color _getCategoryColor(String category) {
    final colors = [
      FinanceConstants.primaryBlue,
      FinanceConstants.teal,
      FinanceConstants.green,
      FinanceConstants.orange,
      FinanceConstants.deepOrange,
      FinanceConstants.purple,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
    ];

    final index = category.hashCode % colors.length;
    return colors[index];
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
            Colors.lightBlue.shade400,
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
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
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
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (percentage != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          percentage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: title == null
          ? child
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _InfoRow(
      this.label,
      this.value,
      this.color, {
        this.isBold = false,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

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

    final colors = [
      FinanceConstants.primaryBlue,
      FinanceConstants.teal,
      FinanceConstants.green,
      FinanceConstants.orange,
      FinanceConstants.deepOrange,
      FinanceConstants.purple,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
    ];

    int colorIndex = 0;
    final sections = categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      if (percentage < 1) return null; // تجاهل الفئات الصغيرة جداً

      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        color: color,
        radius: 80,
      );
    }).whereType<PieChartSectionData>().toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (event is FlTapUpEvent) {
              // يمكن إضافة تفاعل عند النقر
            }
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

    // ترتيب تنازلي
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }
}

class MonthlyFinanceChart extends StatelessWidget {
  final List<MonthlyPoint> monthlyTrend;

  const MonthlyFinanceChart({
    super.key,
    required this.monthlyTrend,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = _getMaxY();

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
            _ChartLegend(color: FinanceConstants.green, label: 'الربح'),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
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
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= FinanceConstants.months.length) {
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
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      String label = '';
                      if (spot.barIndex == 0) label = 'المبيعات';
                      if (spot.barIndex == 1) label = 'المشتريات';
                      if (spot.barIndex == 2) label = 'المصروفات';
                      if (spot.barIndex == 3) label = 'الربح';

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
                _buildLine(
                  data: monthlyTrend.map((e) => e.profit).toList(),
                  color: FinanceConstants.green,
                ),
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
    return LineChartBarData(
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
      spots: List.generate(
        data.length,
            (index) => FlSpot(index.toDouble(), data[index]),
      ),
    );
  }

  double _getMaxY() {
    double maxValue = 0;

    for (final item in monthlyTrend) {
      if (item.sales > maxValue) maxValue = item.sales;
      if (item.purchases > maxValue) maxValue = item.purchases;
      if (item.expenses > maxValue) maxValue = item.expenses;
      if (item.profit > maxValue) maxValue = item.profit;
    }

    if (maxValue <= 0) return 100;
    return maxValue * 1.2;
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