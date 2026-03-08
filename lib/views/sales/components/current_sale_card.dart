import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/sales_model.dart';
import '../dialogs/edit_item_dialog.dart';
import 'sale_item.dart';
import 'package:pharmacy_desktop/views/sales/dialogs/sales_history_dialog.dart';

class CurrentSaleCard extends StatefulWidget {
  final SalesController salesController;

  const CurrentSaleCard({super.key, required this.salesController});

  @override
  State<CurrentSaleCard> createState() => _CurrentSaleCardState();
}

class _CurrentSaleCardState extends State<CurrentSaleCard> {
  final ScrollController _tabsScrollController = ScrollController();

  // ✅ keys لكل تاب (حسب invoiceNumber)
  final Map<String, GlobalKey> _tabKeys = {};

  Timer? _edgeScrollTimer;
  int _edgeDirection = 0; // -1 left, +1 right, 0 stop

  static const double _edgeSize = 70;
  static const double _step = 60;
  static const Duration _tick = Duration(milliseconds: 70);

  @override
  void dispose() {
    _edgeScrollTimer?.cancel();
    _tabsScrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForInvoice(String invoiceNumber) {
    return _tabKeys.putIfAbsent(invoiceNumber, () => GlobalKey());
  }

  void _cleanupTabKeys(List<Sale> activeInvoices) {
    final keep = activeInvoices.map((e) => e.invoiceNumber).toSet();
    _tabKeys.removeWhere((k, _) => !keep.contains(k));
  }

  // ✅ يخلي التاب المختارة تجي في النص/واضحة
  void _scrollToInvoiceTab(String invoiceNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _tabKeys[invoiceNumber];
      final ctx = key?.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _startEdgeScroll(int direction) {
    if (direction == 0) {
      _stopEdgeScroll();
      return;
    }

    _edgeDirection = direction;
    if (_edgeScrollTimer?.isActive == true) return;

    _edgeScrollTimer = Timer.periodic(_tick, (_) async {
      if (!_tabsScrollController.hasClients) return;

      final pos = _tabsScrollController.position;
      final current = _tabsScrollController.offset;

      final target = (current + (_edgeDirection * _step))
          .clamp(pos.minScrollExtent, pos.maxScrollExtent)
          .toDouble();

      if ((target - current).abs() < 1) {
        _stopEdgeScroll();
        return;
      }

      await _tabsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  void _stopEdgeScroll() {
    _edgeDirection = 0;
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
  }

  void _handleHover(PointerHoverEvent event, double width) {
    final dx = event.localPosition.dx;

    if (dx >= width - _edgeSize) {
      _startEdgeScroll(1);
      return;
    }
    if (dx <= _edgeSize) {
      _startEdgeScroll(-1);
      return;
    }
    _stopEdgeScroll();
  }

  void _scrollTabsToEnd() {
    if (!_tabsScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabsScrollController.hasClients) return;
      final max = _tabsScrollController.position.maxScrollExtent;

      _tabsScrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesController = widget.salesController;


    return Obx(() {
      final currentSale = salesController.currentSale.value;
      final activeInvoices = salesController.activeInvoices; // ✅ pending فقط
      final items = currentSale.items;
      final isRefund = salesController.refundMode.value;
      final originalSale = salesController.originalSale.value;
      _cleanupTabKeys(activeInvoices);

      // لون الهيدر بناءً على حالة الفاتورة
      Color headerColor = Colors.blue[50]!;
      Color iconColor = Colors.blue[700]!;
      String statusText = 'قيد التنفيذ';

      if (salesController.refundMode.value) {
        headerColor = Colors.orange[50]!;
        iconColor = Colors.orange[700]!;
        statusText = 'فاتورة ترجيع';
      }

      if (currentSale.isSaved) {
        headerColor = Colors.green[50]!;
        iconColor = Colors.green[700]!;
        statusText = 'مكتملة';
      } else if (currentSale.status == InvoiceStatus.cancelled) {
        headerColor = Colors.red[50]!;
        iconColor = Colors.red[700]!;
        statusText = 'ملغية';
      }

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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    // ✅ الصف الأول: (تاريخ الفواتير هنا) + إلغاء الإحصائيات
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.receipt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isRefund
                                          ? 'فاتورة ترجيع #${currentSale.invoiceNumber}'
                                          : 'فاتورة #${currentSale.invoiceNumber}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: iconColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (currentSale.isSaved) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'محفوظة',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              if (isRefund && originalSale != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.link_1,
                                      size: 14,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'مرتبطة بالفاتورة #${originalSale.invoiceNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 4),
                              Text(
                                '${items.length} أصناف • $statusText',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ✅ زر التاريخ في الصف الأول (تصميم مرتب)
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => SalesHistoryDialog(
                                onOpenInvoice: (sale) {
                                  widget.salesController.switchToInvoice(sale);
                                },
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.receipt_search, size: 18),
                          label: const Text(
                            'تاريخ الفواتير',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[900],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ✅ الصف الثاني: شريط التابات (scroll) + زر فاتورة جديدة ثابت
                    _pendingInvoicesTabsBar(
                      context: context, // ✅ مهم

                      salesController: salesController,
                      activeInvoices: activeInvoices,
                      currentSale: currentSale,
                      currentInvoiceIndex: salesController.currentInvoiceIndex.value,
                      tabsScrollController: _tabsScrollController,
                      keyForInvoice: _keyForInvoice,
                      onTapInvoice: (inv) {
                        salesController.loadInvoiceForEditing(inv);
                        _scrollToInvoiceTab(inv.invoiceNumber);
                      },
                      onHoverEdge: _handleHover,
                      onStopHover: _stopEdgeScroll,
                      onCreateNewInvoice: () {
                        salesController.createNewInvoice();
                        _scrollTabsToEnd(); // يخلي التاب الجديدة تبان بسهولة
                      },
                    ),
                  ],
                ),
              ),

              // Items List or Empty State
              Expanded(
                child: items.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentSale.isSaved
                            ? Iconsax.receipt
                            : Iconsax.shopping_cart,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentSale.isSaved ? 'فاتورة مكتملة' : 'السلة فارغة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSale.isSaved
                            ? 'تم حفظ هذه الفاتورة'
                            : 'ابحث وأضف منتجات للفاتورة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      if (currentSale.isSaved && currentSale.completedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'تم الإكمال: ${DateFormat('hh:mm a').format(currentSale.completedAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SaleItemWidget(
                      item: item,
                      index: index,
                      onEdit: currentSale.isSaved
                          ? null
                          : () {
                        showDialog(
                          context: context,
                          builder: (_) => EditItemDialog(
                            index: index,
                            salesController: salesController,
                          ),
                        );
                      },
                      onDelete: currentSale.isSaved
                          ? null
                          : () => salesController.removeItem(index),
                      isEditable: !currentSale.isSaved,
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

Widget _pendingInvoicesTabsBar({
  required BuildContext context, // ✅ جديد
  required SalesController salesController,
  required List<Sale> activeInvoices,
  required Sale currentSale,
  required int currentInvoiceIndex,
  required ScrollController tabsScrollController,
  required GlobalKey Function(String invoiceNumber) keyForInvoice,
  required void Function(Sale inv) onTapInvoice,
  required void Function(PointerHoverEvent event, double width) onHoverEdge,
  required VoidCallback onStopHover,
  required VoidCallback onCreateNewInvoice,
}) {
  int safeIndex(int i) {
    if (activeInvoices.isEmpty) return 0;
    if (i < 0) return 0;
    if (i >= activeInvoices.length) return activeInvoices.length - 1;
    return i;
  }

  final currentIdx = activeInvoices.indexWhere(
        (inv) => inv.invoiceNumber == currentSale.invoiceNumber,
  );

  final selectedIndex =
  currentIdx != -1 ? currentIdx : safeIndex(currentInvoiceIndex);

  bool canCloseInvoice(Sale inv) {
    if (inv.isSaved) return false;
    if (inv.status != InvoiceStatus.pending) return false;
    return activeInvoices.length > 1;
  }

  String shortInv(String invoiceNumber) {
    final parts = invoiceNumber.split('-');
    return parts.isNotEmpty ? parts.last : invoiceNumber;
  }

  final scrollBehavior = ScrollConfiguration.of(context).copyWith( // ✅ بدل Get.context!
    dragDevices: {
      PointerDeviceKind.mouse,
      PointerDeviceKind.touch,
      PointerDeviceKind.trackpad,
    },
  );

  return Row(
    children: [
      // ⬅ السابق
      IconButton(
        tooltip: 'السابق',
        onPressed: (activeInvoices.isNotEmpty && selectedIndex > 0)
            ? () => onTapInvoice(activeInvoices[selectedIndex - 1])
            : null,
        icon: Icon(Iconsax.arrow_left_3, size: 18, color: Colors.grey[700]),
      ),

      // ✅ شريط التابات فقط (scroll)
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              onHover: (e) => onHoverEdge(e, constraints.maxWidth),
              onExit: (_) => onStopHover(),
              child: Stack(
                children: [
                  // ✅ الشريط نفسه
                  ScrollConfiguration(
                    behavior: scrollBehavior,
                    child: SizedBox(
                      height: 44,
                      child: ListView.builder(
                        controller: tabsScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: activeInvoices.length,
                        itemBuilder: (context, i) {
                          final inv = activeInvoices[i];
                          final isSelected =
                              inv.invoiceNumber == currentSale.invoiceNumber;

                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: keyForInvoice(inv.invoiceNumber),
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => onTapInvoice(inv),
                                child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 12,
                                    end: 8,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue[600]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue[600]!
                                          : Colors.orange[200]!,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.20),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.18)
                                              : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Iconsax.clock,
                                              size: 14,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.orange[800],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '#${shortInv(inv.invoiceNumber)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${inv.items.length}  صنف',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      if (canCloseInvoice(inv)) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(999),
                                          onTap: () {
                                            if (inv.invoiceNumber ==
                                                currentSale.invoiceNumber) {
                                              salesController.deleteCurrentInvoice();
                                            } else {
                                              salesController.loadInvoiceForEditing(inv);
                                              salesController.deleteCurrentInvoice();
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(
                                              Iconsax.close_circle,
                                              size: 18,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.red[400],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ✅ Gradient يسار + يمين (يظهر/يختفي حسب مكان السحب)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: tabsScrollController,
                        builder: (context, _) {
                          if (!tabsScrollController.hasClients ||
                              tabsScrollController.positions.isEmpty ||
                              !tabsScrollController.position.hasContentDimensions) {
                            return const SizedBox.shrink();
                          }

                          final pos = tabsScrollController.position;
                          final max = pos.maxScrollExtent;
                          final offset = pos.pixels;

                          final showLeft = offset > 2;
                          final showRight = (max - offset) > 2;

                          return Row(
                            children: [
                              AnimatedOpacity(
                                opacity: showLeft ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  width: 28,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withOpacity(0.95),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              AnimatedOpacity(
                                opacity: showRight ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  width: 28,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Colors.white.withOpacity(0.95),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // ⮕ التالي
      IconButton(
        tooltip: 'التالي',
        onPressed: (activeInvoices.isNotEmpty &&
            selectedIndex < activeInvoices.length - 1)
            ? () => onTapInvoice(activeInvoices[selectedIndex + 1])
            : null,
        icon: Icon(Iconsax.arrow_right_2, size: 18, color: Colors.grey[700]),
      ),
      const SizedBox(width: 8),
      // ✅ زر فاتورة جديدة ثابت (دايمًا ظاهر وسهل)

      // ✅ زر فاتورة جديدة ثابت (دايمًا ظاهر وسهل)
      ElevatedButton.icon(
        onPressed: salesController.refundMode.value ? null : onCreateNewInvoice,
        icon: Icon(
          Iconsax.add,
          size: 18,
          color: salesController.refundMode.value ? Colors.grey : Colors.white,
        ),
        label: Text(
          'فاتورة جديدة',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: salesController.refundMode.value ? Colors.grey : Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: salesController.refundMode.value
              ? Colors.grey[300]
              : Colors.blue[700],
          foregroundColor: salesController.refundMode.value
              ? Colors.grey
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  );
}
