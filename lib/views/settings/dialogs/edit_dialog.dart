import 'dart:async';
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
  final controller = Get.find<SettingsController>();
  final locationService = Get.isRegistered<LocationService>()
      ? Get.find<LocationService>()
      : Get.put(LocationService(), permanent: true);

  controller.initializeControllers(settings);

  final lat = settings.location.latitude != 0.0
      ? settings.location.latitude
      : 32.871796;
  final lng = settings.location.longitude != 0.0
      ? settings.location.longitude
      : 13.201452;

  final center = LatLng(lat, lng);

  controller.setLocation(lat, lng);
  locationService.currentMapCenter.value = center;
  locationService.currentZoom.value = 15.0;
  locationService.searchResults.clear();
  locationService.searchController.text = settings.address.trim();

  Get.dialog(
    _EditDialog(
      settings: settings,
      controller: controller,
      locationService: locationService,
      initialCenter: center,
    ),
    barrierDismissible: false,
  );
}

class _EditDialog extends StatefulWidget {
  final PharmacySettings settings;
  final SettingsController controller;
  final LocationService locationService;
  final LatLng initialCenter;

  const _EditDialog({
    required this.settings,
    required this.controller,
    required this.locationService,
    required this.initialCenter,
  });

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  OverlayEntry? _searchOverlay;
  Timer? _debounce;

  SettingsController get c => widget.controller;
  LocationService get loc => widget.locationService;

  @override
  void initState() {
    super.initState();

    ever(loc.searchResults, (results) {
      if (!mounted) return;

      if (results.isNotEmpty && loc.searchFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_searchOverlay != null) return;
    _searchOverlay = _createOverlayEntry();
    Overlay.of(context).insert(_searchOverlay!);
  }

  void _hideOverlay() {
    if (_searchOverlay == null) return;
    try {
      _searchOverlay!.remove();
    } catch (_) {
    } finally {
      _searchOverlay = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (_) => Positioned(
        width: 620,
        child: CompositedTransformFollower(
          link: loc.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            elevation: 6,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                final results = loc.searchResults;
                if (results.isEmpty) return const SizedBox.shrink();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: .5,
                      color: const Color(0xFF93C5FD).withOpacity(.6),
                    ),
                    itemBuilder: (_, i) {
                      final item = results[i];

                      return Container(
                        color: i.isEven
                            ? Colors.white.withOpacity(.9)
                            : const Color(0xFFEFF6FF).withOpacity(.7),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE).withOpacity(.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              loc.getIconForType(item['type'] ?? ''),
                              color: const Color(0xFF1D4ED8),
                              size: 16,
                            ),
                          ),
                          title: Text(
                            item['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${(item['lat'] as num).toStringAsFixed(4)}, ${(item['lon'] as num).toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF4B5563).withOpacity(.8),
                            ),
                          ),
                          onTap: () async {
                            final p = LatLng(
                              (item['lat'] as num).toDouble(),
                              (item['lon'] as num).toDouble(),
                            );

                            final name = item['name']?.toString() ?? '';

                            loc.searchController.text = name;
                            c.addressController.text = name;

                            loc.currentMapCenter.value = p;
                            loc.currentZoom.value = 16.0;

                            c.setLocation(p.latitude, p.longitude);

                            await loc.moveMapToLocation(p, 16.0);

                            _hideOverlay();
                            loc.searchFocusNode.unfocus();
                            loc.searchResults.clear();
                          },
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _close() {
    c.initializeControllers(widget.settings);
    c.setLocation(widget.settings.location.latitude, widget.settings.location.longitude);

    loc.currentMapCenter.value = widget.initialCenter;
    loc.currentZoom.value = 15.0;
    loc.searchController.text = widget.settings.address.trim();
    loc.searchResults.clear();

    Get.back();
  }

  Future<void> _save() async {
    if (c.isLoading.value) return;

    final center = loc.currentMapCenter.value;
    if (center == null) {
      Get.snackbar('خطأ', 'الرجاء تحديد الموقع قبل الحفظ');
      return;
    }

    c.setLocation(center.latitude, center.longitude);

    final success = await c.updateSettings(requireLocation: true);
    if (success && Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 920),
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
                _header(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _fields(),
                      const SizedBox(height: 14),
                      _locationBox(),
                      const SizedBox(height: 26),
                      _actions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.edit_2, color: Colors.blue.shade700),
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
            onPressed: _close,
            icon: Icon(Iconsax.close_circle, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Widget _fields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'اسم الصيدلية',
                icon: Iconsax.shop,
                controller: c.nameController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                label: 'اسم المالك',
                icon: Iconsax.user,
                controller: c.ownerNameController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'رقم الهاتف',
                icon: Iconsax.call,
                controller: c.phoneController,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                label: 'وصف الموقع أو أقرب نقطة دالة',
                icon: Iconsax.location,
                controller: c.addressController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _locationBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          _searchBox(),
          const SizedBox(height: 12),
          _map(),
          const SizedBox(height: 10),
          _hint(),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return CompositedTransformTarget(
      link: loc.layerLink,
      child: TextField(
        controller: loc.searchController,
        focusNode: loc.searchFocusNode,
        style: TextStyle(color: Colors.blue.shade900),
        decoration: InputDecoration(
          hintText: 'ابحث عن موقع...',
          hintStyle: TextStyle(color: Colors.blue.shade300),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            if (!loc.isSearching.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }),
          filled: true,
          fillColor: Colors.white,
          border: _border(Colors.blue.shade100),
          enabledBorder: _border(Colors.blue.shade100),
          focusedBorder: _border(Colors.blue.shade400),
        ),
        onChanged: (value) {
          _debounce?.cancel();

          final q = value.trim();
          if (q.length < 3) {
            loc.searchResults.clear();
            _hideOverlay();
            return;
          }

          _debounce = Timer(
            const Duration(milliseconds: 700),
                () => loc.searchPlace(q),
          );
        },
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _map() {
    return SizedBox(
      height: 250,
      child: Obx(() {
        final center = loc.currentMapCenter.value ?? widget.initialCenter;
        final zoom = loc.currentZoom.value == 0.0 ? 15.0 : loc.currentZoom.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            mapController: loc.mapController,
            options: MapOptions(
              center: center,
              zoom: zoom,
              onPositionChanged: (position, hasGesture) {
                final p = position.center;
                if (p == null) return;

                loc.currentMapCenter.value = p;
                loc.currentZoom.value = position.zoom ?? zoom;
                c.setLocation(p.latitude, p.longitude);
              },
              onTap: (_, p) {
                loc.currentMapCenter.value = p;
                c.setLocation(p.latitude, p.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pharmacy2.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 44,
                    height: 44,
                    builder: (_) => Icon(
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
    );
  }

  Widget _hint() {
    return Obx(() {
      final selected = loc.currentMapCenter.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected != null ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null ? Colors.green.shade200 : Colors.orange.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected != null ? Iconsax.tick_circle : Iconsax.info_circle,
              color: selected != null ? Colors.green : Colors.orange,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected != null
                    ? 'تم تحديد الموقع. يمكنك تعديل وصف الموقع يدويًا قبل الحفظ.'
                    : 'حدد موقع الصيدلية من الخريطة أو نتائج البحث.',
                style: TextStyle(
                  color: selected != null ? Colors.green.shade800 : Colors.orange.shade800,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextButton.icon(
              onPressed: _close,
              icon: Icon(Iconsax.close_circle, color: Colors.grey.shade600),
              label: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            height: 48,
            child: Obx(() {
              final loading = c.isLoading.value;

              return TextButton(
                onPressed: loading ? null : _save,
                style: TextButton.styleFrom(
                  backgroundColor: loading ? Colors.blue.shade300 : Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      loading ? 'جاري الحفظ...' : 'حفظ التغييرات',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blue.shade800)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              cursorColor: Colors.blue.shade600,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
                hintText: 'أدخل هنا...',
                filled: true,
                fillColor: Colors.blue.shade50.withOpacity(.4),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}