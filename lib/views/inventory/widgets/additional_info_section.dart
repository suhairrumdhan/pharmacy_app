import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/add_medicine_controller.dart';

class AdditionalInfoSection extends StatelessWidget {
  final AddMedicineController controller;

  const AdditionalInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final deviceType = _getDeviceType(width);

        return _buildSection(
          title: 'المعلومات الإضافية',
          icon: Icons.more_horiz,
          width: width,
          children: [
            // الصف الأول: الحد الأدنى والمورد
            _buildFirstRow(width: width, deviceType: deviceType),

            SizedBox(height: _getResponsiveSpacing(width)),

            // حقل الباركود
            _buildBarcodeField(width: width),

            SizedBox(height: _getResponsiveSpacing(width)),

            // تاريخ انتهاء الصلاحية
            _buildExpiryDateField(
              width: width,
              deviceType: deviceType,
              context: context, // تمرير context
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // تحديد نوع الجهاز
  // ============================================================
  String _getDeviceType(double width) {
    if (width < 480) return 'mobile';           // الهواتف
    if (width < 768) return 'smallTablet';      // التابليت الصغير
    if (width < 1024) return 'largeTablet';     // التابليت الكبير
    if (width < 1440) return 'smallDesktop';    // شاشات desktop صغيرة
    return 'largeDesktop';                       // شاشات كبيرة
  }

  // ============================================================
  // المسافات المتجاوبة
  // ============================================================
  double _getResponsiveSpacing(double width) {
    if (width < 480) return 12;
    if (width < 768) return 14;
    if (width < 1024) return 16;
    return 18;
  }

  // ============================================================
  // أحجام الخطوط المتجاوبة
  // ============================================================
  double _getResponsiveFontSize(double width, {double base = 14}) {
    if (width < 480) return base - 2;
    if (width < 768) return base - 1;
    if (width < 1024) return base;
    return base + 1;
  }

  // ============================================================
  // Padding متجاوب
  // ============================================================
  EdgeInsets _getResponsivePadding(double width) {
    if (width < 480) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    } else if (width < 768) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 18);
    }
  }

  // ============================================================
  // الصف الأول (الحد الأدنى + المورد)
  // ============================================================
  Widget _buildFirstRow({
    required double width,
    required String deviceType,
  }) {
    final isMobile = deviceType == 'mobile';
    final isSmallScreen = width < 600;
    final fontSize = _getResponsiveFontSize(width);

    // للشاشات الصغيرة جداً - عرض عمودي
    if (isSmallScreen) {
      return Column(
        children: [
          _buildMinStockField(width: width, fontSize: fontSize),
          SizedBox(height: _getResponsiveSpacing(width)),
          _buildSupplierField(width: width, fontSize: fontSize),
        ],
      );
    }

    // للشاشات المتوسطة والكبيرة - عرض أفقي
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMinStockField(width: width, fontSize: fontSize)),
        SizedBox(width: _getResponsiveSpacing(width)),
        Expanded(child: _buildSupplierField(width: width, fontSize: fontSize)),
      ],
    );
  }

  // ============================================================
  // حقل الحد الأدنى للمخزون
  // ============================================================
  Widget _buildMinStockField({
    required double width,
    required double fontSize,
  }) {
    final isMobile = width < 480;
    final iconSize = isMobile ? 18.0 : 20.0;

    return TextFormField(
      controller: controller.minStockController,
      decoration: InputDecoration(
        labelText: 'الحد الأدنى للمخزون (اختياري)',
        labelStyle: TextStyle(fontSize: fontSize),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
        prefixIcon: Icon(
          Icons.warning,
          size: iconSize,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: _getResponsivePadding(width),
      ),
      style: TextStyle(fontSize: fontSize),
      keyboardType: TextInputType.number,
    );
  }

  // ============================================================
  // حقل المورد
  // ============================================================
  Widget _buildSupplierField({
    required double width,
    required double fontSize,
  }) {
    final isMobile = width < 480;
    final iconSize = isMobile ? 18.0 : 20.0;

    return Obx(() {
      if (controller.isLoadingSuppliers.value) {
        return TextFormField(
          controller: controller.supplierController,
          decoration: InputDecoration(
            labelText: 'المورد (جاري التحميل...)',
            labelStyle: TextStyle(fontSize: fontSize),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            prefixIcon: Icon(
              Icons.business,
              size: iconSize,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: _getResponsivePadding(width),
            suffixIcon: SizedBox(
              width: iconSize + 8,
              height: iconSize + 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
          ),
          style: TextStyle(fontSize: fontSize),
        );
      }

      return DropdownButtonFormField<String>(
        value: controller.selectedSupplierId.value.isEmpty
            ? null
            : controller.selectedSupplierId.value,
        decoration: InputDecoration(
          labelText: 'المورد (اختياري)',
          labelStyle: TextStyle(fontSize: fontSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          ),
          prefixIcon: Icon(
            Icons.business,
            size: iconSize,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: _getResponsivePadding(width),
        ),
        items: controller.suppliers.map((supplier) {
          final supplierId = supplier['id'] ?? '';
          final supplierName = supplier['name'] ?? '';

          return DropdownMenuItem<String>(
            value: supplierId,
            child: Text(
              supplierId.isEmpty ? 'بدون مورد' : supplierName,
              style: TextStyle(
                fontSize: fontSize,
                fontStyle: supplierId.isEmpty ? FontStyle.italic : null,
                color: supplierId.isEmpty ? Colors.grey.shade600 : Colors.grey.shade900, // <- تم التعديل هنا
                fontWeight: supplierId.isEmpty ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          controller.updateSelectedSupplier(newValue);
        },
        isExpanded: true,
        iconSize: iconSize,
        style: TextStyle(fontSize: fontSize),
      );
    });
  }

  // ============================================================
  // حقل الباركود
  // ============================================================
  Widget _buildBarcodeField({required double width}) {
    final isMobile = width < 480;
    final fontSize = _getResponsiveFontSize(width);
    final iconSize = isMobile ? 18.0 : 20.0;

    return TextFormField(
      controller: controller.barcodeController,
      decoration: InputDecoration(
        labelText: 'الباركود (اختياري)',
        labelStyle: TextStyle(fontSize: fontSize),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
        prefixIcon: Icon(
          Icons.qr_code,
          size: iconSize,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: _getResponsivePadding(width),
        suffixIcon: isMobile
            ? null
            : IconButton(
          icon: Icon(Icons.qr_code_scanner, size: iconSize),
          onPressed: () {
            // فتح ماسح الباركود
          },
        ),
      ),
      style: TextStyle(fontSize: fontSize),
    );
  }

  // ============================================================
  // حقل تاريخ انتهاء الصلاحية
  // ============================================================
  Widget _buildExpiryDateField({
    required double width,
    required String deviceType,
    required BuildContext context, // إضافة context كمعامل
  }) {
    final isMobile = deviceType == 'mobile';
    final isSmallScreen = width < 600;
    final fontSize = _getResponsiveFontSize(width);
    final iconSize = isMobile ? 18.0 : 20.0;

    return Obx(() => Container(
      padding: _getResponsivePadding(width),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: isSmallScreen
          ? _buildExpiryDateColumn(
        width: width,
        fontSize: fontSize,
        iconSize: iconSize,
        context: context, // تمرير context
      )
          : _buildExpiryDateRow(
        width: width,
        fontSize: fontSize,
        iconSize: iconSize,
        context: context, // تمرير context
      ),
    ));
  }

  // ============================================================
  // تاريخ انتهاء الصلاحية - تصميم عمودي للشاشات الصغيرة
  // ============================================================
  Widget _buildExpiryDateColumn({
    required double width,
    required double fontSize,
    required double iconSize,
    required BuildContext context, // إضافة context
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange.shade700, size: iconSize),
            const SizedBox(width: 8),
            Text(
              'تاريخ انتهاء الصلاحية:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: _buildDateButton(
            fontSize: fontSize,
            iconSize: iconSize,
            context: context, // تمرير context
          ),
        ),
      ],
    );
  }

  // ============================================================
  // تاريخ انتهاء الصلاحية - تصميم أفقي للشاشات الكبيرة
  // ============================================================
  Widget _buildExpiryDateRow({
    required double width,
    required double fontSize,
    required double iconSize,
    required BuildContext context, // إضافة context
  }) {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.orange.shade700, size: iconSize),
        const SizedBox(width: 12),
        Text(
          'تاريخ انتهاء الصلاحية:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        const Spacer(),
        _buildDateButton(
          fontSize: fontSize,
          iconSize: iconSize,
          context: context, // تمرير context
        ),
      ],
    );
  }

  // ============================================================
  // زر اختيار التاريخ
  // ============================================================
  Widget _buildDateButton({
    required double fontSize,
    required double iconSize,
    required BuildContext context, // إضافة context كمعامل
  }) {
    return TextButton.icon(
      onPressed: () => _selectExpiryDate(context), // استخدام context المُمرر
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.orange.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(
        Icons.calendar_month,
        color: Colors.orange.shade700,
        size: iconSize,
      ),
      label: Text(
        formatDate(controller.expiryDate.value),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }

  // ============================================================
  // اختيار التاريخ
  // ============================================================
  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.expiryDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != controller.expiryDate.value) {
      controller.updateExpiryDate(picked);
    }
  }
}

// ============================================================
// دالة تنسيق التاريخ
// ============================================================
String formatDate(DateTime date) {
  return DateFormat('yyyy/MM/dd').format(date);
}

// ============================================================
// قالب السكشن (متجاوب)
// ============================================================
Widget _buildSection({
  required String title,
  required IconData icon,
  required double width,
  required List<Widget> children,
}) {
  final isMobile = width < 480;
  final isTablet = width >= 480 && width < 1024;

  final padding = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
  final iconSize = isMobile ? 18.0 : 20.0;
  final fontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
  final borderRadius = isMobile ? 12.0 : 16.0;
  final spacing = isMobile ? 12.0 : 16.0;

  return Card(
    elevation: isMobile ? 1 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                ),
                child: Icon(icon, size: iconSize, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // المحتوى
          ...children,

          // مسافة إضافية في الأسفل
          SizedBox(height: spacing),
        ],
      ),
    ),
  );
}