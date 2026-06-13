import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pharmacy_desktop/views/purchases/widgets/purchase_invoice_dialog.dart';

import '../../controllers/purchase_controller.dart';
import '../../models/purchase_model.dart';

class PurchasesPage extends StatelessWidget {
  PurchasesPage({super.key});

  final PurchaseController controller = Get.find<PurchaseController>();

  static const Color _primary = Color(0xFF1D4ED8);
  static const Color _primaryLight = Color(0xFF3B82F6);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  String _currency(num value) => '${value.toStringAsFixed(2)} د.ل';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Obx(() {
        final stats = controller.getStats();
        final report = controller.getQuickReport();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (stats.isEmpty || report.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // تصنيف الشاشات حسب العرض
            if (width >= 1400) {
              return _buildDesktopLayout(stats, report, isExtraWide: true);
            } else if (width >= 1100) {
              return _buildDesktopLayout(stats, report, isExtraWide: false);
            } else if (width >= 700) {
              return _buildTabletLayout(stats, report);
            } else {
              return _buildMobileLayout(stats, report);
            }
          },
        );
      }),
    );
  }

  // ==================== LAYOUTS الرئيسية ====================

  // تصميم سطح المكتب (1100+)
  Widget _buildDesktopLayout(Map<String, dynamic> stats, Map<String, dynamic> report, {required bool isExtraWide}) {
    final double spacing = isExtraWide ? 20 : 16;
    final int rightColumnWidth = isExtraWide ? 3 : 4;

    return Padding(
      padding: EdgeInsets.all(isExtraWide ? 20 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العمود الرئيسي (70-75%)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildTopHeader(),
                SizedBox(height: spacing),
                _buildStatsRow(stats, columns: 4),
                SizedBox(height: spacing),
                _buildSearchAndFilters(),
                SizedBox(height: spacing),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الفواتير (70%)
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            Expanded(child: _buildInvoicesSection()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing),
          // العمود الجانبي (25-30%)
          Expanded(
            flex: rightColumnWidth,
            child: _buildSidebar(report),
          ),
        ],
      ),
    );
  }

  // تصميم التابلت (700-1100) - معدل ليصبح عمودي مع تمرير
  Widget _buildTabletLayout(Map<String, dynamic> stats, Map<String, dynamic> report) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        slivers: [
          // الهيدر
          SliverToBoxAdapter(
            child: _buildTopHeader(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // الإحصائيات
          SliverToBoxAdapter(
            child: _buildStatsRow(stats, columns: 2),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // البحث والتصفية
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // الملخص الشهري
          SliverToBoxAdapter(
            child: _buildMonthlySummaryCard(report),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // التوصيات
          SliverToBoxAdapter(
            child: _buildAlertsCard(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // الفواتير (تأخذ المساحة المتبقية)
          SliverFillRemaining(
            hasScrollBody: true,
            child: _buildInvoicesSection(),
          ),
        ],
      ),
    );
  }

  // تصميم الموبايل (أقل من 700) - معدل باستخدام CustomScrollView
  Widget _buildMobileLayout(Map<String, dynamic> stats, Map<String, dynamic> report) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildTopHeader(),
              const SizedBox(height: 12),
              _buildStatsRow(stats, columns: 1),
              const SizedBox(height: 12),
              _buildSearchAndFilters(),
              const SizedBox(height: 12),
              _buildMonthlySummaryCard(report),
              const SizedBox(height: 12),
              _buildAlertsCard(),
              const SizedBox(height: 12),
              Container(
                height: 500,
                decoration: _cardDecoration(),
                child: _buildInvoicesSection(),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== المكونات الرئيسية ====================

  Widget _buildSidebar(Map<String, dynamic> report) {
    return Column(
      children: [
        _buildMonthlySummaryCard(report),
        const SizedBox(height: 16),
        Expanded(
          child: _buildAlertsCard(),
        ),
      ],
    );
  }

  // ==================== البطاقات المتنوعة ====================

  // بطاقة الملخص الشهري
  Widget _buildMonthlySummaryCard(Map<String, dynamic> report) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryLight, _primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص الشهر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currency(report['thisMonth'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      (report['trend'] == 'up') ? Iconsax.arrow_up : Iconsax.arrow_down,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(report['change'] ?? 0).toStringAsFixed(1)}% عن الشهر الماضي',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryTile(
                  icon: Iconsax.money_send,
                  title: 'إجمالي المستحق',
                  value: _currency(report['totalDue'] ?? 0),
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 10),
                _summaryTile(
                  icon: Iconsax.truck,
                  title: 'أكثر مورد تعاملاً',
                  value: '${report['topSupplier'] ?? 'لا يوجد'}',
                  color: const Color(0xFF2563EB),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    _buildMiniStat(
                      'مدفوعة',
                      '${report['paidInvoices'] ?? 0}',
                      Iconsax.tick_circle,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      'غير مكتملة',
                      '${report['unpaidInvoices'] ?? 0}',
                      Iconsax.close_circle,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== باقي المكونات (بدون تغيير) ====================

  Widget _buildStatsRow(Map<String, dynamic> stats, {required int columns}) {
    final items = [
      _StatData(
        title: 'مشتريات الشهر',
        value: _currency(stats['totalPurchasesMonth'] ?? 0),
        icon: Iconsax.wallet_3,
        color: const Color(0xFF2563EB),
      ),
      _StatData(
        title: 'مستحق للموردين',
        value: _currency(stats['totalDue'] ?? 0),
        icon: Iconsax.money_send,
        color: const Color(0xFFF59E0B),
      ),
      _StatData(
        title: 'عدد الفواتير',
        value: '${stats['invoicesCount'] ?? 0}',
        icon: Iconsax.receipt_1,
        color: const Color(0xFF0EA5E9),
      ),
      _StatData(
        title: 'عدد الموردين',
        value: '${stats['suppliersCount'] ?? 0}',
        icon: Iconsax.truck_fast,
        color: const Color(0xFF10B981),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 1 ? 16/7 : 16/9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildStatCard(items[index]),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryLight, _primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.shopping_bag, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة المشتريات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'فواتير الموردين • الدفعات • التوريد • التنبيهات',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _headerActionButton(
                icon: Iconsax.add_circle,
                label: 'فاتورة جديدة',
                filled: true,
                onTap: () {
                  Get.dialog(
                    PurchaseInvoiceDialog(
                      controller: controller,
                    ),
                    barrierDismissible: false,
                  );
                },
              ),
              _headerActionButton(
                icon: Iconsax.refresh,
                label: 'تحديث',
                filled: false,
                onTap: controller.loadInvoices,
              ),
            ],
          ),        ],
      ),
    );
  }

  Widget _headerActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? _primary : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? _primary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.search_normal, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'البحث والتصفية',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
              Obx(() {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.filteredInvoices.length} نتيجة',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildStatusFilterDropdown(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: _buildSearchField()),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: _buildStatusFilterDropdown()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: controller.search,
      decoration: InputDecoration(
        hintText: 'ابحث برقم الفاتورة أو المورد...',
        prefixIcon: const Icon(Iconsax.search_normal_1),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildStatusFilterDropdown() {
    return Obx(() {
      return DropdownButtonFormField<PaymentStatus?>(
        value: controller.paymentFilter.value,
        items: [
          const DropdownMenuItem<PaymentStatus?>(
            value: null,
            child: Text('كل الحالات'),
          ),
          ...PaymentStatus.values.map(
                (status) => DropdownMenuItem<PaymentStatus?>(
              value: status,
              child: Text(_paymentStatusText(status)),
            ),
          ),
        ],
        onChanged: controller.filterByPaymentStatus,
        decoration: InputDecoration(
          prefixIcon: const Icon(Iconsax.filter),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.2),
          ),
        ),
      );
    });
  }

  Widget _buildAlertsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.notification_bing, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'التنبيهات ',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
              Obx(() {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.purchaseAlerts.length} تنبيه',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (controller.purchaseAlerts.isEmpty) {
              return _buildEmptyState(
                icon: Iconsax.tick_circle,
                title: 'لا توجد تنبيهات حالياً',
                subtitle: 'كل شيء تحت السيطرة في قسم المشتريات.',
                compact: true,
              );
            }

            final alerts = controller.purchaseAlerts.take(3).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: alerts.map((alert) {
                final Color accent = _alertColor(alert['type']?.toString());
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.20)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Iconsax.info_circle, color: accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${alert['title'] ?? ''}',
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${alert['message'] ?? ''}',
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
          if (controller.purchaseAlerts.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // عرض كل التنبيهات في Dialog
                  },
                  child: Text(
                    '+ عرض ${controller.purchaseAlerts.length - 3} تنبيهات أخرى',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoicesSection() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.receipt_2, color: _primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'فواتير المشتريات',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Obx(() {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.filteredInvoices.length} فاتورة',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredInvoices.isEmpty) {
                return _buildEmptyState(
                  icon: Iconsax.document_text,
                  title: 'لا توجد فواتير حالياً',
                  subtitle: 'ابدأ بإنشاء فاتورة مشتريات جديدة أو غيّر الفلاتر.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: controller.filteredInvoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final invoice = controller.filteredInvoices[index];
                  return _buildInvoiceCard(invoice);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(PurchaseInvoice invoice) {
    final statusColor = _paymentStatusColor(invoice.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.receipt_item, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invoice.supplierName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(invoice.paymentStatus),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _miniInfo('الإجمالي', _currency(invoice.total), Iconsax.money_4)),
                        const SizedBox(width: 8),
                        Expanded(child: _miniInfo('المدفوع', _currency(invoice.paid), Iconsax.wallet_add)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _miniInfo('المتبقي', _currency(invoice.remaining), Iconsax.money_send)),
                        const SizedBox(width: 8),
                        Expanded(child: _miniInfo('التاريخ', _formatDate(invoice.invoiceDate), Iconsax.calendar)),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _miniInfo('الإجمالي', _currency(invoice.total), Iconsax.money_4)),
                  const SizedBox(width: 10),
                  Expanded(child: _miniInfo('المدفوع', _currency(invoice.paid), Iconsax.wallet_add)),
                  const SizedBox(width: 10),
                  Expanded(child: _miniInfo('المتبقي', _currency(invoice.remaining), Iconsax.money_send)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.dialog(_PurchaseInvoiceDetailsDialog(invoice: invoice));
                  },
                  icon: const Icon(Iconsax.eye, size: 16),
                  label: const Text('عرض'),
                  style: _outlinedBtnStyle(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  // في _buildInvoiceCard - تعديل onPressed

                  onPressed: invoice.remaining <= 0
                      ? null
                      : () {
                    Get.dialog(_MakePaymentDialog(
                      invoice: invoice,
                      onSubmit: (amount, paymentMethod) =>
                          controller.makePayment(invoice.id, amount, paymentMethod), // تعديل هنا
                    ));
                  },
                  icon: const Icon(Iconsax.wallet_add_1, size: 16),
                  label: const Text('تسديد'),
                  style: _filledBtnStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 12.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSummaryTile(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 12.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(PaymentStatus status) {
    final color = _paymentStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        _paymentStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 42 : 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  ButtonStyle _outlinedBtnStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _primary,
      side: const BorderSide(color: Color(0xFFD1D5DB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  ButtonStyle _filledBtnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  String _paymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'غير مدفوع';
      case PaymentStatus.partiallyPaid:
        return 'مدفوع جزئياً';
      case PaymentStatus.paid:
        return 'مدفوع بالكامل';
    }
  }

  Color _paymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return const Color(0xFFEF4444);
      case PaymentStatus.partiallyPaid:
        return const Color(0xFFF59E0B);
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
    }
  }

  Color _alertColor(String? type) {
    switch (type) {
      case 'danger':
        return const Color(0xFFEF4444);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'info':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

// الكلاسات المساعدة كما هي بدون تغيير
// في نهاية ملف PurchasesPage.dart - تحديث _MakePaymentDialog

class _MakePaymentDialog extends StatefulWidget {
  final PurchaseInvoice invoice;
  final Future<void> Function(double amount, String paymentMethod) onSubmit; // تعديل هنا

  const _MakePaymentDialog({
    required this.invoice,
    required this.onSubmit,
  });

  @override
  State<_MakePaymentDialog> createState() => _MakePaymentDialogState();
}

class _MakePaymentDialogState extends State<_MakePaymentDialog> {
  final TextEditingController amountCtrl = TextEditingController();
  String selectedPaymentMethod = 'نقدي'; // القيمة الافتراضية
  bool loading = false;

  final List<String> paymentMethods = ['نقدي', 'معاملة مصرفية', ];

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.invoice.remaining;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('تسجيل دفعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المتبقي على الفاتورة: ${remaining.toStringAsFixed(2)} د.ل',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'قيمة الدفعة',
              prefixIcon: const Icon(Iconsax.money_send),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: 'طريقة الدفع',
              prefixIcon: const Icon(Iconsax.wallet),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: paymentMethods.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedPaymentMethod = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Get.back(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: loading
              ? null
              : () async {
            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (amount <= 0) {
              Get.snackbar('تنبيه', 'أدخل مبلغ صحيح');
              return;
            }
            if (amount > remaining) {
              Get.snackbar('تنبيه', 'المبلغ أكبر من المتبقي');
              return;
            }

            setState(() => loading = true);
            // تمرير طريقة الدفع مع المبلغ
            await widget.onSubmit(amount, selectedPaymentMethod);
            if (mounted) {
              setState(() => loading = false);
              Get.back();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
          ),
          child: loading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

class _PurchaseInvoiceDetailsDialog extends StatelessWidget {
  final PurchaseInvoice invoice;

  const _PurchaseInvoiceDetailsDialog({required this.invoice});

  String _currency(num value) => '${value.toStringAsFixed(2)} د.ل';

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _statusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'غير مدفوع';
      case PaymentStatus.partiallyPaid:
        return 'مدفوع جزئياً';
      case PaymentStatus.paid:
        return 'مدفوع بالكامل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 760,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Iconsax.receipt_2_1, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تفاصيل الفاتورة ${invoice.invoiceNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _detailItem('المورد', invoice.supplierName)),
                      Expanded(child: _detailItem('الحالة', _statusText(invoice.paymentStatus))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _detailItem('تاريخ الفاتورة', _formatDate(invoice.invoiceDate))),
                      Expanded(child: _detailItem('تاريخ الاستلام', _formatDate(invoice.receivedDate))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _detailItem('الإجمالي', _currency(invoice.total))),
                      Expanded(child: _detailItem('المدفوع', _currency(invoice.paid))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _detailItem('الخصم', _currency(invoice.discount))),
                      Expanded(child: _detailItem('المتبقي', _currency(invoice.remaining))),
                    ],
                  ),
                  if ((invoice.referenceNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _detailItem('مرجع المورد', invoice.referenceNumber!)),
                        Expanded(child: _detailItem('تاريخ الاستحقاق', _formatDate(invoice.dueDate))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الأصناف',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: invoice.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = invoice.items[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      item.medicineName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'الكمية: ${item.quantity} • السعر: ${_currency(item.price)}'
                          '${item.batchNumber != null ? ' • التشغيلة: ${item.batchNumber}' : ''}',
                    ),
                    trailing: Text(
                      _currency(item.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  );
                },
              ),
            ),
            if ((invoice.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'ملاحظات: ${invoice.notes}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _detailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}