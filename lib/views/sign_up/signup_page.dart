import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../controllers/sign_up_controller.dart';
import '../../services/location_service.dart';

class SignUpPage extends StatefulWidget {
  // 1. التسجيل في الكونستركتور
  SignUpPage({Key? key}) : super(key: key) {
    // سجل الخدمات هنا
    if (!Get.isRegistered<LocationService>()) {
      Get.put(LocationService(), permanent: true);
    }
    if (!Get.isRegistered<SignUpController>()) {
      Get.put(SignUpController());
    }
  }

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final LocationService locationService = Get.find<LocationService>();
  final SignUpController controller = Get.put(SignUpController());

  bool showPass = false;
  OverlayEntry? _searchOverlay;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    // مراقبة نتائج البحث (إظهار / إخفاء القائمة تلقائياً)
    ever(locationService.searchResults, (results) {
      if (!mounted) return;

      if (results.isNotEmpty &&
          locationService.searchFocusNode.hasFocus) {
        _showOverlay();
      } else if (_searchOverlay != null) {
        _hideOverlay();
      }
    });

  }

  @override
  @override
  void dispose() {
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية - صورة
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // طبقة شفافة لتعتيم الخلفية قليلاً
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // المحتوى
          SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  minWidth: 800,
                ),
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade100,
                      Colors.white,
                      Colors.blue.shade100,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // العنوان مع الأيقونة
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "تسجيل صيدلية",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMainContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الجزء الأيسر: معلومات الحساب والصيدلية والملفات
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildAccountAndPharmacyInfo(),
                const SizedBox(height: 25),
                Obx(() => _buildFileUploadSection()), // فقط حول هذا الجزء
              ],
            ),
          ),
        ),
        const SizedBox(width: 30),

        // الجزء الأيمن: الخريطة
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildMapSection(),
              const SizedBox(height: 20),
              _buildSignUpButton(),
              const SizedBox(height: 15),
              _buildLoginLink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountAndPharmacyInfo() {
    return Column(
      children: [
        _buildSectionTitle("معلومات الحساب", Iconsax.profile_circle),
        const SizedBox(height: 15),
        _buildAccountInfoFields(),
        const SizedBox(height: 25),
        _buildSectionTitle("معلومات الصيدلية", Iconsax.hospital),
        const SizedBox(height: 15),
        _buildPharmacyInfoFields(),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildAccountInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.emailController,
                label: "البريد الإلكتروني",
                icon: Iconsax.sms,
                focusNode: controller.emailFocus,
                keyboardType: TextInputType.emailAddress,
                validator: controller.emailValidator,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.passwordFocus);
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: controller.passwordController,
                label: "كلمة المرور",
                icon: Iconsax.lock,
                obscureText: !showPass,
                focusNode: controller.passwordFocus,
                validator: controller.passwordValidator,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.pharmacyNameFocus);
                },
                suffixIcon: IconButton(
                  icon: Icon(showPass ? Iconsax.eye : Iconsax.eye_slash),
                  onPressed: () {
                    setState(() {
                      showPass = !showPass;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPharmacyInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.pharmacyNameController,
                label: "اسم الصيدلية",
                icon: Iconsax.hospital,
                focusNode: controller.pharmacyNameFocus,
                validator: (value) =>
                    controller.requiredValidator(value, 'اسم الصيدلية'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.ownerNameFocus);
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: controller.ownerNameController,
                label: "اسم المالك",
                icon: Iconsax.profile_circle,
                focusNode: controller.ownerNameFocus,
                validator: (value) =>
                    controller.requiredValidator(value, 'اسم المالك'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.licenseFocus);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.licenseController,
                label: "رقم الترخيص",
                icon: Iconsax.card,
                focusNode: controller.licenseFocus,
                validator: (value) =>
                    controller.requiredValidator(value, 'رقم الترخيص'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.ownerIdFocus);
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: controller.ownerIdNumberController,
                label: "رقم هوية المالك",
                icon: Iconsax.card_edit,
                focusNode: controller.ownerIdFocus,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    controller.requiredValidator(value, 'رقم هوية المالك'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.phoneFocus);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.phoneController,
                label: "رقم الهاتف",
                icon: Iconsax.call,
                focusNode: controller.phoneFocus,
                keyboardType: TextInputType.phone,
                validator: controller.phoneValidator,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(controller.addressFocus);
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: locationService.addressController,
                label: "وصف الموقع أو أقرب نقطة دالة",
                icon: Iconsax.location,
                focusNode: controller.addressFocus,
                validator: (value) => controller.requiredValidator(value, 'وصف الموقع'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => controller.submitSignUp(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      children: [
        _buildSectionTitle("موقع الصيدلية", Iconsax.map),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "ابحث عن مكان أو انقر على الخريطة لتحديد موقع الصيدلية",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 15),
        _buildSearchBox(),
        const SizedBox(height: 15),
        _buildMap(),
        const SizedBox(height: 15),
        _buildLocationStatus(),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      children: [
        _buildSectionTitle("الملفات المطلوبة", Iconsax.document_upload),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildFileUploadCard(
                title: "صورة الترخيص",
                fileUrl: controller.licenseFileUrl.value,
                onUpload: () => controller.uploadLicenseImage(),
                onClear: () => controller.clearLicenseImage(),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildFileUploadCard(
                title: "صورة هوية المالك",
                fileUrl: controller.ownerIdFileUrl.value,
                onUpload: () => controller.uploadOwnerIdImage(),
                onClear: () => controller.clearOwnerIdImage(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String fileUrl,
    required Future<void> Function() onUpload,
    required VoidCallback onClear,
  }) {
    final hasFile = fileUrl.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasFile ? Colors.blue : Colors.blue.shade200,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasFile
                ? [Colors.green.shade50, Colors.white]
                : [Colors.blue.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.document,
                    color: hasFile ? Colors.green : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: hasFile ? Colors.green : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasFile)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.tick_circle, color: Colors.green, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "تم رفع الملف",
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: Icon(Iconsax.trash, size: 18),
                      label: Text(
                        "حذف الملف",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: onClear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  icon: Icon(Iconsax.cloud_add, size: 20),
                  label: Text(
                    "رفع ملف",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 1. مربع البحث ============
  void _showOverlay() {
    if (_searchOverlay != null) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _searchOverlay = _createOverlayEntry();
    overlay.insert(_searchOverlay!);
  }



  void _hideOverlay() {
    if (_searchOverlay == null) return;

    try {
      _searchOverlay!.remove();
    } catch (_) {
      // تجاهل أي محاولة إزالة مكررة
    } finally {
      _searchOverlay = null;
    }
  }


  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 950, // تقليل العرض إلى 85%
        child: CompositedTransformFollower(
          link: locationService.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent, // لجعل الخلفية شفافة
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // شفافية 95%
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.8), // شفافية الحدود
                  width: 1.5, // تخفيف سماكة الحدود
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1), // تخفيف الظل
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                final results = locationService.searchResults;

                if (results.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4), // تباعد داخلي
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 0.5,
                      color: const Color(0xFF93C5FD).withOpacity(0.6), // شفافية الفواصل
                    ),
                    itemBuilder: (context, index) {
                      final item = results[index];

                      return Container(
                        color: index % 2 == 0
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFFEFF6FF).withOpacity(0.7), // شفافية الخلفيات
                        child: ListTile(
                          dense: true, // لجعل العناصر أكثر إحكاما
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 32, // تصغير حجم الأيقونة
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              locationService.getIconForType(item['type']),
                              color: const Color(0xFF1D4ED8).withOpacity(0.9),
                              size: 16, // تصغير حجم الأيقونة
                            ),
                          ),
                          title: Text(
                            item['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13, // تصغير حجم الخط
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${item['lat'].toStringAsFixed(4)}, ${item['lon'].toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 11, // تصغير حجم الخط
                              color: const Color(0xFF4B5563).withOpacity(0.8),
                            ),
                          ),
                          onTap: () async {
                            await locationService.selectSearchResult(item);

                            _hideOverlay();
                            locationService.searchFocusNode.unfocus();
                            locationService.searchResults.clear();
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

  Widget _buildSearchBox() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _hideOverlay();
        locationService.searchFocusNode.unfocus();
      },
      child: CompositedTransformTarget(
        link: locationService.layerLink,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: locationService.searchController,
                  focusNode: locationService.searchFocusNode,
                  style: TextStyle(color: Colors.blue[800]),
                  decoration: InputDecoration(
                    hintText: "ابحث عن مكان",
                    hintStyle: TextStyle(color: Colors.blue.shade400),
                    border: InputBorder.none,
                    suffixIcon: Obx(() {
                      return locationService.isSearching.value
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : const SizedBox.shrink();
                    }),
                  ),
                  onChanged: (value) {
                    _debounce?.cancel();

                    if (value.trim().length < 3) {
                      locationService.searchResults.clear();
                      _hideOverlay();
                      return;
                    }

                    _debounce = Timer(
                      const Duration(milliseconds: 700),
                          () => locationService.searchPlace(value),
                    );
                  },
                  onSubmitted: (value) {
                    locationService.searchPlace(value);
                    _hideOverlay();
                  },

                ),
              ),
              Obx(() {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: locationService.isSearching.value
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Iconsax.search_normal,
                        color: Colors.white),
                    onPressed: locationService.isSearching.value
                        ? null
                        : () {
                      locationService.searchPlace(
                        locationService.searchController.text,
                      );
                      _hideOverlay();
                    },

                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _buildFlutterMap(),
            _buildMapControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlutterMap() {
    return Obx(() {
      final currentLocation = locationService.currentMapCenter.value;
      return FlutterMap(
        mapController: locationService.mapController,
        options: MapOptions(
          center: currentLocation ?? locationService.defaultLocation,
          zoom: locationService.currentZoom.value,
            onTap: (tapPosition, latlng) {
              locationService.selectLocation(latlng);
            },
            onPositionChanged: (position, hasGesture) {
              if (hasGesture && position.zoom != null) {
                locationService.currentZoom.value = position.zoom!;
              }
            }

        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.pharmacy_app',
          ),
          if (currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: currentLocation,
                  anchorPos: AnchorPos.align(AnchorAlign.center),
                  builder: (ctx) => Icon(
                    Iconsax.location,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Widget _buildMapControls() {
    return Stack(
      children: [
        // مؤشر التحميل
        if (locationService.isMovingMarker.value)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    "جاري تحديد الموقع...",
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ],
              ),
            ),
          ),

        // أزرار التكبير والتصغير
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر التكبير
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Tooltip(
                    message: "تكبير",
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        onTap: () async {
                          final currentZoom = locationService.mapController.zoom;
                          if (currentZoom < 19) {
                            await locationService.moveMapToLocation(
                              locationService.mapController.center,
                              currentZoom + 1,
                            );
                          }
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            Iconsax.add,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.blue.shade100,
                ),
                // زر التصغير
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Tooltip(
                    message: "تصغير",
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        onTap: () async {
                          final currentZoom = locationService.mapController.zoom;
                          final newZoom = currentZoom > 3 ? currentZoom - 1 : currentZoom;
                          await locationService.moveMapToLocation(
                            locationService.mapController.center,
                            newZoom,
                          );
                        },
                        child: SizedBox(
                          width: 45,
                          height: 45,
                          child: Icon(
                            Iconsax.minus,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // زر حذف الموقع
        Positioned(
          left: 10,
          top: 10,
          child: Tooltip(
            message: "حذف الموقع المحدد",
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    locationService.currentMapCenter.value = null;
                    locationService.searchController.clear();
                    locationService.searchResults.clear();
                  },
                  child: Icon(
                    Iconsax.trash,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Obx(() {
      final selectedLocation = locationService.currentMapCenter.value;
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedLocation != null ? Colors.green.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedLocation != null ? Colors.green.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selectedLocation != null ? Iconsax.tick_circle : Iconsax.info_circle,
              color: selectedLocation != null ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedLocation != null
                    ? "✓ تم تحديد الموقع بنجاح"
                    : "يرجى تحديد موقع الصيدلية على الخريطة",
                style: TextStyle(
                  color: selectedLocation != null ? Colors.green.shade800 : Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selectedLocation != null)
              TextButton(
                onPressed: () => locationService.copyToClipboard(
                    "${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}"
                ),
                child: Text(
                  "نسخ الإحداثيات",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSignUpButton() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            onPressed: controller.isLoading.value ||
                locationService.isSearching.value ||
                locationService.isMovingMarker.value
                ? null
                : () => controller.handleSignUp(),
            child: controller.isLoading.value
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text("جاري التسجيل..."),
              ],
            )
                : const Text(
              "تسجيل الصيدلية",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.info_circle,
            color: Colors.blue.shade600,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            "لديك حساب بالفعل؟",
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: controller.navigateToLogin,
            child: Text(
              "تسجيل الدخول",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widgets Helper Methods
  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
    FocusNode? focusNode,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        style: TextStyle(color: Colors.blue[800], fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.blue.shade50,
          enabled: enabled,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
      ),
    );
  }

  Widget _buildLocationStatusWidget({
    required bool hasLocation,
    required VoidCallback onCopyCoordinates,
  }) {
    if (hasLocation) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.tick_circle, color: Colors.green[700], size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "الموقع محدد بنجاح",
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.info_circle, color: Colors.orange[700], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "لم يتم تحديد موقع الصيدلية بعد - الرجاء تحديد الموقع على الخريطة",
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButtonWidget({
    required bool isLoading,
    required bool isSearching,
    required bool isMovingMarker,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    "جاري إنشاء الحساب...",
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: isLoading || isSearching || isMovingMarker
                  ? null
                  : onPressed,
              child: isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "جاري التسجيل...",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.profile_add, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "تسجيل الصيدلية",
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // void _showOverlay() {
  //   if (locationService.searchResults.isNotEmpty &&
  //       locationService.searchFocusNode.hasFocus) {
  //     final overlay = OverlayEntry(
  //       builder: (context) {
  //         return Positioned(
  //           width: MediaQuery.of(context).size.width * 0.95 * 0.7 - 30,
  //           child: CompositedTransformFollower(
  //             link: locationService.layerLink,
  //             showWhenUnlinked: false,
  //             offset: const Offset(0, 48),
  //             child: Material(
  //               elevation: 8,
  //               borderRadius: BorderRadius.circular(12),
  //               child: Container(
  //                 constraints: const BoxConstraints(
  //                   maxHeight: 300,
  //                   minHeight: 50,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(color: Colors.blue.shade200, width: 2),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.blue.withOpacity(0.2),
  //                       blurRadius: 15,
  //                       offset: const Offset(0, 5),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Obx(() {
  //                   return ListView.builder(
  //                     padding: EdgeInsets.zero,
  //                     shrinkWrap: true,
  //                     itemCount: locationService.searchResults.length,
  //                     itemBuilder: (context, index) {
  //                       final result = locationService.searchResults[index];
  //                       return Container(
  //                         decoration: BoxDecoration(
  //                           border: index < locationService.searchResults.length - 1
  //                               ? Border(
  //                             bottom: BorderSide(color: Colors.blue.shade100),
  //                           )
  //                               : null,
  //                           color: index % 2 == 0 ? Colors.white : Colors.blue.shade50,
  //                         ),
  //                         child: ListTile(
  //                           dense: true,
  //                           leading: Icon(
  //                             locationService.getIconForType(result['type']),
  //                             color: Colors.blue,
  //                             size: 20,
  //                           ),
  //                           title: Text(
  //                             result['name'],
  //                             maxLines: 2,
  //                             overflow: TextOverflow.ellipsis,
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               color: Colors.blue[800],
  //                               fontWeight: FontWeight.w600,
  //                             ),
  //                           ),
  //                           subtitle: Text(
  //                             '${result['lat'].toStringAsFixed(4)}, ${result['lon'].toStringAsFixed(4)}',
  //                             style: TextStyle(fontSize: 12, color: Colors.blue[600]),
  //                           ),
  //                           onTap: () => locationService.selectSearchResult(result),
  //                         ),
  //                       );
  //                     },
  //                   );
  //                 }),
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //
  //     Overlay.of(context).insert(overlay);
  //   }
  // }

}