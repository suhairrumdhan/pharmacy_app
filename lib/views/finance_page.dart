// ignore_for_file: prefer_const_constructors

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../controllers/finance_controller.dart';
import '../../models/finance_model.dart';
import 'expenses_page.dart';

class FinancePage extends GetView<FinanceController> {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FinanceColors.pageBg,
      body: SafeArea(
        child: Obx(() {
          final dashboard = controller.dashboard.value;

          if (controller.isLoading.value && dashboard.monthlyTrend.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadFinanceData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FinanceHeader(
                    selectedYear: controller.selectedYear.value,
                    selectedMonth: controller.selectedMonth.value,
                    onYearChanged: controller.changeYear,
                    onMonthChanged: controller.changeMonth,
                    onRefresh: controller.loadFinanceData,
                    onOpenExpenses: () {
                      if (!controller.canViewExpenses) {
                        Get.snackbar(
                          'غير مسموح',
                          'ليس لديك صلاحية عرض المصروفات',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      Get.dialog(
                        const ExpensesDialog(),
                        barrierDismissible: true,
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  _ExecutiveKpisGrid(dashboard: dashboard),

                  const SizedBox(height: 18),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1180;
                      final isMedium = constraints.maxWidth >= 760;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _SectionCard(
                                    title: 'تحليل الربحية',
                                    icon: Iconsax.chart_21,
                                    child: _ProfitabilitySection(
                                      data: dashboard.profitability,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _SectionCard(
                                    title: 'الاتجاه الشهري',
                                    icon: Iconsax.chart_2,
                                    child: _MonthlyTrendSection(
                                      monthlyTrend: dashboard.monthlyTrend,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _SectionCard(
                                    title: 'السيولة النقدية',
                                    icon: Iconsax.wallet_3,
                                    child: _CashBankSection(
                                      cash: dashboard.cash,
                                      bank: dashboard.bank,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _SectionCard(
                                    title: 'رأس المال العامل',
                                    icon: Iconsax.activity,
                                    child: _WorkingCapitalSection(
                                      data: dashboard.workingCapital,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _SectionCard(
                                    title: 'الرواتب',
                                    icon: Iconsax.profile_2user,
                                    child: _PayrollSection(
                                      data: dashboard.payroll,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _SectionCard(
                                    title: 'المخزون مالياً',
                                    icon: Iconsax.box,
                                    child: _InventorySection(
                                      data: dashboard.inventory,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      if (isMedium) {
                        return Column(
                          children: [
                            _SectionCard(
                              title: 'تحليل الربحية',
                              icon: Iconsax.chart_21,
                              child: _ProfitabilitySection(
                                data: dashboard.profitability,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _SectionCard(
                                    title: 'السيولة النقدية',
                                    icon: Iconsax.wallet_3,
                                    child: _CashBankSection(
                                      cash: dashboard.cash,
                                      bank: dashboard.bank,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _SectionCard(
                                    title: 'رأس المال العامل',
                                    icon: Iconsax.activity,
                                    child: _WorkingCapitalSection(
                                      data: dashboard.workingCapital,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _SectionCard(
                                    title: 'الرواتب',
                                    icon: Iconsax.profile_2user,
                                    child: _PayrollSection(
                                      data: dashboard.payroll,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _SectionCard(
                                    title: 'المخزون مالياً',
                                    icon: Iconsax.box,
                                    child: _InventorySection(
                                      data: dashboard.inventory,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'الاتجاه الشهري',
                              icon: Iconsax.chart_2,
                              child: _MonthlyTrendSection(
                                monthlyTrend: dashboard.monthlyTrend,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _SectionCard(
                            title: 'تحليل الربحية',
                            icon: Iconsax.chart_21,
                            child: _ProfitabilitySection(
                              data: dashboard.profitability,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'السيولة النقدية',
                            icon: Iconsax.wallet_3,
                            child: _CashBankSection(
                              cash: dashboard.cash,
                              bank: dashboard.bank,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'رأس المال العامل',
                            icon: Iconsax.activity,
                            child: _WorkingCapitalSection(
                              data: dashboard.workingCapital,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'الرواتب',
                            icon: Iconsax.profile_2user,
                            child: _PayrollSection(
                              data: dashboard.payroll,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'المخزون مالياً',
                            icon: Iconsax.box,
                            child: _InventorySection(
                              data: dashboard.inventory,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'الاتجاه الشهري',
                            icon: Iconsax.chart_2,
                            child: _MonthlyTrendSection(
                              monthlyTrend: dashboard.monthlyTrend,
                            ),
                          ),
                        ],
                      );
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
}

class _FinanceHeader extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenExpenses;

  const _FinanceHeader({
    required this.selectedYear,
    required this.selectedMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onRefresh,
    required this.onOpenExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(6, (i) => now.year - 3 + i);
    final months = const {
      1: 'يناير',
      2: 'فبراير',
      3: 'مارس',
      4: 'أبريل',
      5: 'مايو',
      6: 'يونيو',
      7: 'يوليو',
      8: 'أغسطس',
      9: 'سبتمبر',
      10: 'أكتوبر',
      11: 'نوفمبر',
      12: 'ديسمبر',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _FinanceColors.primary,
            _FinanceColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _FinanceColors.primary.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerTopRow(onRefresh: onRefresh, onOpenExpenses: onOpenExpenses),
                const SizedBox(height: 16),
                _headerFilters(
                  years: years,
                  months: months,
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  onYearChanged: onYearChanged,
                  onMonthChanged: onMonthChanged,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _headerTopRow(onRefresh: onRefresh, onOpenExpenses: onOpenExpenses)),
              const SizedBox(width: 18),
              SizedBox(
                width: 360,
                child: _headerFilters(
                  years: years,
                  months: months,
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  onYearChanged: onYearChanged,
                  onMonthChanged: onMonthChanged,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerTopRow({
    required Future<void> Function() onRefresh,
    required VoidCallback onOpenExpenses,
  }) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Iconsax.chart_success,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإدارة المالية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'لوحة مالية احترافية للمبيعات والربحية والسيولة والالتزامات',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderActionButton(
          label: 'المصروفات',
          icon: Iconsax.money_4,
          onTap: onOpenExpenses,
        ),
        const SizedBox(width: 10),
        _HeaderActionButton(
          label: 'تحديث',
          icon: Iconsax.refresh,
          onTap: () => onRefresh(),
        ),
      ],
    );
  }

  Widget _headerFilters({
    required List<int> years,
    required Map<int, String> months,
    required int selectedYear,
    required int selectedMonth,
    required ValueChanged<int> onYearChanged,
    required ValueChanged<int> onMonthChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _HeaderDropdown<int>(
            value: selectedYear,
            items: years
                .map((year) => DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) onYearChanged(value);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeaderDropdown<int>(
            value: selectedMonth,
            items: months.entries
                .map((e) => DropdownMenuItem<int>(
              value: e.key,
              child: Text(e.value),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) onMonthChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _ExecutiveKpisGrid extends StatelessWidget {
  final FinanceDashboard dashboard;

  const _ExecutiveKpisGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiData(
        title: 'صافي المبيعات',
        value: _money(dashboard.sales.netSales),
        subtitle: 'عدد الفواتير: ${dashboard.sales.invoicesCount}',
        icon: Iconsax.receipt_2,
        color: _FinanceColors.primary,
      ),
      _KpiData(
        title: 'إجمالي الربح',
        value: _money(dashboard.profitability.grossProfit),
        subtitle:
        'هامش ${dashboard.profitability.grossMarginPercent.toStringAsFixed(1)}%',
        icon: Iconsax.chart_1,
        color: _FinanceColors.success,
      ),
      _KpiData(
        title: 'صافي الربح',
        value: _money(dashboard.profitability.netProfit),
        subtitle:
        'هامش ${dashboard.profitability.netMarginPercent.toStringAsFixed(1)}%',
        icon: Iconsax.trend_up,
        color: dashboard.profitability.netProfit >= 0
            ? _FinanceColors.success
            : _FinanceColors.danger,
      ),
      _KpiData(
        title: 'إغلاق الكاش',
        value: _money(dashboard.cash.closingBalance),
        subtitle: 'صافي تدفق ${_money(dashboard.cash.netCashFlow)}',
        icon: Iconsax.wallet_check,
        color: _FinanceColors.warning,
      ),
      _KpiData(
        title: 'الذمم المدينة',
        value: _money(dashboard.workingCapital.accountsReceivable),
        subtitle: 'متأخر ${_money(dashboard.workingCapital.overdueReceivables)}',
        icon: Iconsax.money_recive,
        color: _FinanceColors.purple,
      ),
      _KpiData(
        title: 'الذمم الدائنة',
        value: _money(dashboard.workingCapital.accountsPayable),
        subtitle: 'مستحق قريب ${_money(dashboard.workingCapital.supplierDueSoon)}',
        icon: Iconsax.money_send,
        color: _FinanceColors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 1180) {
          columns = 3;
        } else if (constraints.maxWidth >= 760) {
          columns = 2;
        }

        final width =
            (constraints.maxWidth - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: kpis
              .map((kpi) => SizedBox(
            width: width,
            child: _KpiCard(data: kpi),
          ))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _FinanceColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: _FinanceColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: _FinanceColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    color: _FinanceColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _FinanceColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _FinanceColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _FinanceColors.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _FinanceColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ProfitabilitySection extends StatelessWidget {
  final ProfitabilitySummary data;

  const _ProfitabilitySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem('صافي المبيعات', _money(data.netSales)),
      _MetricItem('تكلفة البضاعة المباعة', _money(data.cogs)),
      _MetricItem('إجمالي الربح', _money(data.grossProfit), positive: data.grossProfit >= 0),
      _MetricItem('المصروفات التشغيلية', _money(data.operatingExpenses)),
      _MetricItem('الرواتب', _money(data.payrollExpenses)),
      _MetricItem('مصروفات أخرى', _money(data.otherExpenses)),
      _MetricItem('الربح التشغيلي', _money(data.operatingProfit), positive: data.operatingProfit >= 0),
      _MetricItem('صافي الربح', _money(data.netProfit), positive: data.netProfit >= 0),
      _MetricItem('هامش الربح الإجمالي', '${data.grossMarginPercent.toStringAsFixed(1)}%'),
      _MetricItem('هامش الربح الصافي', '${data.netMarginPercent.toStringAsFixed(1)}%'),
      _MetricItem('نسبة المصروفات', '${data.expenseRatioPercent.toStringAsFixed(1)}%'),
      _MetricItem('نسبة الرواتب', '${data.payrollRatioPercent.toStringAsFixed(1)}%'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _MetricTile(item: item)).toList(),
    );
  }
}

class _CashBankSection extends StatelessWidget {
  final CashSummary cash;
  final BankSummary bank;

  const _CashBankSection({
    required this.cash,
    required this.bank,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FlowCard(
          title: 'الصندوق / الكاش',
          icon: Iconsax.wallet,
          color: _FinanceColors.warning,
          opening: cash.openingBalance,
          inflow: cash.inflows,
          outflow: cash.outflows,
          closing: cash.closingBalance,
          net: cash.netCashFlow,
        ),
        const SizedBox(height: 14),
        _FlowCard(
          title: 'الحساب البنكي / معاملات مصرفية',
          icon: Iconsax.card,
          color: _FinanceColors.primary,
          opening: bank.openingBalance,
          inflow: bank.inflows,
          outflow: bank.outflows,
          closing: bank.closingBalance,
          net: bank.netFlow,
        ),
      ],
    );
  }
}

class _WorkingCapitalSection extends StatelessWidget {
  final WorkingCapitalSummary data;

  const _WorkingCapitalSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _infoRow('الذمم المدينة', _money(data.accountsReceivable)),
        _infoRow('المتأخر من الذمم المدينة', _money(data.overdueReceivables),
            valueColor: _FinanceColors.danger),
        _infoRow('الذمم الدائنة', _money(data.accountsPayable)),
        _infoRow('المتأخر من الذمم الدائنة', _money(data.overduePayables),
            valueColor: _FinanceColors.danger),
        _infoRow('موردون مستحقون قريباً', _money(data.supplierDueSoon),
            valueColor: _FinanceColors.orange),
        const Divider(height: 24),
        _infoRow(
          'نسبة تغطية السيولة',
          data.liquidityCoverageRatio.toStringAsFixed(2),
          valueColor: data.liquidityCoverageRatio >= 1
              ? _FinanceColors.success
              : _FinanceColors.danger,
          isBold: true,
        ),
      ],
    );
  }
}

class _PayrollSection extends StatelessWidget {
  final PayrollSummary data;

  const _PayrollSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final progress = (data.paymentRatePercent / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('عدد الموظفين', '${data.employeesCount}'),
        _infoRow('إجمالي الرواتب الشهرية', _money(data.totalMonthlySalaries)),
        _infoRow('المدفوع', _money(data.paidSalariesThisMonth),
            valueColor: _FinanceColors.success),
        _infoRow('المتبقي', _money(data.unpaidSalariesThisMonth),
            valueColor: _FinanceColors.orange),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: _FinanceColors.softBlue,
            valueColor: AlwaysStoppedAnimation<Color>(
              data.paymentRatePercent >= 80
                  ? _FinanceColors.success
                  : _FinanceColors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'نسبة السداد: ${data.paymentRatePercent.toStringAsFixed(1)}%',
          style: const TextStyle(
            color: _FinanceColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InventorySection extends StatelessWidget {
  final InventoryFinancialSummary data;

  const _InventorySection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _infoRow('قيمة المخزون بالتكلفة', _money(data.inventoryValueAtCost)),
        _infoRow('قيمة المخزون بسعر البيع', _money(data.inventoryValueAtRetail)),
        _infoRow('هامش الربح التقديري بالمخزون',
            _money(data.estimatedGrossMarginValue),
            valueColor: _FinanceColors.success),
        _infoRow('قيمة المخزون الراكد/التالف', _money(data.deadStockValue),
            valueColor: _FinanceColors.danger),
        _infoRow('مخاطر النقص', _money(data.lowStockRiskValue),
            valueColor: _FinanceColors.orange),
        const Divider(height: 24),
        _infoRow(
          'معدل دوران المخزون',
          data.turnoverRate.toStringAsFixed(2),
          valueColor: _FinanceColors.primary,
          isBold: true,
        ),
      ],
    );
  }
}

class _MonthlyTrendSection extends StatelessWidget {
  final List<MonthlyFinancePoint> monthlyTrend;

  const _MonthlyTrendSection({required this.monthlyTrend});

  @override
  Widget build(BuildContext context) {
    if (monthlyTrend.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('لا توجد بيانات')),
      );
    }

    final maxY = _findMaxY(monthlyTrend);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 290,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 100 : maxY * 1.15,
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxY <= 0 ? 20 : maxY / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: _FinanceColors.border,
                    strokeWidth: 1,
                  );
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
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
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _compactMoney(value),
                        style: const TextStyle(
                          fontSize: 10,
                          color: _FinanceColors.textMuted,
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
                      if (index < 0 || index >= monthlyTrend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          monthlyTrend[index].label.substring(0, 3),
                          style: const TextStyle(
                            fontSize: 10,
                            color: _FinanceColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      String label = '';
                      if (spot.barIndex == 0) label = 'صافي المبيعات';
                      if (spot.barIndex == 1) label = 'إجمالي الربح';
                      if (spot.barIndex == 2) label = 'صافي الربح';
                      return LineTooltipItem(
                        '$label\n${_money(spot.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                _lineBar(
                  monthlyTrend
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.netSales))
                      .toList(),
                  _FinanceColors.primary,
                ),
                _lineBar(
                  monthlyTrend
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.grossProfit))
                      .toList(),
                  _FinanceColors.success,
                ),
                _lineBar(
                  monthlyTrend
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.netProfit))
                      .toList(),
                  _FinanceColors.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _LegendChip(label: 'صافي المبيعات', color: _FinanceColors.primary),
            _LegendChip(label: 'إجمالي الربح', color: _FinanceColors.success),
            _LegendChip(label: 'صافي الربح', color: _FinanceColors.orange),
          ],
        ),
      ],
    );
  }

  double _findMaxY(List<MonthlyFinancePoint> data) {
    double maxValue = 0;
    for (final point in data) {
      if (point.netSales > maxValue) maxValue = point.netSales;
      if (point.grossProfit > maxValue) maxValue = point.grossProfit;
      if (point.netProfit > maxValue) maxValue = point.netProfit;
    }
    return maxValue;
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3.2,
      dotData: FlDotData(
        show: true,
        getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
          radius: 2.8,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double opening;
  final double inflow;
  final double outflow;
  final double closing;
  final double net;

  const _FlowCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.opening,
    required this.inflow,
    required this.outflow,
    required this.closing,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _FinanceColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('رصيد افتتاحي', _money(opening)),
          _infoRow('داخل', _money(inflow), valueColor: _FinanceColors.success),
          _infoRow('خارج', _money(outflow), valueColor: _FinanceColors.danger),
          const Divider(height: 22),
          _infoRow(
            'رصيد إغلاق',
            _money(closing),
            valueColor: color,
            isBold: true,
          ),
          _infoRow(
            'صافي الحركة',
            _money(net),
            valueColor: net >= 0 ? _FinanceColors.success : _FinanceColors.danger,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricItem item;

  const _MetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _FinanceColors.softBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              color: _FinanceColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: item.positive == null
                  ? _FinanceColors.textDark
                  : (item.positive! ? _FinanceColors.success : _FinanceColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _HeaderDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: Colors.white,
          isExpanded: true,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: _FinanceColors.textDark,
            fontWeight: FontWeight.w700,
          ),
          items: items,
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((item) {
              final child = item.child;
              if (child is Text) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    child.data ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList();
          },
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MetricItem {
  final String label;
  final String value;
  final bool? positive;

  const _MetricItem(this.label, this.value, {this.positive});
}

class _FinanceColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color orange = Color(0xFFEA580C);
  static const Color purple = Color(0xFF7C3AED);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color softBlue = Color(0xFFEFF6FF);
}

Widget _infoRow(
    String label,
    String value, {
      Color? valueColor,
      bool isBold = false,
    }) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _FinanceColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _FinanceColors.textDark,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _money(num value) => '${value.toStringAsFixed(2)} د.ل';

String _compactMoney(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }
  return value.toStringAsFixed(0);
}