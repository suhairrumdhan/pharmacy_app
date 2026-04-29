import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';
import '../../../services/location_service.dart';

void openEditDialog(PharmacySettings settings) {
  final SettingsController controller = Get.find<SettingsController>();
  final LocationService locationService = Get.put(LocationService());

  controller.initializeControllers(settings);

  final initialLat =
  settings.location.latitude != 0.0 ? settings.location.latitude : 32.871796;
  final initialLng =
  settings.location.longitude != 0.0 ? settings.location.longitude : 13.201452;

  final initialCenter = LatLng(initialLat, initialLng);

  controller.setLocation(initialLat, initialLng);

  locationService.currentMapCenter.value = initialCenter;
  locationService.currentZoom.value = 15.0;
  locationService.searchResults.clear();

  if (locationService.searchController.text.trim().isEmpty &&
      settings.address.trim().isNotEmpty) {
    locationService.searchController.text = settings.address.trim();
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
                            child: Icon(
                              Iconsax.edit_2,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تعديل إعدادات الصيدلية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          controller.initializeControllers(settings);
                          controller.setLocation(
                            settings.location.latitude,
                            settings.location.longitude,
                          );
                          locationService.currentMapCenter.value = LatLng(
                            settings.location.latitude != 0.0
                                ? settings.location.latitude
                                : 32.871796,
                            settings.location.longitude != 0.0
                                ? settings.location.longitude
                                : 13.201452,
                          );
                          locationService.currentZoom.value = 15.0;
                          locationService.searchResults.clear();
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
                          child: Icon(
                            Iconsax.close_circle,
                            color: Colors.red.shade600,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildEditField(
                                    label: 'الاسم',
                                    icon: Iconsax.shop,
                                    controller: controller.nameController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEditField(
                                    label: 'المالك',
                                    icon: Iconsax.user,
                                    controller: controller.ownerNameController,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildEditField(
                                    label: 'رقم الهاتف',
                                    icon: Iconsax.call,
                                    controller: controller.phoneController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEditField(
                                    label: 'العنوان',
                                    icon: Iconsax.location,
                                    controller: controller.addressController,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

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
                            SizedBox(
                              height: 200,
                              child: Obx(() {
                                final center = locationService.currentMapCenter.value ??
                                    LatLng(
                                      controller.latitude.value != 0.0
                                          ? controller.latitude.value
                                          : initialLat,
                                      controller.longitude.value != 0.0
                                          ? controller.longitude.value
                                          : initialLng,
                                    );

                                final zoom = locationService.currentZoom.value == 0.0
                                    ? 15.0
                                    : locationService.currentZoom.value;

                                final hasLocation =
                                    center.latitude != 0.0 && center.longitude != 0.0;

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      center: center,
                                      zoom: zoom,
                                      onPositionChanged: (position, hasGesture) async {
                                        final mapCenter = position.center;
                                        if (mapCenter == null) return;

                                        locationService.currentMapCenter.value = mapCenter;
                                        locationService.currentZoom.value = position.zoom ?? 16.0;

                                        controller.setLocation(
                                          mapCenter.latitude,
                                          mapCenter.longitude,
                                        );

                                        if (!hasGesture) return;

                                        try {
                                          final resolvedAddress = await locationService.getAddressForLocation(
                                            mapCenter.latitude,
                                            mapCenter.longitude,
                                          );

                                          if (resolvedAddress != null && resolvedAddress.trim().isNotEmpty) {
                                            controller.addressController.text = resolvedAddress;
                                          }
                                        } catch (_) {}
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                        userAgentPackageName: "com.pharmacy2.app",
                                      ),
                                      if (hasLocation)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: center,
                                              width: 44,
                                              height: 44,
                                              builder: (ctx) => Icon(
                                                Icons.location_on,
                                                color: Colors.red.shade600,
                                                size: 44,
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

                            TextField(
                              controller: locationService.searchController,
                              focusNode: locationService.searchFocusNode,
                              style: TextStyle(color: Colors.blue.shade900),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن موقع...',
                                hintStyle: TextStyle(color: Colors.blue.shade300),
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade100,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade100,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade400,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.trim().length < 2) {
                                  locationService.searchResults.clear();
                                  return;
                                }
                                locationService.searchPlace(value);
                              },
                            ),

                            const SizedBox(height: 8),

                            const SizedBox(height: 8),

                            Obx(() {
                              if (locationService.searchResults.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 120),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: locationService.searchResults.length,
                                    itemBuilder: (context, index) {
                                      final result = locationService.searchResults[index];

                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          locationService.getIconForType(result['type'] ?? ''),
                                          color: Colors.blue.shade700,
                                          size: 20,
                                        ),
                                        title: Text(
                                          result['name'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onTap: () {
                                          final selectedPoint = LatLng(
                                            (result['lat'] as num).toDouble(),
                                            (result['lon'] as num).toDouble(),
                                          );

                                          controller.addressController.text = result['name'] ?? '';
                                          locationService.searchController.text = result['name'] ?? '';

                                          locationService.currentMapCenter.value = selectedPoint;
                                          locationService.currentZoom.value = 16.0;

                                          controller.setLocation(
                                            selectedPoint.latitude,
                                            selectedPoint.longitude,
                                          );

                                          locationService.searchResults.clear();
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () {
                                  controller.initializeControllers(settings);
                                  controller.setLocation(
                                    settings.location.latitude,
                                    settings.location.longitude,
                                  );
                                  locationService.currentMapCenter.value = LatLng(
                                    settings.location.latitude != 0.0
                                        ? settings.location.latitude
                                        : 32.871796,
                                    settings.location.longitude != 0.0
                                        ? settings.location.longitude
                                        : 13.201452,
                                  );
                                  locationService.currentZoom.value = 15.0;
                                  locationService.searchResults.clear();
                                  Get.back();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.close_circle,
                                      color: Colors.grey.shade600,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  final selectedCenter =
                                      locationService.currentMapCenter.value;

                                  if (selectedCenter == null) {
                                    Get.snackbar('خطأ', 'الرجاء تحديد الموقع قبل الحفظ');
                                    return;
                                  }

                                  controller.setLocation(
                                    selectedCenter.latitude,
                                    selectedCenter.longitude,
                                  );

                                  final success = await controller.updateSettings(
                                    requireLocation: true,
                                  );

                                  if (success) {
                                    Get.back();
                                  }
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Obx(() {
                                  final isLoading = controller.isLoading.value;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isLoading)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      else

                                        const Icon(
                                          Iconsax.tick_circle,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isLoading
                                            ? 'جاري الحفظ...'
                                            : 'حفظ التغييرات',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
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