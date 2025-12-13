import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LocationService extends GetxService {
  // --- Map Controller ---
  final MapController mapController = MapController();

  // --- Rx Variables ---
  final isSearching = false.obs;
  final isMovingMarker = false.obs;
  final currentZoom = 12.0.obs;
  final currentMapCenter = Rxn<LatLng>();
  final searchResults = <Map<String, dynamic>>[].obs;


  final RxString addressDescription = ''.obs;
  final TextEditingController addressController = TextEditingController();

  final LayerLink layerLink = LayerLink();

  // --- Text Controller للبحث ---
  final searchController = TextEditingController();

  // --- Focus Node للبحث ---
  final FocusNode searchFocusNode = FocusNode();

  // --- Constants ---
  LatLng get defaultLocation => const LatLng(32.871796, 13.201452);

  static const LatLng safeDefaultLocation = LatLng(32.875595, 13.197557);

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  // ==================== طرق الحصول على الموقع الحالي ====================

  // الحصول على الموقع من IP (للديسكتوب والويب)
  Future<LatLng?> getCurrentLocation() async {
    try {
      final location1 = await _getLocationFromIpApi().timeout(const Duration(seconds: 5));
      if (location1 != null) {
        await updateMapToLocation(location1);
        return location1;
      }

      final location2 = await _getLocationFromIpInfo().timeout(const Duration(seconds: 5));
      if (location2 != null) {
        await updateMapToLocation(location2);
        return location2;
      }

      final location3 = await _getLocationFromIpGeolocation().timeout(const Duration(seconds: 5));
      if (location3 != null) {
        await updateMapToLocation(location3);
        return location3;
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // الحصول على الموقع من ip-api.com (مجاني)
  Future<LatLng?> _getLocationFromIpApi() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final lat = data['lat'] as double;
          final lon = data['lon'] as double;
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      print("Error with ip-api: $e");
    }
    return null;
  }

  // الحصول على الموقع من ipinfo.io
  Future<LatLng?> _getLocationFromIpInfo() async {
    try {
      const apiKey = ''; // ضع الـ API key هنا إذا كان لديك
      String url = 'https://ipinfo.io/json';
      if (apiKey.isNotEmpty) {
        url += '?token=$apiKey';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['loc'] != null) {
          final loc = data['loc'].split(',');
          final lat = double.parse(loc[0]);
          final lon = double.parse(loc[1]);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      print("Error with ipinfo: $e");
    }
    return null;
  }

  // الحصول على الموقع من ipgeolocation.io
  Future<LatLng?> _getLocationFromIpGeolocation() async {
    try {
      const apiKey = ''; // ضع الـ API key هنا إذا كان لديك
      if (apiKey.isEmpty) return null;

      final response = await http.get(
        Uri.parse('https://api.ipgeolocation.io/ipgeo?apiKey=$apiKey'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = double.parse(data['latitude']);
        final lon = double.parse(data['longitude']);
        return LatLng(lat, lon);
      }
    } catch (e) {
      print("Error with ipgeolocation: $e");
    }
    return null;
  }

  // جلب العنوان من الإحداثيات (عكسي)
  Future<String?> getAddressForLocation(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PharmacyApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return null;
  }

  // ==================== طرق الخريطة والبحث ====================

  void initializeMap({LatLng? initialLocation}) {
    try {
      final location = initialLocation ?? defaultLocation;
      currentMapCenter.value = location;
      currentZoom.value = 12.0;

      _moveMapToDefaultWithRetry(location);
    } catch (e) {
      print("خطأ في تهيئة الخريطة: $e");
    }
  }

  Future<void> initializeMapWithUserLocation() async {
    try {
      final userLocation = await getCurrentLocation();
      if (userLocation != null) {
        initializeMap(initialLocation: userLocation);

        // الحصول على اسم الموقع
        final address = await getAddressForLocation(
            userLocation.latitude,
            userLocation.longitude
        );
        if (address != null) {
          searchController.text = address;
        }
      } else {
        initializeMap();
      }
    } catch (e) {
      initializeMap();
    }
  }

  void _moveMapToDefaultWithRetry(LatLng location, {int retryCount = 3}) async {
    int attempts = 0;

    while (attempts < retryCount) {
      try {
        await Future.delayed(Duration(milliseconds: 100 * (attempts + 1)));

        if (mapController != null) {
          mapController.move(location, 12.0);
          return;
        }
      } catch (e) {
        print("فشلت محاولة تحريك الخريطة ${attempts + 1}: $e");
        attempts++;
      }
    }
  }

  Future<void> moveMapToLocation(LatLng location, double zoom) async {
    try {
      isMovingMarker.value = true;
      currentMapCenter.value = location;
      currentZoom.value = zoom;

      mapController.move(location, zoom);

      await Future.delayed(const Duration(milliseconds: 500));
      isMovingMarker.value = false;
    } catch (e) {
      print("خطأ في تحريك الخريطة: $e");
      isMovingMarker.value = false;
    }
  }

  Future<void> updateMapToLocation(LatLng location) async {
    await moveMapToLocation(location, 14.0);
  }

  Future<void> searchPlace(String query) async {
    if (query.trim().isEmpty) return;

    isSearching.value = true;

    try {
      final encodedQuery = Uri.encodeComponent(query);

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
              '?format=json'
              '&q=$encodedQuery'
              '&limit=10'
              '&addressdetails=1'
              '&countrycodes=ly'
              '&accept-language=ar'
      );


      final response = await http
          .get(
        url,
        headers: {
          'User-Agent':
          'PharmacyApp/2.0 (contact: suheerrumdhan@gmail.com)',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 8));

      // 🔴 Rate limit
      if (response.statusCode == 429) {
        Get.snackbar(
          'تنبيه',
          'الرجاء الانتظار قليلاً قبل إعادة البحث',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List data = jsonDecode(response.body);

      if (data.isEmpty) {
        searchResults.clear();
        return;
      }

      searchResults.assignAll(
        data.map((e) => {
          'name': e['display_name'],
          'lat': double.parse(e['lat']),
          'lon': double.parse(e['lon']),
          'type': e['type'] ?? '',
        }).toList(),
      );
    } catch (e, s) {
      debugPrint('SEARCH ERROR: $e');
      debugPrintStack(stackTrace: s);

      Get.snackbar(
        'خطأ',
        'تعذر البحث حالياً',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectSearchResult(Map<String, dynamic> result) async {
    final location = LatLng(result['lat'], result['lon']);

    searchController.text = result['name'];
    currentMapCenter.value = location;
    searchResults.clear();

    // تحديث الوصف
    addressDescription.value = result['name']; // نستخدم اسم الاقتراح
    addressController.text = addressDescription.value;


    await moveMapToLocation(location, 16.0);

    Get.snackbar(
      "تم تحديد الموقع",
      result['name'],
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void selectLocation(LatLng latLng) {
    currentMapCenter.value = latLng;
    searchResults.clear();

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

  // ==================== Utilities ====================

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

  // التحقق من تحديد موقع
  bool validateLocation() {
    if (currentMapCenter.value == null) {
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

  // تحويل LatLng إلى Map
  Map<String, dynamic> getLocationAsMap() {
    if (currentMapCenter.value == null) {
      return {
        "address": "",
        "lat": defaultLocation.latitude,
        "lng": defaultLocation.longitude,
      };
    }

    return {
      "address": addressController.text,
      "lat": currentMapCenter.value!.latitude,
      "lng": currentMapCenter.value!.longitude,
    };
  }

  // الحصول على الإحداثيات كمصفوفة
  List<double> getLocationCoordinates() {
    if (currentMapCenter.value == null) {
      return [defaultLocation.latitude, defaultLocation.longitude];
    }

    return [
      currentMapCenter.value!.latitude,
      currentMapCenter.value!.longitude
    ];
  }

  // الحصول على موقع آمن
  LatLng getSafeDefaultLocation() {
    return safeDefaultLocation;
  }

  // تنظيف البيانات
  void clearLocationData() {
    searchResults.clear();
    isSearching.value = false;
    isMovingMarker.value = false;
  }
}