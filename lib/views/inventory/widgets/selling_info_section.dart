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
  final pieceCountController = TextEditingController();
  final _pieceCountKey = GlobalKey<FormFieldState<String>>();
  String? _pieceCountError;

  // ✅ لمنع overwrite أثناء كتابة المستخدم
  final FocusNode _pieceCountFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // ✅ Seed أولي من الكنترولر الرئيسي (ينفع في الإضافة)
    if (widget.controller.unitsPerPackageController.text.isNotEmpty) {
      pieceCountController.text = widget.controller.unitsPerPackageController.text;
    }

    // ✅ listeners
    widget.controller.unitsPerPackageController.addListener(_syncFromMainUnits);
    pieceCountController.addListener(_calculatePiecePrice);
    widget.controller.sellingPriceController.addListener(_calculatePiecePrice);

    // ✅ احسب مرة بعد أول فريم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromMainUnits();      // مهم في التعديل
      _calculatePiecePrice();
    });
  }

  /// ✅ لو جت قيمة من init(medicine) بعدين، نخليها تظهر في الحقل المحلي
  void _syncFromMainUnits() {
    final mainText = widget.controller.unitsPerPackageController.text.trim();

    // لو المستخدم يكتب توا، ما نبدلش عليه
    if (_pieceCountFocus.hasFocus) return;

    // لو main عنده قيمة و المحلي فاضي أو مختلف → حدّث
    if (mainText.isNotEmpty && pieceCountController.text.trim() != mainText) {
      pieceCountController.text = mainText;
      _pieceCountKey.currentState?.validate();
    }

    // ✅ نخلي الـ piecePrice يتحدث
    _calculatePiecePrice();
  }

  void _calculatePiecePrice() {
    // keep main controller synced من المحلي (وقت إدخال المستخدم)
    if (widget.controller.unitsPerPackageController.text != pieceCountController.text) {
      // فقط لو المستخدم يكتب (أو المحلي تغيّر)
      if (_pieceCountFocus.hasFocus) {
        widget.controller.unitsPerPackageController.text = pieceCountController.text;
      }
    }

    final sellByPiece = widget.controller.sellByPiece.value;

    if (!sellByPiece) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    final priceText = widget.controller.sellingPriceController.text.trim();
    final unitsText = pieceCountController.text.trim();

    if (priceText.isEmpty || unitsText.isEmpty) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    final price = double.tryParse(priceText);
    final units = int.tryParse(unitsText);

    if (price == null || units == null || units <= 0) {
      widget.controller.piecePriceCalculated.value = null;
      return;
    }

    widget.controller.piecePriceCalculated.value = price / units;
  }

  String? _validatePieceCount(String? value) {
    final sellByPiece = widget.controller.sellByPiece.value;

    if (!sellByPiece) {
      _pieceCountError = null;
      return null;
    }

    final v = (value ?? '').trim();
    if (v.isEmpty) return _pieceCountError = 'عدد القطع مطلوب عند البيع بالقطعة';

    final units = int.tryParse(v);
    if (units == null) return _pieceCountError = 'يجب أن يكون عدد القطع رقماً صحيحاً';
    if (units <= 0) return _pieceCountError = 'عدد القطع يجب أن يكون أكبر من صفر';
    if (units > 10000) return _pieceCountError = 'عدد القطع كبير جداً (الحد الأقصى 10,000)';

    _pieceCountError = null;
    return null;
  }

  void _toggleSellByPiece(bool enabled) {
    widget.controller.sellByPiece.value = enabled;

    if (!enabled) {
      pieceCountController.clear();
      widget.controller.unitsPerPackageController.clear();
      _pieceCountError = null;
      _pieceCountKey.currentState?.validate();
      widget.controller.piecePriceCalculated.value = null;
    } else {
      // لو عندنا قيمة جاهزة من التعديل خذيها
      if (widget.controller.unitsPerPackageController.text.trim().isNotEmpty &&
          pieceCountController.text.trim().isEmpty) {
        pieceCountController.text = widget.controller.unitsPerPackageController.text.trim();
      }
      _pieceCountError = _validatePieceCount(pieceCountController.text);
      _pieceCountKey.currentState?.validate();
      _calculatePiecePrice();
    }

    setState(() {}); // فقط لتحديث errorText إن لزم
  }

  @override
  void dispose() {
    widget.controller.unitsPerPackageController.removeListener(_syncFromMainUnits);
    widget.controller.sellingPriceController.removeListener(_calculatePiecePrice);
    pieceCountController.removeListener(_calculatePiecePrice);

    _pieceCountFocus.dispose();
    pieceCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final compact = w < 520;
        final twoCols = w >= 900;

        final gap = compact ? 12.0 : 16.0;

        return buildSection(
          title: 'معلومات البيع',
          icon: Icons.sell,
          children: [
            // ✅ نخلي الجزء هذا Obx باش يتحدث وقت التعديل لما sellByPiece يتغير من controller.init
            Obx(() {
              final sellByPiece = widget.controller.sellByPiece.value;

              return Column(
                children: [
                  // ====== Selling price + toggle row ======
                  if (twoCols)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _sellingPriceField()),
                        SizedBox(width: gap),
                        Expanded(child: _sellByPieceRow(compact: compact, value: sellByPiece)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _sellingPriceField(),
                        SizedBox(height: gap),
                        _sellByPieceRow(compact: compact, value: sellByPiece),
                      ],
                    ),

                  SizedBox(height: gap),

                  // ====== Animated piece fields ======
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: ClipRect(
                      child: sellByPiece
                          ? Column(
                        children: [
                          TextFormField(
                            key: _pieceCountKey,
                            focusNode: _pieceCountFocus,
                            controller: pieceCountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'عدد القطع في العبوة *',
                              prefixIcon: const Icon(Icons.format_list_numbered),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                              errorText: _pieceCountError,
                              errorStyle: const TextStyle(fontSize: 12),
                              isDense: compact,
                            ),
                            validator: _validatePieceCount,
                            onChanged: (value) {
                              setState(() => _pieceCountError = _validatePieceCount(value));
                              _pieceCountKey.currentState?.validate();
                              _calculatePiecePrice();
                            },
                          ),
                          SizedBox(height: gap),

                          Obx(() {
                            final piece = widget.controller.piecePriceCalculated.value;
                            if (piece == null) return const SizedBox();

                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(compact ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.calculate, color: Colors.green.shade700),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'سعر القطعة المحسوب',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green.shade800,
                                            fontSize: compact ? 12.5 : 13.5,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${piece.toStringAsFixed(2)} د.ل للقطعة الواحدة',
                                          style: TextStyle(
                                            fontSize: compact ? 12 : 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ],
                                    ),
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
            }),
          ],
        );
      },
    );
  }

  Widget _sellingPriceField() {
    return TextFormField(
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
        final v = (value ?? '').trim();
        if (v.isEmpty) return 'سعر البيع مطلوب';
        final price = double.tryParse(v);
        if (price == null) return 'يجب أن يكون سعر البيع رقماً';
        if (price <= 0) return 'سعر البيع يجب أن يكون أكبر من صفر';
        if (price > 1000000) return 'سعر البيع كبير جداً (الحد الأقصى 1,000,000)';
        return null;
      },
      onChanged: (_) => _calculatePiecePrice(),
    );
  }

  Widget _sellByPieceRow({required bool compact, required bool value}) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => _toggleSellByPiece(v ?? false),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'البيع بالقطعة',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 13 : 14,
              ),
            ),
          ),
          if (value)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
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