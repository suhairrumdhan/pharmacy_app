import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

class ImageUploadSection extends StatelessWidget {
  final AddMedicineController controller;

  const ImageUploadSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final deviceType = _getDeviceType(width);

        return Obx(() {
          final hasImage = controller.hasImage;
          final isUploading = controller.isUploadingImage.value;

          return _buildSection(
            title: 'صورة الصنف',
            icon: Icons.image,
            width: width,
            children: [
              _buildContent(
                width: width,
                deviceType: deviceType,
                hasImage: hasImage,
                isUploading: isUploading,
              ),
              SizedBox(height: _getResponsiveSpacing(width)),
            ],
          );
        });
      },
    );
  }

  // ============================================================
  // تحديد نوع الجهاز بناءً على العرض
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
    if (width < 480) return 16;
    if (width < 768) return 20;
    return 24;
  }

  // ============================================================
  // المحتوى الرئيسي المتجاوب
  // ============================================================
  Widget _buildContent({
    required double width,
    required String deviceType,
    required bool hasImage,
    required bool isUploading,
  }) {
    final isMobile = deviceType == 'mobile';
    final isTablet = deviceType == 'smallTablet' || deviceType == 'largeTablet';
    final isDesktop = deviceType == 'smallDesktop' || deviceType == 'largeDesktop';

    // للشاشات الصغيرة جداً (أقل من 360)
    if (width < 360) {
      return _buildStackedLayout(
        width: width,
        hasImage: hasImage,
        isUploading: isUploading,
        isMobile: isMobile,
      );
    }

    // للشاشات المتوسطة (360 - 600)
    if (width < 600) {
      return _buildColumnLayout(
        width: width,
        hasImage: hasImage,
        isUploading: isUploading,
      );
    }

    // للشاشات الكبيرة (600+)
    return _buildRowLayout(
      width: width,
      hasImage: hasImage,
      isUploading: isUploading,
      isDesktop: isDesktop,
    );
  }

  // ============================================================
  // تصميم التكديس للشاشات الصغيرة جداً
  // ============================================================
  Widget _buildStackedLayout({
    required double width,
    required bool hasImage,
    required bool isUploading,
    required bool isMobile,
  }) {
    return Column(
      children: [
        // صندوق الصورة في الأعلى
        Center(
          child: Container(
            width: width * 0.7,
            height: width * 0.7,
            constraints: const BoxConstraints(
              maxWidth: 180,
              maxHeight: 180,
              minWidth: 120,
              minHeight: 120,
            ),
            child: _imageBox(hasImage),
          ),
        ),
        const SizedBox(height: 16),

        // الأزرار في الأسفل
        _rightColumn(
          width: width,
          hasImage: hasImage,
          isUploading: isUploading,
          isVertical: true,
          isCompact: true,
        ),
      ],
    );
  }

  // ============================================================
  // تصميم العمودي للشاشات المتوسطة
  // ============================================================
  Widget _buildColumnLayout({
    required double width,
    required bool hasImage,
    required bool isUploading,
  }) {
    return Column(
      children: [
        // صندوق الصورة
        Center(
          child: Container(
            width: 200,
            height: 200,
            child: _imageBox(hasImage),
          ),
        ),
        const SizedBox(height: 20),

        // الأزرار
        _rightColumn(
          width: width,
          hasImage: hasImage,
          isUploading: isUploading,
          isVertical: true,
        ),
      ],
    );
  }

  // ============================================================
  // تصميم الصف للشاشات الكبيرة
  // ============================================================
  Widget _buildRowLayout({
    required double width,
    required bool hasImage,
    required bool isUploading,
    required bool isDesktop,
  }) {
    final imageSize = isDesktop ? 250.0 : 230.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العمود الأيسر: صندوق الصورة
        Container(
          width: imageSize,
          alignment: Alignment.topCenter,
          child: Container(
            width: imageSize - 30,
            height: imageSize - 30,
            child: _imageBox(hasImage),
          ),
        ),
        SizedBox(width: isDesktop ? 32 : 24),

        // العمود الأيمن: الأزرار
        Expanded(
          child: _rightColumn(
            width: width,
            hasImage: hasImage,
            isUploading: isUploading,
            isVertical: false,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // صندوق الصورة
  // ============================================================
  Widget _imageBox(bool hasImage) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: hasImage ? _buildImagePreview() : _buildUploadPlaceholder(),
    );
  }

  // ============================================================
  // العمود الأيمن — أزرار + حالة الرفع
  // ============================================================
  Widget _rightColumn({
    required double width,
    required bool hasImage,
    required bool isUploading,
    bool isVertical = true,
    bool isCompact = false,
  }) {
    final isSmallScreen = width < 600;
    final buttonWidth = isSmallScreen ? double.infinity : null;
    final buttonPadding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الأزرار
        if (isVertical)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildButtons(
              hasImage: hasImage,
              buttonWidth: buttonWidth,
              buttonPadding: buttonPadding,
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildButtons(
                    hasImage: hasImage,
                    buttonWidth: buttonWidth,
                    buttonPadding: buttonPadding,
                  ),
                ),
              ),
            ],
          ),

        SizedBox(height: isCompact ? 12 : 14),

        // ملاحظات الملفات المدعومة
        if (!hasImage && !isUploading)
          _buildFileNotes(width: width, isCompact: isCompact),

        // مؤشر رفع الصورة
        if (isUploading)
          _buildUploadingIndicator(width: width, isCompact: isCompact),
      ],
    );
  }

  // ============================================================
  // بناء الأزرار
  // ============================================================
  List<Widget> _buildButtons({
    required bool hasImage,
    double? buttonWidth,
    required EdgeInsets buttonPadding,
  }) {
    if (!hasImage) {
      return [
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton.icon(
            onPressed: () => controller.pickImageFromFiles(),
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('اختيار صورة'),
            style: ElevatedButton.styleFrom(
              padding: buttonPadding,
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SizedBox(
        width: buttonWidth,
        child: ElevatedButton.icon(
          onPressed: () => controller.pickImageFromFiles(),
          icon: const Icon(Icons.change_circle, size: 18),
          label: const Text('تغيير الصورة'),
          style: ElevatedButton.styleFrom(
            padding: buttonPadding,
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: buttonWidth,
        child: OutlinedButton.icon(
          onPressed: controller.removeImage,
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          label: const Text('إزالة الصورة',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ];
  }

  // ============================================================
  // ملاحظات الملفات المدعومة
  // ============================================================
  Widget _buildFileNotes({required double width, required bool isCompact}) {
    final isSmallScreen = width < 600;
    final fontSize = isSmallScreen ? 11.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الملفات المدعومة:',
            style: TextStyle(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• JPG, PNG, GIF, BMP, WebP',
            style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
          ),
          Text(
            '• الحجم الأقصى: 5 ميجابايت',
            style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
          ),
          if (isSmallScreen)
            Text(
              '• الصورة اختيارية',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // مؤشر رفع الصورة
  // ============================================================
  Widget _buildUploadingIndicator({
    required double width,
    required bool isCompact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'جاري رفع الصورة...',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // معاينة الصورة
  // ============================================================
  Widget _buildImagePreview() {
    final image = controller.displayImage;

    if (image is File) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (image is String) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // صورة الخطأ
  // ============================================================
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'فشل تحميل الصورة',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Placeholder عند عدم وجود صورة
  // ============================================================
  Widget _buildUploadPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 150;

        return GestureDetector(
          onTap: () => controller.pickImageFromFiles(),
          child: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: isSmall ? 32 : 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  isSmall ? 'إضافة صورة' : 'انقر لإضافة صورة',
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isSmall) ...[
                  const SizedBox(height: 4),
                  Text(
                    '(اختياري)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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

    final padding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final iconSize = isMobile ? 18.0 : 20.0;
    final fontSize = isMobile ? 15.0 : (isTablet ? 16.0 : 17.0);
    final borderRadius = isMobile ? 10.0 : 12.0;

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
            SizedBox(height: isMobile ? 10 : 14),
            ...children,
          ],
        ),
      ),
    );
  }
}