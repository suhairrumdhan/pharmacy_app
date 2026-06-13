import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../controllers/inventory_controller.dart';
import '../../../controllers/purchase_controller.dart';
import '../../../controllers/supplier_controller.dart';
import '../../../models/inventory_model.dart';
import '../../../models/purchase_model.dart';

class PurchaseInvoiceDialog extends StatefulWidget {
  final PurchaseController controller;

  const PurchaseInvoiceDialog({
    super.key,
    required this.controller,
  });

  @override
  State<PurchaseInvoiceDialog> createState() => _PurchaseInvoiceDialogState();
}

class _PurchaseInvoiceDialogState extends State<PurchaseInvoiceDialog> {
  static const Color _primary = Color(0xFF1D4ED8);
  static const Color _primaryLight = Color(0xFF3B82F6);
  static const Color _bgSoft = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _cardBg = Color(0xFFF7FBFF);

  final _formKey = GlobalKey<FormState>();
  final ScrollController _itemsHorizontalCtrl = ScrollController();

  late final InventoryController inventoryCtrl;
  late final SupplierController supplierCtrl;

  final TextEditingController supplierNameCtrl = TextEditingController();
  final TextEditingController referenceCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController(text: '0');

  DateTime invoiceDate = DateTime.now();
  DateTime? dueDate;

  String? selectedSupplierId;
  String? selectedSupplierName;

  final List<_PurchaseItemDraft> draftItems = [];

  bool submitting = false;

  @override
  void initState() {
    super.initState();
    inventoryCtrl = Get.find<InventoryController>();
    supplierCtrl = Get.find<SupplierController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if ((supplierCtrl as dynamic).suppliers.isEmpty) {
          (supplierCtrl as dynamic).fetchSuppliers?.call();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _itemsHorizontalCtrl.dispose();
    supplierNameCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    discountCtrl.dispose();
    for (final item in draftItems) {
      item.dispose();
    }
    super.dispose();
  }

  double get subtotal => draftItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get discount => double.tryParse(discountCtrl.text.trim()) ?? 0.0;

  double get total => (subtotal - discount).clamp(0.0, double.infinity);

  int get totalLines => draftItems.length;

  int get totalPackages => draftItems.fold(
    0,
        (sum, item) => sum + (item.purchaseMode == _PurchaseMode.package ? item.qty : 0),
  );

  int get totalPieces => draftItems.fold(
    0,
        (sum, item) => sum + (item.purchaseMode == _PurchaseMode.piece ? item.qty : 0),
  );

  String _currency(num value) => '${value.toStringAsFixed(2)} د.ل';

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => invoiceDate = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => dueDate = picked);
    }
  }

  Future<void> _openMedicinePicker() async {
    final result = await showDialog<List<Medicine>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MedicineMultiPickerDialog(
        inventoryCtrl: inventoryCtrl,
        selectedIds: draftItems.map((e) => e.selectedMedicineId).whereType<String>().toSet(),
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      for (final med in result) {
        final exists = draftItems.any((e) => e.selectedMedicineId == med.id);
        if (exists) continue;
        draftItems.add(_PurchaseItemDraft.fromMedicine(med));
      }
    });
  }

  void _addEmptyItem() {
    setState(() {
      draftItems.add(_PurchaseItemDraft.empty());
    });
  }

  void _removeItem(int index) {
    setState(() {
      draftItems[index].dispose();
      draftItems.removeAt(index);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (selectedSupplierId == null || selectedSupplierName == null) {
      Get.snackbar('تنبيه', 'اختر المورد أولاً');
      return;
    }

    if (draftItems.isEmpty) {
      Get.snackbar('تنبيه', 'أضف صنف واحد على الأقل');
      return;
    }

    final purchaseItems = <PurchaseItem>[];
    final stockEntries = <PurchaseStockEntry>[];

    for (int i = 0; i < draftItems.length; i++) {
      final item = draftItems[i];

      if (item.selectedMedicineId == null || item.selectedMedicineName == null) {
        Get.snackbar('تنبيه', 'اختر الصنف في السطر رقم ${i + 1}');
        return;
      }

      final qty = item.qty;
      final unitPrice = item.purchaseUnitPrice;

      if (qty <= 0) {
        Get.snackbar('تنبيه', 'الكمية غير صحيحة في السطر رقم ${i + 1}');
        return;
      }

      if (unitPrice <= 0) {
        Get.snackbar('تنبيه', 'سعر الشراء غير صحيح في السطر رقم ${i + 1}');
        return;
      }

      if (item.purchaseMode == _PurchaseMode.package && item.unitsPerPackage <= 0) {
        Get.snackbar('تنبيه', 'أدخل عدد القطع داخل العبوة في السطر رقم ${i + 1}');
        return;
      }

      purchaseItems.add(
        PurchaseItem(
          medicineId: item.selectedMedicineId!,
          medicineName: item.selectedMedicineName!,
          quantity: qty,
          price: unitPrice,
          expiryDate: item.expiryDate,
          batchNumber: item.batchCtrl.text.trim().isEmpty ? null : item.batchCtrl.text.trim(),
        ),
      );

      stockEntries.add(
        PurchaseStockEntry(
          medicineId: item.selectedMedicineId!,
          medicineName: item.selectedMedicineName!,
          packageQty: item.purchaseMode == _PurchaseMode.package ? qty : 0,
          pieceQty: item.purchaseMode == _PurchaseMode.piece ? qty : 0,
          purchasePrice: unitPrice,
          sellingPrice: item.sellingPrice > 0 ? item.sellingPrice : null,
          sellByPiece: item.sellByPiece,
          unitsPerPackage: item.unitsPerPackage > 0 ? item.unitsPerPackage : null,
          piecePrice: item.sellByPiece && item.pieceSellingPrice > 0 ? item.pieceSellingPrice : null,
          batchNumber: item.batchCtrl.text.trim().isEmpty ? null : item.batchCtrl.text.trim(),
          expiryDate: item.expiryDate,
          barcode: item.barcodeCtrl.text.trim().isEmpty ? null : item.barcodeCtrl.text.trim(),
          supplier: selectedSupplierName,
        ),
      );
    }

    try {
      setState(() => submitting = true);

      await widget.controller.createPurchaseInvoiceAdvanced(
        supplierId: selectedSupplierId!,
        supplierName: selectedSupplierName!,
        items: purchaseItems,
        stockEntries: stockEntries,
        discount: discount,
        referenceNumber: referenceCtrl.text.trim().isEmpty ? null : referenceCtrl.text.trim(),
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        notes: _buildSystemNotes(),
      );

      if (mounted) Get.back();
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  String? _buildSystemNotes() {
    final userNotes = notesCtrl.text.trim();
    final buffer = StringBuffer();

    if (userNotes.isNotEmpty) {
      buffer.writeln(userNotes);
      buffer.writeln();
    }

    for (int i = 0; i < draftItems.length; i++) {
      final item = draftItems[i];
      buffer.writeln(
        '${i + 1}) ${item.selectedMedicineName ?? '-'} | '
            'purchaseMode=${item.purchaseMode.name} | '
            'qty=${item.qty} | '
            'unitsPerPackage=${item.unitsPerPackage} | '
            'purchase=${item.purchaseUnitPrice.toStringAsFixed(2)} | '
            'selling=${item.sellingPrice.toStringAsFixed(2)} | '
            'sellByPiece=${item.sellByPiece} | '
            'piece=${item.pieceSellingPrice.toStringAsFixed(2)}',
      );
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1520,
        height: 860,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F7FD),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildMainContent(constraints);
                      },
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BoxConstraints constraints) {
    final isWide = constraints.maxWidth >= 1260;

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBarCompact(),
          const SizedBox(height: 14),
          Expanded(child: _buildItemsSection()),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: _buildSummarySection(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBarWide(),
        const SizedBox(height: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 12,
                child: _buildItemsSection(),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: _buildSummarySection(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF4FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.receipt_add, color: _primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء فاتورة مشتريات',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'إدخال سريع للبيانات من الأعلى وجدول أصناف واضح في الجزء الرئيسي',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: submitting ? null : () => Get.back(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarWide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildSupplierDropdown()),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: referenceCtrl,
              decoration: _inputDecoration('رقم المرجع', Iconsax.document_text),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _topDateField(
              label: 'تاريخ الفاتورة',
              value: _formatDate(invoiceDate),
              onTap: _pickInvoiceDate,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _topDateField(
              label: 'الاستحقاق',
              value: dueDate == null ? 'غير محدد' : _formatDate(dueDate!),
              onTap: _pickDueDate,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('الخصم', Iconsax.discount_shape),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final d = double.tryParse((v ?? '').trim());
                if ((v ?? '').trim().isEmpty) return null;
                if (d == null || d < 0) return 'قيمة غير صحيحة';
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: notesCtrl,
              decoration: _inputDecoration('ملاحظات', Iconsax.note_text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarCompact() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Column(
        children: [
          _buildSupplierDropdown(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: referenceCtrl,
                  decoration: _inputDecoration('رقم المرجع', Iconsax.document_text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('الخصم', Iconsax.discount_shape),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final d = double.tryParse((v ?? '').trim());
                    if ((v ?? '').trim().isEmpty) return null;
                    if (d == null || d < 0) return 'قيمة غير صحيحة';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _topDateField(
                  label: 'تاريخ الفاتورة',
                  value: _formatDate(invoiceDate),
                  onTap: _pickInvoiceDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _topDateField(
                  label: 'الاستحقاق',
                  value: dueDate == null ? 'غير محدد' : _formatDate(dueDate!),
                  onTap: _pickDueDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: notesCtrl,
            decoration: _inputDecoration('ملاحظات', Iconsax.note_text),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return _sectionCard(
      title: 'أصناف الفاتورة',
      icon: Iconsax.box,
      expandChild: true,
      headerAction: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _addEmptyItem,
            icon: const Icon(Iconsax.add, size: 16),
            label: const Text('سطر فارغ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openMedicinePicker,
            icon: const Icon(Iconsax.search_normal_1, size: 16),
            label: const Text('إضافة من المخزون'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          _itemsTopStats(),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  controller: _itemsHorizontalCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _itemsHorizontalCtrl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1700,
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          _buildItemsTableHeader(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: draftItems.isEmpty
                                ? _emptyItemsState()
                                : ListView.separated(
                              itemCount: draftItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _buildItemTableRow(index, draftItems[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsTopStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _miniInfoChip(Iconsax.box_1, 'عدد الأصناف', '$totalLines'),
          _miniInfoChip(Iconsax.archive, 'عبوات', '$totalPackages'),
          _miniInfoChip(Iconsax.category, 'قطاعي', '$totalPieces'),
          _miniInfoChip(Iconsax.money_4, 'الإجمالي الحالي', _currency(subtotal)),
        ],
      ),
    );
  }

  Widget _buildItemsTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          _HeaderCell('م', 50),
          _HeaderCell('الصنف', 260),
          _HeaderCell('الباركود', 130),
          _HeaderCell('نمط الشراء', 170),
          _HeaderCell('يباع بالقطعة', 120),
          _HeaderCell('الكمية', 100),
          _HeaderCell('داخل الصندوق', 120),
          _HeaderCell('سعر الشراء', 120),
          _HeaderCell('بيع الصندوق', 120),
          _HeaderCell('بيع القطعة', 120),
          _HeaderCell('الصلاحية', 140),
          _HeaderCell('إجمالي السطر', 130),
          _HeaderCell('', 54),
        ],
      ),
    );
  }

  Widget _buildItemTableRow(int index, _PurchaseItemDraft item) {
    return StatefulBuilder(
      builder: (context, setRowState) {
        Future<void> pickExpiry() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: item.expiryDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            item.expiryDate = picked;
            setState(() {});
            setRowState(() {});
          }
        }

        Future<void> pickMedicineSingle() async {
          final result = await showDialog<List<Medicine>>(
            context: context,
            builder: (_) => _MedicineMultiPickerDialog(
              inventoryCtrl: inventoryCtrl,
              selectedIds: draftItems.map((e) => e.selectedMedicineId).whereType<String>().toSet(),
              singleSelection: true,
            ),
          );

          if (result == null || result.isEmpty) return;

          item.fillFromMedicine(result.first);
          setState(() {});
          setRowState(() {});
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _cellSized(
                50,
                Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              _cellSized(
                260,
                InkWell(
                  onTap: pickMedicineSingle,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bgSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.box, size: 17, color: _textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.selectedMedicineName ?? 'اختيار صنف',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.selectedMedicineName == null ? _textMuted : _textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.category != null && item.category!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.category!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Iconsax.arrow_down_1, size: 16, color: _textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              _cellSized(
                130,
                TextFormField(
                  controller: item.barcodeCtrl,
                  decoration: _inputDecoration('باركود', Iconsax.barcode),
                ),
              ),
              _cellSized(
                170,
                _modeSegment(
                  value: item.purchaseMode,
                  onChanged: (mode) {
                    item.purchaseMode = mode;
                    setState(() {});
                    setRowState(() {});
                  },
                ),
              ),
              _cellSized(
                120,
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _bgSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: CheckboxListTile(
                    value: item.sellByPiece,
                    onChanged: (v) {
                      item.sellByPiece = v ?? false;
                      if (!item.sellByPiece) {
                        item.piecePriceCtrl.clear();
                      }
                      setState(() {});
                      setRowState(() {});
                    },
                    dense: true,
                    activeColor: _primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    title: const Text(
                      'نعم',
                      style: TextStyle(fontSize: 12.3, fontWeight: FontWeight.w700),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ),
              _cellSized(
                100,
                TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    item.purchaseMode == _PurchaseMode.package ? 'عبوات' : 'قطاعي',
                    item.purchaseMode == _PurchaseMode.package ? Iconsax.archive : Iconsax.category,
                  ),
                  onChanged: (_) {
                    setState(() {});
                    setRowState(() {});
                  },
                  validator: (v) {
                    final val = int.tryParse((v ?? '').trim());
                    if (val == null || val <= 0) return 'مطلوب';
                    return null;
                  },
                ),
              ),
              _cellSized(
                120,
                TextFormField(
                  controller: item.unitsPerPackageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('عدد القطع', Iconsax.box_1),
                  onChanged: (_) {
                    setState(() {});
                    setRowState(() {});
                  },
                  validator: (v) {
                    if (item.purchaseMode == _PurchaseMode.package) {
                      final val = int.tryParse((v ?? '').trim());
                      if (val == null || val <= 0) return 'مطلوب';
                    }
                    return null;
                  },
                ),
              ),
              _cellSized(
                120,
                TextFormField(
                  controller: item.purchasePriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(
                    item.purchaseMode == _PurchaseMode.package ? 'شراء عبوة' : 'شراء قطعة',
                    Iconsax.money_4,
                  ),
                  onChanged: (_) {
                    setState(() {});
                    setRowState(() {});
                  },
                  validator: (v) {
                    final val = double.tryParse((v ?? '').trim());
                    if (val == null || val <= 0) return 'مطلوب';
                    return null;
                  },
                ),
              ),
              _cellSized(
                120,
                TextFormField(
                  controller: item.sellingPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('بيع عبوة', Iconsax.wallet_3),
                  onChanged: (_) {
                    setState(() {});
                    setRowState(() {});
                  },
                ),
              ),
              _cellSized(
                120,
                TextFormField(
                  controller: item.piecePriceCtrl,
                  enabled: item.sellByPiece,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('بيع قطعة', Iconsax.coin_1),
                  onChanged: (_) {
                    setState(() {});
                    setRowState(() {});
                  },
                ),
              ),

              _cellSized(
                140,
                InkWell(
                  onTap: pickExpiry,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bgSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.calendar, size: 18, color: _textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.expiryDate == null ? 'اختيار' : _formatDate(item.expiryDate!),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.expiryDate == null ? _textMuted : _textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _cellSized(
                130,
                Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'إجمالي',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currency(item.lineTotal),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _cellSized(
                54,
                Center(
                  child: IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection() {
    return _sectionCard(
      title: 'ملخص الفاتورة',
      icon: Iconsax.money_4,
      expandChild: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryTile(
              title: 'عدد الأصناف',
              value: '$totalLines',
              icon: Iconsax.box_1,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 10),
            _summaryTile(
              title: 'إجمالي العبوات',
              value: '$totalPackages',
              icon: Iconsax.archive,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 10),
            _summaryTile(
              title: 'إجمالي القطاعي',
              value: '$totalPieces',
              icon: Iconsax.category,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 10),
            _summaryTile(
              title: 'الإجمالي قبل الخصم',
              value: _currency(subtotal),
              icon: Iconsax.receipt_1,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 10),
            _summaryTile(
              title: 'الخصم',
              value: _currency(discount),
              icon: Iconsax.discount_shape,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 10),
            _summaryTile(
              title: 'الإجمالي النهائي',
              value: _currency(total),
              icon: Iconsax.wallet_3,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryLight, _primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجمالي المستحق',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F8FD),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: submitting ? null : () => Get.back(),
            icon: const Icon(Iconsax.close_circle, size: 16),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: submitting ? null : _submit,
            icon: submitting
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Iconsax.receipt_add, size: 16),
            label: Text(submitting ? 'جارٍ الحفظ...' : 'إنشاء الفاتورة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return GetBuilder<SupplierController>(
      builder: (_) {
        List<dynamic> suppliers = [];
        try {
          suppliers = (supplierCtrl as dynamic).suppliers ?? [];
        } catch (_) {}

        return DropdownButtonFormField<String>(
          value: selectedSupplierId,
          decoration: _inputDecoration('اختر المورد', Iconsax.building_3),
          items: suppliers.map((supplier) {
            final id = supplier.id?.toString() ?? '';
            final name = supplier.name?.toString() ??
                supplier.supplierName?.toString() ??
                supplier['name']?.toString() ??
                supplier['supplierName']?.toString() ??
                'مورد';

            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            dynamic selected;
            try {
              selected = suppliers.firstWhere((e) => (e.id?.toString() ?? '') == value);
            } catch (_) {}

            final name = selected?.name?.toString() ??
                selected?.supplierName?.toString() ??
                selected?['name']?.toString() ??
                selected?['supplierName']?.toString() ??
                '';

            setState(() {
              selectedSupplierId = value;
              selectedSupplierName = name;
              supplierNameCtrl.text = name;
            });
          },
          validator: (value) => value == null || value.isEmpty ? 'اختر المورد' : null,
        );
      },
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 12.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar, color: _primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? headerAction,
    bool expandChild = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (headerAction != null) headerAction,
              ],
            ),
            const SizedBox(height: 14),
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }

  Widget _miniInfoChip(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _primary),
          const SizedBox(width: 6),
          Text(
            '$title: ',
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 12.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSegment({
    required _PurchaseMode value,
    required ValueChanged<_PurchaseMode> onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              title: 'جملة',
              active: value == _PurchaseMode.package,
              onTap: () => onChanged(_PurchaseMode.package),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _modeButton(
              title: 'قطاعي',
              active: value == _PurchaseMode.piece,
              onTap: () => onChanged(_PurchaseMode.piece),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required bool active,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _cellSized(double width, Widget child) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _emptyItemsState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _bgSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.box_add, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'لا توجد أصناف في الفاتورة',
              style: TextStyle(
                color: _textDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'ابدأ بإضافة صنف من المخزون أو أضف سطرًا فارغًا وأدخل البيانات يدويًا',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

enum _PurchaseMode { package, piece }

class _PurchaseItemDraft {
  String? selectedMedicineId;
  String? selectedMedicineName;
  String? category;
  DateTime? expiryDate;

  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController purchasePriceCtrl = TextEditingController();
  final TextEditingController sellingPriceCtrl = TextEditingController();
  final TextEditingController piecePriceCtrl = TextEditingController();
  final TextEditingController batchCtrl = TextEditingController();
  final TextEditingController barcodeCtrl = TextEditingController();
  final TextEditingController unitsPerPackageCtrl = TextEditingController();

  bool sellByPiece = false;
  _PurchaseMode purchaseMode = _PurchaseMode.package;
  UnitType? unitType;

  _PurchaseItemDraft.empty();

  _PurchaseItemDraft.fromMedicine(Medicine med) {
    fillFromMedicine(med);
  }

  int get qty => int.tryParse(qtyCtrl.text.trim()) ?? 0;

  int get unitsPerPackage => int.tryParse(unitsPerPackageCtrl.text.trim()) ?? 0;

  double get purchaseUnitPrice => double.tryParse(purchasePriceCtrl.text.trim()) ?? 0.0;

  double get sellingPrice => double.tryParse(sellingPriceCtrl.text.trim()) ?? 0.0;

  double get pieceSellingPrice {
    final direct = double.tryParse(piecePriceCtrl.text.trim());
    if (direct != null && direct > 0) return direct;

    if (sellByPiece && unitsPerPackage > 0 && sellingPrice > 0) {
      return sellingPrice / unitsPerPackage;
    }
    return 0.0;
  }

  double get lineTotal => qty * purchaseUnitPrice;

  void fillFromMedicine(Medicine med) {
    selectedMedicineId = med.id;
    selectedMedicineName = med.name;
    category = med.category;
    unitType = med.unit;
    expiryDate = med.expiryDate;

    barcodeCtrl.text = med.barcode ?? '';
    unitsPerPackageCtrl.text = med.unitsPerPackage?.toString() ?? '';
    purchasePriceCtrl.text = (med.purchasePrice ?? 0).toStringAsFixed(
      (med.purchasePrice ?? 0) % 1 == 0 ? 0 : 2,
    );
    sellingPriceCtrl.text = (med.sellingPrice ?? 0).toStringAsFixed(
      (med.sellingPrice ?? 0) % 1 == 0 ? 0 : 2,
    );

    sellByPiece = med.sellByPiece;

    final piece = med.piecePrice ??
        ((med.sellByPiece && (med.unitsPerPackage ?? 0) > 0 && (med.sellingPrice ?? 0) > 0)
            ? (med.sellingPrice! / med.unitsPerPackage!)
            : 0.0);

    piecePriceCtrl.text = piece > 0 ? piece.toStringAsFixed(piece % 1 == 0 ? 0 : 2) : '';
    purchaseMode = _PurchaseMode.package;
  }

  void dispose() {
    qtyCtrl.dispose();
    purchasePriceCtrl.dispose();
    sellingPriceCtrl.dispose();
    piecePriceCtrl.dispose();
    batchCtrl.dispose();
    barcodeCtrl.dispose();
    unitsPerPackageCtrl.dispose();
  }
}

class _MedicineMultiPickerDialog extends StatefulWidget {
  final InventoryController inventoryCtrl;
  final Set<String> selectedIds;
  final bool singleSelection;

  const _MedicineMultiPickerDialog({
    required this.inventoryCtrl,
    required this.selectedIds,
    this.singleSelection = false,
  });

  @override
  State<_MedicineMultiPickerDialog> createState() => _MedicineMultiPickerDialogState();
}

class _MedicineMultiPickerDialogState extends State<_MedicineMultiPickerDialog> {
  static const Color _primary = Color(0xFF1D4ED8);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  final TextEditingController searchCtrl = TextEditingController();
  final Set<String> localSelectedIds = {};
  String query = '';

  @override
  void initState() {
    super.initState();
    localSelectedIds.addAll(widget.selectedIds);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  List<Medicine> get _filtered {
    final all = widget.inventoryCtrl.medicines.toList();
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return all;
    }

    final result = all.where((m) {
      final name = m.name.toLowerCase();
      final sci = m.scientificName.toLowerCase();
      final barcode = (m.barcode ?? '').toLowerCase();
      final supplier = (m.supplier ?? '').toLowerCase();
      final category = (m.category ?? '').toLowerCase();

      return name.contains(q) ||
          sci.contains(q) ||
          barcode.contains(q) ||
          supplier.contains(q) ||
          category.contains(q);
    }).toList();

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  void _toggle(String id) {
    setState(() {
      if (widget.singleSelection) {
        localSelectedIds
          ..clear()
          ..add(id);
      } else {
        if (localSelectedIds.contains(id)) {
          localSelectedIds.remove(id);
        } else {
          localSelectedIds.add(id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Dialog(
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 980,
        height: 680,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF6FAFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.search_normal_1, color: _primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.singleSelection ? 'اختيار صنف' : 'إضافة أصناف من المخزون',
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: searchCtrl,
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الاسم العلمي أو الباركود أو المورد',
                  prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'عدد النتائج: ${results.length}',
                    style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!widget.singleSelection)
                    Text(
                      'المحدد: ${localSelectedIds.length}',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                child: Text(
                  'لا توجد أصناف مطابقة',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final med = results[index];
                  final checked = localSelectedIds.contains(med.id);

                  return InkWell(
                    onTap: () => _toggle(med.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: checked ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: checked ? _primary : _border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: (_) => _toggle(med.id),
                            activeColor: _primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontSize: 14.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _pickerTag(Iconsax.scissor, med.scientificName),
                                    _pickerTag(Iconsax.tag, med.category ?? 'بدون تصنيف'),
                                    _pickerTag(Iconsax.barcode, med.barcode ?? 'بدون باركود'),
                                    _pickerTag(Iconsax.truck, med.supplier ?? 'بدون مورد'),
                                    _pickerTag(Iconsax.archive, 'كمية: ${med.quantity}'),
                                    _pickerTag(
                                      Iconsax.money_4,
                                      'شراء: ${(med.purchasePrice ?? 0).toStringAsFixed(2)}',
                                    ),
                                    _pickerTag(
                                      Iconsax.wallet_3,
                                      'بيع: ${(med.sellingPrice ?? 0).toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final selected = widget.inventoryCtrl.medicines
                          .where((m) => localSelectedIds.contains(m.id))
                          .toList();

                      Navigator.pop(context, selected);
                    },
                    icon: const Icon(Iconsax.tick_circle, size: 16),
                    label: Text(widget.singleSelection ? 'اختيار الصنف' : 'إضافة المحدد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}