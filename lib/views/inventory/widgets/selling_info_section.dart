import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

class SellingInfoSection extends StatefulWidget {
  final AddMedicineController controller;

  const SellingInfoSection({super.key, required this.controller});

  @override
  State<SellingInfoSection> createState() => _SellingInfoSectionState();
}

class _SellingInfoSectionState extends State<SellingInfoSection> {
  bool sellByPiece = false;
  final pieceCountController = TextEditingController();

  void _calculatePiecePrice() {
    if (!sellByPiece) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    final priceText = widget.controller.sellingPriceController.text;
    final unitsText = pieceCountController.text;

    if (priceText.isEmpty || unitsText.isEmpty) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    final price = double.tryParse(priceText);
    final units = int.tryParse(unitsText);

    if (price == null || units == null || units == 0) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    widget.controller.piecePriceCalculated.value = price / units;
  }

  @override
  void dispose() {
    pieceCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'معلومات البيع',
      icon: Icons.sell,
      children: [
        // سعر البيع للعبوة
        TextFormField(
          controller: widget.controller.sellingPriceController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _calculatePiecePrice(),
          decoration: InputDecoration(
            labelText: 'سعر البيع للعبوة',
            prefixIcon: const Icon(Icons.money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),

        // Checkbox بيع بالقطعة
        Row(
          children: [
            Checkbox(
              value: sellByPiece,
              onChanged: (value) {
                setState(() => sellByPiece = value ?? false);
                _calculatePiecePrice();
              },
            ),
            const Text(
              'البيع بالقطعة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // حقل عدد القطع يظهر فقط إذا اخترنا البيع بالقطعة
        if (sellByPiece) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: pieceCountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculatePiecePrice(),
            decoration: InputDecoration(
              labelText: 'عدد القطع في العبوة',
              prefixIcon: const Icon(Icons.format_list_numbered),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),

          // عرض سعر القطعة المحسوب
          Obx(() {
            final piece = widget.controller.piecePriceCalculated.value;
            if (piece == null) return const SizedBox();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'سعر القطعة المحسوب: ${piece.toStringAsFixed(2)} د.ع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------
// Section Template المعاد استخدامه
Widget buildSection({
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
