import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/inventory_model.dart';

class MedicineDetailsSheet extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEditPressed;

  const MedicineDetailsSheet({
    super.key,
    required this.medicine,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final compact = w < 520;
        final medium = w >= 520 && w < 900;
        final wide = w >= 900;

        final pad = compact ? 14.0 : (medium ? 18.0 : 24.0);
        final gap = compact ? 12.0 : 16.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(isDark, compact: compact),
              SizedBox(height: gap),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: wide ? _buildWideLayout(isDark) : _buildNarrowLayout(isDark),
                ),
              ),

              SizedBox(height: gap),
              _buildActionButtons(isDark, compact: compact),
            ],
          ),
        );
      },
    );
  }

  // ==================== Layouts ====================

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
            _buildBasicInfoColumn(isDark),
            _buildPricingStockColumn(isDark),
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
        const SizedBox(height: 12),
        _buildPricingStockColumn(isDark),
        const SizedBox(height: 12),
        _buildAdditionalInfoColumn(isDark),
      ],
    );
  }

  // ==================== Header ====================

  Widget _buildDialogHeader(bool isDark, {required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252A40) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrowHeader = c.maxWidth < 700;

          final title = Text(
            medicine.name,
            style: TextStyle(
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A237E),
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

          final subTitle = Text(
            medicine.scientificName,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF666666),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

          final badges = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (medicine.isExpired)
                _buildStatusBadge('منتهي الصلاحية', const Color(0xFFF56565), isDark),
              if (medicine.isLowStock)
                _buildStatusBadge('كمية منخفضة', const Color(0xFFED8936), isDark),
              if (medicine.sellByPiece)
                _buildStatusBadge('بيع بالقطعة', const Color(0xFF38B2AC), isDark),
            ],
          );

          final closeBtn = IconButton(
            onPressed: Get.back,
            icon: Icon(
              Icons.close_rounded,
              size: compact ? 20 : 24,
              color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF718096),
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFEDF2F7),
              padding: EdgeInsets.all(compact ? 6 : 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          if (narrowHeader) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildMedicineImage(isDark, compact: compact),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 4),
                          subTitle,
                        ],
                      ),
                    ),
                    closeBtn,
                  ],
                ),
                const SizedBox(height: 10),
                badges,
              ],
            );
          }

          return Row(
            children: [
              _buildMedicineImage(isDark, compact: compact),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 4),
                    subTitle,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  badges,
                  const SizedBox(height: 8),
                  closeBtn,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== Image ====================

  Widget _buildMedicineImage(bool isDark, {required bool compact}) {
    final size = compact ? 58.0 : 70.0;

    if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF4299E1) : const Color(0xFF3182CE),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF4299E1) : const Color(0xFF3182CE))
                  .withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            medicine.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, prog) {
              if (prog == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isDark ? const Color(0xFF4299E1) : const Color(0xFF3182CE),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _buildFallbackIcon(isDark, compact: compact),
          ),
        ),
      );
    }

    return _buildFallbackIcon(isDark, compact: compact);
  }

  Widget _buildFallbackIcon(bool isDark, {required bool compact}) {
    final size = compact ? 58.0 : 70.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3182CE), const Color(0xFF805AD5)]
              : [const Color(0xFF4299E1), const Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF3182CE) : const Color(0xFF4299E1))
                .withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.medication_rounded,
        size: compact ? 28 : 34,
        color: Colors.white,
      ),
    );
  }

  // ==================== Columns ====================

  Widget _buildBasicInfoColumn(bool isDark) {
    return _cardShell(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المعلومات الأساسية', Icons.info_outline_rounded, isDark),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 12,
            children: [
              _buildInfoItem(
                title: 'الصنف',
                value: medicine.category ?? 'غير محدد',
                icon: Icons.category_rounded,
                iconColor: const Color(0xFF805AD5),
                isDark: isDark,
              ),
              _buildInfoItem(
                title: 'الوحدة',
                value: _getUnitName(medicine.unit),
                icon: Icons.scale_rounded,
                iconColor: const Color(0xFF38B2AC),
                isDark: isDark,
              ),
              if (medicine.unitsPerPackage != null)
                _buildInfoItem(
                  title: 'القطع/العلبة',
                  value: '${medicine.unitsPerPackage} قطعة',
                  icon: Icons.layers_rounded,
                  iconColor: const Color(0xFF4299E1),
                  isDark: isDark,
                ),
              _buildInfoItem(
                title: 'المورد',
                value: medicine.supplier ?? 'غير محدد',
                icon: Icons.business_rounded,
                iconColor: const Color(0xFFED8936),
                isDark: isDark,
              ),
              if (medicine.barcode != null && medicine.barcode!.isNotEmpty)
                _buildInfoItem(
                  title: 'الباركود',
                  value: medicine.barcode!,
                  icon: Icons.qr_code_rounded,
                  iconColor: const Color(0xFF319795),
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStockColumn(bool isDark) {
    return _cardShell(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المخزون', Icons.inventory_2_rounded, isDark),
          const SizedBox(height: 12),

          // Stock block
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: medicine.isLowStock
                    ? (isDark
                    ? [const Color(0xFF552211), const Color(0xFF774422)]
                    : [const Color(0xFFFFF5F5), const Color(0xFFFED7D7)])
                    : (isDark
                    ? [const Color(0xFF1A365D), const Color(0xFF2D3748)]
                    : [const Color(0xFFEBF8FF), const Color(0xFFBEE3F8)]),
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: medicine.isLowStock
                    ? (isDark ? const Color(0xFFC53030) : const Color(0xFFE53E3E))
                    : (isDark ? const Color(0xFF3182CE) : const Color(0xFF4299E1)),
                width: 1.4,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'الكمية المتاحة',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF4A5568),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${medicine.quantity} ${_getUnitName(medicine.unit)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: medicine.isLowStock
                        ? (isDark ? const Color(0xFFFC8181) : const Color(0xFFE53E3E))
                        : (isDark ? const Color(0xFF90CDF4) : const Color(0xFF3182CE)),
                  ),
                ),
                if (medicine.minStockLevel != null) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الحد الأدنى',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF718096),
                        ),
                      ),
                      Text(
                        '${medicine.minStockLevel}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionTitle('التسعير', Icons.monetization_on_rounded, isDark),
          const SizedBox(height: 12),

          Wrap(
            runSpacing: 12,
            children: [
              _buildPriceItem(
                title: 'سعر الشراء',
                price: medicine.purchasePrice,
                icon: Icons.shopping_cart_rounded,
                color: const Color(0xFF38A169),
                isDark: isDark,
              ),
              _buildPriceItem(
                title: 'سعر البيع',
                price: medicine.sellingPrice,
                icon: Icons.sell_rounded,
                color: const Color(0xFF3182CE),
                isDark: isDark,
              ),
              if (medicine.sellByPiece && medicine.piecePrice != null)
                _buildPriceItem(
                  title: 'سعر القطعة',
                  price: medicine.piecePrice,
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFF805AD5),
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoColumn(bool isDark) {
    return _cardShell(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (medicine.description != null && medicine.description!.isNotEmpty) ...[
            _buildSectionTitle('الوصف', Icons.description_rounded, isDark),
            const SizedBox(height: 12),
            _softBox(
              isDark,
              child: Text(
                medicine.description!,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4A5568),
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (medicine.expiryDate != null) ...[
            _buildSectionTitle('تاريخ الصلاحية', Icons.calendar_month_rounded, isDark),
            const SizedBox(height: 12),
            _buildExpiryDateCard(isDark),
            const SizedBox(height: 16),
          ],

          if (medicine.lastUpdated != null) ...[
            _buildSectionTitle('آخر تحديث', Icons.update_rounded, isDark),
            const SizedBox(height: 12),
            _softBox(
              isDark,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF90CDF4) : const Color(0xFF3182CE),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم التحديث في',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy - HH:mm').format(medicine.lastUpdated!),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF2D3748),
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

  // ==================== Small buttons (responsive) ====================

  Widget _buildActionButtons(bool isDark, {required bool compact}) {
    final btnH = compact ? 42.0 : 46.0;
    final iconSz = compact ? 18.0 : 20.0;
    final fontSz = compact ? 13.0 : 14.0;

    return LayoutBuilder(
      builder: (context, c) {
        final stackButtons = c.maxWidth < 520;

        final editBtn = SizedBox(
          height: btnH,
          child: ElevatedButton.icon(
            onPressed: onEditPressed,
            icon: Icon(Icons.edit_rounded, size: iconSz),
            label: Text('تعديل', style: TextStyle(fontSize: fontSz, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3182CE) : const Color(0xFF4299E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        );

        final closeBtn = SizedBox(
          height: btnH,
          child: OutlinedButton.icon(
            onPressed: Get.back,
            icon: Icon(Icons.close_rounded, size: iconSz),
            label: Text('إغلاق', style: TextStyle(fontSize: fontSz, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2D3748) : Colors.white,
              foregroundColor: isDark ? const Color(0xFFCBD5E0) : const Color(0xFF4A5568),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                color: isDark ? const Color(0xFF4A5568) : const Color(0xFFCBD5E0),
                width: 1.2,
              ),
            ),
          ),
        );

        if (stackButtons) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: editBtn),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: closeBtn),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: editBtn),
            const SizedBox(width: 10),
            Expanded(child: closeBtn),
          ],
        );
      },
    );
  }

  // ==================== UI Helpers ====================

  Widget _cardShell(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252A40) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _softBox(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF3182CE).withOpacity(0.20)
                : const Color(0xFF4299E1).withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isDark ? const Color(0xFF90CDF4) : const Color(0xFF3182CE)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A237E),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2D3748),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(isDark ? 0.30 : 0.20), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFCBD5E0) : const Color(0xFF4A5568),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price != null ? '${price.toStringAsFixed(2)} د.ل' : 'غير محدد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(isDark ? 0.40 : 0.30), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDateCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: medicine.isExpired
              ? (isDark
              ? [const Color(0xFF63171B), const Color(0xFF742A2A)]
              : [const Color(0xFFFFF5F5), const Color(0xFFFED7D7)])
              : (isDark
              ? [const Color(0xFF22543D), const Color(0xFF276749)]
              : [const Color(0xFFF0FFF4), const Color(0xFFC6F6D5)]),
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: medicine.isExpired
              ? (isDark ? const Color(0xFFF56565) : const Color(0xFFE53E3E))
              : (isDark ? const Color(0xFF38A169) : const Color(0xFF48BB78)),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (medicine.isExpired
                  ? (isDark ? const Color(0xFFF56565) : const Color(0xFFE53E3E))
                  : (isDark ? const Color(0xFF38A169) : const Color(0xFF48BB78)))
                  .withOpacity(isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 24,
              color: medicine.isExpired
                  ? (isDark ? const Color(0xFFFC8181) : const Color(0xFFE53E3E))
                  : (isDark ? const Color(0xFF68D391) : const Color(0xFF38A169)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.isExpired ? 'منتهي الصلاحية' : 'صالحة حتى',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: medicine.isExpired
                        ? (isDark ? const Color(0xFFFC8181) : const Color(0xFFE53E3E))
                        : (isDark ? const Color(0xFF68D391) : const Color(0xFF38A169)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(medicine.expiryDate!),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: medicine.isExpired
                        ? (isDark ? const Color(0xFFF56565) : const Color(0xFFC53030))
                        : (isDark ? const Color(0xFF48BB78) : const Color(0xFF276749)),
                  ),
                ),
              ],
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
