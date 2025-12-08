import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../controllers/auth_controller.dart';

class SignUpLogic {
  final AuthController controller;
  final MapController mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pharmacyNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isSearching = false;
  bool showSearchResults = false;
  List<Map<String, dynamic>> searchResults = [];
  final FocusNode searchFocusNode = FocusNode();
  final LayerLink layerLink = LayerLink();
  OverlayEntry? overlayEntry;
  bool isMovingMarker = false;
  LatLng? currentMapCenter;
  double currentZoom = 12.0;

  // Callback functions
  VoidCallback? onSignUpSuccess;
  VoidCallback? onNavigateToLogin;

  SignUpLogic(this.controller);

  void initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDefaultLocation();
    });

    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) {
        removeOverlay();
      }
    });
  }

  void dispose() {
    removeOverlay();
    emailController.dispose();
    passwordController.dispose();
    pharmacyNameController.dispose();
    ownerNameController.dispose();
    licenseController.dispose();
    phoneController.dispose();
    addressController.dispose();
    _searchController.dispose();
    searchFocusNode.dispose();
  }

  void removeOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
    showSearchResults = false;
  }

  Future<void> initDefaultLocation() async {
    try {
      final defaultLocation = const LatLng(32.871796, 13.201452);
      controller.selectedLocation.value = defaultLocation;
      currentMapCenter = defaultLocation;
      currentZoom = 12.0;

      await Future.delayed(const Duration(milliseconds: 300));

      updateSearchControllerWithCoordinates(defaultLocation);
    } catch (e) {
      print("Error initializing location: $e");
    }
  }

  Future<void> moveMapToLocation(LatLng location, double zoom) async {
    try {
      isMovingMarker = true;
      currentMapCenter = location;
      currentZoom = zoom;

      mapController.move(location, zoom);

      await Future.delayed(const Duration(milliseconds: 500));
      isMovingMarker = false;
    } catch (e) {
      print("Error moving map: $e");
      isMovingMarker = false;
    }
  }

  Future<void> searchPlace(String query) async {
    if (query.trim().isEmpty) {
      removeOverlay();
      return;
    }

    isSearching = true;

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5&accept-language=ar');

      final response = await http.get(
        url,
        headers: {'User-Agent': 'PharmacyApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);

        searchResults = results.map((item) => {
          'name': item['display_name'] ?? 'موقع غير معروف',
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
          'type': item['type'] ?? '',
          'importance': item['importance'] ?? 0.0,
        }).toList();

        showSearchResults = results.isNotEmpty;

        if (results.isEmpty) {
          removeOverlay();
          Get.snackbar(
            "لم يتم العثور",
            "لم نتمكن من العثور على '$query'",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        throw Exception('فشل في جلب البيانات');
      }
    } catch (e) {
      print("Search error: $e");
      removeOverlay();
      Get.snackbar(
        "خطأ في البحث",
        "تعذر البحث عن الموقع",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSearching = false;
    }
  }

  IconData getIconForType(String type) {
    switch (type) {
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'school':
      case 'university':
        return Icons.school;
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'airport':
        return Icons.flight;
      case 'park':
      case 'zoo':
      case 'garden':
        return Icons.park;
      default:
        return Icons.place;
    }
  }

  Future<void> selectSearchResult(Map<String, dynamic> result) async {
    final location = LatLng(result['lat'], result['lon']);

    _searchController.text = result['name'];
    controller.selectedLocation.value = location;

    if (addressController.text.isEmpty) {
      addressController.text = result['name'];
      controller.address.value = result['name'];
    }

    removeOverlay();
    searchFocusNode.unfocus();

    await moveMapToLocation(location, 16.0);

    Get.snackbar(
      "تم تحديد الموقع",
      result['name'],
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> smartSearch(String query) async {
    if (query.trim().isEmpty) return;

    searchFocusNode.unfocus();

    try {
      final cleaned = query.replaceAll(' ', '');
      final parts = cleaned.split(',');

      if (parts.length == 2) {
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);

        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          final location = LatLng(lat, lng);

          controller.selectedLocation.value = location;
          updateSearchControllerWithCoordinates(location);
          await moveMapToLocation(location, 16.0);

          Get.snackbar(
            "تم تحديث الموقع",
            "تم تحديد الموقع بالإحداثيات",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return;
        }
      }
    } catch (e) {
      // ليس إحداثيات
    }

    await searchPlace(query);
  }

  bool validateLocation() {
    if (controller.selectedLocation.value == null) {
      Get.snackbar(
        "موقع مطلوب",
        "يرجى تحديد موقع الصيدلية على الخريطة",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  void updateSearchControllerWithCoordinates(LatLng location) {
    _searchController.text =
    "${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}";
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      "تم النسخ",
      "تم نسخ الإحداثيات إلى الحافظة",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void handleSignUp() {
    if (formKey.currentState!.validate() && validateLocation()) {
      controller.signUpPharmacy();
      onSignUpSuccess?.call();
    }
  }

  void navigateToLogin() {
    onNavigateToLogin?.call();
  }

  // Validators
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!value.contains('@')) {
      return 'بريد إلكتروني غير صحيح';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    List<String> errors = [];
    if (value.length < 8) {
      errors.add('8 أحرف على الأقل');
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('حرف كبير واحد على الأقل');
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('حرف صغير واحد على الأقل');
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('رقم واحد على الأقل');
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('حرف خاص واحد على الأقل');
    }
    if (errors.isNotEmpty) {
      return 'كلمة مرور ضعيفة. يجب أن تحتوي على:\n${errors.map((e) => '• $e').join('\n')}';
    }
    return null;
  }

  String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final trimmedValue = value.trim();
    if (!RegExp(r'^[\d\+\-\(\)\s]+$').hasMatch(trimmedValue)) {
      return 'يجب أن يحتوي على أرقام فقط مع الرموز (+, -, (, ))';
    }
    final digitsOnly = trimmedValue.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 9) {
      return 'يجب أن يحتوي على 9 أرقام على الأقل';
    }
    if (digitsOnly.length > 15) {
      return 'يجب ألا يتجاوز 15 رقماً';
    }
    return null;
  }

  String get searchText => _searchController.text;
  set searchText(String value) => _searchController.text = value;
}