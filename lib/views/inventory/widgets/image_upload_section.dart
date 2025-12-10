import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_medicine_controller.dart';

class ImageUploadSection extends StatelessWidget {
  final AddMedicineController controller;

  const ImageUploadSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasImage = controller.hasImage;
      final isUploading = controller.isUploadingImage.value;

      return _buildSection(
        title: 'صورة الصنف',
        icon: Icons.image,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== العمود الأيسر: صندوق الصورة ====================
              Container(
                width: 230,
                alignment: Alignment.topCenter,
                child: _imageBox(hasImage),
              ),

              const SizedBox(width: 24),

              // ==================== العمود الأيمن: كل شيء ====================
              Expanded(
                child: _rightColumn(
                  hasImage: hasImage,
                  isUploading: isUploading,
                ),
              ),
            ],
          ),
          SizedBox(height: 20,)
        ],
      );
    });
  }

  // ============================================================
  // صندوق الصورة
  // ============================================================
  Widget _imageBox(bool hasImage) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: hasImage ? _buildImagePreview() : _buildUploadPlaceholder(),
    );
  }

  // ============================================================
  // العمود الأيمن — أزرار عمودية + حالة الرفع
  // ============================================================
  Widget _rightColumn({
    required bool hasImage,
    required bool isUploading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ========== الأزرار بشكل عمودي ==========
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasImage)
              ElevatedButton.icon(
                onPressed: () => controller.pickImageFromFiles(),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('اختيار صورة'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                ),
              ),

            if (hasImage) ...[
              ElevatedButton.icon(
                onPressed: () => controller.pickImageFromFiles(),
                icon: const Icon(Icons.change_circle, size: 18),
                label: const Text('تغيير الصورة'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.removeImage,
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: const Text('إزالة الصورة', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // ملاحظات
        if (!hasImage && !isUploading)
          Text(
            ' الملفات المدعومة\n JPG, PNG, GIF, BMP, WebP\n الحجم الأقصى: 5 ميجابايت',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign:TextAlign.center
          ),
      ],
    );
  }

  // ============================================================
  // معاينة الصورة
  // ============================================================
  Widget _buildImagePreview() {
    final image = controller.displayImage;

    if (image is File) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // Placeholder عند عدم وجود صورة
  // ============================================================
  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: () => controller.pickImageFromFiles(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('انقر لإضافة صورة',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('(اختياري)',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ============================================================
  // قالب السكشن
  // ============================================================
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
