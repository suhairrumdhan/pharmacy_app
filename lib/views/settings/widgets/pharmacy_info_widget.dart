import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';
import '../dialogs/edit_dialog.dart';

Widget buildPharmacySettingsCard(PharmacySettings settings) {
  final SettingsController controller = Get.put(SettingsController());
  final lat = settings.location.latitude;
  final lng = settings.location.longitude;
  final hasValidLocation = lat != 0.0 || lng != 0.0;
  final mapCenter = hasValidLocation ? LatLng(lat, lng) : LatLng(0.0, 0.0);
  final initialZoom = hasValidLocation ? 16.0 : 2.0;

  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // عنوان القسم الرئيسي
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.settings_rounded,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إعدادات الصيدلية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),

                  /// زر التعديل في الجانب الأيمن
                  IconButton(
                    onPressed: () {
                      // افتح دياالوج التعديل هنا
                      openEditDialog(settings);
                    },
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // وضع 24 ساعة - نظيف جداً
                              _build24HoursSwitch(),
                              const SizedBox(height: 20),

                              // الحالة المتاحة - نظيف جداً
                              _buildOnlineStatusSwitch(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // حاوية الصورة
                      Stack(
                        children: [
                          Obx(() {
                            final controller = Get.find<SettingsController>();
                            final imageUrl = controller.imageUrlValue;
                            final hasImage = imageUrl.isNotEmpty;

                            return Container(
                              width: 400,
                              height: 173,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                                color: Colors.grey.shade100,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: !hasImage
                                    ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported,
                                          size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text('لا توجد صورة',
                                          style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                )
                                    : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.blue,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline,
                                              size: 48, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          Text('خطأ في تحميل الصورة',
                                              style: TextStyle(color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }),

                          // زر التعديل (قلم) في الزاوية اليمنى السفلى
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Obx(() {
                              final controller = Get.find<SettingsController>();
                              final isLoading = controller.isLoading.value;
                              final hasImage = controller.imageUrlValue.isNotEmpty;
                              final isUploading = controller.isUploadingImage.value;

                              return GestureDetector(
                                onTap: (isLoading || isUploading)
                                    ? null // تعطيل الزر أثناء التحميل
                                    : () {
                                  controller.pickAndUploadImage();
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (isLoading || isUploading)
                                        ? Colors.grey.shade400
                                        : Colors.blue.shade700,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity((isLoading || isUploading) ? 0.1 : 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: (isLoading || isUploading)
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          // زر حذف الصورة في الزاوية اليسرى السفلى (يظهر فقط عند وجود صورة)
                          Obx(() {
                            final controller = Get.find<SettingsController>();
                            final hasImage = controller.imageUrlValue.isNotEmpty;
                            final isDeleting = controller.isUploadingImage.value;

                            if (!hasImage) return const SizedBox.shrink();
                            return Positioned(
                              bottom: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: isDeleting
                                    ? null
                                    : () {
                                  // تأكيد قبل الحذف
                                  Get.defaultDialog(
                                    title: 'تأكيد الحذف',
                                    middleText: 'هل أنت متأكد من حذف صورة الصيدلية؟',
                                    textConfirm: 'نعم، احذف',
                                    textCancel: 'إلغاء',
                                    confirmTextColor: Colors.white,
                                    onConfirm: () {
                                      Get.back();
                                      controller.deleteCurrentImage();
                                    },
                                    onCancel: () {
                                      Get.back();
                                    },
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDeleting
                                        ? Colors.grey.shade400
                                        : Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(isDeleting ? 0.1 : 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: isDeleting
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // المعلومات المدمجة بدون كونتينر
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildCompactInfoField('الاسم', settings.name, Icons.store_rounded),
                _buildCompactInfoField('المالك', settings.ownerName, Icons.person_rounded),
                _buildCompactInfoField('رقم هوية المالك', settings.ownerIdNumber, Icons.badge_rounded),
                _buildCompactInfoField('البريد الإلكتروني', settings.email, Icons.email_rounded),
                _buildCompactInfoField('رقم الهاتف', settings.phoneNumber, Icons.phone_rounded),
                _buildCompactInfoField('العنوان', settings.address, Icons.location_on_rounded),
                _buildCompactInfoField('رقم الترخيص', settings.licenseNumber, Icons.verified_rounded),
                _buildCompactInfoField('الحالة', settings.status, Icons.check_circle_rounded),
              ],
            ),

            const SizedBox(height: 30),

            // الخريطة في الأسفل بدون كونتينر
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'الموقع ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    center: mapCenter,
                    zoom: initialZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.example.app2",
                    ),
                    MarkerLayer(
                      markers: [
                        if (hasValidLocation)
                          Marker(
                            point: LatLng(lat, lng),
                            width: 40,
                            height: 40,
                            builder: (ctx) => Icon(
                              Icons.location_on,
                              color: Colors.blue.shade700,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

          ],
        ),
      ),
    ),
  );
}

Widget _build24HoursSwitch() {
  final controller = Get.find<SettingsController>();
  return Container(
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.access_time_rounded,
            color: Colors.blue.shade700,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'وضع 24 ساعة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'الصيدلية مفتوحة 24 ساعة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Obx(() => Switch(
          value: controller.is24HoursValue, // استخدم الجيتر
          onChanged: (_) => controller.toggle24HoursWithUI(), // استخدم الدالة الجديدة
          activeColor: Colors.blue.shade700,
        )),
      ],
    ),
  );
}
Widget _buildOnlineStatusSwitch() {
  final controller = Get.find<SettingsController>();

  return Container(
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.online_prediction_rounded,
            color: Colors.blue.shade700,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحالة المتاحة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'الصيدلية متاحة للطلبات',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Obx(() => Switch(
          value: controller.isOnlineValue, // استخدم الجيتر
          onChanged: (_) => controller.toggleOnlineStatusWithUI(), // استخدم الدالة الجديدة
          activeColor: Colors.blue.shade700,
        )),
      ],
    ),
  );
}
Widget _buildCompactInfoField(String label, String value, IconData icon) {
  return Container(
    width: 240,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
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