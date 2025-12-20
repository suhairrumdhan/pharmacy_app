import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Added iconsax import
import 'package:latlong2/latlong.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';
import '../../../services/location_service.dart';
import '../dialogs/edit_dialog.dart';

Widget buildPharmacySettingsCard(PharmacySettings settings) {
  final SettingsController controller = Get.put(SettingsController());
  final lat = settings.location.latitude;
  final lng = settings.location.longitude;
  final hasValidLocation = lat != 0.0 || lng != 0.0;
  final mapCenter = hasValidLocation ? LatLng(lat, lng) : LatLng(0.0, 0.0);
  final initialZoom = hasValidLocation ? 16.0 : 2.0;
  final LocationService locationService = Get.put(LocationService());
  final auth = Get.find<AuthController>();

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
            Colors.blue.shade100,
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
                          Iconsax.setting_2, // Changed from Icons.settings_rounded
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
                    onPressed: auth.can('settings.update')
                        ? () => openEditDialog(settings)
                        : null,

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
                        Iconsax.edit_2, // Changed from Icons.edit_rounded
                        color: auth.can('settings.update')
                            ? Colors.blue.shade700
                            : Colors.grey.shade400,
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
                                      Icon(Iconsax.gallery_slash, // Changed from Icons.image_not_supported
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
                                          Icon(Iconsax.close_circle, // Changed from Icons.error_outline
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
                                onTap: (!auth.can('settings.edit_image') || isLoading || isUploading)
                                    ? null
                                    : () {
                                  controller.pickAndUploadImage();
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (!auth.can('settings.edit_image') || isLoading || isUploading)
                                        ? Colors.grey.shade400
                                        : Colors.blue.shade700,

                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(
                                          (!auth.can('settings.edit_image') || isLoading || isUploading) ? 0.1 : 0.3,
                                        ),
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
                                      Iconsax.edit_2, // Changed from Icons.edit_rounded
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
                                onTap: (!auth.can('settings.delete_image') || isDeleting)
                                    ? null
                                    : () {
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
                                    color: (!auth.can('settings.delete_image') || isDeleting)
                                        ? Colors.grey.shade400
                                        : Colors.red.shade600,

                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(
                                          (!auth.can('settings.delete_image') || isDeleting) ? 0.1 : 0.3,
                                        ),
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
                                      Iconsax.trash, // Changed from Icons.delete_rounded
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
                _buildCompactInfoField('الاسم', settings.name, Iconsax.shop), // Changed from Icons.store_rounded
                _buildCompactInfoField('المالك', settings.ownerName, Iconsax.user), // Changed from Icons.person_rounded
                _buildCompactInfoField('رقم هوية المالك', settings.ownerIdNumber, Iconsax.card), // Changed from Icons.badge_rounded
                _buildCompactInfoField('البريد الإلكتروني', settings.email, Iconsax.sms), // Changed from Icons.email_rounded
                _buildCompactInfoField('رقم الهاتف', settings.phoneNumber, Iconsax.call), // Changed from Icons.phone_rounded
                _buildCompactInfoField('رقم الترخيص', settings.licenseNumber, Iconsax.verify), // Changed from Icons.verified_rounded
                _buildCompactInfoField('الحالة', settings.status, Iconsax.tick_circle), // Changed from Icons.check_circle_rounded
                _buildCompactInfoField('العنوان', settings.address, Iconsax.location,), // Changed from Icons.location_on_rounded
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
                    Iconsax.location, // Changed from Icons.location_on_outlined
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
            Obx(() {
              final lat = controller.latitude.value;
              final lng = controller.longitude.value;

              // قيمة افتراضية لو لم يتم تحديد الموقع
              final mapCenter = (lat != 0.0 && lng != 0.0)
                  ? LatLng(lat, lng)
                  : LatLng(33.8886, 22.5555);

              // إنشاء MapController محلي
              final mapController = MapController();
              final zoom = 15.0; // قيمة zoom محلية

              // تحديث مركز الخريطة بعد البناء
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (lat != 0.0 && lng != 0.0) {
                  mapController.move(mapCenter, zoom);
                }
              });

              return Container(
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
                    mapController: mapController,
                    options: MapOptions(
                      center: mapCenter,
                      zoom: zoom,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.pharmacy22.app",
                      ),
                      MarkerLayer(
                        markers: [
                          if (lat != 0.0 && lng != 0.0)
                            Marker(
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 40,
                              builder: (ctx) => Icon(
                                Iconsax.location,
                                color: Colors.blue.shade700,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),

          ],
        ),
      ),
    ),
  );
}

Widget _build24HoursSwitch() {
  final auth = Get.find<AuthController>();

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
            Iconsax.clock, // Changed from Icons.access_time_rounded
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
        Obx(() {
          final canEdit24h = auth.can('settings.update_24h');

          return Tooltip(
            message: canEdit24h ? '' : 'ليس لديك صلاحية تعديل وضع 24 ساعة',
            child: Switch(
              value: controller.is24HoursValue,
              onChanged: canEdit24h
                  ? (_) => controller.toggle24HoursWithUI()
                  : null,
              activeColor: Colors.blue.shade700,
            ),
          );
        }),
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
            Iconsax.global, // Changed from Icons.online_prediction_rounded
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
        Obx(() {
          final auth = Get.find<AuthController>();
          final canEditOnline = auth.can('settings.update_online');

          return Switch(
            value: controller.isOnlineValue,
            onChanged: canEditOnline
                ? (_) => controller.toggleOnlineStatusWithUI()
                : null, // تعطيل السويتش تلقائياً
            activeColor: Colors.blue.shade700,
          );
        }),

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