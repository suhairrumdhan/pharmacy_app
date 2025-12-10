import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/auth_controller.dart';
import '../login_page.dart';
import 'sign_up_logic.dart';
import 'sign_up_widgets.dart';
import 'search_overlay.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final SignUpLogic logic;
  bool showPass = false;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    logic = SignUpLogic(authController);
    logic.initialize();
    logic.onSignUpSuccess = _onSignUpSuccess;
    logic.onNavigateToLogin = _navigateToLogin;
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  void _onSignUpSuccess() {}
  void _navigateToLogin() => Get.off(() => const LoginPage());

  void _showOverlay() {
    logic.removeOverlay();
    if (logic.searchResults.isNotEmpty && logic.searchFocusNode.hasFocus) {
      logic.overlayEntry = SearchOverlay.createOverlay(
        layerLink: logic.layerLink,
        searchResults: logic.searchResults,
        context: context,
        onSelectResult: logic.selectSearchResult,
        getIconForType: logic.getIconForType,
      );
      Overlay.of(context).insert(logic.overlayEntry!);
    }
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
                image: AssetImage('assets/images/bg.jpg'), // نفس الصورة المستخدمة في LoginPage
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
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  minWidth: 800,
                ),
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), // صندوق شبه شفاف
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: logic.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "تسجيل صيدلية",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
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
        Expanded(flex: 6, child: _buildAccountAndPharmacyInfo()),
        const SizedBox(width: 30),
        Expanded(flex: 7, child: _buildMapSection()),
      ],
    );
  }

  Widget _buildAccountAndPharmacyInfo() {
    return Column(
      children: [
        SignUpWidgets.buildSectionTitle("معلومات الحساب"),
        const SizedBox(height: 15),
        _buildAccountInfoFields(),
        const SizedBox(height: 25),
        SignUpWidgets.buildSectionTitle("معلومات الصيدلية"),
        const SizedBox(height: 15),
        _buildPharmacyInfoFields(),
      ],
    );
  }

  Widget _buildAccountInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SignUpWidgets.buildTextField(
                controller: logic.emailController,
                label: "البريد الإلكتروني",
                icon: Icons.email,
                focusNode: logic.emailFocus,
                keyboardType: TextInputType.emailAddress,
                validator: logic.emailValidator,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(logic.passwordFocus);
                },
                onChanged: (value) => logic.controller.email.value = value,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SignUpWidgets.buildTextField(
                controller: logic.passwordController,
                label: "كلمة المرور",
                icon: Icons.lock,
                obscureText: !showPass,
                focusNode: logic.passwordFocus,
                validator: logic.passwordValidator,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(logic.pharmacyNameFocus);
                },
                suffixIcon: IconButton(
                  icon:
                  Icon(showPass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      showPass = !showPass;
                    });
                  },
                ),
                onChanged: (value) => logic.controller.password.value = value,
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
              child: SignUpWidgets.buildTextField(
                controller: logic.pharmacyNameController,
                label: "اسم الصيدلية",
                icon: Icons.local_pharmacy,
                focusNode: logic.pharmacyNameFocus,
                validator: (value) =>
                    logic.requiredValidator(value, 'اسم الصيدلية'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(logic.ownerNameFocus);
                },
                onChanged: (value) => logic.controller.pharmacyName.value = value,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SignUpWidgets.buildTextField(
                controller: logic.ownerNameController,
                label: "اسم المالك",
                icon: Icons.person,
                focusNode: logic.ownerNameFocus,
                validator: (value) =>
                    logic.requiredValidator(value, 'اسم المالك'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(logic.licenseFocus);
                },
                onChanged: (value) => logic.controller.ownerName.value = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: SignUpWidgets.buildTextField(
                controller: logic.licenseController,
                label: "رقم الترخيص",
                icon: Icons.badge,
                focusNode: logic.licenseFocus,
                validator: (value) =>
                    logic.requiredValidator(value, 'رقم الترخيص'),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(logic.phoneFocus);
                },
                onChanged: (value) => logic.controller.licenseNumber.value = value,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SignUpWidgets.buildTextField(
                controller: logic.phoneController,
                label: "رقم الهاتف",
                icon: Icons.phone,
                focusNode: logic.phoneFocus,
                keyboardType: TextInputType.phone,
                validator: logic.phoneValidator,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(logic.addressFocus);
                },
                onChanged: (value) => logic.controller.phoneNumber.value = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SignUpWidgets.buildTextField(
          controller: logic.addressController,
          label: "وصف الموقع أو أقرب نقطة دالة",
          icon: Icons.location_on,
          focusNode: logic.addressFocus,
          maxLines: 2,
          validator: (value) => logic.requiredValidator(value, 'وصف الموقع'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => logic.handleSignUp(),
          onChanged: (value) => logic.controller.address.value = value,
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      children: [
        SignUpWidgets.buildSectionTitle("موقع الصيدلية"),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "ابحث عن مكان أو انقر على الخريطة لتحديد موقع الصيدلية",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 15),
        _buildSearchBox(),
        const SizedBox(height: 15),
        _buildMap(),
        const SizedBox(height: 15),
        _buildLocationStatus(),
        const SizedBox(height: 30),
        _buildSignUpButton(),
        const SizedBox(height: 15),
        _buildLoginLink(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSearchBox() {
    return CompositedTransformTarget(
      link: logic.layerLink,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: logic.searchText),
                      focusNode: logic.searchFocusNode,
                      decoration: InputDecoration(
                        hintText:
                        "ابحث عن مكان (مثال: طرابلس، حديقة، مستشفى...)",
                        border: InputBorder.none,
                        suffixIcon: logic.isSearching
                            ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: logic.smartSearch,
                      onChanged: (value) {
                        logic.searchText = value;
                        if (value.length > 2) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted && value == logic.searchText) {
                              logic.searchPlace(value);
                            }
                          });
                        } else {
                          logic.removeOverlay();
                        }
                      },
                      onTap: () {
                        if (logic.searchResults.isNotEmpty &&
                            logic.searchFocusNode.hasFocus &&
                            mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showOverlay();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: logic.isSearching
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.search),
                    onPressed: logic.isSearching
                        ? null
                        : () => logic.smartSearch(logic.searchText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _buildFlutterMap(),
            SignUpWidgets.buildMapControls(
              onZoomIn: () async {
                final currentZoom = logic.mapController.zoom;
                if (currentZoom < 19) {
                  await logic.moveMapToLocation(
                    logic.mapController.center,
                    currentZoom + 1,
                  );
                }
              },
              onZoomOut: () async {
                final currentZoom = logic.mapController.zoom;
                final newZoom = currentZoom > 3 ? currentZoom - 1 : currentZoom;
                await logic.moveMapToLocation(
                  logic.mapController.center,
                  newZoom,
                );
              },
              onMyLocation: () async {
                logic.isMovingMarker = true;
                setState(() {});
                await logic.controller.getCurrentLocation();
                if (logic.controller.selectedLocation.value != null) {
                  logic.controller.selectedLocation.value =
                      logic.controller.selectedLocation.value;
                  logic.updateSearchControllerWithCoordinates(
                      logic.controller.selectedLocation.value!);
                  logic.removeOverlay();
                }
                logic.isMovingMarker = false;
                setState(() {});
              },
              onDeleteLocation: () {
                logic.controller.selectedLocation.value = null;
                logic.currentMapCenter = null;
                logic.searchText = '';
                logic.removeOverlay();
                setState(() {});
                Get.snackbar(
                  "تم المسح",
                  "تم مسح الموقع المحدد",
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                );
              },
              isMovingMarker: logic.isMovingMarker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlutterMap() {
    return Obx(() {
      final currentLocation = logic.controller.selectedLocation.value;
      return FlutterMap(
        mapController: logic.mapController,
        options: MapOptions(
          center: logic.currentMapCenter ??
              currentLocation ??
              const LatLng(32.871796, 13.201452),
          zoom: logic.currentZoom,
          onTap: (tapPosition, latlng) async {
            logic.controller.selectedLocation.value = latlng;
            logic.updateSearchControllerWithCoordinates(latlng);
            logic.removeOverlay();
          },
          onPositionChanged: (MapPosition position, bool hasGesture) {
            if (hasGesture) {
              logic.currentMapCenter = position.center;
              logic.currentZoom = position.zoom!;
            }
          },
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
                  builder: (ctx) => const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Widget _buildLocationStatus() {
    return Obx(() {
      final selectedLocation = logic.controller.selectedLocation.value;
      return SignUpWidgets.buildLocationStatus(
        hasLocation: selectedLocation != null,
        onCopyCoordinates: selectedLocation != null
            ? () => logic.copyToClipboard(
            "${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}")
            : () {},
      );
    });
  }

  Widget _buildSignUpButton() {
    return Obx(() {
      return SignUpWidgets.buildSignUpButton(
        isLoading: logic.controller.isLoading.value,
        isSearching: logic.isSearching,
        isMovingMarker: logic.isMovingMarker,
        onPressed: logic.handleSignUp,
      );
    });
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("لديك حساب بالفعل؟"),
        TextButton(
          onPressed: logic.navigateToLogin,
          child: const Text("تسجيل الدخول"),
        ),
      ],
    );
  }
}
