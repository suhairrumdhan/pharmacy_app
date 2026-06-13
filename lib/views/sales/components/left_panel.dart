import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/inventory_controller.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';
import '../../../models/sales_model.dart';

import 'search_card.dart';
import 'search_results_card.dart';
import 'current_sale_card.dart';

class LeftPanel extends StatefulWidget {
  final SalesController salesController;
  final InventoryController inventoryController;

  const LeftPanel({
    super.key,
    required this.salesController,
    required this.inventoryController,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  final GlobalKey _resultsListKey = GlobalKey();

  void _onMedicineAdded(Medicine medicine) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsListKey.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RefundToggleHeader(
          salesController: widget.salesController,
        ),

        _RefundOriginalInvoiceCard(
          salesController: widget.salesController,
        ),

        Expanded(
          flex: 3,
          child: Obx(() {
            final isRefund = widget.salesController.refundMode.value;
            final originalLoaded =
                widget.salesController.originalSale.value != null;

            if (isRefund && originalLoaded) {
              return RefundOriginalItemsCard(
                salesController: widget.salesController,
              );
            }

            return Column(
              children: [
                SearchCard(
                  salesController: widget.salesController,
                  onMedicineAdded: _onMedicineAdded,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SearchResultsCard(
                    key: _resultsListKey,
                    salesController: widget.salesController,
                    onMedicineSelected: _onMedicineAdded,
                  ),
                ),
              ],
            );
          }),
        ),

        const SizedBox(height: 12),

        Expanded(
          flex: 2,
          child: CurrentSaleCard(
            salesController: widget.salesController,
          ),
        ),
      ],
    );
  }
}

class _RefundToggleHeader extends StatelessWidget {
  final SalesController salesController;

  const _RefundToggleHeader({
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isRefund = salesController.refundMode.value;
      final loaded = salesController.originalSale.value != null;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRefund
                ? [Colors.blue.shade800, Colors.blue.shade600]
                : [Colors.blue.shade600, Colors.blue.shade400],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isRefund ? Icons.keyboard_return : Icons.point_of_sale,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),

            Expanded(
              flex: isRefund ? 2 : 5,
              child: Text(
                isRefund ? 'وضع الترجيع مفعل' : 'وضع البيع',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            if (isRefund) ...[
              const SizedBox(width: 10),

              Expanded(
                flex: 5,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Icon(
                        Icons.receipt_long,
                        color: Colors.white.withOpacity(0.95),
                        size: 18,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue v) {
                            final q = v.text.trim().toLowerCase();
                            if (q.isEmpty) {
                              return const Iterable<String>.empty();
                            }

                            final list =
                                salesController.completedInvoiceSuggestions;

                            return list
                                .where(
                                  (inv) =>
                                  inv.toLowerCase().contains(q),
                            )
                                .take(8);
                          },
                          onSelected: (selected) {
                            salesController.refundInvoiceController.text =
                                selected;
                            salesController.loadOriginalInvoiceForRefund();
                          },
                          fieldViewBuilder: (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                              ) {
                            salesController.refundInvoiceController.value =
                                textController.value;

                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: 'اكتب INV- أو جزء من الرقم...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => salesController
                                  .loadOriginalInvoiceForRefund(),
                            );
                          },
                          optionsViewBuilder: (
                              context,
                              onSelected,
                              options,
                              ) {
                            return Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                    maxHeight: 260,
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                    itemBuilder: (context, i) {
                                      final opt = options.elementAt(i);

                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          opt,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        leading: Icon(
                                          Icons.receipt_long,
                                          color: Colors.blue.shade700,
                                        ),
                                        onTap: () => onSelected(opt),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            salesController.loadOriginalInvoiceForRefund(),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.download_done,
                                size: 18,
                                color: Colors.white.withOpacity(0.95),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                loaded ? 'تم' : 'تحميل',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: loaded
                      ? Colors.white.withOpacity(0.22)
                      : Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      loaded ? 0.30 : 0.18,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      loaded ? Icons.verified : Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loaded ? 'فاتورة جاهزة' : 'حمّل الأصل',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(width: 10),

            GestureDetector(
              onTap: () => salesController.toggleRefundMode(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isRefund ? 'إلغاء الترجيع' : 'تفعيل الترجيع',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _RefundOriginalInvoiceCard extends StatelessWidget {
  final SalesController salesController;

  const _RefundOriginalInvoiceCard({
    required this.salesController,
  });

  String _money(num v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isRefund = salesController.refundMode.value;
      final original = salesController.originalSale.value;

      if (!isRefund) return const SizedBox.shrink();

      if (original == null) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withOpacity(.25)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'حمّل الفاتورة الأصلية أولًا حتى تظهر أصنافها القابلة للترجيع.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(.075),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفاتورة الأصلية #${original.invoiceNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _miniInfo('الأصناف', '${original.items.length}'),
                      _miniInfo(
                        'دفع الزبون',
                        '${_money(original.customerPaidAmount)} د.ل',
                      ),
                      if (original.companyBilledAmount > 0)
                        _miniInfo(
                          'على التأمين',
                          '${_money(original.companyBilledAmount)} د.ل',
                        ),
                      _miniInfo('الموظف', original.employeeName ?? '--'),
                    ],
                  ),
                ],
              ),
            ),

            TextButton.icon(
              onPressed: () {
                salesController.originalSale.value = null;
                salesController.refundInvoiceController.clear();
                salesController.searchResults.clear();
                salesController.currentSale.value = salesController
                    .currentSale.value
                    .copyWith(items: [])
                    .recalculate();
              },
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('إلغاء'),
            ),
          ],
        ),
      );
    });
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.orange.withOpacity(.15)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class RefundOriginalItemsCard extends StatelessWidget {
  final SalesController salesController;

  const RefundOriginalItemsCard({
    super.key,
    required this.salesController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final original = salesController.originalSale.value;

      if (original == null) {
        return const SizedBox.shrink();
      }

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_return_rounded,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'اختر الأصناف المراد ترجيعها',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${original.items.length} صنف',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: original.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = original.items[index];

                    return _RefundItemTile(
                      item: item,
                      salesController: salesController,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _RefundItemTile extends StatelessWidget {
  final SaleItem item;
  final SalesController salesController;

  const _RefundItemTile({
    required this.item,
    required this.salesController,
  });
  Future<int?> _showRefundQtyDialog(
      BuildContext context, {
        required int maxQty,
      }) async {
    int qty = 1;

    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.keyboard_return_rounded,
                        color: Colors.orange.shade800,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'المتاح للترجيع: $maxQty',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: qty <= 1
                              ? null
                              : () => setState(() => qty--),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red.shade600,
                          iconSize: 34,
                        ),

                        Container(
                          width: 76,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.withOpacity(.22),
                            ),
                          ),
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: qty >= maxQty
                              ? null
                              : () => setState(() => qty++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.green.shade700,
                          iconSize: 34,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

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
                            onPressed: () => Navigator.pop(context, qty),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'تأكيد',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _money(num v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final alreadyInRefund = salesController.currentSale.value.items
          .where(
            (x) =>
        x.medicineId == item.medicineId &&
            x.sellAsPiece == item.sellAsPiece,
      )
          .fold<int>(0, (sum, x) => sum + x.quantity);

      final availableNow = item.quantity - alreadyInRefund;
      final disabled = availableNow <= 0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : Colors.orange.withOpacity(.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_liquid_rounded,
                color: disabled ? Colors.grey : Colors.orange.shade800,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: disabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.sellAsPiece ? 'قطعة' : 'علبة'} • السعر ${_money(item.unitPrice)} د.ل • المباعة ${item.quantity} • المتاح $availableNow',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            ElevatedButton.icon(
              onPressed: disabled
                  ? null
                  : () async {
                final qty = await _showRefundQtyDialog(
                  context,
                  maxQty: availableNow,
                );

                if (qty == null || qty <= 0) return;

                await salesController.addRefundItemFromOriginal(
                  item,
                  quantity: qty,
                );
              },
              icon: const Icon(Icons.keyboard_return_rounded, size: 17),
              label: Text(
                disabled ? 'تم' : 'ترجيع',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}