import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Added iconsax import
import 'package:latlong2/latlong.dart';

import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';

void openEditDialog(PharmacySettings settings) {
  final SettingsController controller = Get.find<SettingsController>();

  // Initialize controllers with current settings
  controller.initializeControllers(settings);

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: 900,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
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
                              Iconsax.edit_2, // Changed from Icons.edit_rounded
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
                          controller.initializeControllers(settings); // Reset to original values
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
                            Iconsax.close_circle, // Changed from Icons.close_rounded
                            color: Colors.red.shade600,
                            size: 18,
                          ),
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
                      // Pharmacy Settings in two columns
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Row 1
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildEditField(
                                    label: 'الاسم',
                                    icon: Iconsax.shop, // Changed from Icons.store_rounded
                                    controller: controller.nameController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEditField(
                                    label: 'المالك',
                                    icon: Iconsax.user, // Changed from Icons.person_rounded
                                    controller: controller.ownerNameController,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Row 2
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildEditField(
                                    label: 'رقم هوية المالك',
                                    icon: Iconsax.card, // Changed from Icons.badge_rounded
                                    controller: controller.ownerIdNumberController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEditField(
                                    label: 'البريد الإلكتروني',
                                    icon: Iconsax.sms, // Changed from Icons.email_rounded
                                    controller: controller.emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Row 3
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildEditField(
                                    label: 'رقم الهاتف',
                                    icon: Iconsax.call, // Changed from Icons.phone_rounded
                                    controller: controller.phoneController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEditField(
                                    label: 'العنوان',
                                    icon: Iconsax.location, // Changed from Icons.location_on_rounded
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Map Preview
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade50),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FlutterMap(
                                  options: MapOptions(
                                    center: LatLng(
                                      settings.location.latitude != 0.0
                                          ? settings.location.latitude
                                          : 13.7136,
                                      settings.location.longitude != 0.0
                                          ? settings.location.longitude
                                          : 31.6753,
                                    ),
                                    zoom: 12.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                      userAgentPackageName: "com.example.app2",
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(
                                            controller.latitude.value != 0.0
                                                ? controller.latitude.value
                                                : 24.7136,
                                            controller.longitude.value != 0.0
                                                ? controller.longitude.value
                                                : 46.6753,
                                          ),
                                          width: 30,
                                          height: 30,
                                          builder: (ctx) => Icon(
                                            Iconsax.location, // Changed from Icons.location_on
                                            color: Colors.blue.shade700,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Search box
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade100.withOpacity(0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      // Add your search function here
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Iconsax.search_normal_1, // Changed from Icons.search
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                      hintText: 'ابحث عن موقع...',
                                      hintStyle: TextStyle(
                                        color: Colors.blue.shade400,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 14,
                                    ),
                                    cursorColor: Colors.blue.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          // Cancel Button
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
                                  controller.initializeControllers(settings); // Reset to original values
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
                                      Iconsax.close_circle, // Changed from Icons.close_rounded
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

                          // Save Button
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
                                  // Save changes
                                  final success = await controller.updateSettings();
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
                                        Icon(
                                          Iconsax.tick_circle, // Changed from Icons.check_rounded
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات',
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