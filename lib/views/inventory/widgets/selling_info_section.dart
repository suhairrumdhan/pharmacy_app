import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

class SellingInfoSection extends StatefulWidget {
  final AddMedicineController controller;

  const SellingInfoSection({super.key, required this.controller});

  @override
  State<SellingInfoSection> createState() => _SellingInfoSectionState();
}

class _SellingInfoSectionState extends State<SellingInfoSection> with TickerProviderStateMixin {
  bool sellByPiece = false;
  final pieceCountController = TextEditingController();
  final _pieceCountFormKey = GlobalKey<FormFieldState>();
  String? _pieceCountError;

  @override
  void initState() {
    super.initState();

    // ربط الـ controller من widget مع controller المحلي
    widget.controller.unitsPerPackageController.addListener(_calculatePiecePrice);
    pieceCountController.addListener(_calculatePiecePrice);
    widget.controller.sellingPriceController.addListener(_calculatePiecePrice);

    // مزامنة القيمة الأولية
    sellByPiece = widget.controller.sellByPiece.value;
    if (widget.controller.unitsPerPackageController.text.isNotEmpty) {
      pieceCountController.text = widget.controller.unitsPerPackageController.text;
    }
  }

  void _calculatePiecePrice() {
    // تحديث الـ controller الرئيسي
    widget.controller.unitsPerPackageController.text = pieceCountController.text;

    if (!sellByPiece) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    final priceText = widget.controller.sellingPriceController.text;
    final unitsText = pieceCountController.text;

    // التحقق من صحة البيانات
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

    // تحديث قيمة القطعة المحسوبة
    final piecePrice = price / units;
    widget.controller.piecePriceCalculated.value = piecePrice;
  }

  // التحقق من صحة عدد القطع
  String? _validatePieceCount(String? value) {
    if (!sellByPiece) {
      _pieceCountError = null;
      return null;
    }

    if (value == null || value.isEmpty) {
      _pieceCountError = 'عدد القطع مطلوب عند البيع بالقطعة';
      return _pieceCountError;
    }

    final units = int.tryParse(value);
    if (units == null) {
      _pieceCountError = 'يجب أن يكون عدد القطع رقماً صحيحاً';
      return _pieceCountError;
    }

    if (units <= 0) {
      _pieceCountError = 'عدد القطع يجب أن يكون أكبر من صفر';
      return _pieceCountError;
    }

    if (units > 10000) {
      _pieceCountError = 'عدد القطع كبير جداً (الحد الأقصى 10,000)';
      return _pieceCountError;
    }

    _pieceCountError = null;
    return null;
  }

  @override
  void dispose() {
    widget.controller.unitsPerPackageController.removeListener(_calculatePiecePrice);
    pieceCountController.removeListener(_calculatePiecePrice);
    widget.controller.sellingPriceController.removeListener(_calculatePiecePrice);
    pieceCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'معلومات البيع',
      icon: Icons.sell,
      children: [
        // سعر البيع للعبوة مع تحقق إجباري
        TextFormField(
          controller: widget.controller.sellingPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'سعر البيع للعبوة*',
            prefixIcon: const Icon(Icons.money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            errorStyle: const TextStyle(fontSize: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'سعر البيع مطلوب';
            }
            final price = double.tryParse(value);
            if (price == null) {
              return 'يجب أن يكون سعر البيع رقماً';
            }
            if (price <= 0) {
              return 'سعر البيع يجب أن يكون أكبر من صفر';
            }
            if (price > 1000000) {
              return 'سعر البيع كبير جداً (الحد الأقصى 1,000,000)';
            }
            return null;
          },
          onChanged: (_) => _calculatePiecePrice(),
        ),
        const SizedBox(height: 16),

        // Checkbox بيع بالقطعة
        Row(
          children: [
            Checkbox(
              value: sellByPiece,
              onChanged: (value) {
                setState(() {
                  sellByPiece = value ?? false;
                  widget.controller.sellByPiece.value = sellByPiece;

                  // تنظيف حقل عدد القطع عند إلغاء التفعيل
                  if (!sellByPiece) {
                    pieceCountController.clear();
                    widget.controller.unitsPerPackageController.clear();
                    _pieceCountError = null;
                    if (_pieceCountFormKey.currentState != null) {
                      _pieceCountFormKey.currentState!.validate();
                    }
                  }
                });
                _calculatePiecePrice();

                // إعادة التحقق من صحة عدد القطع عند التفعيل
                if (value == true) {
                  _pieceCountError = _validatePieceCount(pieceCountController.text);
                }
              },
            ),
            const Text(
              'البيع بالقطعة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (sellByPiece)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'مطلوب',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        // ---------- الجزء المتغير مع AnimatedSize ----------
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: ClipRect(
            child: sellByPiece
                ? Column(
              children: [
                const SizedBox(height: 12),

                // عدد القطع (إجباري عند تفعيل البيع بالقطعة)
                TextFormField(
                  key: _pieceCountFormKey,
                  controller: pieceCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'عدد القطع في العبوة *',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    errorText: _pieceCountError,
                    errorStyle: const TextStyle(fontSize: 12),
                  ),
                  validator: _validatePieceCount,
                  onChanged: (value) {
                    _pieceCountError = _validatePieceCount(value);
                    if (_pieceCountFormKey.currentState != null) {
                      _pieceCountFormKey.currentState!.validate();
                    }
                    _calculatePiecePrice();
                  },
                ),
                const SizedBox(height: 12),

                // سعر القطعة المحسوب - فقط استخدام Obx هنا حيث يوجد observable
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'سعر القطعة المحسوب:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 13,
                              ),
                              textDirection: TextDirection.rtl, // 🔥 إضافة هذا السطر

                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${piece.toStringAsFixed(2)}د.ل للقطعة الواحدة ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl, // 🔥 إضافة هذا السطر

                        ),
                        if (widget.controller.sellingPriceController.text.isNotEmpty &&
                            pieceCountController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            )
                : const SizedBox(),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// Section Template (ثابت)
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