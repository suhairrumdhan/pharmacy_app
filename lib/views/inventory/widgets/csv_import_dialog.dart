import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../models/inventory_model.dart';

class CSVImportDialog extends StatefulWidget {
  final List<dynamic> headers;

  const CSVImportDialog({super.key, required this.headers});

  @override
  State<CSVImportDialog> createState() => _CSVImportDialogState();
}

class _CSVImportDialogState extends State<CSVImportDialog> {
  final Map<String, int> mapping = {};

  // =========================
  // ✅ Apply-to-all controllers
  // =========================
  final supplierCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final minStockCtrl = TextEditingController(text: '10');

  final purchasePriceCtrl = TextEditingController();
  final sellingPriceCtrl = TextEditingController();

  final descriptionCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();

  final unitsPerPackageCtrl = TextEditingController(text: '1');
  final piecePriceCtrl = TextEditingController();
  final pieceQuantityCtrl = TextEditingController(text: '0');

  bool applySupplier = false;
  bool applyCategory = false;
  bool applyMinStock = false;

  bool applyPurchasePrice = false;
  bool applySellingPrice = false;

  bool applyDescription = false;
  bool applyImageUrl = false;

  bool applyUnit = false;
  bool applyUnitsPerPackage = false;

  bool applySellByPiece = false;
  bool sellByPieceValue = false;

  bool applyPiecePrice = false;
  bool applyPieceQuantity = false;

  UnitType unitValue = UnitType.Tablet;

  // =========================
  // ✅ Mapping fields
  // =========================
  final List<String> systemFields = [
    "id",
    "name",
    "scientificName",
    "category",
    "description",
    "purchasePrice",
    "sellingPrice",
    "unit",
    "unitsPerPackage",
    "sellByPiece",
    "piecePrice",
    "pieceQuantity",
    "quantity",
    "minStockLevel",
    "supplier",
    "expiryDate",
    "barcode",
    "imageUrl",
  ];

  final Map<String, String> displayNames = {
    "id": "المعرف (اختياري)",
    "name": "اسم الدواء *",
    "scientificName": "الاسم العلمي",
    "category": "الفئة",
    "description": "الوصف",
    "purchasePrice": "سعر الشراء",
    "sellingPrice": "سعر البيع",
    "unit": "الوحدة",
    "unitsPerPackage": "عدد القطع في العلبة",
    "sellByPiece": "البيع بالقطعة",
    "piecePrice": "سعر القطعة",
    "pieceQuantity": "كمية القطع",
    "quantity": "كمية العلب",
    "minStockLevel": "أقل مخزون",
    "supplier": "المورد",
    "expiryDate": "تاريخ الصلاحية",
    "barcode": "الباركود",
    "imageUrl": "رابط الصورة",
  };

  bool _isColumnUsed(int index, String field) {
    return mapping.entries.any((e) => e.value == index && e.key != field);
  }

  @override
  void dispose() {
    supplierCtrl.dispose();
    categoryCtrl.dispose();
    minStockCtrl.dispose();
    purchasePriceCtrl.dispose();
    sellingPriceCtrl.dispose();
    descriptionCtrl.dispose();
    imageUrlCtrl.dispose();
    unitsPerPackageCtrl.dispose();
    piecePriceCtrl.dispose();
    pieceQuantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 900;

    // تحديد عرض الديالوج بناءً على حجم الشاشة
    double dialogWidth;
    if (isSmallScreen) {
      dialogWidth = screenWidth * 0.95;
    } else {
      dialogWidth = 1100.0; // عرض أكبر للشاشات الكبيرة لتقسيم المحتوى
    }

    final dialogMaxHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // ✅ التدرج اللوني السابق (أزرق فاتح)
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE1F5FE), Colors.white, Color(0xFFE8F0FE)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 50,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.75), // شفافية أنيقة
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildNotes(),
                    const SizedBox(height: 20),

                    Expanded(
                      child: isSmallScreen
                          ? _buildMobileLayout()
                          : _buildDesktopLayout(),
                    ),

                    const SizedBox(height: 16),
                    _buildButtons(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================= تصميم سطح المكتب (قسمين) =========================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الجزء الأيمن - ربط الأعمدة
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF7E57C2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.link, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        ' ربط الأعمدة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.headers.length} أعمدة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.white54),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _buildMappingList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // الجزء الأيسر - القيم العامة
        Expanded(
          flex: 7,
          child: Container(
            margin: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7E57C2), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.setting, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        ' قيم عامة لكل الأدوية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.white54),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ✅ أهم الأشياء أولاً
                        _applyTextRow(
                          title: 'المورد',
                          fieldName: 'supplier',
                          enabled: applySupplier,
                          onToggle: (v) => setState(() => applySupplier = v),
                          controller: supplierCtrl,
                          hint: 'شركة اليسر للأدوية',
                          icon: Iconsax.building,
                        ),
                        const SizedBox(height: 10),

                        _applyTextRow(
                          title: 'الفئة',
                          fieldName: 'category',
                          enabled: applyCategory,
                          onToggle: (v) => setState(() => applyCategory = v),
                          controller: categoryCtrl,
                          hint: 'حساسية / مسكنات / مضادات',
                          icon: Iconsax.category,
                        ),
                        const SizedBox(height: 10),

                        _applyNumberRow(
                          title: 'أقل مخزون',
                          fieldName: 'minStockLevel',
                          enabled: applyMinStock,
                          onToggle: (v) => setState(() => applyMinStock = v),
                          controller: minStockCtrl,
                          hint: '10',
                          icon: Iconsax.box,
                        ),
                        const SizedBox(height: 10),

                        // ✅ أسعار
                        _applyNumberRow(
                          title: 'سعر الشراء',
                          fieldName: 'purchasePrice',
                          enabled: applyPurchasePrice,
                          onToggle: (v) => setState(() => applyPurchasePrice = v),
                          controller: purchasePriceCtrl,
                          hint: '10.50',
                          isDouble: true,
                          icon: Iconsax.money_recive,
                        ),
                        const SizedBox(height: 10),

                        _applyNumberRow(
                          title: 'سعر البيع',
                          fieldName: 'sellingPrice',
                          enabled: applySellingPrice,
                          onToggle: (v) => setState(() => applySellingPrice = v),
                          controller: sellingPriceCtrl,
                          hint: '14.00',
                          isDouble: true,
                          icon: Iconsax.money_send,
                        ),
                        const SizedBox(height: 10),

                        // ✅ وصف وصورة
                        _applyTextRow(
                          title: 'الوصف',
                          fieldName: 'description',
                          enabled: applyDescription,
                          onToggle: (v) => setState(() => applyDescription = v),
                          controller: descriptionCtrl,
                          hint: 'نص ثابت للوصف',
                          maxLines: 2,
                          icon: Iconsax.note_text,
                        ),
                        const SizedBox(height: 10),

                        _applyTextRow(
                          title: 'رابط الصورة',
                          fieldName: 'imageUrl',
                          enabled: applyImageUrl,
                          onToggle: (v) => setState(() => applyImageUrl = v),
                          controller: imageUrlCtrl,
                          hint: 'https://...',
                          icon: Iconsax.gallery,
                        ),
                        const SizedBox(height: 10),

                        // ✅ وحدة + عدد بالعلبة
                        _applyUnitRow(),
                        const SizedBox(height: 10),

                        _applyNumberRow(
                          title: 'عدد القطع في العلبة',
                          fieldName: 'unitsPerPackage',
                          enabled: applyUnitsPerPackage,
                          onToggle: (v) => setState(() => applyUnitsPerPackage = v),
                          controller: unitsPerPackageCtrl,
                          hint: '2',
                          icon: Iconsax.box_1,
                        ),
                        const SizedBox(height: 10),

                        // ✅ بيع بالقطعة + سعر القطعة + كمية القطع
                        _applySellByPieceRow(),
                        const SizedBox(height: 10),

                        _applyNumberRow(
                          title: 'سعر القطعة',
                          fieldName: 'piecePrice',
                          enabled: applyPiecePrice,
                          onToggle: (v) => setState(() => applyPiecePrice = v),
                          controller: piecePriceCtrl,
                          hint: '7',
                          isDouble: true,
                          icon: Iconsax.money,
                        ),
                        const SizedBox(height: 10),

                        _applyNumberRow(
                          title: 'كمية القطع',
                          fieldName: 'pieceQuantity',
                          enabled: applyPieceQuantity,
                          onToggle: (v) => setState(() => applyPieceQuantity = v),
                          controller: pieceQuantityCtrl,
                          hint: '0',
                          icon: Iconsax.status,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================= تصميم الموبايل (عمودي) =========================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // قسم ربط الأعمدة
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF7E57C2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.link, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '🔗 ربط الأعمدة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.white54),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _buildMappingList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // قسم القيم العامة
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7E57C2), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.setting, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '⚙️ قيم عامة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.white54),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // نفس القيم السابقة
                      _applyTextRow(
                        title: 'المورد',
                        fieldName: 'supplier',
                        enabled: applySupplier,
                        onToggle: (v) => setState(() => applySupplier = v),
                        controller: supplierCtrl,
                        hint: 'شركة اليسر للأدوية',
                        icon: Iconsax.building,
                      ),
                      const SizedBox(height: 10),
                      _applyTextRow(
                        title: 'الفئة',
                        fieldName: 'category',
                        enabled: applyCategory,
                        onToggle: (v) => setState(() => applyCategory = v),
                        controller: categoryCtrl,
                        hint: 'حساسية / مسكنات',
                        icon: Iconsax.category,
                      ),
                      const SizedBox(height: 10),
                      _applyNumberRow(
                        title: 'أقل مخزون',
                        fieldName: 'minStockLevel',
                        enabled: applyMinStock,
                        onToggle: (v) => setState(() => applyMinStock = v),
                        controller: minStockCtrl,
                        hint: '10',
                        icon: Iconsax.box,
                      ),
                      const SizedBox(height: 10),
                      _applyNumberRow(
                        title: 'سعر الشراء',
                        fieldName: 'purchasePrice',
                        enabled: applyPurchasePrice,
                        onToggle: (v) => setState(() => applyPurchasePrice = v),
                        controller: purchasePriceCtrl,
                        hint: '10.50',
                        isDouble: true,
                        icon: Iconsax.money_recive,
                      ),
                      const SizedBox(height: 10),
                      _applyNumberRow(
                        title: 'سعر البيع',
                        fieldName: 'sellingPrice',
                        enabled: applySellingPrice,
                        onToggle: (v) => setState(() => applySellingPrice = v),
                        controller: sellingPriceCtrl,
                        hint: '14.00',
                        isDouble: true,
                        icon: Iconsax.money_send,
                      ),
                      const SizedBox(height: 10),
                      _applyUnitRow(),
                      const SizedBox(height: 10),
                      _applySellByPieceRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================= UI Helpers =========================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF7E57C2), Color(0xFFBA68C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Iconsax.import, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استيراد ملف CSV',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'ربط الأعمدة وتحديد القيم العامة',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Iconsax.close_circle, color: Colors.blueGrey),
              tooltip: 'إغلاق',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.info_circle, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "• حقل الاسم مطلوب.\n"
                  "• أي حقل تربطه من CSV بياخذ قيمته من الملف.\n"
                  "• لو الحقل مش مربوط، تقدر تعبيه من القيم العامة.",
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMappingList() {
    return systemFields.map((field) {
      final isRequired = field == 'name';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRequired ? Colors.red.withOpacity(0.3) : Colors.grey.shade300,
              width: isRequired ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isRequired ? Colors.red.shade400 : Colors.blue.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayNames[field] ?? field,
                    style: TextStyle(
                      fontWeight: isRequired ? FontWeight.w800 : FontWeight.w600,
                      color: isRequired ? Colors.red.shade700 : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButton<int>(
                    value: mapping[field],
                    underline: const SizedBox(),
                    hint: const Text("اختر", style: TextStyle(fontSize: 11)),
                    isDense: true,
                    items: List.generate(widget.headers.length, (i) {
                      final used = _isColumnUsed(i, field);
                      return DropdownMenuItem(
                        value: i,
                        enabled: !used,
                        child: Text(
                          widget.headers[i].toString(),
                          style: TextStyle(
                            color: used ? Colors.grey.shade400 : Colors.black,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }),
                    onChanged: (v) {
                      setState(() {
                        if (v == null) return;
                        mapping[field] = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'مسح',
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: mapping.containsKey(field)
                      ? () => setState(() => mapping.remove(field))
                      : null,
                  icon: Icon(
                    Iconsax.close_circle,
                    size: 18,
                    color: mapping.containsKey(field)
                        ? Colors.red.shade400
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _applyTextRow({
    required String title,
    required String fieldName,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required IconData icon,
  }) {
    return _applyRow(
      title: title,
      fieldName: fieldName,
      enabled: enabled,
      onToggle: onToggle,
      icon: icon,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _applyNumberRow({
    required String title,
    required String fieldName,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController controller,
    required String hint,
    bool isDouble = false,
    required IconData icon,
  }) {
    return _applyRow(
      title: title,
      fieldName: fieldName,
      enabled: enabled,
      onToggle: onToggle,
      icon: icon,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _applyUnitRow() {
    return _applyRow(
      title: 'الوحدة',
      fieldName: 'unit',
      enabled: applyUnit,
      onToggle: (v) => setState(() => applyUnit = v),
      icon: Iconsax.element_3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonFormField<UnitType>(
          value: unitValue,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          items: UnitType.values.map((u) {
            return DropdownMenuItem(
              value: u,
              child: Text(u.name, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => unitValue = v);
          },
        ),
      ),
    );
  }

  Widget _applySellByPieceRow() {
    return _applyRow(
      title: 'البيع بالقطعة',
      fieldName: 'sellByPiece',
      enabled: applySellByPiece,
      onToggle: (v) => setState(() => applySellByPiece = v),
      icon: Iconsax.scissor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sellByPieceValue ? '✅ مفعل' : '⭕ غير مفعل',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: sellByPieceValue ? Colors.green.shade700 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
            Switch(
              value: sellByPieceValue,
              onChanged: applySellByPiece
                  ? (v) => setState(() => sellByPieceValue = v)
                  : null,
              activeColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyRow({
    required String title,
    required String fieldName,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? Colors.blue.withOpacity(0.5) : Colors.grey.shade300,
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: enabled ? Colors.blue.shade600 : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: enabled ? Colors.blue.shade800 : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.blue.withOpacity(0.15) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fieldName,
                        style: TextStyle(
                          fontSize: 10,
                          color: enabled ? Colors.blue.shade600 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: enabled,
                        onChanged: onToggle,
                        activeColor: Colors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        thumbIcon: WidgetStateProperty.all(
                          Icon(
                            enabled ? Icons.check : Icons.close,
                            size: 12,
                            color: enabled ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 10),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.close_circle, size: 18),
                  const SizedBox(width: 8),
                  const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.blue.withOpacity(0.4),
              ),
              onPressed: () {
                if (mapping['name'] == null) {
                  Get.snackbar(
                    'خطأ',
                    'يجب اختيار عمود اسم الدواء',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    borderRadius: 12,
                    margin: const EdgeInsets.all(10),
                    icon: const Icon(Iconsax.info_circle, color: Colors.white),
                  );
                  return;
                }

                final defaults = <String, dynamic>{};

                if (applySupplier && supplierCtrl.text.trim().isNotEmpty) {
                  defaults['supplier'] = supplierCtrl.text.trim();
                }
                if (applyCategory && categoryCtrl.text.trim().isNotEmpty) {
                  defaults['category'] = categoryCtrl.text.trim();
                }
                if (applyDescription && descriptionCtrl.text.trim().isNotEmpty) {
                  defaults['description'] = descriptionCtrl.text.trim();
                }
                if (applyImageUrl && imageUrlCtrl.text.trim().isNotEmpty) {
                  defaults['imageUrl'] = imageUrlCtrl.text.trim();
                }

                if (applyMinStock) {
                  final v = int.tryParse(minStockCtrl.text.trim());
                  if (v != null) defaults['minStockLevel'] = v;
                }

                if (applyUnitsPerPackage) {
                  final v = int.tryParse(unitsPerPackageCtrl.text.trim());
                  if (v != null) defaults['unitsPerPackage'] = v;
                }

                if (applyPieceQuantity) {
                  final v = int.tryParse(pieceQuantityCtrl.text.trim());
                  if (v != null) defaults['pieceQuantity'] = v;
                }

                if (applyPurchasePrice) {
                  final v = double.tryParse(purchasePriceCtrl.text.trim().replaceAll(',', ''));
                  if (v != null) defaults['purchasePrice'] = v;
                }
                if (applySellingPrice) {
                  final v = double.tryParse(sellingPriceCtrl.text.trim().replaceAll(',', ''));
                  if (v != null) defaults['sellingPrice'] = v;
                }
                if (applyPiecePrice) {
                  final v = double.tryParse(piecePriceCtrl.text.trim().replaceAll(',', ''));
                  if (v != null) defaults['piecePrice'] = v;
                }

                if (applyUnit) defaults['unit'] = unitValue.name;
                if (applySellByPiece) defaults['sellByPiece'] = sellByPieceValue;

                Get.back(result: {
                  'mapping': mapping,
                  'defaults': defaults,
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.import_1, size: 18),
                  const SizedBox(width: 8),
                  const Text('استيراد', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}