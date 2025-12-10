import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import '../../../models/inventory_model.dart';

enum PurchaseType { retail, wholesale }

class PurchaseInfoSection extends StatelessWidget {
  final AddMedicineController controller;

  PurchaseInfoSection({super.key, required this.controller});

  final Rx<PurchaseType> purchaseType = PurchaseType.retail.obs;

  final TextEditingController retailPrice = TextEditingController();
  final TextEditingController retailQty = TextEditingController();

  final TextEditingController boxCount = TextEditingController();
  final TextEditingController piecesPerBox = TextEditingController();
  final TextEditingController boxPrice = TextEditingController();

  int get totalPieces {
    if (purchaseType.value == PurchaseType.wholesale) {
      int b = int.tryParse(boxCount.text) ?? 0;
      int p = int.tryParse(piecesPerBox.text) ?? 0;
      return b * p;
    }
    return int.tryParse(retailQty.text) ?? 0;
  }

  double get pricePerPiece {
    if (purchaseType.value == PurchaseType.wholesale) {
      double bp = double.tryParse(boxPrice.text) ?? 0;
      int p = int.tryParse(piecesPerBox.text) ?? 1;
      return bp / p;
    }
    return double.tryParse(retailPrice.text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      title: ' الشراء والمخزون',
      icon: Icons.shopping_cart,
      children: [
        // ---------------------- Radio Buttons ----------------------
        Obx(() => Row(
          children: [
            Expanded(
              child: RadioListTile<PurchaseType>(
                title: const Text("شراء قطاعي"),
                value: PurchaseType.retail,
                groupValue: purchaseType.value,
                onChanged: (v) => purchaseType.value = v!,
              ),
            ),
            Expanded(
              child: RadioListTile<PurchaseType>(
                title: const Text("شراء جملة"),
                value: PurchaseType.wholesale,
                groupValue: purchaseType.value,
                onChanged: (v) => purchaseType.value = v!,
              ),
            ),
          ],
        )),
        const SizedBox(height: 16),

        // ---------------------- Animated Switch ----------------------
        Obx(() {
          return ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: purchaseType.value == PurchaseType.retail
                  ? _buildRetailFields()
                  : _buildWholesaleFields(),
            ),
          );
        }),

        const SizedBox(height: 16),

        // ------------------- إرجاع القيم للكونترولر -------------------
        Obx(() {
          controller.quantityController.text = totalPieces.toString();
          controller.purchasePriceController.text =
              pricePerPiece.toStringAsFixed(2);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("الكمية النهائية (بالقطع): $totalPieces",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("سعر القطعة النهائي: ${pricePerPiece.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.blue)),
            ],
          );
        }),
      ],
    );
  }

  // ---------------------- UI — شراء قطاعي ----------------------
  Widget _buildRetailFields() {
    return Column(
      key: const ValueKey("retail"),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: retailPrice,
                decoration: _input("سعر الشراء للقطعة", Icons.attach_money),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: retailQty,
                decoration: _input("الكمية بالقطع", Icons.inventory),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------- UI — شراء جملة ----------------------
  Widget _buildWholesaleFields() {
    return Column(
      key: const ValueKey("wholesale"),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: boxCount,
                decoration: _input("عدد الصناديق", Icons.inventory_2),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: piecesPerBox,
                decoration: _input("عدد القطع في الصندوق", Icons.format_list_numbered),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: boxPrice,
          decoration: _input("سعر الصندوق الواحد", Icons.attach_money),
          onChanged: (_) => purchaseType.refresh(),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // ---------------------- Input Decoration Helper ----------------------
  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}

// ---------------------- Section Wrapper ----------------------
Widget _buildSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
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
