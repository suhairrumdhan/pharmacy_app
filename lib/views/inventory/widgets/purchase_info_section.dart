import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

enum PurchaseType { retail, wholesale }

class PurchaseInfoSection extends StatefulWidget {
  final AddMedicineController controller;
  const PurchaseInfoSection({super.key, required this.controller});

  @override
  State<PurchaseInfoSection> createState() => _PurchaseInfoSectionState();
}

class _PurchaseInfoSectionState extends State<PurchaseInfoSection>
    with TickerProviderStateMixin {
  final Rx<PurchaseType> purchaseType = PurchaseType.retail.obs;

  // ✅ wholesale فقط (محلي)
  late final TextEditingController boxCountCtrl;
  late final TextEditingController piecesPerBoxCtrl;
  late final TextEditingController boxPriceCtrl;

  // ✅ Trigger لإعادة بناء الـ Summary لما تتغير Controllers
  final RxInt _tick = 0.obs;
  void _forceRebuild() => _tick.value++;

  @override
  void initState() {
    super.initState();

    boxCountCtrl = TextEditingController();
    piecesPerBoxCtrl = TextEditingController();
    boxPriceCtrl = TextEditingController();

    // ✅ Retail: تابع تغيّر الحقول المربوطة بالكنترولر الرئيسي
    widget.controller.quantityController.addListener(_forceRebuild);
    widget.controller.purchasePriceController.addListener(_forceRebuild);

    // ✅ Wholesale: تابع تغيّر حقول الجملة
    boxCountCtrl.addListener(_forceRebuild);
    piecesPerBoxCtrl.addListener(_forceRebuild);
    boxPriceCtrl.addListener(_forceRebuild);
  }

  @override
  void dispose() {
    // ✅ لازم نحذف listeners
    widget.controller.quantityController.removeListener(_forceRebuild);
    widget.controller.purchasePriceController.removeListener(_forceRebuild);

    boxCountCtrl.dispose();
    piecesPerBoxCtrl.dispose();
    boxPriceCtrl.dispose();
    super.dispose();
  }

  // ========= Retail values from MAIN controller مباشرة =========
  int get retailQty =>
      int.tryParse(widget.controller.quantityController.text.trim()) ?? 0;

  double get retailPrice =>
      double.tryParse(widget.controller.purchasePriceController.text.trim()) ?? 0;

  // ========= Wholesale حسابات =========
  int get totalPieces {
    if (purchaseType.value == PurchaseType.wholesale) {
      final b = int.tryParse(boxCountCtrl.text) ?? 0;
      final p = int.tryParse(piecesPerBoxCtrl.text) ?? 0;
      return b * p;
    }
    return retailQty;
  }

  double get pricePerPiece {
    if (purchaseType.value == PurchaseType.wholesale) {
      final bp = double.tryParse(boxPriceCtrl.text) ?? 0;
      final p = int.tryParse(piecesPerBoxCtrl.text) ?? 0;
      if (p <= 0) return 0;
      return bp / p;
    }
    return retailPrice;
  }

  // ✅ مزامنة wholesale -> main
  void _syncWholesaleToMain() {
    widget.controller.quantityController.text = totalPieces.toString();
    widget.controller.purchasePriceController.text =
        pricePerPiece.toStringAsFixed(2);
  }

  void _onWholesaleChanged() {
    _syncWholesaleToMain();
    purchaseType.refresh();
    _forceRebuild(); // ✅ تحديث summary فورًا
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final bool compact = w < 520;
        final double pad = compact ? 14 : 20;
        final double gap = compact ? 12 : 16;
        final double fieldGap = compact ? 10 : 16;
        final double titleSize = compact ? 16 : 18;

        Widget twoFields(Widget a, Widget b) {
          if (compact) {
            return Column(
              children: [
                a,
                SizedBox(height: fieldGap),
                b,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: a),
              SizedBox(width: fieldGap),
              Expanded(child: b),
            ],
          );
        }

        return _buildSection(
          title: 'الشراء والمخزون',
          icon: Icons.shopping_cart,
          padding: pad,
          titleSize: titleSize,
          children: [
            // ---------------------- Radio Buttons ----------------------
            Obx(() {
              if (compact) {
                return Column(
                  children: [
                    RadioListTile<PurchaseType>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("شراء قطاعي"),
                      value: PurchaseType.retail,
                      groupValue: purchaseType.value,
                      onChanged: (v) {
                        if (v == null) return;
                        purchaseType.value = v;
                        purchaseType.refresh();
                        _forceRebuild(); // ✅ تحديث summary عند التبديل
                      },
                    ),
                    RadioListTile<PurchaseType>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("شراء جملة"),
                      value: PurchaseType.wholesale,
                      groupValue: purchaseType.value,
                      onChanged: (v) {
                        if (v == null) return;
                        purchaseType.value = v;
                        purchaseType.refresh();
                        _forceRebuild(); // ✅ تحديث summary عند التبديل
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: RadioListTile<PurchaseType>(
                      title: const Text("شراء قطاعي"),
                      value: PurchaseType.retail,
                      groupValue: purchaseType.value,
                      onChanged: (v) {
                        if (v == null) return;
                        purchaseType.value = v;
                        purchaseType.refresh();
                        _forceRebuild();
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<PurchaseType>(
                      title: const Text("شراء جملة"),
                      value: PurchaseType.wholesale,
                      groupValue: purchaseType.value,
                      onChanged: (v) {
                        if (v == null) return;
                        purchaseType.value = v;
                        purchaseType.refresh();
                        _forceRebuild();
                      },
                    ),
                  ),
                ],
              );
            }),

            SizedBox(height: gap),

            // ---------------------- Animated Switch ----------------------
            Obx(() {
              return ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  child: purchaseType.value == PurchaseType.retail
                      ? _buildRetailFields(twoFields, compact)
                      : _buildWholesaleFields(twoFields, compact),
                ),
              );
            }),

            SizedBox(height: gap),

            // ------------------- Summary -------------------
            Obx(() {
              _tick.value; // ✅ يخلي summary يتحدث مع أي تغيير controllers

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الكمية النهائية (بالقطع): $totalPieces",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "سعر القطعة النهائي: ${pricePerPiece.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ✅ Retail: مربوط مباشرة بـ Main Controllers (يطلع في التعديل فوراً)
  Widget _buildRetailFields(
      Widget Function(Widget, Widget) twoFields,
      bool compact,
      ) {
    return Column(
      key: const ValueKey("retail"),
      children: [
        twoFields(
          TextFormField(
            controller: widget.controller.purchasePriceController,
            decoration: _input("سعر الشراء للقطعة", Icons.attach_money, compact),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: widget.controller.quantityController,
            decoration: _input("الكمية بالقطع", Icons.inventory, compact),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  // ✅ Wholesale: محلي + sync للـ main
  Widget _buildWholesaleFields(
      Widget Function(Widget, Widget) twoFields,
      bool compact,
      ) {
    return Column(
      key: const ValueKey("wholesale"),
      children: [
        twoFields(
          TextFormField(
            controller: boxCountCtrl,
            decoration: _input("عدد الصناديق", Icons.inventory_2, compact),
            onChanged: (_) => _onWholesaleChanged(),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: piecesPerBoxCtrl,
            decoration:
            _input("عدد القطع في الصندوق", Icons.format_list_numbered, compact),
            onChanged: (_) => _onWholesaleChanged(),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
        TextFormField(
          controller: boxPriceCtrl,
          decoration: _input("سعر الصندوق الواحد", Icons.attach_money, compact),
          onChanged: (_) => _onWholesaleChanged(),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  InputDecoration _input(String label, IconData icon, bool compact) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[50],
      isDense: compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 12 : 14,
      ),
    );
  }
}

Widget _buildSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
  double padding = 20,
  double titleSize = 18,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}