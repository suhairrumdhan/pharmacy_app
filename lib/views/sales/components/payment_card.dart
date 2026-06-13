import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../controllers/sales_controller.dart';
import '../../../models/insurance_company_model.dart';
import '../../../models/sales_model.dart';

class PaymentCard extends StatefulWidget {
  final SalesController salesController;

  const PaymentCard({
    super.key,
    required this.salesController,
  });

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  late final TextEditingController _receivedCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _refundCashCtrl;
  late final TextEditingController _refundCardCtrl;

  late final FocusNode _receivedFocus;
  late final FocusNode _discountFocus;
  late final FocusNode _refundCashFocus;
  late final FocusNode _refundCardFocus;
  late final FocusNode _customerNameFocus;
  late final FocusNode _customerPhoneFocus;
  late final FocusNode _notesFocus;

  bool _selfChange = false;

  SalesController get salesController => widget.salesController;

  @override
  void initState() {
    super.initState();

    _receivedCtrl = TextEditingController();
    _discountCtrl = TextEditingController();
    _refundCashCtrl = TextEditingController();
    _refundCardCtrl = TextEditingController();

    _receivedFocus = FocusNode();
    _discountFocus = FocusNode();
    _refundCashFocus = FocusNode();
    _refundCardFocus = FocusNode();
    _customerNameFocus = FocusNode();
    _customerPhoneFocus = FocusNode();
    _notesFocus = FocusNode();

    for (final node in [
      _receivedFocus,
      _discountFocus,
      _refundCashFocus,
      _refundCardFocus,
      _customerNameFocus,
      _customerPhoneFocus,
      _notesFocus,
    ]) {
      node.addListener(() {
        if (!mounted) return;

        if (node.hasFocus) {
          salesController.pauseAutoFocus();
        } else {
          final anyFocused = _receivedFocus.hasFocus ||
              _discountFocus.hasFocus ||
              _refundCashFocus.hasFocus ||
              _refundCardFocus.hasFocus ||
              _customerNameFocus.hasFocus ||
              _customerPhoneFocus.hasFocus ||
              _notesFocus.hasFocus;

          if (!anyFocused) {
            salesController.resumeAutoFocus();
            salesController.focusSearchIfAllowed();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    _discountCtrl.dispose();
    _refundCashCtrl.dispose();
    _refundCardCtrl.dispose();

    _receivedFocus.dispose();
    _discountFocus.dispose();
    _refundCashFocus.dispose();
    _refundCardFocus.dispose();
    _customerNameFocus.dispose();
    _customerPhoneFocus.dispose();
    _notesFocus.dispose();

    super.dispose();
  }

  double _parse(String v) {
    return double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;
  }

  String _lyd(double v) => '${v.toStringAsFixed(2)} د.ل';

  void _syncSaleFields(Sale sale) {
    if (_selfChange) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _selfChange = true;

      if (!_discountFocus.hasFocus) {
        final discount = sale.discount ?? 0.0;
        final text = discount > 0 ? discount.toStringAsFixed(2) : '';
        if (_discountCtrl.text != text) {
          _discountCtrl.text = text;
        }
      }

      if (!_receivedFocus.hasFocus &&
          sale.customerPaymentMethod == PaymentMethod.cash &&
          !salesController.refundMode.value) {
        final due = sale.customerPaidAmount;
        final text = due.toStringAsFixed(2);

        if (_receivedCtrl.text != text) {
          _receivedCtrl.text = text;
          salesController.setCashReceived(due);
        }
      }

      if (!_refundCashFocus.hasFocus) {
        final text = salesController.refundCashOut.value > 0
            ? salesController.refundCashOut.value.toStringAsFixed(2)
            : '';
        if (_refundCashCtrl.text != text) {
          _refundCashCtrl.text = text;
        }
      }

      if (!_refundCardFocus.hasFocus) {
        final text = salesController.refundCardOut.value > 0
            ? salesController.refundCardOut.value.toStringAsFixed(2)
            : '';
        if (_refundCardCtrl.text != text) {
          _refundCardCtrl.text = text;
        }
      }

      _selfChange = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final sale = salesController.currentSale.value.recalculate();
          final isRefund = salesController.refundMode.value;
          final isReadOnly =
              sale.isSaved || sale.status == InvoiceStatus.completed;

          _syncSaleFields(sale);

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: isRefund
                ? _buildRefundPanel(sale, isReadOnly: isReadOnly)
                : _buildSalePanel(sale, isReadOnly: isReadOnly),
          );
        }),
      ),
    );
  }

  Widget _buildSalePanel(Sale sale, {required bool isReadOnly}) {
    final subtotal = sale.subtotal;
    final discount = (sale.discount ?? 0.0).clamp(0.0, subtotal);
    final insuranceAmount = sale.companyBilledAmount;
    final customerDue = sale.customerPaidAmount;
    final currentMethod = sale.customerPaymentMethod;
    final received = salesController.cashReceived.value;
    final change = received > customerDue ? received - customerDue : 0.0;
    final remaining = customerDue > received ? customerDue - received : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          isReadOnly ? 'الدفع - عرض فقط' : 'الدفع',
          Iconsax.wallet_3,
          isReadOnly ? Colors.grey : Colors.blue,
        ),

        const SizedBox(height: 14),

        _summaryBox(
          children: [
            _summaryRow('إجمالي الأصناف', _lyd(subtotal)),
            _summaryRow('خصم الفاتورة', _lyd(discount), color: Colors.red),
            if (insuranceAmount > 0)
              _summaryRow(
                'على شركة التأمين',
                _lyd(insuranceAmount),
                color: Colors.indigo,
              ),
            const Divider(height: 18),
            _summaryRow(
              'المطلوب من الزبون',
              _lyd(customerDue),
              bold: true,
              large: true,
              color: Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 14),

        _title('طريقة الدفع', Iconsax.card, Colors.blue),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _methodButton(
                label: 'نقدي',
                icon: Iconsax.money,
                selected: currentMethod == PaymentMethod.cash,
                enabled: !isReadOnly,
                onTap: () {
                  salesController.changePaymentMethod(PaymentMethod.cash);
                  salesController.setCashReceived(customerDue);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _methodButton(
                label: 'معاملة مصرفية',
                icon: Iconsax.card,
                selected: currentMethod == PaymentMethod.card,
                enabled: !isReadOnly,
                onTap: () {
                  salesController.changePaymentMethod(PaymentMethod.card);
                  salesController.setCashReceived(customerDue);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _moneyField(
          label: 'خصم الفاتورة',
          controller: _discountCtrl,
          focusNode: _discountFocus,
          icon: Iconsax.discount_shape,
          enabled: !isReadOnly,
          onChanged: (value) {
            if (_selfChange) return;

            final discountValue = _parse(value).clamp(0.0, subtotal);
            salesController.applyDiscount(discountValue);

            final updatedDue =
                salesController.currentSale.value.recalculate().customerPaidAmount;

            if (currentMethod == PaymentMethod.cash) {
              salesController.setCashReceived(updatedDue);
            }
          },
        ),

        const SizedBox(height: 14),

        if (currentMethod == PaymentMethod.cash) ...[
          _moneyField(
            label: 'المبلغ المستلم من الزبون',
            controller: _receivedCtrl,
            focusNode: _receivedFocus,
            icon: Iconsax.money_recive,
            enabled: !isReadOnly,
            onChanged: (value) {
              if (_selfChange) return;
              salesController.setCashReceived(_parse(value));
            },
          ),

          const SizedBox(height: 10),

          if (change > 0)
            _statusLine(
              icon: Iconsax.money_send,
              text: 'الباقي للزبون: ${_lyd(change)}',
              color: Colors.green,
            )
          else if (remaining > 0)
            _statusLine(
              icon: Iconsax.warning_2,
              text: 'الناقص من الزبون: ${_lyd(remaining)}',
              color: Colors.orange,
            )
          else


          const SizedBox(height: 16),
        ],

        _buildInsuranceSection(sale, isReadOnly: isReadOnly),

        const SizedBox(height: 16),

        _buildCustomerSection(isReadOnly: isReadOnly),
      ],
    );
  }

  Widget _buildRefundPanel(Sale sale, {required bool isReadOnly}) {
    final refundTotal = sale.items.fold<double>(
      0.0,
          (sum, item) => sum + item.total,
    );

    final cashOut = salesController.refundCashOut.value;
    final cardOut = salesController.refundCardOut.value;
    final paidOut = cashOut + cardOut;
    final remaining = refundTotal > paidOut ? refundTotal - paidOut : 0.0;
    final over = paidOut > refundTotal ? paidOut - refundTotal : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          isReadOnly ? 'تفاصيل الترجيع - عرض فقط' : 'تفاصيل الترجيع',
          Iconsax.undo,
          Colors.orange,
        ),

        const SizedBox(height: 14),

        _summaryBox(
          color: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          children: [
            _summaryRow('قيمة الأصناف المرجعة', _lyd(refundTotal)),
            _summaryRow('كاش خارج', _lyd(cashOut)),
            _summaryRow('مصرفي خارج', _lyd(cardOut)),
            const Divider(height: 18),
            _summaryRow(
              'إجمالي المصروف',
              _lyd(paidOut),
              bold: true,
              large: true,
              color: Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 14),

        _moneyField(
          label: 'كاش خارج',
          controller: _refundCashCtrl,
          focusNode: _refundCashFocus,
          icon: Iconsax.money_send,
          color: Colors.orange,
          enabled: !isReadOnly,
          onChanged: (value) {
            salesController.refundCashOut.value = _parse(value);
          },
        ),

        const SizedBox(height: 10),

        _moneyField(
          label: 'معاملة مصرفية خارجة',
          controller: _refundCardCtrl,
          focusNode: _refundCardFocus,
          icon: Iconsax.card_remove,
          color: Colors.orange,
          enabled: !isReadOnly,
          onChanged: (value) {
            salesController.refundCardOut.value = _parse(value);
          },
        ),

        const SizedBox(height: 12),

        if (over > 0)
          _statusLine(
            icon: Iconsax.warning_2,
            text: 'المبلغ الخارج أكبر من قيمة الترجيع بـ ${_lyd(over)}',
            color: Colors.red,
          )
        else if (remaining > 0)
          _statusLine(
            icon: Iconsax.info_circle,
            text: 'متبقي من قيمة الترجيع: ${_lyd(remaining)}',
            color: Colors.orange,
          )
        else if (refundTotal > 0)
            _statusLine(
              icon: Iconsax.tick_circle,
              text: 'العملية صحيحة',
              color: Colors.green,
            ),

        const SizedBox(height: 16),

        _buildCustomerSection(isReadOnly: isReadOnly),
      ],
    );
  }

  Widget _buildInsuranceSection(
      Sale sale, {
        required bool isReadOnly,
      }) {
    final selected = salesController.selectedInsuranceCompany.value;
    final companies = salesController.insuranceCompanies;
    final hasInsurance = selected != null && sale.companyBilledAmount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('التأمين اختياري', Iconsax.shield_tick, Colors.indigo),
        const SizedBox(height: 10),

        if (hasInsurance) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.withOpacity(.18)),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.shield_tick,
                  size: 18,
                  color: Colors.indigo.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selected.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.indigo.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: isReadOnly
                      ? null
                      : () {
                    salesController.selectInsuranceCompany(null);

                    final due = salesController.currentSale.value
                        .recalculate()
                        .customerPaidAmount;

                    if (salesController
                        .currentSale.value.customerPaymentMethod ==
                        PaymentMethod.cash) {
                      salesController.setCashReceived(due);
                    }
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('إلغاء'),
                  style: TextButton.styleFrom(
                    foregroundColor: isReadOnly
                        ? Colors.grey
                        : Colors.red.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _statusLine(
            icon: Iconsax.shield_tick,
            text:
            'على التأمين: ${_lyd(sale.companyBilledAmount)} | على الزبون: ${_lyd(sale.customerPaidAmount)}',
            color: Colors.indigo,
          ),

          const SizedBox(height: 10),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InsuranceCompany>(
              value: selected,
              isExpanded: true,
              hint: const Text('اختر شركة التأمين'),
              items: companies.map(
                    (company) {
                  return DropdownMenuItem<InsuranceCompany>(
                    value: company,
                    child: Text(
                      '${company.name} - ${company.discountPercentage.toStringAsFixed(1)}%',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged: isReadOnly
                  ? null
                  : (company) {
                if (company == null) return;

                salesController.selectInsuranceCompany(company);

                final due = salesController.currentSale.value
                    .recalculate()
                    .customerPaidAmount;

                if (salesController
                    .currentSale.value.customerPaymentMethod ==
                    PaymentMethod.cash) {
                  salesController.setCashReceived(due);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection({
    required bool isReadOnly,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Icon(Iconsax.user, color: Colors.blue.shade700, size: 20),
      title: Text(
        isReadOnly ? 'معلومات الزبون' : 'معلومات الزبون (اختياري)',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
      ),
      children: [
        const SizedBox(height: 8),

        _textField(
          label: 'اسم الزبون',
          controller: salesController.customerNameController,
          focusNode: _customerNameFocus,
          icon: Iconsax.user,
          enabled: !isReadOnly,
        ),

        const SizedBox(height: 10),

        _textField(
          label: 'رقم الهاتف',
          controller: salesController.customerPhoneController,
          focusNode: _customerPhoneFocus,
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
          enabled: !isReadOnly,
        ),

        const SizedBox(height: 10),

        _textField(
          label: 'ملاحظات',
          controller: salesController.notesController,
          focusNode: _notesFocus,
          icon: Iconsax.note_text,
          maxLines: 3,
          enabled: !isReadOnly,
        ),
      ],
    );
  }

  Widget _title(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _summaryBox({
    required List<Widget> children,
    Color? color,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.blue.shade50.withOpacity(.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.blue.shade100,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
        bool large = false,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: large ? 14 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 17 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: selected
              ? (enabled ? Colors.blue.shade700 : Colors.grey.shade400)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (enabled ? Colors.blue.shade700 : Colors.grey.shade400)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required ValueChanged<String> onChanged,
    Color color = Colors.blue,
    bool enabled = true,
  }) {
    return TextField(
      enabled: enabled,
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: enabled ? salesController.pauseAutoFocus : null,
      onChanged: enabled ? onChanged : null,
// في _moneyField نحّي prefixIcon بالكامل
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'د.ل',
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      enabled: enabled,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onTap: enabled ? salesController.pauseAutoFocus : null,
// في _textField نحّي prefixIcon بالكامل
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),

    );
  }

  // في _statusLine خليه بدون أيقونة
  Widget _statusLine({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}