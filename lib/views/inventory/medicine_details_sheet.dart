import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/inventory_model.dart';

class MedicineDetailsSheet extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEditPressed;

  const MedicineDetailsSheet({
    Key? key,
    required this.medicine,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24), // تقليل المساحة
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header متميز
          _buildDialogHeader(isDark),
          const SizedBox(height: 16), // تقليل المسافة

          // محتوى رئيسي مع Scroll
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return _buildWideLayout(isDark);
                  } else {
                    return _buildNarrowLayout(isDark);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16), // تقليل المسافة
          _buildActionButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildWideLayout(bool isDark) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            // العمود الأول - المعلومات الأساسية مع الصورة
            _buildBasicInfoColumn(isDark),

            // العمود الثاني - التسعير والمخزون
            _buildPricingStockColumn(isDark),

            // العمود الثالث - المعلومات الإضافية
            _buildAdditionalInfoColumn(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoColumn(isDark),
        SizedBox(height: 16), // تقليل المسافة
        _buildPricingStockColumn(isDark),
        SizedBox(height: 16), // تقليل المسافة
        _buildAdditionalInfoColumn(isDark),
      ],
    );
  }

  Widget _buildDialogHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16), // تقليل المساحة
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252A40) : Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16), // تقليل الزوايا
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12, // تقليل التظليل
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // صورة الدواء
                _buildMedicineImage(isDark),
                SizedBox(width: 16), // تقليل المسافة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: TextStyle(
                          fontSize: 20, // خط متوسط
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Color(0xFF1A237E),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4), // تقليل المسافة
                      Text(
                        medicine.scientificName,
                        style: TextStyle(
                          fontSize: 14, // خط متوسط
                          color: isDark ? Color(0xFFA0AEC0) : Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16), // تقليل المسافة
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Status Badges
              Wrap(
                spacing: 6, // تقليل المسافة
                runSpacing: 6,
                children: [
                  if (medicine.isExpired)
                    _buildStatusBadge('منتهي الصلاحية', Color(0xFFF56565), isDark),
                  if (medicine.isLowStock)
                    _buildStatusBadge('كمية منخفضة', Color(0xFFED8936), isDark),
                  if (medicine.sellByPiece)
                    _buildStatusBadge('بيع بالقطعة', Color(0xFF38B2AC), isDark),
                ],
              ),
              SizedBox(height: 8), // تقليل المسافة
              IconButton(
                onPressed: Get.back,
                icon: Icon(
                  Icons.close_rounded,
                  size: 24, // أيقونة أصغر
                  color: isDark ? Color(0xFFA0AEC0) : Color(0xFF718096),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Color(0xFF2D3748) : Color(0xFFEDF2F7),
                  padding: EdgeInsets.all(6), // تقليل المساحة
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // تقليل الزوايا
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineImage(bool isDark) {
    if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty) {
      return Container(
        width: 70, // تصغير الصورة
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14), // تقليل الزوايا
          border: Border.all(
            color: isDark ? Color(0xFF4299E1) : Color(0xFF3182CE),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Color(0xFF4299E1) : Color(0xFF3182CE)).withOpacity(0.3),
              blurRadius: 10, // تقليل التظليل
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // تقليل الزوايا
          child: Image.network(
            medicine.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(isDark ? Color(0xFF4299E1) : Color(0xFF3182CE)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(isDark),
          ),
        ),
      );
    }
    return _buildFallbackIcon(isDark);
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Container(
      width: 70, // تصغير الأيقونة
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Color(0xFF3182CE), Color(0xFF805AD5)]
              : [Color(0xFF4299E1), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14), // تقليل الزوايا
        boxShadow: [
          BoxShadow(
            color: (isDark ? Color(0xFF3182CE) : Color(0xFF4299E1)).withOpacity(0.4),
            blurRadius: 10, // تقليل التظليل
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.medication_rounded,
        size: 34, // تصغير الأيقونة
        color: Colors.white,
      ),
    );
  }

  Widget _buildBasicInfoColumn(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16), // تقليل المساحة
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252A40) : Colors.white,
        borderRadius: BorderRadius.circular(16), // تقليل الزوايا
        border: Border.all(
          color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المعلومات الأساسية', Icons.info_outline_rounded, isDark),
          SizedBox(height: 12), // تقليل المسافة

          Wrap(
            runSpacing: 12, // تقليل المسافة
            children: [
              _buildInfoItem(
                title: 'الصنف',
                value: medicine.category ?? 'غير محدد',
                icon: Icons.category_rounded,
                iconColor: Color(0xFF805AD5),
                isDark: isDark,
              ),
              _buildInfoItem(
                title: 'الوحدة',
                value: _getUnitName(medicine.unit),
                icon: Icons.scale_rounded,
                iconColor: Color(0xFF38B2AC),
                isDark: isDark,
              ),
              if (medicine.unitsPerPackage != null)
                _buildInfoItem(
                  title: 'القطع/العلبة',
                  value: '${medicine.unitsPerPackage} قطعة',
                  icon: Icons.layers_rounded,
                  iconColor: Color(0xFF4299E1),
                  isDark: isDark,
                ),
              _buildInfoItem(
                title: 'المورد',
                value: medicine.supplier ?? 'غير محدد',
                icon: Icons.business_rounded,
                iconColor: Color(0xFFED8936),
                isDark: isDark,
              ),
              if (medicine.barcode != null && medicine.barcode!.isNotEmpty)
                _buildInfoItem(
                  title: 'الباركود',
                  value: medicine.barcode!,
                  icon: Icons.qr_code_rounded,
                  iconColor: Color(0xFF319795),
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStockColumn(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16), // تقليل المساحة
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252A40) : Colors.white,
        borderRadius: BorderRadius.circular(16), // تقليل الزوايا
        border: Border.all(
          color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المخزون', Icons.inventory_2_rounded, isDark),
          SizedBox(height: 12), // تقليل المسافة

          Container(
            padding: EdgeInsets.all(16), // تقليل المساحة
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: medicine.isLowStock
                    ? isDark
                    ? [Color(0xFF552211), Color(0xFF774422)]
                    : [Color(0xFFFFF5F5), Color(0xFFFED7D7)]
                    : isDark
                    ? [Color(0xFF1A365D), Color(0xFF2D3748)]
                    : [Color(0xFFEBF8FF), Color(0xFFBEE3F8)],
              ),
              borderRadius: BorderRadius.circular(14), // تقليل الزوايا
              border: Border.all(
                color: medicine.isLowStock
                    ? isDark ? Color(0xFFC53030) : Color(0xFFE53E3E)
                    : isDark ? Color(0xFF3182CE) : Color(0xFF4299E1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'الكمية المتاحة',
                  style: TextStyle(
                    fontSize: 14, // خط متوسط
                    color: isDark ? Color(0xFFA0AEC0) : Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8), // تقليل المسافة
                Text(
                  '${medicine.quantity} ${_getUnitName(medicine.unit)}',
                  style: TextStyle(
                    fontSize: 24, // خط متوسط
                    fontWeight: FontWeight.w700,
                    color: medicine.isLowStock
                        ? isDark ? Color(0xFFFC8181) : Color(0xFFE53E3E)
                        : isDark ? Color(0xFF90CDF4) : Color(0xFF3182CE),
                    letterSpacing: -0.5,
                  ),
                ),

                if (medicine.minStockLevel != null) ...[
                  SizedBox(height: 12), // تقليل المسافة
                  Divider(
                    height: 1,
                    color: isDark ? Color(0xFF4A5568) : Color(0xFFE2E8F0),
                  ),
                  SizedBox(height: 12), // تقليل المسافة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الحد الأدنى للمخزون',
                        style: TextStyle(
                          fontSize: 12, // خط متوسط
                          color: isDark ? Color(0xFFA0AEC0) : Color(0xFF718096),
                        ),
                      ),
                      Text(
                        '${medicine.minStockLevel}',
                        style: TextStyle(
                          fontSize: 18, // خط متوسط
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20), // تقليل المسافة
          _buildSectionTitle('التسعير', Icons.monetization_on_rounded, isDark),
          SizedBox(height: 12), // تقليل المسافة

          Wrap(
            runSpacing: 12, // تقليل المسافة
            children: [
              _buildPriceItem(
                title: 'سعر الشراء',
                price: medicine.purchasePrice,
                icon: Icons.shopping_cart_rounded,
                color: Color(0xFF38A169),
                isDark: isDark,
              ),
              _buildPriceItem(
                title: 'سعر البيع',
                price: medicine.sellingPrice,
                icon: Icons.sell_rounded,
                color: Color(0xFF3182CE),
                isDark: isDark,
              ),
              if (medicine.sellByPiece && medicine.piecePrice != null)
                _buildPriceItem(
                  title: 'سعر القطعة',
                  price: medicine.piecePrice,
                  icon: Icons.monetization_on_rounded,
                  color: Color(0xFF805AD5),
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoColumn(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16), // تقليل المساحة
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252A40) : Colors.white,
        borderRadius: BorderRadius.circular(16), // تقليل الزوايا
        border: Border.all(
          color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (medicine.description != null && medicine.description!.isNotEmpty) ...[
            _buildSectionTitle('الوصف', Icons.description_rounded, isDark),
            SizedBox(height: 12), // تقليل المسافة
            Container(
              padding: EdgeInsets.all(16), // تقليل المساحة
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A202C) : Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(14), // تقليل الزوايا
                border: Border.all(
                  color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                medicine.description!,
                style: TextStyle(
                  fontSize: 14, // خط متوسط
                  color: isDark ? Color(0xFFE2E8F0) : Color(0xFF4A5568),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            SizedBox(height: 20), // تقليل المسافة
          ],

          if (medicine.expiryDate != null) ...[
            _buildSectionTitle('تاريخ الصلاحية', Icons.calendar_month_rounded, isDark),
            SizedBox(height: 12), // تقليل المسافة
            _buildExpiryDateCard(isDark),
            SizedBox(height: 20), // تقليل المسافة
          ],

          if (medicine.lastUpdated != null) ...[
            _buildSectionTitle('آخر تحديث', Icons.update_rounded, isDark),
            SizedBox(height: 12), // تقليل المسافة
            Container(
              padding: EdgeInsets.all(16), // تقليل المساحة
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A202C) : Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(14), // تقليل الزوايا
                border: Border.all(
                  color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, // تصغير الحاوية
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10), // تقليل الزوايا
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      size: 20, // تصغير الأيقونة
                      color: isDark ? Color(0xFF90CDF4) : Color(0xFF3182CE),
                    ),
                  ),
                  SizedBox(width: 12), // تقليل المسافة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم التحديث في',
                          style: TextStyle(
                            fontSize: 12, // خط متوسط
                            color: isDark ? Color(0xFFA0AEC0) : Color(0xFF718096),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy - HH:mm').format(medicine.lastUpdated!), // تبسيط التنسيق
                          style: TextStyle(
                            fontSize: 15, // خط متوسط
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpiryDateCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16), // تقليل المساحة
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: medicine.isExpired
              ? isDark
              ? [Color(0xFF63171B), Color(0xFF742A2A)]
              : [Color(0xFFFFF5F5), Color(0xFFFED7D7)]
              : isDark
              ? [Color(0xFF22543D), Color(0xFF276749)]
              : [Color(0xFFF0FFF4), Color(0xFFC6F6D5)],
        ),
        borderRadius: BorderRadius.circular(14), // تقليل الزوايا
        border: Border.all(
          color: medicine.isExpired
              ? isDark ? Color(0xFFF56565) : Color(0xFFE53E3E)
              : isDark ? Color(0xFF38A169) : Color(0xFF48BB78),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50, // تصغير الحاوية
            height: 50,
            decoration: BoxDecoration(
              color: medicine.isExpired
                  ? (isDark ? Color(0xFFF56565).withOpacity(0.2) : Color(0xFFE53E3E).withOpacity(0.1))
                  : (isDark ? Color(0xFF38A169).withOpacity(0.2) : Color(0xFF48BB78).withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12), // تقليل الزوايا
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 26, // تصغير الأيقونة
              color: medicine.isExpired
                  ? isDark ? Color(0xFFFC8181) : Color(0xFFE53E3E)
                  : isDark ? Color(0xFF68D391) : Color(0xFF38A169),
            ),
          ),
          SizedBox(width: 16), // تقليل المسافة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.isExpired ? 'منتهي الصلاحية' : 'صالحة حتى',
                  style: TextStyle(
                    fontSize: 14, // خط متوسط
                    color: medicine.isExpired
                        ? isDark ? Color(0xFFFC8181) : Color(0xFFE53E3E)
                        : isDark ? Color(0xFF68D391) : Color(0xFF38A169),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(medicine.expiryDate!), // تبسيط التنسيق
                  style: TextStyle(
                    fontSize: 22, // خط متوسط
                    fontWeight: FontWeight.w700,
                    color: medicine.isExpired
                        ? isDark ? Color(0xFFF56565) : Color(0xFFC53030)
                        : isDark ? Color(0xFF48BB78) : Color(0xFF276749),
                    letterSpacing: -0.3,
                  ),
                ),
                if (medicine.isExpired) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 16, // تصغير الأيقونة
                        color: isDark ? Color(0xFFF56565) : Color(0xFFE53E3E),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'انتهت صلاحية الدواء',
                        style: TextStyle(
                          fontSize: 12, // خط متوسط
                          color: isDark ? Color(0xFFF56565) : Color(0xFFE53E3E),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40, // تصغير الحاوية
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF3182CE).withOpacity(0.2) : Color(0xFF4299E1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10), // تقليل الزوايا
          ),
          child: Icon(
            icon,
            size: 20, // تصغير الأيقونة
            color: isDark ? Color(0xFF90CDF4) : Color(0xFF3182CE),
          ),
        ),
        SizedBox(width: 10), // تقليل المسافة
        Text(
          title,
          style: TextStyle(
            fontSize: 17, // خط متوسط
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Color(0xFF1A237E),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12), // تقليل المساحة
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A202C) : Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12), // تقليل الزوايا
        border: Border.all(
          color: isDark ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, // تصغير الحاوية
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8), // تقليل الزوايا
            ),
            child: Icon(
              icon,
              size: 20, // تصغير الأيقونة
              color: iconColor,
            ),
          ),
          SizedBox(width: 12), // تقليل المسافة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12, // خط متوسط
                    color: isDark ? Color(0xFFA0AEC0) : Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2), // تقليل المسافة
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14, // خط متوسط
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Color(0xFF2D3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required String title,
    required double? price,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16), // تقليل المساحة
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(14), // تقليل الزوايا
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, // تصغير الحاوية
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8), // تقليل الزوايا
                ),
                child: Icon(
                  icon,
                  size: 20, // تصغير الأيقونة
                  color: color,
                ),
              ),
              SizedBox(width: 10), // تقليل المسافة
              Text(
                title,
                style: TextStyle(
                  fontSize: 14, // خط متوسط
                  color: isDark ? Color(0xFFCBD5E0) : Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8), // تقليل المسافة
          Text(
            price != null ? '${price.toStringAsFixed(2)} د.ك' : 'غير محدد', // تقليل النص
            style: TextStyle(
              fontSize: 22, // خط متوسط
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onEditPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Color(0xFF3182CE) : Color(0xFF4299E1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24), // أزرار أصغر
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // تقليل الزوايا
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_rounded, size: 20), // أيقونة أصغر
                SizedBox(width: 8), // تقليل المسافة
                Text(
                  'تعديل الدواء',
                  style: TextStyle(
                    fontSize: 15, // خط متوسط
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12), // تقليل المسافة
        Expanded(
          child: OutlinedButton(
            onPressed: Get.back,
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? Color(0xFF2D3748) : Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24), // أزرار أصغر
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // تقليل الزوايا
              ),
              side: BorderSide(
                color: isDark ? Color(0xFF4A5568) : Color(0xFFCBD5E0),
                width: 1.2,
              ),
            ),
            child: Text(
              'إغلاق',
              style: TextStyle(
                fontSize: 15, // خط متوسط
                fontWeight: FontWeight.w600,
                color: isDark ? Color(0xFFCBD5E0) : Color(0xFF4A5568),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // تقليل المساحة
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16), // تقليل الزوايا
        border: Border.all(
          color: color.withOpacity(isDark ? 0.4 : 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, // تصغير النقطة
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 6), // تقليل المسافة
          Text(
            text,
            style: TextStyle(
              fontSize: 12, // خط متوسط
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getUnitName(UnitType? unit) {
    if (unit == null) return 'وحدة';

    final unitNames = {
      UnitType.Tablet: 'قرص',
      UnitType.Capsule: 'كبسولة',
      UnitType.Syrup: 'شراب',
      UnitType.Drops: 'قطرة',
      UnitType.Bottle: 'زجاجة',
      UnitType.Ampoule: 'أمبولة',
      UnitType.Vial: 'قارورة',
      UnitType.Ointment: 'مرهم',
      UnitType.Cream: 'كريم',
      UnitType.Gel: 'جل',
      UnitType.Spray: 'سبراي',
      UnitType.Patch: 'لصقة',
      UnitType.Powder: 'مسحوق',
      UnitType.Sachet: 'كيس',
      UnitType.Suppository: 'تحميلة',
      UnitType.Inhaler: 'بخاخ',
      UnitType.Suspension: 'معلق',
      UnitType.Solution: 'محلول',
      UnitType.Lotion: 'لوشن',
      UnitType.Strip: 'شريط',
      UnitType.Tube: 'أنبوب',
    };

    return unitNames[unit] ?? unit.name;
  }
}