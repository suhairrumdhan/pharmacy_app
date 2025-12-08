import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

class LocationService {
  // الحصول على الموقع من IP (الطريقة الرئيسية للديسكتوب)
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Use a shorter timeout for each service
      final location1 = await _getLocationFromIpApi().timeout(const Duration(seconds: 5));
      if (location1 != null) {
        return location1;
      }

      // المحاولة الثانية: استخدام ipinfo.io
      final location2 = await _getLocationFromIpInfo().timeout(const Duration(seconds: 5));
      if (location2 != null) {
        return location2;
      }

      // المحاولة الثالثة: استخدام ipgeolocation.io
      final location3 = await _getLocationFromIpGeolocation().timeout(const Duration(seconds: 5));
      if (location3 != null) {
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
      const apiKey = 'YOUR_IPINFO_API_KEY'; // ضع الـ API key هنا
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
      const apiKey = 'YOUR_IPGEOLOCATION_API_KEY';
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

  // موقع افتراضي آمن
  LatLng getSafeDefaultLocation() {
    return LatLng(32.875595, 13.197557); // ليبيا
  }
}