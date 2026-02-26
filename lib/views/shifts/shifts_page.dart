import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../models/sales_model.dart';
import '../../models/shift_model.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final ShiftController shiftCtrl = Get.find<ShiftController>();

  final TextEditingController openingCashCtrl = TextEditingController(text: '0');
  final TextEditingController closingCashCtrl = TextEditingController(text: '0');

  // ✅ فصل الملاحظات
  final TextEditingController openingNotesCtrl = TextEditingController();
  final TextEditingController closingNotesCtrl = TextEditingController();

  // ✅ formatter للفلوس (رقم + . أو , إلى خانتين)
  final TextInputFormatter moneyFmt =
  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}([.,]\d{0,2})?$'));

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
    openingCashCtrl.dispose();
    closingCashCtrl.dispose();
    openingNotesCtrl.dispose();
    closingNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        final Shift? active = shiftCtrl.activeShift.value;
        final bool loading = shiftCtrl.isLoading.value;
        final bool mutating = shiftCtrl.isMutating.value;
        final shifts = shiftCtrl.shifts;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: ActiveShiftPanel(
                  active: active,
                  loading: loading,
                  mutating: mutating,
                  auth: auth,
                  openingCashCtrl: openingCashCtrl,
                  closingCashCtrl: closingCashCtrl,
                  openingNotesCtrl: openingNotesCtrl,
                  closingNotesCtrl: closingNotesCtrl,
                  moneyFormatter: moneyFmt,
                  onRefresh: () => shiftCtrl.loadShifts(),
                  onOpen: () async {
                    final cash = _parseMoney(openingCashCtrl.text);
                    await shiftCtrl.openShift(
                      openingCash: cash,
                      notes: openingNotesCtrl.text,
                    );
                    // ✅ نظّف بعد العملية
                    openingCashCtrl.text = '0';
                    openingNotesCtrl.clear();
                  },
                  onClose: () async {
                    final cash = _parseMoney(closingCashCtrl.text);
                    await shiftCtrl.closeShift(
                      closingCash: cash,
                      notes: closingNotesCtrl.text,
                    );
                    // ✅ نظّف بعد العملية
                    closingCashCtrl.text = '0';
                    closingNotesCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: ShiftHistoryPanel(
                  loading: loading,
                  shifts: shifts,
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
// LEFT PANEL: Active shift
// ==============================
class ActiveShiftPanel extends StatelessWidget {
  const ActiveShiftPanel({
    super.key,
    required this.active,
    required this.loading,
    required this.mutating,
    required this.auth,
    required this.openingCashCtrl,
    required this.closingCashCtrl,
    required this.openingNotesCtrl,
    required this.closingNotesCtrl,
    required this.moneyFormatter,
    required this.onRefresh,
    required this.onOpen,
    required this.onClose,
  });

  final Shift? active;
  final bool loading;
  final bool mutating;
  final AuthController auth;

  final TextEditingController openingCashCtrl;
  final TextEditingController closingCashCtrl;

  final TextEditingController openingNotesCtrl;
  final TextEditingController closingNotesCtrl;

  final TextInputFormatter moneyFormatter;

  final VoidCallback onRefresh;
  final Future<void> Function() onOpen;
  final Future<void> Function() onClose;

  String _money(num v) => NumberFormat('#,##0.00', 'en').format(v);
  String _dt(DateTime? d) => d == null ? '--' : DateFormat('yyyy-MM-dd  HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final canOpen = auth.can('shifts.open');
    final canClose = auth.can('shifts.close');

    return _GradientCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _HeaderIcon(icon: Icons.schedule_rounded),
                    const SizedBox(width: 10),
                    const Text('الوردية النشطة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              IconButton(
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'تحديث',
              )
            ],
          ),
          const SizedBox(height: 12),

          if (active == null) ...[
            _InfoBanner(
              icon: Icons.schedule_rounded,
              text: mutating ? 'جاري التنفيذ...' : 'لا توجد وردية نشطة حالياً',
              tone: BannerTone.warning,
            ),
            const SizedBox(height: 12),

            const _SectionTitle('فتح وردية'),
            const SizedBox(height: 8),

            MoneyField(
              controller: openingCashCtrl,
              label: 'رصيد افتتاح (د.ل)',
              enabled: !mutating,
              formatter: moneyFormatter,
            ),
            const SizedBox(height: 10),

            NotesField(
              controller: openingNotesCtrl,
              enabled: !mutating,
              label: 'ملاحظات فتح (اختياري)',
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (!canOpen || mutating) ? null : onOpen,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('فتح'),
              ),
            ),
          ] else ...[
            _ActiveShiftSummaryCard(active!, money: _money, dt: _dt),
            const SizedBox(height: 14),
            const SizedBox(height: 10),
            _InsuranceCollectButton(
              enabled: !mutating && auth.can('shifts.close'), // أو حط permission خاص: insurance.collect
              onCollect: (amount, method, note) async {
                await Get.find<ShiftController>().collectInsuranceOnShift(
                  amount: amount,
                  method: method,
                  note: note,
                );
              },
            ),

            const _SectionTitle('إغلاق وردية'),
            const SizedBox(height: 8),

            _CashExpectedHint(
              openingCash: active!.openingCash,
              cashTotal: active!.cashTotal,
              money: _money,
            ),
            const SizedBox(height: 14),

            MoneyField(
              controller: closingCashCtrl,
              label: 'الكاش داخل الدرج (د.ل)',
              enabled: !mutating,
              formatter: moneyFormatter,
            ),
            const SizedBox(height: 10),

            NotesField(
              controller: closingNotesCtrl,
              enabled: !mutating,
              label: 'ملاحظات إغلاق (اختياري)',
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: (!canClose || mutating) ? null : onClose,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('إغلاق'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _InsuranceCollectButton extends StatelessWidget {
  const _InsuranceCollectButton({
    required this.enabled,
    required this.onCollect,
  });

  final bool enabled;
  final Future<void> Function(double amount, PaymentMethod method, String? note) onCollect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: !enabled
            ? null
            : () async {
          final res = await showDialog<_CollectInsuranceResult>(
            context: context,
            builder: (_) => const _CollectInsuranceDialog(),
          );
          if (res == null) return;
          await onCollect(res.amount, res.method, res.note);
        },
        icon: const Icon(Icons.health_and_safety_rounded),
        label: const Text('تحصيل تأمين'),
      ),
    );
  }
}

class _CollectInsuranceResult {
  final double amount;
  final PaymentMethod method;
  final String? note;
  _CollectInsuranceResult(this.amount, this.method, this.note);
}

class _CollectInsuranceDialog extends StatefulWidget {
  const _CollectInsuranceDialog();

  @override
  State<_CollectInsuranceDialog> createState() => _CollectInsuranceDialogState();
}

class _CollectInsuranceDialogState extends State<_CollectInsuranceDialog> {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  PaymentMethod method = PaymentMethod.cash;

  double _parseMoney(String s) {
    final t = s.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0.0;
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
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
            const Text('تحصيل التأمين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),

            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ (د.ل)',
                filled: true,
                fillColor: Colors.white.withOpacity(.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<PaymentMethod>(
              value: method,
              items: const [
                DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش')),
                DropdownMenuItem(value: PaymentMethod.card, child: Text('بطاقة')),
              ],
              onChanged: (v) => setState(() => method = v ?? PaymentMethod.cash),
              decoration: InputDecoration(
                labelText: 'طريقة التحصيل',
                filled: true,
                fillColor: Colors.white.withOpacity(.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                filled: true,
                fillColor: Colors.white.withOpacity(.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = _parseMoney(amountCtrl.text);
                      if (amount <= 0) return;
                      Navigator.pop(context, _CollectInsuranceResult(amount, method, noteCtrl.text.trim()));
                    },
                    child: const Text('تحصيل'),
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

class _ActiveShiftSummaryCard extends StatelessWidget {
  const _ActiveShiftSummaryCard(this.shift, {required this.money, required this.dt});

  final Shift shift;
  final String Function(num) money;
  final String Function(DateTime?) dt;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        border: Border.all(color: Colors.blue.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('وردية مفتوحة', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('وقت الفتح: ${dt(shift.openedAt)}', style: TextStyle(color: Colors.grey[800])),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('كاش (مبيعات)', '${money(shift.cashTotal)} د.ل'),
              const SizedBox(width: 10),
              stat('بطاقة', '${money(shift.cardTotal)} د.ل'),
              const SizedBox(width: 10),
              stat('تأمين (فواتير)', '${money(shift.insuranceBilledTotal)} د.ل'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat('تأمين (محصّل)', '${money(shift.insuranceCollectedTotal)} د.ل'),
              const SizedBox(width: 10),
              stat('تأمين (متبقي)', '${money(shift.insurancePendingTotal)} د.ل'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat('الإجمالي', '${money(shift.grandTotal)} د.ل'),
              const SizedBox(width: 10),
              stat('عدد الفواتير', '${shift.salesCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashExpectedHint extends StatelessWidget {
  const _CashExpectedHint({
    required this.openingCash,
    required this.cashTotal,
    required this.money,
  });

  final double openingCash;
  final double cashTotal;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    final expected = openingCash + cashTotal;

    return _InfoBanner(
      icon: Icons.info_outline_rounded,
      text:
      'المفروض الكاش في الدرج ≈ (افتتاح ${money(openingCash)}) + (مبيعات كاش ${money(cashTotal)}) = ${money(expected)} د.ل',
      tone: BannerTone.info,
    );
  }
}

// ==============================
// RIGHT PANEL: History
// ==============================
class ShiftHistoryPanel extends StatelessWidget {
  const ShiftHistoryPanel({super.key, required this.loading, required this.shifts});

  final bool loading;
  final List<Shift> shifts;

  String _money(num v) => NumberFormat('#,##0.00', 'en').format(v);
  String _dt(DateTime? d) => d == null ? '--' : DateFormat('yyyy-MM-dd  HH:mm').format(d);

  Widget _diffChip(double diff) {
    final isOk = diff.abs() < 0.0001;
    final isPlus = diff > 0;

    final bg = isOk ? Colors.green[50] : (isPlus ? Colors.orange[50] : Colors.red[50]);
    final fg = isOk ? Colors.green[800] : (isPlus ? Colors.orange[800] : Colors.red[800]);

    final label = isOk
        ? 'مطابق'
        : (isPlus ? 'زيادة ${diff.toStringAsFixed(2)}' : 'عجز ${diff.abs().toStringAsFixed(2)}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }

  Widget _tileDesktop(Shift s, bool open) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.blue.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: open ? Colors.blue[50] : Colors.blueGrey[50],
            child: Icon(
              open ? Icons.play_arrow_rounded : Icons.check_rounded,
              color: open ? Colors.blue[700] : Colors.blueGrey,
            ),
          ),
          const SizedBox(width: 14),

          // ✅ الجزء الأوسط (العنوان + الأوقات)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open ? 'وردية مفتوحة' : 'وردية مغلقة',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text('فتح: ${_dt(s.openedAt)}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                Text('إغلاق: ${_dt(s.closedAt)}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ✅ الجزء اليمين (الإجمالي + الحالة)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الإجمالي: ${_money(s.grandTotal)} د.ل',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),

              if (!open) _diffChip(s.drawerDiff),

              if (open)
                Text(
                  'فواتير: ${s.salesCount}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tileMobile(Shift s, bool open) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.blue.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: open ? Colors.blue[50] : Colors.blueGrey[50],
                child: Icon(
                  open ? Icons.play_arrow_rounded : Icons.check_rounded,
                  color: open ? Colors.blue[700] : Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(open ? 'وردية مفتوحة' : 'وردية مغلقة',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              if (!open) _diffChip(s.drawerDiff),
            ],
          ),
          const SizedBox(height: 10),

          Text('فتح: ${_dt(s.openedAt)}', style: TextStyle(color: Colors.grey[700])),
          Text('إغلاق: ${_dt(s.closedAt)}', style: TextStyle(color: Colors.grey[700])),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الإجمالي: ${_money(s.grandTotal)} د.ل',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (open)
                Text('فواتير: ${s.salesCount}',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _GradientCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _HeaderIcon(icon: Icons.history_rounded),
              const SizedBox(width: 10),
              const Text('سجل الورديات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),

          if (loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (shifts.isEmpty)
            const Expanded(child: Center(child: Text('لا توجد ورديات بعد', style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // ✅ حدّد نقطة التحول
                  final isWide = c.maxWidth >= 700;

                  return ListView.separated(
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = shifts[i];
                      final open = s.status == ShiftStatus.open;

                      return isWide ? _tileDesktop(s, open) : _tileMobile(s, open);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================
// Reusable small widgets
// ==============================
class _GradientCardShell extends StatelessWidget {
  const _GradientCardShell({required this.child});

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900));
  }
}

class NotesField extends StatelessWidget {
  const NotesField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.formatter,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [formatter],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(.85),
        prefixIcon: const Icon(Icons.payments_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
    final Color border = tone == BannerTone.warning
        ? Colors.orange.withOpacity(.25)
        : Colors.blue.withOpacity(.25);
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
