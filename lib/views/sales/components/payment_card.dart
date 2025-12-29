import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/insurance_company_model.dart';
import '../../../models/sales_model.dart';

class PaymentCard extends StatelessWidget {
  final SalesController salesController;

  const PaymentCard({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طريقة الدفع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 12),

              // طرق الدفع
              Obx(() {
                final currentMethod = salesController.currentSale.value.paymentMethod;
                return Row(
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
                    const SizedBox(width: 8),
                    _buildPaymentMethodChip(
                      '🏥 تأمين',
                      currentMethod == PaymentMethod.insurance,
                          () => salesController.changePaymentMethod(PaymentMethod.insurance),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // تفاصيل الدفع النقدي
              Obx(() {
                if (salesController.currentSale.value.paymentMethod != PaymentMethod.cash) {
                  return Container();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ المستلم',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0.0;
                          salesController.setCashReceived(amount);
                        },
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ المستلم',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixText: 'ر.س',
                          suffixStyle: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    Obx(() {
                      final change = salesController.changeAmount.value;
                      final received = salesController.cashReceived.value;
                      final total = salesController.currentSale.value.total;

                      if (change > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.money_send,
                                color: Colors.green[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'المبلغ المتبقي: ${change.toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (received > 0 && received < total) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: Colors.orange[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ناقص: ${(total - received).toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container();
                    }),
                  ],
                );
              }),

              // اختيار شركة التأمين
              Obx(() {
                if (salesController.currentSale.value.paymentMethod != PaymentMethod.insurance) {
                  return Container();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'شركة التأمين',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            value: salesController.selectedInsuranceCompany.value,
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
                                      child: Icon(
                                        Iconsax.shield_tick,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            company.name,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          Text(
                                            'خصم ${company.discountPercentage}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green[700],
                                            ),
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
                            hint: Text(
                              'اختر شركة التأمين',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Iconsax.arrow_down_1,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // معلومات الزبون
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                leading: Icon(
                  Iconsax.user,
                  color: Colors.blue[700],
                  size: 20,
                ),
                title: Text(
                  'معلومات الزبون (اختياري)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                children: [
                  Column(
                    children: [
                      _buildCustomerField(
                        '👤 اسم الزبون',
                        salesController.customerNameController,
                      ),
                      const SizedBox(height: 8),
                      _buildCustomerField(
                        '📞 رقم الجوال',
                        salesController.customerPhoneController,
                        TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: salesController.notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: '💬 ملاحظات إضافية',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue[700] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.blue[700]! : Colors.grey[200]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerField(String hint, TextEditingController controller, [TextInputType keyboardType = TextInputType.text]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}