import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../models/shift_model.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final ShiftController shiftCtrl = Get.find<ShiftController>();
  final AuthController auth = Get.find<AuthController>();

  final TextInputFormatter moneyFmt =
  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}([.,]\d{0,2})?$'));

  final TextEditingController searchCtrl = TextEditingController();
  ShiftStatus? statusFilter;
  _RangePreset preset = _RangePreset.today;
  DateTimeRange? customRange;

  double _parseMoney(String s) {
    final t = s.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => shiftCtrl.loadShifts());
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  DateTimeRange _calcRange(_RangePreset p) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (p == _RangePreset.today) {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
      return DateTimeRange(start: start, end: end);
    }

    if (p == _RangePreset.week) {
      end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      start = end.subtract(const Duration(days: 7));
      return DateTimeRange(start: start, end: end);
    }

    if (p == _RangePreset.month) {
      end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      start = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: start, end: end);
    }

    return customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
        );
  }

  bool _inRange(DateTime? d, DateTimeRange r) {
    if (d == null) return false;
    return (d.isAtSameMomentAs(r.start) || d.isAfter(r.start)) && d.isBefore(r.end);
  }

  List<Shift> _applyFilters(List<Shift> input) {
    final q = searchCtrl.text.trim().toLowerCase();
    final range = _calcRange(preset);

    return input.where((s) {
      if (statusFilter != null && s.status != statusFilter) return false;

      if (preset != _RangePreset.all) {
        if (!_inRange(s.openedAt, range)) return false;
      }

      if (q.isNotEmpty) {
        final hay = [
          s.id,
          s.openedByName,
          s.openedById,
          s.openedByType,
        ].join(' ').toLowerCase();

        if (!hay.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _openShiftDialog() async {
    final res = await showDialog<_OpenShiftResult>(
      context: context,
      builder: (_) => _OpenShiftDialog(moneyFormatter: moneyFmt),
    );
    if (res == null) return;

    await shiftCtrl.openShift(openingCash: res.openingCash, notes: res.note);
  }

  Future<void> _closeMyShiftDialog(Shift active) async {
    final expectedCash = active.openingCash + active.cashTotal;

    final res = await showDialog<_CloseShiftResult>(
      context: context,
      builder: (_) => _CloseShiftDialog(
        moneyFormatter: moneyFmt,
        expectedCash: expectedCash,
      ),
    );
    if (res == null) return;

    await shiftCtrl.closeShift(closingCash: res.closingCash, notes: res.note);
  }

  Future<void> _closeOtherShiftDialog({required Shift targetShift}) async {
    // ✅ يقفلها admin/owner/close_any (check UI + controller)
    final expectedCash = targetShift.openingCash + targetShift.cashTotal;

    final res = await showDialog<_CloseShiftResult>(
      context: context,
      builder: (_) => _CloseShiftDialog(
        moneyFormatter: moneyFmt,
        expectedCash: expectedCash,
        title: 'إغلاق وردية موظف',
      ),
    );
    if (res == null) return;

    await shiftCtrl.closeShiftByActorKey(
      targetActorKey: targetShift.openedByKey,
      closingCash: res.closingCash,
      notes: res.note,
    );
  }

  Future<void> _showShiftDetails(Shift s) async {
    // ✅ تجيب تفاصيل كاملة + تحقق الصلاحيات (وردية الموظف فقط)
    final full = await shiftCtrl.getShiftDetailsById(s.id);
    if (full == null) return;

    if (!mounted) return;
    showDialog(context: context, builder: (_) => _ShiftDetailsDialog(shift: full));
  }
  @override
  Widget build(BuildContext context) {
    final canHistoryView = shiftCtrl.canViewShift; // shifts.view ✅
    final canHistoryOpen = auth.can('shifts.history.open') || shiftCtrl.canViewAll;
// لو ما عنده history.open لكن عنده view_all يعتبر يقدر يفتح تفاصيل
    final canCloseAny = auth.can('shifts.close_any') || (auth.currentEmployee.value == null); // owner

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        final active = shiftCtrl.activeShift.value;
        final loading = shiftCtrl.isLoading.value;
        final mutating = shiftCtrl.isMutating.value;

        final all = shiftCtrl.shifts.toList();
        final filtered = _applyFilters(all);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT
              Expanded(
                flex: 4,
                child: _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ActiveShiftHeader(
                        active: active,
                        loading: loading,
                        mutating: mutating,
                        onRefresh: () => shiftCtrl.loadShifts(),
                        canOpen: auth.can('shifts.open'),
                        canClose: auth.can('shifts.close'),
                        onOpen: _openShiftDialog,
                        onClose: active != null ? () => _closeMyShiftDialog(active) : null,
                      ),
                      const SizedBox(height: 12),
                      if (active == null) ...[
                        _InfoBanner(
                          icon: Icons.info_outline_rounded,
                          text: mutating ? 'جاري التنفيذ...' : 'لا توجد وردية نشطة حالياً. افتح وردية لبدء البيع.',
                          tone: BannerTone.info,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        _ShiftKpisRow(shift: active),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _InfoBanner(
                            icon: Icons.lightbulb_outline_rounded,
                            text: 'التأمين يُحسب على الشركة (insurance) وليس ضمن كاش الدرج.',
                            tone: BannerTone.info,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),
              // RIGHT (History)
              Expanded(
                flex: 6,
                child: _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const _HeaderIcon(icon: Icons.history_rounded),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('سجل الورديات',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          ),
                          IconButton(
                            onPressed: loading ? null : () => shiftCtrl.loadShifts(),
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'تحديث',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ✅ لو ماعندكش صلاحية عرض السجل
                      if (!canHistoryView) ...[
                        const SizedBox(height: 12),
                        const _InfoBanner(
                          icon: Icons.lock_outline_rounded,
                          text: 'ليس لديك صلاحية عرض سجل الورديات.',
                          tone: BannerTone.warning,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: Text(
                              'تواصل مع المدير لتفعيل ..',
                              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      ] else ...[
                        _HistoryFiltersBar(
                          searchCtrl: searchCtrl,
                          preset: preset,
                          statusFilter: statusFilter,
                          onPresetChanged: (p) async {
                            if (p == _RangePreset.custom) {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(now.year - 3),
                                lastDate: DateTime(now.year + 1),
                                initialDateRange: customRange ??
                                    DateTimeRange(
                                      start: DateTime(now.year, now.month, now.day),
                                      end: DateTime(now.year, now.month, now.day)
                                          .add(const Duration(days: 1)),
                                    ),
                              );
                              if (picked != null) {
                                setState(() {
                                  customRange = picked;
                                  preset = _RangePreset.custom;
                                });
                              }
                              return;
                            }
                            setState(() => preset = p);
                          },
                          onStatusChanged: (st) => setState(() => statusFilter = st),
                          onSearchChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 10),

                        if (loading)
                          const Expanded(child: Center(child: CircularProgressIndicator()))
                        else if (filtered.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text('لا توجد ورديات مطابقة',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          Expanded(
                            child: _ShiftsDataTable(
                              shifts: filtered,
                              activeShiftId: shiftCtrl.activeShift.value?.id,
                              canOpenDetails: canHistoryOpen,
                              canCloseAny: canCloseAny,
                              myActorKey: shiftCtrl.actorKey,
                              onView: (s) async => await _showShiftDetails(s),                              onCloseOther: (s) => _closeOtherShiftDialog(targetShift: s),
                            ),
                          ),
                          // Expanded(
                          //   child: _ShiftsHistoryCards(
                          //     shifts: filtered,
                          //     activeShiftId: shiftCtrl.activeShift.value?.id,
                          //     canOpenDetails: canHistoryOpen,
                          //     canCloseAny: canCloseAny,
                          //     myActorKey: shiftCtrl.actorKey,
                          //     onView: (s) => _showShiftDetails(s),
                          //     onCloseOther: (s) => _closeOtherShiftDialog(targetShift: s),
                          //   ),
                          // ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ==============================
// Widgets
// ==============================

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.blue.shade700, size: 20),
    );
  }
}

enum BannerTone { info, warning }

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg = tone == BannerTone.warning ? Colors.orange[50]! : Colors.blue[50]!;
    final Color border =
    tone == BannerTone.warning ? Colors.orange.withOpacity(.25) : Colors.blue.withOpacity(.25);
    final Color iconColor = tone == BannerTone.warning ? Colors.orange[800]! : Colors.blue[800]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

enum _PillTone { success, neutral }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.tone});
  final String text;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == _PillTone.success ? Colors.green[50] : Colors.blueGrey[50];
    final fg = tone == _PillTone.success ? Colors.green[800] : Colors.blueGrey[700];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

/// ✅ Responsive (Fix overflow)
class _DiffPill extends StatelessWidget {
  const _DiffPill({required this.diff});
  final double diff;

  @override
  Widget build(BuildContext context) {
    final isOk = diff.abs() < 0.0001;
    final isPlus = diff > 0;

    final bg = isOk ? Colors.green[50] : (isPlus ? Colors.orange[50] : Colors.red[50]);
    final fg = isOk ? Colors.green[800] : (isPlus ? Colors.orange[800] : Colors.red[800]);

    final label = isOk
        ? 'مطابق'
        : (isPlus ? 'زيادة ${diff.toStringAsFixed(2)}' : 'عجز ${diff.abs().toStringAsFixed(2)}');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
class _ActiveShiftHeader extends StatelessWidget {
  const _ActiveShiftHeader({
    required this.active,
    required this.loading,
    required this.mutating,
    required this.onRefresh,
    required this.canOpen,
    required this.canClose,
    required this.onOpen,
    required this.onClose,
  });

  final Shift? active;
  final bool loading;
  final bool mutating;

  final VoidCallback onRefresh;

  final bool canOpen;
  final bool canClose;

  final VoidCallback onOpen;
  final VoidCallback? onClose;

  String _dt(DateTime? d) => d == null ? '--' : DateFormat('yyyy-MM-dd  HH:mm').format(d);

  void _deny(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = active != null && active!.status == ShiftStatus.open;

    final openEnabled = canOpen && !mutating && !isOpen;
    final closeEnabled = canClose && !mutating && isOpen && onClose != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _HeaderIcon(icon: Icons.schedule_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('الوردية النشطة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'تحديث',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusPill(
                text: isOpen ? 'مفتوحة' : 'غير موجودة',
                tone: isOpen ? _PillTone.success : _PillTone.neutral,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOpen ? 'فتح: ${_dt(active!.openedAt)}' : 'افتح وردية لبدء البيع',
                  style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Tooltip(
                    message: !canOpen
                        ? 'ليس لديك صلاحية فتح وردية'
                        : isOpen
                        ? 'عندك وردية مفتوحة بالفعل'
                        : mutating
                        ? 'جاري التنفيذ...'
                        : '',
                    child: ElevatedButton.icon(
                      onPressed: openEnabled
                          ? onOpen
                          : () {
                        if (!canOpen) _deny(context, 'غير مسموح: لا تملك صلاحية فتح وردية');
                        if (isOpen) _deny(context, 'لديك وردية مفتوحة بالفعل');
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('فتح وردية'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Tooltip(
                    message: !canClose
                        ? 'ليس لديك صلاحية إغلاق وردية'
                        : !isOpen
                        ? 'لا توجد وردية مفتوحة للإغلاق'
                        : mutating
                        ? 'جاري التنفيذ...'
                        : '',
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: closeEnabled
                          ? onClose
                          : () {
                        if (!canClose) _deny(context, 'غير مسموح: لا تملك صلاحية إغلاق وردية');
                        if (!isOpen) _deny(context, 'لا توجد وردية مفتوحة لإغلاقها');
                      },
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('إغلاق'),
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
}

class _ShiftKpisRow extends StatelessWidget {
  const _ShiftKpisRow({required this.shift});
  final Shift shift;

  String _money(num v) => NumberFormat('#,##0.00', 'en').format(v);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children: [
        _KpiCard(label: 'الإجمالي', value: '${_money(shift.grandTotal)} د.ل', icon: Icons.summarize_rounded),
        _KpiCard(label: 'كاش', value: '${_money(shift.cashTotal)} د.ل', icon: Icons.payments_rounded),
        _KpiCard(label: 'بطاقة', value: '${_money(shift.cardTotal)} د.ل', icon: Icons.credit_card_rounded),
        _KpiCard(label: 'تأمين', value: '${_money(shift.insuranceBilledTotal)} د.ل', icon: Icons.health_and_safety_rounded),
        _KpiCard(label: 'فواتير', value: '${shift.salesCount}', icon: Icons.receipt_long_rounded),
        _KpiCard(label: 'مرتجعات', value: '${shift.refundsCount}', icon: Icons.keyboard_return_rounded),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.90),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue.shade700, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


enum _RangePreset { all, today, week, month, custom }

class _HistoryFiltersBar extends StatelessWidget {
  const _HistoryFiltersBar({
    required this.searchCtrl,
    required this.preset,
    required this.statusFilter,
    required this.onPresetChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchCtrl;
  final _RangePreset preset;
  final ShiftStatus? statusFilter;

  final Future<void> Function(_RangePreset p) onPresetChanged;
  final void Function(ShiftStatus? st) onStatusChanged;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Segmented(
          value: preset,
          items: const [
            _SegItem(_RangePreset.all, 'الكل'),
            _SegItem(_RangePreset.today, 'اليوم'),
            _SegItem(_RangePreset.week, 'أسبوع'),
            _SegItem(_RangePreset.month, 'شهر'),
            _SegItem(_RangePreset.custom, 'مخصص'),
          ],
          onChanged: (v) => onPresetChanged(v),
        ),
        const SizedBox(width: 10),
        DropdownButton<ShiftStatus?>(
          value: statusFilter,
          items: const [
            DropdownMenuItem(value: null, child: Text('كل الحالات')),
            DropdownMenuItem(value: ShiftStatus.open, child: Text('مفتوحة')),
            DropdownMenuItem(value: ShiftStatus.closed, child: Text('مغلقة')),
          ],
          onChanged: onStatusChanged,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: searchCtrl,
            onChanged: (_) => onSearchChanged(),
            decoration: InputDecoration(
              hintText: 'بحث (اسم موظف / رقم وردية)',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white.withOpacity(.90),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShiftsDataTable extends StatelessWidget {
  const _ShiftsDataTable({
    required this.shifts,
    required this.activeShiftId,
    required this.canOpenDetails,
    required this.canCloseAny,
    required this.myActorKey,
    required this.onView,
    required this.onCloseOther,
  });

  final List<Shift> shifts;
  final String? activeShiftId;

  final bool canOpenDetails;
  final bool canCloseAny;
  final String myActorKey;

  final void Function(Shift s) onView;
  final void Function(Shift s) onCloseOther;

  String _money(num v) => NumberFormat('#,##0.00', 'en').format(v);
  String _dt(DateTime? d) => d == null ? '--' : DateFormat('yyyy-MM-dd  HH:mm').format(d);

  DataCell _cellText(
      String t, {
        double maxW = 160,
        FontWeight fw = FontWeight.w700,
        TextAlign align = TextAlign.start,
      }) {
    return DataCell(
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Text(
          t,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(fontWeight: fw),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;

        // ✅ Breakpoints
        final bool compact = w < 1050; // شاشة ضيقة = جدول مختصر
        final bool medium = w >= 1050 && w < 1350;

        // ✅ أعمدة حسب العرض
        final columns = <DataColumn>[
          const DataColumn(label: Text('الحالة')),
          const DataColumn(label: Text('فتح')),
          if (!compact) const DataColumn(label: Text('إغلاق')),
          const DataColumn(label: Text('الموظف')),
          const DataColumn(label: Text('الإجمالي')),
          if (!compact) const DataColumn(label: Text('كاش')),
          if (!compact && !medium) const DataColumn(label: Text('بطاقة')),
          if (!compact && !medium) const DataColumn(label: Text('تأمين')),
          if (!compact) const DataColumn(label: Text('فواتير')),
          const DataColumn(label: Text('فرق الدرج')),
          const DataColumn(label: Text('إجراءات')),
        ];

        final rows = shifts.map((s) {
          final isActive = activeShiftId != null && (s.id == activeShiftId);
          final open = s.status == ShiftStatus.open;

          final canCloseThisOther =
              canCloseAny && open && s.openedByKey.isNotEmpty && s.openedByKey != myActorKey;

          final cells = <DataCell>[
            DataCell(
              _StatusPill(
                text: open ? 'مفتوحة' : 'مغلقة',
                tone: open ? _PillTone.success : _PillTone.neutral,
              ),
            ),
            _cellText(_dt(s.openedAt), maxW: 150),
            if (!compact) _cellText(_dt(s.closedAt), maxW: 150),
            _cellText(s.openedByName.isEmpty ? '--' : s.openedByName, maxW: 170, fw: FontWeight.w900),
            _cellText('${_money(s.grandTotal)} د.ل', maxW: 140, fw: FontWeight.w900),
            if (!compact) _cellText(_money(s.cashTotal), maxW: 110),
            if (!compact && !medium) _cellText(_money(s.cardTotal), maxW: 110),
            if (!compact && !medium) _cellText(_money(s.insuranceBilledTotal), maxW: 110),
            if (!compact) _cellText('${s.salesCount}', maxW: 70, align: TextAlign.center),
            DataCell(_DiffPill(diff: s.drawerDiff)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: canOpenDetails ? 'عرض تفاصيل' : 'ليس لديك صلاحية فتح تفاصيل وردية',
                    child: IconButton(
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      padding: EdgeInsets.zero,
                      onPressed: canOpenDetails ? () => onView(s) : null,
                      icon: const Icon(Icons.visibility_rounded, size: 20),
                    ),
                  ),
                  if (canCloseThisOther) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'إغلاق وردية الموظف',
                      child: IconButton(
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        padding: EdgeInsets.zero,
                        onPressed: () => onCloseOther(s),
                        icon: const Icon(Icons.lock_clock_rounded, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ];

          return DataRow(selected: isActive, cells: cells);
        }).toList();

        // ✅ Scroll أفقي + عمودي (عشان الأعمدة ما تضيعش)
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // minWidth باش الجدول ما يضغطش نفسه ويعمل overflow
              constraints: BoxConstraints(minWidth: compact ? 900 : (medium ? 1150 : 1350)),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 58,
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    columns: columns,
                    rows: rows,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// ==============================
// Details Dialog
// ==============================
class _ShiftDetailsDialog extends StatelessWidget {
  const _ShiftDetailsDialog({required this.shift});
  final Shift shift;

  String _money(num v) => NumberFormat('#,##0.00', 'en').format(v);
  String _dt(DateTime? d) => d == null ? '--' : DateFormat('yyyy-MM-dd  HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final expectedDrawer = (shift.expectedDrawerCash == 0)
        ? (shift.openingCash + shift.cashTotal)
        : shift.expectedDrawerCash;

    final isOpen = shift.status == ShiftStatus.open;
    final accent = Colors.blueAccent;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
                color: Colors.white.withOpacity(.75),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade200, Colors.blueAccent],
                      ),
                    ),
                    child: const Icon(Icons.summarize_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل الوردية',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'name: ${shift.openedByName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(isOpen: isOpen),
                  const SizedBox(width: 8),
                  IconButton(
                    splashRadius: 18,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.blueGrey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Meta card
            _CardSection(
              title: 'البيانات',
              icon: Icons.badge_outlined,
              child: Column(
                children: [
                  _kv('الموظف', shift.openedByName.isEmpty ? '--' : shift.openedByName),
                  const SizedBox(height: 8),
                  _kv('فتح', _dt(shift.openedAt)),
                  const SizedBox(height: 8),
                  _kv('إغلاق', _dt(shift.closedAt)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Totals card
            _CardSection(
              title: 'تفاصيل',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _pillStat('رصيد افتتاح', '${_money(shift.openingCash)} د.ل', icon: Icons.login_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _pillStat('الإجمالي', '${_money(shift.grandTotal)} د.ل', icon: Icons.summarize_rounded, strong: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _pillStat('كاش', '${_money(shift.cashTotal)} د.ل', icon: Icons.payments_outlined)),
                      const SizedBox(width: 8),
                      Expanded(child: _pillStat('بطاقة', '${_money(shift.cardTotal)} د.ل', icon: Icons.credit_card_rounded)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _pillStat('تأمين (على الشركات)', '${_money(shift.insuranceBilledTotal)} د.ل', icon: Icons.verified_user_outlined),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Counters + Drawer card
            _CardSection(
              title: 'الحركة والدرج',
              icon: Icons.point_of_sale_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _counterTile('فواتير', '${shift.salesCount}', icon: Icons.receipt_long_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _counterTile('مرتجعات', '${shift.refundsCount}', icon: Icons.assignment_return_rounded)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _kv('المفروض داخل الدرج', '${_money(expectedDrawer)} د.ل'),
                  const SizedBox(height: 8),
                  _kv('الكاش المقفول', '${_money(shift.closingCash)} د.ل'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'فرق الدرج',
                          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey.shade800),
                        ),
                      ),
                      _DiffPill(diff: shift.drawerDiff),
                    ],
                  ),

                  if ((shift.drawerDiff).abs() > 0.01 && ((shift.notes ?? '').trim().isEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _softHint(
                        icon: Icons.info_outline_rounded,
                        text: 'فيه فرق مسجل، لكن بدون ملاحظة.',
                        color: Colors.blue.shade700,
                      ),
                    ),
                ],
              ),
            ),

            if ((shift.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade100),
                  color: Colors.white.withOpacity(.82),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt_outlined, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظات: ${shift.notes}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('تم', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey.shade800),
          ),
        ),
        Text(
          v,
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey.shade900),
        ),
      ],
    );
  }

  Widget _pillStat(String label, String value, {required IconData icon, bool strong = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
        color: Colors.white.withOpacity(.85),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterTile(String label, String value, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(.9), Colors.blue.shade50],
        ),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade100,
            ),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softHint({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

// ------- Helpers صغيرة (خفيفة) -------
class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        color: Colors.white.withOpacity(.82),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final bg = isOpen ? Colors.blue.shade50 : Colors.blueGrey.shade50;
    final bd = isOpen ? Colors.blue.shade200 : Colors.blueGrey.shade200;
    final fg = isOpen ? Colors.blueAccent : Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd),
      ),
      child: Row(
        children: [
          Icon(isOpen ? Icons.lock_open_rounded : Icons.lock_rounded, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'مفتوحة' : 'مغلقة',
            style: TextStyle(fontWeight: FontWeight.w900, color: fg),
          ),
        ],
      ),
    );
  }
}
// ==============================
// Dialogs
// ==============================
class _OpenShiftResult {
  final double openingCash;
  final String? note;
  _OpenShiftResult(this.openingCash, this.note);
}

class _OpenShiftDialog extends StatefulWidget {
  const _OpenShiftDialog({required this.moneyFormatter});
  final TextInputFormatter moneyFormatter;

  @override
  State<_OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<_OpenShiftDialog> {
  final cashCtrl = TextEditingController(text: '0');
  final noteCtrl = TextEditingController();

  double _parseMoney(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0.0;

  @override
  void dispose() {
    cashCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('فتح وردية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: cashCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [widget.moneyFormatter],
              decoration: InputDecoration(
                labelText: 'رصيد افتتاح (د.ل)',
                filled: true,
                fillColor: Colors.white.withOpacity(.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                filled: true,
                fillColor: Colors.white.withOpacity(.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _OpenShiftResult(_parseMoney(cashCtrl.text), noteCtrl.text.trim())),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('فتح'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _CloseShiftResult {
  final double closingCash;
  final String? note;
  _CloseShiftResult(this.closingCash, this.note);
}

class _CloseShiftDialog extends StatefulWidget {
  const _CloseShiftDialog({
    required this.moneyFormatter,
    required this.expectedCash,
    this.title,
  });

  final TextInputFormatter moneyFormatter;
  final double expectedCash;
  final String? title;

  @override
  State<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<_CloseShiftDialog> {
  final cashCtrl = TextEditingController(text: '0');
  final noteCtrl = TextEditingController();

  double _parseMoney(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0.0;

  double _diff = 0.0; // closing - expected
  bool _noteRequired = false;
  String? _noteError;

  static const double _eps = 0.01; // tolerance

  @override
  void initState() {
    super.initState();
    // تحديث الحالة عند أي تغيير
    cashCtrl.addListener(_recalc);
    noteCtrl.addListener(_recalc);
    _recalc();
  }

  void _recalc() {
    final closing = _parseMoney(cashCtrl.text);
    final expected = widget.expectedCash;

    final diff = closing - expected;
    final hasDiff = diff.abs() > _eps;

    final note = noteCtrl.text.trim();
    final noteRequired = hasDiff;
    final noteOk = !noteRequired || note.isNotEmpty;

    setState(() {
      _diff = diff;
      _noteRequired = noteRequired;
      _noteError = (!noteOk) ? 'الملاحظة مطلوبة إذا فيه فرق في الكاش' : null;
    });
  }

  bool get _canConfirm {
    final hasDiff = _diff.abs() > _eps;
    if (!hasDiff) return true;
    return noteCtrl.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    cashCtrl.removeListener(_recalc);
    noteCtrl.removeListener(_recalc);
    cashCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expected = widget.expectedCash;

    final hasDiff = _diff.abs() > _eps;
    final diffText = (_diff >= 0)
        ? '+${_diff.toStringAsFixed(2)} د.ل'
        : '${_diff.toStringAsFixed(2)} د.ل';

    // ألوان أزرق خفيفة (بدون تغيير جذري)
    final bg1 = Colors.blue.shade50;
    final bg2 = Colors.white;
    final accent = Colors.blueAccent;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg1, bg2, bg1],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title ?? 'إغلاق الوردية',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _InfoBanner(
              icon: Icons.info_outline_rounded,
              text: 'المفروض الكاش في الدرج ≈ ${expected.toStringAsFixed(2)} د.ل',
              tone: BannerTone.info,
            ),

            const SizedBox(height: 10),
            TextField(
              controller: cashCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [widget.moneyFormatter],
              decoration: InputDecoration(
                labelText: 'الكاش داخل الدرج فعليًا (د.ل)',
                filled: true,
                fillColor: Colors.white.withOpacity(.92),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.payments_outlined, color: accent),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظة (مطلوبة إذا فيه فرق)',
                errorText: _noteError,
                filled: true,
                fillColor: Colors.white.withOpacity(.92),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.sticky_note_2_outlined, color: accent),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canConfirm ? accent : Colors.blueGrey.shade200,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueGrey.shade200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: !_canConfirm
                        ? null
                        : () => Navigator.pop(
                      context,
                      _CloseShiftResult(
                        _parseMoney(cashCtrl.text),
                        noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      ),
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('تأكيد الإغلاق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ==============================
// Segmented
// ==============================
class _SegItem<T> {
  final T value;
  final String label;
  const _SegItem(this.value, this.label);
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<_SegItem<T>> items;
  final void Function(T v) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((it) {
          final selected = it.value == value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(it.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue.withOpacity(.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  it.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.blue[800] : Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}