import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Added iconsax import
import 'package:latlong2/latlong.dart';
import '../../../services/location_service.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';

void openEditDialog(PharmacySettings settings) {
  final SettingsController controller = Get.find<SettingsController>();
  final LocationService locationService = Get.put(LocationService());

  // Initialize controllers with current settings
  controller.initializeControllers(settings);

  // تأكد من أن currentMapCenter جاهز قبل فتح الـ dialog
  if (locationService.currentMapCenter.value == null) {
    locationService.initializeMap(initialLocation: LatLng(
      settings.location.latitude != 0 ? settings.location.latitude : 32.871796,
      settings.location.longitude != 0 ? settings.location.longitude : 13.201452,
    ));
  }

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 900),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (كما هو)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(Iconsax.edit_2, color: Colors.blue.shade700, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تعديل إعدادات الصيدلية',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          controller.initializeControllers(settings);
                          Get.back();
                        },
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(Iconsax.close_circle, color: Colors.red.shade600, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Two-column fields
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Row 1
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(child: _buildEditField(label: 'الاسم', icon: Iconsax.shop, controller: controller.nameController)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildEditField(label: 'المالك', icon: Iconsax.user, controller: controller.ownerNameController)),
                              ],
                            ),
                          ),
                          // Row 2
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(child: _buildEditField(label: 'رقم الهاتف', icon: Iconsax.call, controller: controller.phoneController, keyboardType: TextInputType.phone)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildEditField(label: 'العنوان', icon: Iconsax.location, controller: controller.addressController, maxLines: 1)),

                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ====== الخريطة ======
                            SizedBox(
                              height: 200,
                              child: Obx(() {
                                final lat = controller.latitude.value;
                                final lng = controller.longitude.value;

                                final mapCenter = (lat != 0.0 && lng != 0.0)
                                    ? LatLng(lat, lng)
                                    : LatLng(33.8886, 22.5555); // قيمة افتراضية

                                // MapController محلي
                                final mapController = MapController();
                                final zoom = 15.0; // zoom محلي

                                // تحديث مركز الخريطة بعد البناء
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (lat != 0.0 && lng != 0.0) {
                                    mapController.move(mapCenter, zoom);
                                  }
                                });

                                return ClipRRect(
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
                                        userAgentPackageName: "com.pharmacy2.app",
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          if (lat != 0.0 && lng != 0.0)
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
                                );
                              }),
                            ),

                            const SizedBox(height: 12),

                            // ====== حقل البحث ======
                            TextField(
                              controller: locationService.searchController,
                              focusNode: locationService.searchFocusNode,
                              style: TextStyle(color: Colors.blue),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن موقع...',
                                hintStyle: TextStyle(color: Colors.blue.shade300),
                                prefixIcon: Icon(Icons.search, color: Colors.blue),
                              ),
                              onChanged: (value) => locationService.searchPlace(value),
                            ),

                            const SizedBox(height: 8),

                            // ====== اقتراحات البحث Scrollable ======
// ===== قائمة النتائج مع تحديث الخريطة محليًا فقط =====
                            Obx(() => ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 100),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: locationService.searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = locationService.searchResults[index];
                                  return ListTile(
                                    title: Text(
                                      result['name'],
                                      style: TextStyle(color: Colors.blue.shade900),
                                    ),
                                    onTap: () {
                                      // ===== تحديث العنوان فقط =====
                                      controller.addressController.text = result['name'];

                                      // ===== تحديث مركز الخريطة محليًا فقط =====
                                      locationService.currentMapCenter.value = LatLng(result['lat'], result['lon']);
                                      locationService.currentZoom.value = 15.0; // أو أي قيمة مناسبة للزووم

                                      // ===== تحديث حقل البحث =====
                                      locationService.searchController.text = result['name'];

                                      // ===== مسح النتائج لإخفاء ListView =====
                                      locationService.searchResults.value = [];
                                    },
                                  );
                                },
                              ),
                            )),                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                              ),
                              child: TextButton(
                                onPressed: () { controller.initializeControllers(settings); Get.back(); },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300, width: 1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.close_circle, color: Colors.grey.shade600, size: 18),
                                    const SizedBox(width: 8),
                                    Text('إلغاء', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  // 1️⃣ تأكد أن هناك إحداثيات مختارة
                                  if (locationService.currentMapCenter.value == null) {
                                    Get.snackbar('خطأ', 'الرجاء تحديد الموقع قبل الحفظ');
                                    return;
                                  }

                                  // 2️⃣ تحديث الكونترولر بالإحداثيات المختارة
                                  controller.latitude.value = locationService.currentMapCenter.value!.latitude;
                                  controller.longitude.value = locationService.currentMapCenter.value!.longitude;

                                  // 3️⃣ تحديث باقي الإعدادات في Firestore
                                  final success = await controller.updateSettings(requireLocation: true);

                                  // 4️⃣ إغلاق الشاشة إذا تم الحفظ بنجاح
                                  if (success) Get.back();
                                },                                style: TextButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Obx(() {
                                  final isLoading = controller.isLoading.value;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isLoading)
                                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      else
                                        Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

Widget _buildEditField({
  required String label,
  required IconData icon,
  required TextEditingController controller,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.4),
              border: Border.all(
                color: Colors.blue.shade100.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              cursorColor: Colors.blue.shade600,
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                hintText: 'أدخل هنا...',
                hintStyle: TextStyle(
                  color: Colors.blue.shade400,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                filled: false,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
    ],
  );
}