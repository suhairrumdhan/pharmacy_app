import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';
import '../../../models/inventory_model.dart';

enum PurchaseType { retail, wholesale }

class PurchaseInfoSection extends StatelessWidget {
  final AddMedicineController controller;

  PurchaseInfoSection({super.key, required this.controller});

  // ------------------------------
  // 🔵 المتغيرات المحلية
  // ------------------------------
  final Rx<PurchaseType> purchaseType = PurchaseType.retail.obs;

  final TextEditingController retailPrice = TextEditingController();
  final TextEditingController retailQty = TextEditingController();

  final TextEditingController boxCount = TextEditingController();
  final TextEditingController piecesPerBox = TextEditingController();
  final TextEditingController boxPrice = TextEditingController();

  // حساب الكمية النهائية
  int get totalPieces {
    if (purchaseType.value == PurchaseType.wholesale) {
      int b = int.tryParse(boxCount.text) ?? 0;
      int p = int.tryParse(piecesPerBox.text) ?? 0;
      return b * p;
    }
    return int.tryParse(retailQty.text) ?? 0;
  }

  // حساب سعر القطعة
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

        // ---------------------- UI Switch ----------------------
        Obx(() {
          if (purchaseType.value == PurchaseType.retail) {
            return _buildRetailFields();
          } else {
            return _buildWholesaleFields();
          }
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

  // ----------------------------------------------------------
  // 🔵  UI — شراء قطاعي
  // ----------------------------------------------------------
  Widget _buildRetailFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: retailPrice,
                decoration: InputDecoration(
                  labelText: 'سعر الشراء للقطعة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: retailQty,
                decoration: InputDecoration(
                  labelText: 'الكمية بالقطع',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 🔵  UI — شراء جملة (صناديق)
  // ----------------------------------------------------------
  Widget _buildWholesaleFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: boxCount,
                decoration: InputDecoration(
                  labelText: 'عدد الصناديق',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory_2),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: piecesPerBox,
                decoration: InputDecoration(
                  labelText: 'عدد القطع في الصندوق',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (_) => purchaseType.refresh(),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: boxPrice,
          decoration: InputDecoration(
            labelText: 'سعر الصندوق الواحد',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.attach_money),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (_) => purchaseType.refresh(),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// 🔵  Section Wrapper
// ----------------------------------------------------------
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
