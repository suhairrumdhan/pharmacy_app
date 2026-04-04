import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../controllers/dashboard_controller.dart';
import '../models/finance_model.dart';
import 'finance_page.dart';

// ============= ثوابت الألوان الموحدة =============
class DashboardColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color skyBlue = Color(0xFF4FC3F7);
  static const Color cyan = Color(0xFF26C6DA);
  static const Color teal = Color(0xFF26A69A);
  static const Color green = Color(0xFF66BB6A);
  static const Color lightGreen = Color(0xFF9CCC65);
  static const Color orange = Color(0xFFFFA726);
  static const Color deepOrange = Color(0xFFEF6C00);
  static const Color red = Color(0xFFEF5350);
  static const Color purple = Color(0xFF7E57C2);
  static const Color indigo = Color(0xFF5C6BC0);
  static const Color blueGrey = Color(0xFF78909C);

  static const List<Color> chartColors = [
    primaryBlue,
    teal,
    orange,
    purple,
    green,
    cyan,
    indigo,
    deepOrange,
    red,
  ];
}

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  final DashboardController controller = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,  // خلفية بيضاء مثل FinancePage
      body: Obx(() {
        if (controller.isLoading.value && !controller.isRefreshing.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(DashboardColors.primaryBlue),
                ),
                const SizedBox(height: 16),
                Text(
                  'جاري تحميل لوحة التحكم...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          color: DashboardColors.primaryBlue,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16), // نفس padding في FinancePage
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== HEADER SECTION ==========
                _buildHeader(),
                const SizedBox(height: 12),

                // ========== QUICK STATS CARDS ==========
                _buildQuickStats(),
                const SizedBox(height: 20),
                // ========== FINANCIAL HEALTH ==========
                _buildFinancialHealth(),
                const SizedBox(height: 20),
                // ========== MAIN CHARTS ROW ==========
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      // عرض عمودي للشاشات الصغيرة
                      return Column(
                        children: [
                          _buildSalesChart(),
                          const SizedBox(height: 20),
                          _buildExpensesPieChart(),
                        ],
                      );
                    } else {
                      // عرض أفقي للشاشات الكبيرة
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _buildSalesChart()),
                          const SizedBox(width: 20),
                          Expanded(flex: 3, child: _buildExpensesPieChart()),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                // ========== ALERTS AND TOP PRODUCTS ==========
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: [
                          _buildAlertsSection(),
                          const SizedBox(height: 20),
                          _buildTopProductsSection(),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildAlertsSection()),
                          const SizedBox(width: 20),
                          Expanded(flex: 5, child: _buildTopProductsSection()),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),


              ],
            ),
          ),
        );
      }),
    );
  }

// ========== Header with Pharmacy Info and Time Range ==========
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.primaryBlue,
            DashboardColors.lightBlue,
            DashboardColors.skyBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primaryBlue.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // للشاشات الصغيرة (أقل من 800)
          if (constraints.maxWidth < 800) {
            return Column(
              children: [
                // الصف العلوي: معلومات الصيدلية والأزرار الرئيسية
                Row(
                  children: [
                    // أيقونة الصيدلية
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Iconsax.hospital,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // اسم الصيدلية والعنوان
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.pharmacyName.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.formattedAddress,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // زر التحديث للشاشات الصغيرة - بدون خلفية
                    IconButton(
                      onPressed: controller.refreshDashboard,
                      icon: controller.isRefreshing.value
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'تحديث',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // الصف السفلي: الفترات الزمنية
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButton<DashboardTimeRange>(
                        value: controller.selectedTimeRange.value,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: [
                          DropdownMenuItem(
                            value: DashboardTimeRange.week,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Iconsax.calendar_1, size: 16),
                                SizedBox(width: 8),
                                Text('أسبوع'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: DashboardTimeRange.month,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Iconsax.calendar_2, size: 16),
                                SizedBox(width: 8),
                                Text('شهر'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: DashboardTimeRange.year,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Iconsax.calendar, size: 16),
                                SizedBox(width: 8),
                                Text('سنة'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (range) {
                          if (range != null) {
                            controller.changeTimeRange(range);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // للشاشات الكبيرة
          return Row(
            children: [
              // أيقونة الصيدلية
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.hospital,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // اسم الصيدلية والعنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.pharmacyName.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.formattedAddress,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Dropdown للفترات الزمنية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButton<DashboardTimeRange>(
                  value: controller.selectedTimeRange.value,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: [
                    DropdownMenuItem(
                      value: DashboardTimeRange.week,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.calendar_1, size: 16),
                          SizedBox(width: 8),
                          Text('أسبوع'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: DashboardTimeRange.month,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.calendar_2, size: 16),
                          SizedBox(width: 8),
                          Text('شهر'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: DashboardTimeRange.year,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.calendar, size: 16),
                          SizedBox(width: 8),
                          Text('سنة'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (range) {
                    if (range != null) {
                      controller.changeTimeRange(range);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              // زر إضافي - بدون تغيير
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {
                    // أضف الوظيفة المناسبة هنا
                  },
                  icon: const Icon(
                    Iconsax.setting_2,
                    color: Color(0xFF1565C0),
                  ),
                  tooltip: 'إعدادات إضافية',
                ),
              ),
              const SizedBox(width: 10),

              IconButton(
                onPressed: controller.refreshDashboard,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade700,
                ),
                icon: controller.isRefreshing.value
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'تحديث',
                constraints: const BoxConstraints(),
              ),
            ],
          );
        },
      ),
    );
  }
  // نسخة مخصصة من TimeRangeChip للهيدر (بألوان بيضاء)
  Widget _buildQuickStats() {
    return _CompactPanel(
      title: 'المبيعات',
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1200 ? 5 :
          constraints.maxWidth > 800 ? 4 :
          constraints.maxWidth > 500 ? 3 : 2;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5, // نسبة عرض إلى ارتفاع مناسبة للبطاقات الأفقية
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _buildStatCard(
                    title: 'مبيعات اليوم',
                    value: controller.todaySales.value,
                    icon: Iconsax.money_recive,
                    color: DashboardColors.primaryBlue,
                    format: true,
                  );
                case 1:
                  return _buildStatCard(
                    title: 'أرباح اليوم',
                    value: controller.todayProfit.value,
                    icon: Iconsax.chart,
                    color: DashboardColors.green,
                    format: true,
                  );
                case 2:
                  return _buildStatCard(
                    title: 'مصروفات اليوم',
                    value: controller.todayExpenses.value,
                    icon: Iconsax.money_send,
                    color: DashboardColors.red,
                    format: true,
                  );
                case 3:
                  return _buildStatCard(
                    title: 'معاملات اليوم',
                    value: controller.todayTransactions.value.toDouble(),
                    icon: Iconsax.receipt,
                    color: DashboardColors.purple,
                    format: false,
                  );
                case 4:
                  return _buildStatCard(
                    title: 'الكاش المتوفر',
                    value: controller.cashInHand.value,
                    icon: Iconsax.wallet,
                    color: DashboardColors.orange,
                    format: true,
                  );
                case 5:
                  return _buildStatCard(
                    title: 'مبيعات الشهر',
                    value: controller.monthSales.value,
                    icon: Iconsax.money_recive,
                    color: DashboardColors.indigo,
                    format: true,
                  );
                case 6:
                  return _buildStatCard(
                    title: 'أرباح الشهر',
                    value: controller.monthProfit.value,
                    icon: Iconsax.chart,
                    color: DashboardColors.teal,
                    format: true,
                  );
                case 7:
                  return _buildStatCard(
                    title: 'مخزون منخفض',
                    value: controller.lowStockCount.value.toDouble(),
                    icon: Iconsax.danger,
                    color: DashboardColors.deepOrange,
                    format: false,
                  );
                case 8:
                  return _buildStatCard(
                    title: 'منتهي الصلاحية',
                    value: controller.expiredCount.value.toDouble(),
                    icon: Iconsax.timer,
                    color: DashboardColors.red,
                    format: false,
                  );
                case 9:
                  return _buildStatCard(
                    title: 'موظفين نشطين',
                    value: controller.activeEmployees.value.toDouble(),
                    icon: Iconsax.people,
                    color: DashboardColors.cyan,
                    format: false,
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required bool format,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primaryBlue.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // أيقونة بحجم متوسط
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          // النصوص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,

                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
                Text(
                  format
                      ? NumberFormat.currency(symbol: 'د.ل ').format(value)
                      : value.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== Financial Health ==========
  Widget _buildFinancialHealth() {
    return _CompactPanel(
      title: 'المؤشرات المالية',
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFinancialMetric(
                      title: 'المبيعات السنوية',
                      value: controller.yearSales.value,
                      icon: Iconsax.money_recive,
                      color: DashboardColors.primaryBlue,
                      subtitle: '${((controller.yearSales.value / controller.yearExpenses.value) * 100).toStringAsFixed(1)}% من المصروفات',
                    ),
                    _buildFinancialMetric(
                      title: 'المصروفات السنوية',
                      value: controller.yearExpenses.value,
                      icon: Iconsax.money_send,
                      color: DashboardColors.red,
                      subtitle: '${((controller.yearExpenses.value / controller.yearSales.value) * 100).toStringAsFixed(1)}% من المبيعات',
                    ),
                    _buildFinancialMetric(
                      title: 'الأرباح السنوية',
                      value: controller.yearProfit.value,
                      icon: Iconsax.chart,
                      color: DashboardColors.green,
                      subtitle: 'هامش الربح: ${controller.profitMargin.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFinancialMetric(
                      title: 'المستحقات (ذمم مدينة)',
                      value: controller.receivablesTotal.value,
                      icon: Iconsax.receipt,
                      color: DashboardColors.orange,
                      subtitle: 'مستحق على العملاء',
                    ),
                    _buildFinancialMetric(
                      title: 'المطلوبات (ذمم دائنة)',
                      value: controller.payablesTotal.value,
                      icon: Iconsax.bill,
                      color: DashboardColors.deepOrange,
                      subtitle: 'مستحق للموردين',
                    ),
                    _buildFinancialMetric(
                      title: 'صافي التدفق النقدي',
                      value: controller.netCashFlow.value,
                      icon: Iconsax.money_change,
                      color: controller.netCashFlow.value >= 0 ? DashboardColors.green : DashboardColors.red,
                      subtitle: controller.netCashFlow.value >= 0 ? 'إيجابي' : 'سلبي',
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    title: 'المبيعات السنوية',
                    value: controller.yearSales.value,
                    icon: Iconsax.money_recive,
                    color: DashboardColors.primaryBlue,
                    subtitle: '${((controller.yearSales.value / controller.yearExpenses.value) * 100).toStringAsFixed(1)}% من المصروفات',
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    title: 'المصروفات السنوية',
                    value: controller.yearExpenses.value,
                    icon: Iconsax.money_send,
                    color: DashboardColors.red,
                    subtitle: '${((controller.yearExpenses.value / controller.yearSales.value) * 100).toStringAsFixed(1)}% من المبيعات',
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    title: 'الأرباح السنوية',
                    value: controller.yearProfit.value,
                    icon: Iconsax.chart,
                    color: DashboardColors.green,
                    subtitle: 'هامش الربح: ${controller.profitMargin.toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    title: 'المستحقات (ذمم مدينة)',
                    value: controller.receivablesTotal.value,
                    icon: Iconsax.receipt,
                    color: DashboardColors.orange,
                    subtitle: 'مستحق على العملاء',
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    title: 'المطلوبات (ذمم دائنة)',
                    value: controller.payablesTotal.value,
                    icon: Iconsax.bill,
                    color: DashboardColors.deepOrange,
                    subtitle: 'مستحق للموردين',
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    title: 'صافي التدفق النقدي',
                    value: controller.netCashFlow.value,
                    icon: Iconsax.money_change,
                    color: controller.netCashFlow.value >= 0 ? DashboardColors.green : DashboardColors.red,
                    subtitle: controller.netCashFlow.value >= 0 ? 'إيجابي' : 'سلبي',
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }  // ========== Sales Chart ==========


  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.primaryBlue.withOpacity(0.04),
            Colors.white,
            DashboardColors.primaryBlue.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primaryBlue.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.chart_2, color: DashboardColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'تحليل المبيعات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildLegendItem('المبيعات', DashboardColors.primaryBlue),
              const SizedBox(width: 12),
              _buildLegendItem('المصروفات', DashboardColors.red),
              const SizedBox(width: 12),
              _buildLegendItem('الأرباح', DashboardColors.green),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: controller.salesTrend.isEmpty
                ? Center(
              child: Text(
                'لا توجد بيانات كافية',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < controller.salesTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              controller.salesTrend[index].label,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: DashboardColors.primaryBlue.withOpacity(0.3)),
                    bottom: BorderSide(color: DashboardColors.primaryBlue.withOpacity(0.3)),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                lineBarsData: [
                  _buildLineChartBar(
                    data: controller.salesTrend.map((e) => e.value).toList(),
                    color: DashboardColors.primaryBlue,
                    gradientColors: [DashboardColors.primaryBlue, DashboardColors.lightBlue],
                  ),
                  _buildLineChartBar(
                    data: controller.profitTrend.map((e) => e.value).toList(),
                    color: DashboardColors.green,
                    gradientColors: [DashboardColors.green, DashboardColors.lightGreen],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBar({
    required List<double> data,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
            (i) => FlSpot(i.toDouble(), data[i]),
      ),
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ========== Expenses Pie Chart ==========
// ========== Expenses Pie Chart ==========
// ========== Expenses Pie Chart - نسخة تستخدم الكود الأصلي ==========
  Widget _buildExpensesPieChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.orange.withOpacity(0.04),
            Colors.white,
            DashboardColors.orange.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.orange.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.chart_21, color: DashboardColors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'توزيع المصروفات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pie Chart - استخدام الكود الأصلي مباشرة
          SizedBox(
            height: 200,
            child: controller.topExpenses.isEmpty
                ? Center(
              child: Text(
                'لا توجد مصروفات',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
                : PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(
                  controller.topExpenses.length,
                      (i) {
                    final expense = controller.topExpenses[i];

                    // استخراج البيانات بأمان
                    String category;
                    double amount;

                    try {
                      category = expense.category?.toString() ?? 'مصروف ${i + 1}';
                    } catch (e) {
                      category = 'مصروف ${i + 1}';
                    }

                    try {
                      amount = (expense.amount is num)
                          ? (expense.amount as num).toDouble()
                          : double.tryParse(expense.amount?.toString() ?? '0') ?? 100;
                    } catch (e) {
                      amount = 100.0;
                    }

                    final color = DashboardColors.chartColors[i % DashboardColors.chartColors.length];

                    return PieChartSectionData(
                      value: amount,
                      title: category,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: color,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Legend/List of expenses
          ...controller.topExpenses.take(5).map((expense) {
            String category;
            double amount;

            try {
              category = expense.category?.toString() ?? 'غير معروف';
            } catch (e) {
              category = 'مصروف';
            }

            try {
              amount = (expense.amount is num)
                  ? (expense.amount as num).toDouble()
                  : double.tryParse(expense.amount?.toString() ?? '0') ?? 0;
            } catch (e) {
              amount = 0;
            }

            final color = _getCategoryColor(category);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: 'د.ل ').format(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (controller.topExpenses.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+ ${controller.topExpenses.length - 5} مصروفات أخرى',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'إيجار':
        return DashboardColors.indigo;
      case 'رواتب':
        return DashboardColors.primaryBlue;
      case 'فواتير':
        return DashboardColors.orange;
      case 'صيانة':
        return DashboardColors.purple;
      case 'تسويق':
        return DashboardColors.deepOrange;
      case 'مشتريات':
        return DashboardColors.teal;
      default:
        return DashboardColors.cyan;
    }
  }

  // ========== Alerts Section ==========
  Widget _buildAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.red.withOpacity(0.04),
            Colors.white,
            DashboardColors.red.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.red.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.notification, color: DashboardColors.red, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'التنبيهات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DashboardColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.lowStockAlerts.length + controller.duePayments.length} تنبيه',
                  style: TextStyle(
                    color: DashboardColors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Low Stock Alerts
          if (controller.lowStockAlerts.isNotEmpty) ...[
            const Text(
              'مخزون منخفض',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DashboardColors.orange,
              ),
            ),
            const SizedBox(height: 10),
            ...controller.lowStockAlerts.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alert.isCritical ? DashboardColors.red.withOpacity(0.05) : DashboardColors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: alert.isCritical ? DashboardColors.red.withOpacity(0.3) : DashboardColors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (alert.isCritical ? DashboardColors.red : DashboardColors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      alert.isCritical ? Iconsax.danger : Iconsax.warning_2,
                      color: alert.isCritical ? DashboardColors.red : DashboardColors.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.medicineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'المتبقي: ${alert.currentStock} | الحد الأدنى: ${alert.minLevel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: alert.isCritical ? DashboardColors.red : DashboardColors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alert.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 16),

          // Due Payments Alerts
          if (controller.duePayments.isNotEmpty) ...[
            const Text(
              'مدفوعات مستحقة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DashboardColors.red,
              ),
            ),
            const SizedBox(height: 10),
            ...controller.duePayments.map((payment) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: payment.isOverdue ? DashboardColors.red.withOpacity(0.05) : DashboardColors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: payment.isOverdue ? DashboardColors.red.withOpacity(0.3) : DashboardColors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (payment.isOverdue ? DashboardColors.red : DashboardColors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      payment.isOverdue ? Iconsax.timer : Iconsax.calendar,
                      color: payment.isOverdue ? DashboardColors.red : DashboardColors.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فاتورة ${payment.invoiceNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          payment.supplierName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: 'د.ل ').format(payment.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        payment.isOverdue
                            ? 'متأخرة ${-payment.daysRemaining} يوم'
                            : 'متبقي ${payment.daysRemaining} يوم',
                        style: TextStyle(
                          fontSize: 11,
                          color: payment.isOverdue ? DashboardColors.red : DashboardColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],

          if (controller.lowStockAlerts.isEmpty && controller.duePayments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: DashboardColors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.tick_circle,
                        size: 40,
                        color: DashboardColors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد تنبيهات',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========== Top Products Section ==========
  Widget _buildTopProductsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.green.withOpacity(0.04),
            Colors.white,
            DashboardColors.green.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.green.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.box, color: DashboardColors.green, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'الأكثر مبيعاً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...controller.topSellingProducts.take(7).map((product) {
            final index = controller.topSellingProducts.indexOf(product);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DashboardColors.green,
                          DashboardColors.lightGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${product.quantity} وحدة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DashboardColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      NumberFormat.currency(symbol: 'د.ل ').format(product.revenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: DashboardColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (controller.topSellingProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'لا توجد مبيعات كافية',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildFinancialMetric({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            NumberFormat.currency(symbol: 'د.ل ').format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}


// إضافة كلاس CompactPanel داخل نفس الملف
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
