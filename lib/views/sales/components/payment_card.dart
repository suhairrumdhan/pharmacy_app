import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/insurance_company_model.dart';
import '../../../models/sales_model.dart';

class PaymentCard extends StatefulWidget {
  final SalesController salesController;

  const PaymentCard({super.key, required this.salesController});

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  late final TextEditingController _receivedCtrl;
  late final FocusNode _receivedFocus;

  late final FocusNode _customerNameFocus;
  late final FocusNode _customerPhoneFocus;
  late final FocusNode _notesFocus;

  bool _selfChange = false; // يمنع loop لما نعدّل النص برمجيًا

  String _lyd(double v) => '${v.toStringAsFixed(2)} د.ل';

  SalesController get salesController => widget.salesController;

  @override
  void initState() {
    super.initState();
    _receivedCtrl = TextEditingController();
    _receivedFocus = FocusNode();

    _customerNameFocus = FocusNode();
    _customerPhoneFocus = FocusNode();
    _notesFocus = FocusNode();

    // لما أي حقل ياخذ فوكس -> وقف auto focus search
    void attachPauseResume(FocusNode node) {
      node.addListener(() {
        if (!mounted) return;

        if (node.hasFocus) {
          salesController.pauseAutoFocus();
        } else {
          // رجعها مسموحة + رجّع الفوكس للبحث لو ما فيش حقل ثاني مركز
          final anyOtherFocused = _receivedFocus.hasFocus ||
              _customerNameFocus.hasFocus ||
              _customerPhoneFocus.hasFocus ||
              _notesFocus.hasFocus;

          if (!anyOtherFocused) {
            salesController.resumeAutoFocus();
            salesController.focusSearchIfAllowed();
          }
        }
      });
    }

    attachPauseResume(_receivedFocus);
    attachPauseResume(_customerNameFocus);
    attachPauseResume(_customerPhoneFocus);
    attachPauseResume(_notesFocus);
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    _receivedFocus.dispose();

    _customerNameFocus.dispose();
    _customerPhoneFocus.dispose();
    _notesFocus.dispose();

    super.dispose();
  }

  void _syncReceivedWithTotalIfNotEditing() {
    if (_receivedFocus.hasFocus) return; // لو الموظف يكتب، ما نغيّرش عليه

    final total = salesController.currentSale.value.total;
    final txt = total.toStringAsFixed(2);

    if (_receivedCtrl.text.trim() == txt) return;

    _selfChange = true;
    _receivedCtrl.text = txt;
    _receivedCtrl.selection = TextSelection.fromPosition(TextPosition(offset: txt.length));
    _selfChange = false;

    // نخلي cashReceived متزامن افتراضيًا مع إجمالي الزبون
    salesController.setCashReceived(total);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + viewInsets),
          child: Obx(() {
            final sale = salesController.currentSale.value;

            final hasInsurance =
                (salesController.selectedInsuranceCompany.value != null) &&
                    (sale.insuranceCompanyId != null && sale.insuranceCompanyId!.trim().isNotEmpty) &&
                    ((sale.insuranceDiscount ?? 0) > 0);

            final companyBilled = hasInsurance ? (sale.insuranceDiscount ?? 0.0) : 0.0;

            // الزبون يدفع هذا (بعد التأمين/الخصم)
            final customerTotal = sale.total;

            // الإجمالي قبل التأمين (بعد خصم الفاتورة)
            final grandTotal = (sale.subtotal - (sale.discount ?? 0.0)).clamp(0.0, double.infinity);

            // للزبون فقط (cash/card) — back-compat: لو legacy insurance رجّعها cash
            final currentMethod = (sale.paymentMethod == PaymentMethod.insurance)
                ? PaymentMethod.cash
                : sale.paymentMethod;

            // ✅ مهم: نخلي حقل المستلم يتزامن مع الإجمالي كل مرة يتغير (لو مش قاعد يكتب)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (currentMethod == PaymentMethod.cash) {
                _syncReceivedWithTotalIfNotEditing();
              }
            });

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدفع',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 12),

                  // طرق دفع الزبون
                  Row(
                    children: [
                      _buildPaymentMethodChip(
                        '💵 نقدي',
                        currentMethod == PaymentMethod.cash,
                            () => salesController.changePaymentMethod(PaymentMethod.cash),
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentMethodChip(
                        '💳 بطاقة',
                        currentMethod == PaymentMethod.card,
                            () => salesController.changePaymentMethod(PaymentMethod.card),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // تفاصيل التأمين (لو موجود)
                  if (hasInsurance) ...[
                    _buildSplitInfo(
                      customerTotal: customerTotal,
                      companyBilled: companyBilled,
                      grandTotal: grandTotal,
                      companyName: sale.insuranceCompanyName,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // =========================
                  // كاش: المبلغ المستلم default = إجمالي الزبون
                  // وإذا تغيّر → يحسب خصم فواتير تلقائي
                  // =========================
                  if (currentMethod == PaymentMethod.cash) ...[
                    Text('المبلغ المستلم (من الزبون)', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        focusNode: _receivedFocus,
                        controller: _receivedCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onTap: () => salesController.pauseAutoFocus(),
                        onChanged: (value) {
                          if (_selfChange) return;

                          final entered = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

                          // الصافي المطلوب (بدون خصم الموظف)
                          final baseTotal = salesController.currentSale.value.recalculate().total;

                          // خصم الموظف = الفرق (لو دخل أقل)
                          double disc = (baseTotal - entered);
                          if (disc < 0) disc = 0; // لو دفع أكثر، ما فيش خصم

                          salesController.manualDiscount.value = disc;

                          // ثم احسب cashReceived والباقي حسب الصافي بعد الخصم
                          salesController.setCashReceived(entered);
                        },                        onEditingComplete: () {
                          _receivedFocus.unfocus();
                          salesController.resumeAutoFocus();
                          salesController.focusSearchIfAllowed();
                        },
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ المستلم',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixText: 'د.ل',
                          suffixStyle: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    // فرق الباقي/الناقص
                    Obx(() {
                      final received = salesController.cashReceived.value;

                      final baseTotal = salesController.currentSale.value.recalculate().total; // الإجمالي الثابت
                      final disc = salesController.manualDiscount.value;                      // خصم الموظف
                      final payable = (baseTotal - disc).clamp(0.0, double.infinity);         // الصافي المطلوب

                      final diff = received - payable;

                      if (diff > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Iconsax.money_send, color: Colors.green[700], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'الباقي للزبون: ${_lyd(diff)}',
                                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      } else if (received > 0 && received < payable) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Iconsax.info_circle, color: Colors.orange[700], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'ناقص من الزبون: ${_lyd(payable - received)}',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    }),
                    // عرض خصم الموظف (لو صار)
                    const SizedBox(height: 10),
                    if ((sale.discount ?? 0) > 0)
                      Row(
                        children: [
                          Icon(Iconsax.discount_shape, size: 16, color: Colors.red[700]),
                          const SizedBox(width: 6),
                          Text(
                            'خصم موظف: ${_lyd(sale.discount ?? 0)}',
                            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),

                    const SizedBox(height: 14),
                  ],

                  // =========================
                  // التأمين (اختياري)
                  // =========================
                  _buildInsuranceSection(hasInsurance: hasInsurance),

                  const SizedBox(height: 16),

                  // =========================
                  // معلومات الزبون (سكرول موجود فوق)
                  // =========================
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    leading: Icon(Iconsax.user, color: Colors.blue[700], size: 20),
                    title: Text('معلومات الزبون (اختياري)', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    children: [
                      Column(
                        children: [
                          _buildCustomerField(
                            '👤 اسم الزبون',
                            salesController.customerNameController,
                            focusNode: _customerNameFocus,
                          ),
                          const SizedBox(height: 8),
                          _buildCustomerField(
                            '📞 رقم الهاتف',
                            salesController.customerPhoneController,
                            focusNode: _customerPhoneFocus,
                          ),
                          const SizedBox(height: 8),

                          // ✅ ملاحظات: صغّر padding + حدّد maxLines
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: TextField(
                              focusNode: _notesFocus,
                              controller: salesController.notesController,
                              maxLines: 3,
                              minLines: 2,
                              onTap: () => salesController.pauseAutoFocus(),
                              onEditingComplete: () {
                                _notesFocus.unfocus();
                                salesController.resumeAutoFocus();
                                salesController.focusSearchIfAllowed();
                              },
                              decoration: InputDecoration(
                                hintText: '💬 ملاحظات إضافية',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // --------- UI Helpers ---------

  Widget _buildInsuranceSection({required bool hasInsurance}) {
    return Obx(() {
      final sale = salesController.currentSale.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.shield_tick, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'التأمين (اختياري)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w600),
                ),
              ),

              // ✅ إلغاء/تفعيل بدون ما يرجع "insurance method"
              TextButton.icon(
                onPressed: () {
                  // لو مفيش تأمين -> افتح الدروب داون بس (تفعيل)
                  if (!hasInsurance) return;

                  salesController.selectInsuranceCompany(null);

                  // لو كانت legacy insurance رجّعها كاش
                  if (sale.paymentMethod == PaymentMethod.insurance) {
                    salesController.changePaymentMethod(PaymentMethod.cash);
                  }

                  // رجّع الفوكس للبحث لو مسموح
                  salesController.resumeAutoFocus();
                  salesController.focusSearchIfAllowed();
                },
                icon: Icon(
                  hasInsurance ? Iconsax.close_circle : Iconsax.add_circle,
                  size: 18,
                  color: hasInsurance ? Colors.red[700] : Colors.blue[700],
                ),
                label: Text(
                  hasInsurance ? 'إلغاء' : 'تفعيل',
                  style: TextStyle(
                    color: hasInsurance ? Colors.red[700] : Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (salesController.insuranceCompanies.isEmpty) ...[
            Text(
              salesController.isLoading.value ? 'جاري التحميل...' : 'لا توجد شركات تأمين',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InsuranceCompany>(
                    value: hasInsurance ? salesController.selectedInsuranceCompany.value : null,
                    items: salesController.insuranceCompanies.map((company) {
                      return DropdownMenuItem(
                        value: company,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Iconsax.shield_tick, size: 12, color: Colors.blue[700]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(company.name, style: const TextStyle(fontSize: 13)),
                                  Text(
                                    'تغطية ${company.discountPercentage}%',
                                    style: TextStyle(fontSize: 11, color: Colors.green[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (company) => salesController.selectInsuranceCompany(company),
                    isExpanded: true,
                    hint: Text('اختر شركة التأمين', style: TextStyle(color: Colors.grey[500])),
                    dropdownColor: Colors.white,
                    icon: Icon(Iconsax.arrow_down_1, color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSplitInfo({
    required double customerTotal,
    required double companyBilled,
    required double grandTotal,
    String? companyName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.receipt_2, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text('تفاصيل التأمين', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _splitRow(label: 'الإجمالي قبل التأمين', value: grandTotal, icon: Iconsax.wallet_1),
          const SizedBox(height: 6),
          _splitRow(label: 'الزبون يدفع', value: customerTotal, icon: Iconsax.money, valueColor: Colors.green[800]),
          const SizedBox(height: 6),
          _splitRow(
            label: 'الشركة تتحمّل${(companyName ?? '').trim().isNotEmpty ? ' ($companyName)' : ''}',
            value: companyBilled,
            icon: Iconsax.shield_tick,
            valueColor: Colors.orange[800],
          ),
        ],
      ),
    );
  }

  Widget _splitRow({
    required String label,
    required double value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[800]))),
        Text(
          _lyd(value),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor ?? Colors.grey[900]),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // لما يختار طريقة دفع، نخلي البحث يرجع فوكس (لو مسموح)
          onTap();
          salesController.resumeAutoFocus();
          salesController.focusSearchIfAllowed();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue[700] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? Colors.blue[700]! : Colors.grey[200]!, width: selected ? 2 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerField(
      String hint,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        FocusNode? focusNode,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        keyboardType: keyboardType,
        onTap: () => salesController.pauseAutoFocus(),
        onEditingComplete: () {
          focusNode?.unfocus();
          salesController.resumeAutoFocus();
          salesController.focusSearchIfAllowed();
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}