import 'dart:convert';
import 'dart:io';
import '../../../services/receipt_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/employee_controller.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/insurance_company_model.dart';
import '../../../models/sales_model.dart';

enum HistoryMode { today, all, range }

class SalesHistoryDialog extends StatefulWidget {
  final void Function(Sale sale) onOpenInvoice;

  const SalesHistoryDialog({
    super.key,
    required this.onOpenInvoice,
  });

  @override
  State<SalesHistoryDialog> createState() => _SalesHistoryDialogState();
}

class _SalesHistoryDialogState extends State<SalesHistoryDialog> {
  // ✅ Permissions (متوافقة مع DefaultPermissions اللي عطيتني)
  static const String pViewHistory = 'sales.view_history';
  static const String pDelete = 'sales.delete';
  static const String pEmployeesView = 'employees.view';

  final SalesController salesController = Get.find<SalesController>();
  final AuthController auth = Get.find<AuthController>();

  late final EmployeeController employeeController;

  // ===== Rx filters =====
  final Rx<HistoryMode> mode = HistoryMode.today.obs;
  final Rxn<DateTimeRange> range = Rxn<DateTimeRange>();

  final RxString query = ''.obs;
  final Rxn<InvoiceStatus> status = Rxn<InvoiceStatus>(); // null = all
  final Rxn<PaymentMethod> pay = Rxn<PaymentMethod>(); // null = all
  final Rxn<String> employeeIdFilter = Rxn<String>(); // owner only
  final Rxn<String> insuranceCompanyId = Rxn<String>(); // when insurance selected

  final _fmt = DateFormat('yyyy-MM-dd  HH:mm');
  final _money = NumberFormat('#,##0.00');

  Future<void> _previewInvoicePdf(Sale inv) async {
    final pharmacyData = auth.pharmacyData;

    await ReceiptService.previewReceipt(
      context: context,
      sale: inv,
      pharmacyName: pharmacyData['pharmacyName']?.toString() ?? 'الصيدلية',
      pharmacyPhone: pharmacyData['phone']?.toString() ?? '',
      pharmacyAddress: pharmacyData['address']?.toString() ?? '',
      cashierName: inv.employeeName ?? auth.userName,
    );
  }

  Future<void> _printInvoiceDirect(Sale inv) async {
    final pharmacyData = auth.pharmacyData;

    await ReceiptService.printReceipt(
      sale: inv,
      pharmacyName: pharmacyData['pharmacyName']?.toString() ?? 'الصيدلية',
      pharmacyPhone: pharmacyData['phone']?.toString() ?? '',
      pharmacyAddress: pharmacyData['address']?.toString() ?? '',
      cashierName: inv.employeeName ?? auth.userName,
    );
  }

  bool get isOwner => auth.actorInfo['type'] == 'owner';

  bool get canView => auth.can(pViewHistory);
  bool get canOpen => auth.can(pViewHistory) || auth.can('sales.view');
  bool get canDelete => auth.can(pDelete);
  bool get canExport => auth.can(pViewHistory); // لو تبي صلاحية مستقلة نقسمها
  bool get canFilterEmployee => isOwner && auth.can(pEmployeesView);

  @override
  void initState() {
    super.initState();

    employeeController = Get.isRegistered<EmployeeController>()
        ? Get.find<EmployeeController>()
        : Get.put(EmployeeController(), permanent: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!canView) {
        Get.snackbar('صلاحيات', 'ليس لديك صلاحية لعرض تاريخ الفواتير');
        Get.back();
        return;
      }

      await salesController.initializeEmployeeData();

      // ✅ تأكد من تحميل البيانات
      await salesController.ensureHistoryLoaded();
      await _reloadAccordingToMode();

    });
  }
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Future<void> _reloadAccordingToMode() async {
    final m = mode.value;

    if (m == HistoryMode.today) {
      final now = DateTime.now();
      final start = _startOfDay(now);
      final end = _endOfDay(now);

      if (isOwner) {
        await salesController.loadHistoryByRange(
          start: start,
          end: end,
          employeeId: employeeIdFilter.value, // null = كل الموظفين
          includeLocalPending: false,
        );
      } else {
        await salesController.loadMyHistoryToday(includeLocalPending: true);
      }
      return;
    }

    if (m == HistoryMode.all) {
      if (isOwner) {
        await salesController.loadHistoryAllForOwner(
          employeeId: employeeIdFilter.value,
        );
      } else {
        await salesController.loadMyHistoryAll();
      }
      return;
    }

    if (m == HistoryMode.range) {
      final r = range.value;
      if (r == null) return;

      final start = _startOfDay(r.start);
      final end = _endOfDay(r.end);

      if (isOwner) {
        await salesController.loadHistoryByRange(
          start: start,
          end: end,
          employeeId: employeeIdFilter.value,
          includeLocalPending: false,
        );
      } else {
        // للموظف: نخليها من Firebase (لو تبي نديرها للموظف أيضاً قولي)
        await salesController.loadHistoryByRange(
          start: start,
          end: end,
          employeeId: null,
          includeLocalPending: false,
        );
      }
    }
  }

  _FilteredData _computeFiltered() {
    final all = salesController.historyInvoices;

    final q = query.value.trim();
    final st = status.value;
    final pm = pay.value;
    final insId = insuranceCompanyId.value;

    final list = all.where((inv) {
      if (st != null && inv.status != st) return false;

      final hasInsurance = (inv.insuranceDiscount ?? 0) > 0 &&
          (inv.insuranceCompanyId ?? '').trim().isNotEmpty;

      if (pm == PaymentMethod.cash) {
        if (inv.type == SaleType.refund) {
          if (inv.cashOut <= 0) return false;
        } else {
          if (inv.customerPaymentMethod != PaymentMethod.cash) return false;
        }
      }

      if (pm == PaymentMethod.card) {
        if (inv.type == SaleType.refund) {
          if (inv.cardOut <= 0) return false;
        } else {
          if (inv.customerPaymentMethod != PaymentMethod.card) return false;
        }
      }

      if (pm == PaymentMethod.insurance) {
        if (!hasInsurance) return false;
        if (insId != null && (inv.insuranceCompanyId ?? '') != insId) {
          return false;
        }
      }

      if (q.isEmpty) return true;

      final invNo = inv.invoiceNumber.toString();
      final cust = inv.customerName ?? '';
      final itemsText = inv.items.map((e) => e.name).join(' ');
      final empName = inv.employeeName ?? '';

      return invNo.contains(q) ||
          cust.contains(q) ||
          itemsText.contains(q) ||
          empName.contains(q);
    }).toList();

    double cash = 0;
    double card = 0;
    double insurance = 0;
    double refundCash = 0;
    double refundCard = 0;

    int completedCount = 0;
    int pendingCount = 0;
    int refundCount = 0;
    int saleCount = 0;

    for (final s in list) {
      if (s.status == InvoiceStatus.pending) {
        pendingCount++;
        continue;
      }

      if (s.status != InvoiceStatus.completed || s.isDeleted) continue;

      completedCount++;

      if (s.type == SaleType.refund) {
        refundCount++;
        refundCash += s.cashOut;
        refundCard += s.cardOut;
        continue;
      }

      saleCount++;

      final customerPaid = s.customerPaidAmount;
      final companyBilled = s.companyBilledAmount;

      if (s.customerPaymentMethod == PaymentMethod.cash) {
        cash += customerPaid;
      } else if (s.customerPaymentMethod == PaymentMethod.card) {
        card += customerPaid;
      }

      insurance += companyBilled;
    }

    return _FilteredData(
      list: list,
      cash: cash,
      card: card,
      insurance: insurance,
      refundCash: refundCash,
      refundCard: refundCard,
      completedCount: completedCount,
      pendingCount: pendingCount,
      saleCount: saleCount,
      refundCount: refundCount,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 930,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 10),

              _filtersRow(context),
              const SizedBox(height: 10),

              TextField(
                onChanged: (v) => query.value = v,
                decoration: InputDecoration(
                  hintText: 'بحث: رقم فاتورة / زبون / صنف...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Obx(() {
                final data = _computeFiltered();
                return _summaryBar(data);
              }),

              const SizedBox(height: 10),

              Expanded(
                child: Obx(() {
                  final isLoading = salesController.isLoading.value;
                  final data = _computeFiltered();
                  final list = data.list;

                  if (isLoading && list.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.isEmpty) return _empty();

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _invoiceTile(context, list[i]),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.receipt_text, size: 22),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'تاريخ الفواتير',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),

        IconButton(
          tooltip: 'تصدير CSV',
          onPressed: !canExport
              ? null
              : () async {
            final data = _computeFiltered();
            await _exportCsv(data.list);
          },
          icon: const Icon(Iconsax.document_download),
        ),

        IconButton(
          tooltip: 'تحديث',
          onPressed: () async => _reloadAccordingToMode(),
          icon: const Icon(Iconsax.refresh),
        ),

        IconButton(
          onPressed: Get.back,
          icon: const Icon(Iconsax.close_circle),
        ),
      ],
    );
  }

  Widget _filtersRow(BuildContext context) {
    return Obx(() {
      final m = mode.value;
      final st = status.value;
      final pm = pay.value;

      final companies = salesController.insuranceCompanies;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip('اليوم', selected: m == HistoryMode.today, onTap: () async {
            mode.value = HistoryMode.today;
            range.value = null;
            await _reloadAccordingToMode();
          }),

          _chip('الكل', selected: m == HistoryMode.all, onTap: () async {
            mode.value = HistoryMode.all;
            range.value = null;
            await _reloadAccordingToMode();
          }),


          _chip('مدة', selected: m == HistoryMode.range, onTap: () async {
            final picked = await showDialog<DateTimeRange>(
              context: context,
              builder: (context) {
                DateTimeRange? selectedRange;

                return StatefulBuilder(  // ✅ إضافة StatefulBuilder
                  builder: (context, setState) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Iconsax.calendar, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text('اختر المدة', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      content: SizedBox(
                        width: 400,
                        height: 400,
                        child: SfDateRangePicker(
                          view: DateRangePickerView.month,
                          selectionMode: DateRangePickerSelectionMode.range,
                          monthViewSettings: const DateRangePickerMonthViewSettings(
                            viewHeaderHeight: 40,
                          ),
                          headerStyle: const DateRangePickerHeaderStyle(
                            textAlign: TextAlign.center,
                            textStyle: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          monthCellStyle: DateRangePickerMonthCellStyle(
                            todayCellDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(.12),
                            ),
                            todayTextStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.blue,
                            ),
                          ),
                          onSelectionChanged: (args) {
                            if (args.value is PickerDateRange) {
                              final range = args.value as PickerDateRange;
                              selectedRange = DateTimeRange(
                                start: range.startDate!,
                                end: range.endDate ?? range.startDate!,
                              );
                              setState(() {}); // ✅ تحديث الواجهة بعد اختيار التاريخ
                            }
                          },
                        ),


                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: selectedRange != null
                              ? () => Navigator.pop(context, selectedRange)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('تطبيق'),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (picked != null) {
              mode.value = HistoryMode.range;
              range.value = picked;
              await _reloadAccordingToMode();
            }

          }),

          if (canFilterEmployee) ...[
            Obx(() {
              final emps = employeeController.employees;

              final Map<String, String> map = {};
              map['admin'] = 'admin';

              for (final e in emps) {
                final id = e.id.trim();
                if (id.isEmpty) continue;
                map.putIfAbsent(id, () => (e.name.isNotEmpty ? e.name : id));
              }

              final current = employeeIdFilter.value;
              final safeValue = (current == null || map.containsKey(current)) ? current : null;
              if (safeValue != employeeIdFilter.value) {
                employeeIdFilter.value = safeValue;
              }

              final items = <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('كل الموظفين'),
                ),
                ...map.entries.map((e) => DropdownMenuItem<String?>(
                  value: e.key,
                  child: Text(e.value),
                )),
              ];

              return Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: employeeIdFilter.value,
                    isExpanded: true,
                    hint: const Text('كل الموظفين'),
                    items: items,
                    onChanged: (v) async {
                      employeeIdFilter.value = v;
                      await _reloadAccordingToMode();
                    },
                  ),
                ),
              );
            }),
          ],

          Container(
            width: 170,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<InvoiceStatus?>(
                value: st,
                isExpanded: true,
                icon: const Icon(Iconsax.arrow_down_1),
                items: const [
                  DropdownMenuItem(value: null, child: Text('كل الحالات')),
                  DropdownMenuItem(value: InvoiceStatus.completed, child: Text('مكتملة')),
                  DropdownMenuItem(value: InvoiceStatus.pending, child: Text('قيد التنفيذ')),
                ],
                onChanged: (v) => status.value = v,
              ),
            ),
          ),

          _chip('كل الدفع', selected: pm == null, onTap: () => pay.value = null),
          _chip('نقدي', selected: pm == PaymentMethod.cash, onTap: () => pay.value = PaymentMethod.cash),
          _chip('معاملة مصرفية', selected: pm == PaymentMethod.card, onTap: () => pay.value = PaymentMethod.card),
          _chip('تأمين', selected: pm == PaymentMethod.insurance, onTap: () => pay.value = PaymentMethod.insurance),

          if (pm == PaymentMethod.insurance) ...[
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: insuranceCompanyId.value,
                  isExpanded: true,
                  hint: const Text('كل شركات التأمين'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('كل شركات التأمين'),
                    ),
                    ...companies.map((InsuranceCompany c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    )),
                  ],
                  onChanged: (v) => insuranceCompanyId.value = v,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _summaryBar(_FilteredData d) {
    final grossIn = d.cash + d.card + d.insurance;
    final refunds = d.refundCash + d.refundCard;
    final net = grossIn - refunds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.withOpacity(.14)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _statChip('الفواتير', '${d.list.length}', Iconsax.receipt_text),
          _statChip('مبيعات', '${d.saleCount}', Iconsax.arrow_up_3, color: Colors.green),
          _statChip('مرتجعات', '${d.refundCount}', Iconsax.arrow_down_2, color: Colors.orange),
          _statChip('نقدي', _money.format(d.cash), Iconsax.money, color: Colors.green),
          _statChip('مصرفي', _money.format(d.card), Iconsax.card, color: Colors.blue),
          _statChip('تأمين', _money.format(d.insurance), Iconsax.shield_tick, color: Colors.purple),
          _statChip('ترجيع كاش', '-${_money.format(d.refundCash)}', Iconsax.undo, color: Colors.orange),
          _statChip('ترجيع مصرفي', '-${_money.format(d.refundCard)}', Iconsax.undo, color: Colors.red),
          _statChip('الصافي', _money.format(net), Iconsax.chart_success, color: Colors.blue, strong: true),
        ],
      ),
    );
  }

  Widget _statChip(
      String label,
      String value,
      IconData icon, {
        Color color = Colors.blueGrey,
        bool strong = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: strong ? color.withOpacity(.14) : Colors.white.withOpacity(.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 13 : 12,
              color: strong ? color : Colors.grey.shade900,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
  Widget _sumText(String label, String value, {bool strong = false}) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: strong ? Colors.blue.shade800 : Colors.grey.shade900,
      ),
    );
  }
  Widget _invoiceTile(BuildContext context, Sale inv) {
    final isPending = inv.status == InvoiceStatus.pending;
    final isCompleted =
        inv.status == InvoiceStatus.completed && !inv.isDeleted;

    final isRefund = inv.type == SaleType.refund;

    final hasInsurance =
        (inv.insuranceDiscount ?? 0) > 0 &&
            (inv.insuranceCompanyId ?? '').trim().isNotEmpty;

    final customerPaid = inv.customerPaidAmount;
    final companyBilled = inv.companyBilledAmount;
    final refundTotal = inv.refundPaidOut;

    Color tint = Colors.grey[50]!;
    Color badge = Colors.grey;
    String badgeText = 'غير معروف';
    IconData icon = Iconsax.receipt;

    if (isRefund) {
      tint = Colors.orange.withOpacity(.07);
      badge = Colors.orange;
      badgeText = 'ترجيع';
      icon = Iconsax.undo;
    } else if (isPending) {
      tint = Colors.orange.withOpacity(.06);
      badge = Colors.orange;
      badgeText = 'قيد التنفيذ';
      icon = Iconsax.receipt_edit;
    } else if (isCompleted) {
      tint = Colors.green.withOpacity(.06);
      badge = Colors.green;
      badgeText = hasInsurance ? 'بيع + تأمين' : 'بيع';
      icon = Iconsax.receipt;
    } else if (inv.status == InvoiceStatus.cancelled || inv.isDeleted) {
      tint = Colors.red.withOpacity(.06);
      badge = Colors.red;
      badgeText = 'ملغية';
      icon = Iconsax.close_circle;
    }

    return Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Get.theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badge.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: badge, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  isRefund
                      ? 'فاتورة ترجيع #${inv.invoiceNumber}'
                      : 'فاتورة #${inv.invoiceNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badge.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badge,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'إجراءات',
                itemBuilder: (_) => [
                  if (canOpen)
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('عرض داخل الشاشة'),
                    ),
                  if (canOpen)
                    const PopupMenuItem(
                      value: 'preview',
                      child: Text('معاينة PDF'),
                    ),
                  if (canOpen)
                    const PopupMenuItem(
                      value: 'print',
                      child: Text('طباعة مباشرة'),
                    ),
                  if (canDelete)
                    const PopupMenuDivider(),
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف (Soft)'),
                    ),
                ],
                onSelected: (v) async {
                  if (v == 'open') {
                    salesController.openSavedInvoiceAsTab(inv);
                   // Get.back();
                    return;
                  }

                  if (v == 'preview') {
                    await _previewInvoicePdf(inv);
                    return;
                  }

                  if (v == 'print') {
                    await _printInvoiceDirect(inv);
                    return;
                  }

                  if (v == 'delete') {
                    if (!canDelete) {
                      Get.snackbar('صلاحيات', 'ليس لديك صلاحية للحذف');
                      return;
                    }

                    if (inv.status == InvoiceStatus.completed) {
                      await salesController.deleteSale(inv.id);
                      await _reloadAccordingToMode();
                    } else {
                      Get.snackbar(
                        'غير مسموح',
                        'الحذف هنا للفواتير المكتملة فقط',
                      );
                    }
                  }
                },
                child: const Icon(Iconsax.more, size: 18),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              isRefund
                  ? '${_fmt.format(inv.saleDate)}  •  ${inv.items.length} صنف  •  ترجيع: ${_money.format(refundTotal)}'
                  '${isOwner ? '  •  ${(inv.employeeName ?? inv.employeeId ?? '')}' : ''}'
                  : '${_fmt.format(inv.saleDate)}  •  ${inv.items.length} صنف  •  الزبون: ${_money.format(customerPaid)}'
                  '${hasInsurance ? '  •  التأمين: ${_money.format(companyBilled)}' : ''}'
                  '${isOwner ? '  •  ${(inv.employeeName ?? inv.employeeId ?? '')}' : ''}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
          children: [
            _invoiceDetailsPanel(
              inv: inv,
              isRefund: isRefund,
              hasInsurance: hasInsurance,
              customerPaid: customerPaid,
              companyBilled: companyBilled,
              refundTotal: refundTotal,
            ),
          ],
        ),
      ),
    );
  }


  Widget _invoiceDetailsPanel({
    required Sale inv,
    required bool isRefund,
    required bool hasInsurance,
    required double customerPaid,
    required double companyBilled,
    required double refundTotal,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _receiptInfoBlock(
                  title: 'بيانات الفاتورة',
                  children: [
                    if ((inv.customerName ?? '').trim().isNotEmpty)
                      _receiptRow('الزبون', inv.customerName!.trim()),
                    _receiptRow('الموظف', inv.employeeName ?? inv.employeeId ?? '--'),
                    _receiptRow('التاريخ', _fmt.format(inv.saleDate)),
                    if (isRefund)
                      _receiptRow('فاتورة أصلية', inv.refInvoiceNumber ?? '--'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _receiptInfoBlock(
                  title: isRefund ? 'ملخص الترجيع' : 'ملخص الدفع',
                  children: isRefund
                      ? [
                    _receiptRow('كاش خارج', _money.format(inv.cashOut), danger: inv.cashOut > 0),
                    _receiptRow('ترجيع مصرفي', _money.format(inv.cardOut), danger: inv.cardOut > 0),
                    const Divider(height: 16),
                    _receiptRow('إجمالي الترجيع', _money.format(refundTotal), strong: true, danger: true),
                  ]
                      : [
                    _receiptRow(
                      'طريقة الدفع',
                      inv.customerPaymentMethod == PaymentMethod.cash
                          ? 'نقدي'
                          : 'معاملة مصرفية',
                    ),
                    _receiptRow('دفع الزبون', _money.format(customerPaid), strong: true),
                    if (hasInsurance) ...[
                      _receiptRow('شركة التأمين', inv.insuranceCompanyName ?? '--'),
                      _receiptRow('على شركة التأمين', _money.format(companyBilled), strong: true),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _itemsReceiptList(inv),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Iconsax.eye, size: 18),
                  label: const Text(
                    'عرض',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onPressed: !canOpen
                      ? null
                      : () {
                    salesController.openSavedInvoiceAsTab(inv);
                    //Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[900],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Iconsax.document_text, size: 18),
                  label: const Text(
                    'PDF',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onPressed: !canOpen ? null : () => _previewInvoicePdf(inv),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.printer, size: 18),
                  label: const Text(
                    'طباعة',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onPressed: !canOpen ? null : () => _printInvoiceDirect(inv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptInfoBlock({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _receiptRow(
      String label,
      String value, {
        bool strong = false,
        bool danger = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: strong ? 13 : 12,
                color: danger ? Colors.orange.shade800 : Colors.grey.shade900,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsReceiptList(Sale inv) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(.045),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.w900))),
                Expanded(child: Text('كمية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900))),
                Expanded(child: Text('سعر', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900))),
                Expanded(child: Text('إجمالي', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w900))),
              ],
            ),
          ),
          ...inv.items.map((it) {
            final line = it.unitPrice * it.quantity;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${it.quantity}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _money.format(it.unitPrice),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _money.format(line),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  Future<void> _exportCsv(List<Sale> list) async {
    try {
      final header = [
        'invoiceNumber',
        'date',
        'employeeId',
        'employeeName',
        'customerName',
        'paymentMethod',
        'insuranceCompany',
        'itemsCount',
        'total',
        'status',
      ];

      final csv = StringBuffer();
      csv.writeln(header.join(','));

      for (final s in list) {
        final row = [
          s.invoiceNumber,
          s.saleDate.toIso8601String(),
          s.employeeId ?? '',
          s.employeeName ?? '',
          s.customerName ?? '',
          s.paymentMethod.name,
          s.insuranceCompanyName ?? '',
          s.items.length.toString(),
          s.total.toStringAsFixed(2),
          s.status.name,
        ].map(_escapeCsv).join(',');
        csv.writeln(row);
      }

      final dir = await _downloadsDir();
      final fileName = 'sales_history_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv.toString(), encoding: utf8);

      Get.snackbar('تم', 'تم حفظ الملف: $fileName');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التصدير: $e');
    }
  }

  String _escapeCsv(String v) {
    final needs = v.contains(',') || v.contains('"') || v.contains('\n');
    if (!needs) return v;
    return '"${v.replaceAll('"', '""')}"';
  }

  Future<Directory> _downloadsDir() async {
    final d = await getDownloadsDirectory();
    if (d != null) return d;
    return await getApplicationDocumentsDirectory();
  }

  Widget _chip(String label, {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.blue.withOpacity(.35) : Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.blue[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.receipt, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('لا توجد فواتير', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('جرّب تبدّل الفلترة أو اكتب بحث', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _FilteredData {
  final List<Sale> list;

  final double cash;
  final double card;
  final double insurance;

  final double refundCash;
  final double refundCard;

  final int completedCount;
  final int pendingCount;
  final int saleCount;
  final int refundCount;

  _FilteredData({
    required this.list,
    required this.cash,
    required this.card,
    required this.insurance,
    required this.refundCash,
    required this.refundCard,
    required this.completedCount,
    required this.pendingCount,
    required this.saleCount,
    required this.refundCount,
  });
}