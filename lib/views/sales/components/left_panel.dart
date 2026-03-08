import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';
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
  // استبدل ScrollController بـ GlobalKey
  final GlobalKey _resultsListKey = GlobalKey();

  void _onMedicineAdded(Medicine medicine) {
    // الطريقة الآمنة - استخدام PostFrameCallback للانتظار حتى يكون الـ Widget جاهزاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsListKey.currentContext;
      if (context != null && context.mounted) {
        // استخدم Scrollable.ensureVisible بدلاً من ScrollController.animateTo
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.1, // تمرير قليلاً للأعلى لإظهار العنصر
        );
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // ==============================
        // 🔹 Refund Toggle Header
        // ==============================
        Obx(() {
          final isRefund = widget.salesController.refundMode.value;
          final loaded = widget.salesController.originalSale.value != null;

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

                // عنوان
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

                // ✅ حقل رقم الفاتورة يظهر فقط في Refund Mode
                if (isRefund) ...[
                  const SizedBox(width: 10),

                  // Input + زر تحميل
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Icon(Icons.receipt_long, color: Colors.white.withOpacity(0.95), size: 18),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Autocomplete<String>(
                              optionsBuilder: (TextEditingValue v) {
                                final q = v.text.trim().toLowerCase();
                                if (q.isEmpty) return const Iterable<String>.empty();

                                final list = widget.salesController.completedInvoiceSuggestions;
                                return list.where((inv) => inv.toLowerCase().contains(q)).take(8);
                              },
                              onSelected: (selected) {
                                widget.salesController.refundInvoiceController.text = selected;
                                widget.salesController.loadOriginalInvoiceForRefund();
                              },
                              fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                // نخلي نفس controller اللي عندك في الكنترولر
                                widget.salesController.refundInvoiceController.value = textController.value;

                                return TextField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    hintText: 'اكتب INV- أو جزء من الرقم...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onSubmitted: (_) => widget.salesController.loadOriginalInvoiceForRefund(),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topRight,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 260),
                                      child: ListView.separated(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: options.length,
                                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                        itemBuilder: (context, i) {
                                          final opt = options.elementAt(i);
                                          return ListTile(
                                            dense: true,
                                            title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            leading: Icon(Icons.receipt_long, color: Colors.blue.shade700),
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
                          // زر تحميل
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => widget.salesController.loadOriginalInvoiceForRefund(),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.download_done, size: 18, color: Colors.white.withOpacity(0.95)),
                                  const SizedBox(width: 6),
                                  Text(
                                    loaded ? 'تم' : 'تحميل',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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

                  // مؤشر حالة (✅ / ⚠️)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: loaded
                          ? Colors.white.withOpacity(0.22)
                          : Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(loaded ? 0.30 : 0.18),
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

                // زر تفعيل/إلغاء الترجيع
                GestureDetector(
                  onTap: () => widget.salesController.toggleRefundMode(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        }),
        // ==============================
        // 🔹 Search Card
        // ==============================
        SearchCard(
          salesController: widget.salesController,
          onMedicineAdded: _onMedicineAdded,
        ),

        const SizedBox(height: 12),

        // ==============================
        // 🔹 Results
        // ==============================
        Expanded(
          child: SearchResultsCard(
            key: _resultsListKey,
            salesController: widget.salesController,
            onMedicineSelected: _onMedicineAdded,
          ),
        ),

        const SizedBox(height: 12),

        // ==============================
        // 🔹 Current Sale
        // ==============================
        Expanded(
          flex: 2,
          child: CurrentSaleCard(
            salesController: widget.salesController,
          ),
        ),
      ],
    );
  }
  @override
  void dispose() {
    // لا حاجة لتنظيف ScrollController بعد الآن
    super.dispose();
  }
}