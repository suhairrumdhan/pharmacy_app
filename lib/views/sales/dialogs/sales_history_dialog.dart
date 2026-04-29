import 'dart:convert';
import 'dart:io';

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
    // ✅ هنا الإصلاح الكبير: نقرأ من historyInvoices بدل allUserInvoices
    final all = salesController.historyInvoices;

    final q = query.value.trim();
    final st = status.value;
    final pm = pay.value;
    final insId = insuranceCompanyId.value;

    final list = all.where((inv) {
      if (st != null && inv.status != st) return false;
      if (pm != null && inv.paymentMethod != pm) return false;

      if (pm == PaymentMethod.insurance && insId != null) {
        if ((inv.insuranceCompanyId ?? '') != insId) return false;
      }

      if (q.isEmpty) return true;

      final invNo = inv.invoiceNumber.toString();
      final cust = (inv.customerName ?? '');
      final itemsText = inv.items.map((e) => e.name).join(' ');
      final empName = (inv.employeeName ?? '');

      return invNo.contains(q) ||
          cust.contains(q) ||
          itemsText.contains(q) ||
          empName.contains(q);
    }).toList();

    double cash = 0, card = 0, ins = 0;
    int completedCount = 0, pendingCount = 0;

    for (final s in list) {
      if (s.status == InvoiceStatus.pending) {
        pendingCount++;
        continue;
      }
      if (s.status == InvoiceStatus.completed && !s.isDeleted) {
        completedCount++;
        switch (s.paymentMethod) {
          case PaymentMethod.cash:
            cash += s.total;
            break;
          case PaymentMethod.card:
            card += s.total;
            break;
          case PaymentMethod.insurance:
            ins += s.total;
            break;
        }
      }
    }

    return _FilteredData(
      list: list,
      cash: cash,
      card: card,
      insurance: ins,
      completedCount: completedCount,
      pendingCount: pendingCount,
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
          _chip('بطاقة', selected: pm == PaymentMethod.card, onTap: () => pay.value = PaymentMethod.card),
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
    final grand = d.cash + d.card + d.insurance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(.15)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.clipboard_text, size: 18),
              const SizedBox(width: 8),
              Text('عدد الفواتير: ${d.list.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.tick_circle, size: 18),
              const SizedBox(width: 8),
              Text('مكتملة: ${d.completedCount}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.clock, size: 18),
              const SizedBox(width: 8),
              Text('قيد التنفيذ: ${d.pendingCount}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          Text('نقدي: ${_money.format(d.cash)}', style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('بطاقة: ${_money.format(d.card)}', style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('تأمين: ${_money.format(d.insurance)}', style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('الإجمالي: ${_money.format(grand)}', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _invoiceTile(BuildContext context, Sale inv) {
    final isPending = inv.status == InvoiceStatus.pending;
    final isCompleted = inv.status == InvoiceStatus.completed && !inv.isDeleted;

    Color tint = Colors.grey[50]!;
    Color badge = Colors.grey;
    String badgeText = 'غير معروف';
    IconData icon = Iconsax.receipt;

    if (isPending) {
      tint = Colors.orange.withOpacity(.06);
      badge = Colors.orange;
      badgeText = 'قيد التنفيذ';
      icon = Iconsax.receipt_edit;
    } else if (isCompleted) {
      tint = Colors.green.withOpacity(.06);
      badge = Colors.green;
      badgeText = 'مكتملة';
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
                  'فاتورة #${inv.invoiceNumber}',
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
                  style: TextStyle(color: badge, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),

              PopupMenuButton<String>(
                tooltip: 'إجراءات',
                itemBuilder: (_) => [
                  if (canOpen) const PopupMenuItem(value: 'open', child: Text('فتح')),
                  if (canDelete) const PopupMenuItem(value: 'delete', child: Text('حذف (Soft)')),
                ],
                onSelected: (v) async {
                  if (v == 'open') {
                    widget.onOpenInvoice(inv);
                    Get.back();
                    return;
                  }
                  if (v == 'delete') {
                    if (!canDelete) {
                      Get.snackbar('صلاحيات', 'ليس لديك صلاحية للحذف');
                      return;
                    }

                    if (inv.id != null && inv.status == InvoiceStatus.completed) {
                      await salesController.deleteSale(inv.id!);
                      await _reloadAccordingToMode();
                    } else {
                      Get.snackbar('غير مسموح', 'الحذف هنا للفواتير المكتملة فقط');
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
              '${_fmt.format(inv.saleDate)}  •  ${inv.items.length} صنف  •  ${_money.format(inv.total)}'
                  '${isOwner ? '  •  ${(inv.employeeName ?? inv.employeeId ?? '')}' : ''}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
          children: [
            if ((inv.customerName ?? '').trim().isNotEmpty) ...[
              _kv('الزبون', inv.customerName!.trim()),
              const SizedBox(height: 6),
            ],
            _kv('الدفع', inv.paymentMethod.name),
            if (inv.paymentMethod == PaymentMethod.insurance && (inv.insuranceCompanyName ?? '').isNotEmpty)
              _kv('شركة التأمين', inv.insuranceCompanyName ?? ''),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: inv.items.map((it) {
                  final line = (it.unitPrice * it.quantity);
                  return ListTile(
                    dense: true,
                    title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('الكمية: ${it.quantity}  •  السعر: ${_money.format(it.unitPrice)}'),
                    trailing: Text(_money.format(line), style: const TextStyle(fontWeight: FontWeight.w900)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isPending ? Iconsax.edit : Iconsax.eye, size: 18),
                    label: Text(
                      isPending ? 'فتح وتعديل' : 'عرض الفاتورة',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onPressed: !canOpen
                        ? null
                        : () {
                      widget.onOpenInvoice(inv);
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[900],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: TextStyle(color: Colors.grey[700]))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
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
  final int completedCount;
  final int pendingCount;

  _FilteredData({
    required this.list,
    required this.cash,
    required this.card,
    required this.insurance,
    required this.completedCount,
    required this.pendingCount,
  });
}