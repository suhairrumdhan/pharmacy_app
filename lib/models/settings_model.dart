// models/pharmacy_settings.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacySettings {
  final String uid;
  final String name;
  final String ownerName;
  final String ownerIdNumber;
  final String email;
  final String phoneNumber;
  final String address;
  final String licenseNumber;
  final String status;
  final bool is24Hours;
  final bool isOnline;
  final String? imageUrl;
  final PharmacyLocation location;
  final BusinessHours businessHours;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  PharmacySettings({
    required this.uid,
    required this.name,
    required this.ownerName,
    required this.ownerIdNumber,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.licenseNumber,
    required this.status,
    required this.is24Hours,
    required this.isOnline,
    required this.imageUrl,
    required this.location,
    required this.businessHours,
    required this.createdAt,
    required this.updatedAt,
  });

  // القيمة الافتراضية
  factory PharmacySettings.empty() {
    return PharmacySettings(
      uid: '',
      name: '',
      ownerName: '',
      ownerIdNumber: '',
      email: '',
      phoneNumber: '',
      address: '',
      licenseNumber: '',
      status: 'pending',
      is24Hours: false,
      isOnline: false,
      imageUrl: null,
      location: PharmacyLocation(latitude: 0, longitude: 0),
      businessHours: BusinessHours.empty(), // لازم توفرها
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }


  factory PharmacySettings.fromMap(Map<String, dynamic> data, String documentId) {
    return PharmacySettings(
      uid: data['uid'],
      name: data['name'],
      ownerName: data['ownerName'],
      ownerIdNumber: data['ownerIdNumber'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      address: data['address']?.toString() ?? '',
      licenseNumber: data['licenseNumber'],
      status: data['status'],
      is24Hours: data['is24Hours'] ?? false,
      isOnline: data['isOnline'] ?? false,
      imageUrl: data['imageUrl']?.toString() ?? '',
      location: PharmacyLocation.fromMap(data['location'] ?? {}),
      businessHours: BusinessHours.fromMap(data['businessHours'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'ownerName': ownerName,
      'ownerIdNumber': ownerIdNumber,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'licenseNumber': licenseNumber,
      'status': status,
      'is24Hours': is24Hours,
      'isOnline': isOnline,
      'imageUrl': imageUrl,
      'location': location.toMap(),
      'businessHours': businessHours.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  PharmacySettings copyWith({
    String? name,
    String? ownerName,
    String? ownerIdNumber,
    String? email,
    String? phoneNumber,
    String? address,
    String? description,
    String? licenseNumber,
    String? status,
    bool? is24Hours,
    bool? isOnline,
    String? imageUrl,
    PharmacyLocation? location,
    BusinessHours? businessHours,
    Timestamp? updatedAt, // هذا ضروري!
  }) {
    return PharmacySettings(
      uid: uid,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      ownerIdNumber: ownerIdNumber ?? this.ownerIdNumber,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      is24Hours: is24Hours ?? this.is24Hours,
      isOnline: isOnline ?? this.isOnline,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      businessHours: businessHours ?? this.businessHours,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
    );
  }
}

class PharmacyLocation {
  final double latitude;
  final double longitude;

  PharmacyLocation({
    required this.latitude,
    required this.longitude,
  });

  factory PharmacyLocation.fromMap(Map<String, dynamic> data) {
    final latFromMap = _parseDouble(data['lat']);
    final lngFromMap = _parseDouble(data['lng']);

    double latFromCoords = 0.0;
    double lngFromCoords = 0.0;
    if (data['locationCoordinates'] is List &&
        (data['locationCoordinates'] as List).length >= 2) {
      final coords = data['locationCoordinates'] as List;
      latFromCoords = _parseDouble(coords[0]) ?? 0.0;
      lngFromCoords = _parseDouble(coords[1]) ?? 0.0;
    }

    return PharmacyLocation(
      latitude: latFromMap ?? latFromCoords ?? 0.0,
      longitude: lngFromMap ?? lngFromCoords ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': latitude,
      'lng': longitude,
      'locationCoordinates': [latitude, longitude], // تحديث المصفوفة
    };
  }

  PharmacyLocation copyWith({
    double? latitude,
    double? longitude,
  }) {
    final newLat = latitude ?? this.latitude;
    final newLng = longitude ?? this.longitude;
    return PharmacyLocation(
      latitude: newLat,
      longitude: newLng,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class BusinessHours {
  final String sunday;
  final String monday;
  final String tuesday;
  final String wednesday;
  final String thursday;
  final String friday;
  final String saturday;

  BusinessHours({
    required this.sunday,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
  });

  factory BusinessHours.fromMap(Map<String, dynamic> data, {bool is24Hours = false}) {
    if (is24Hours) {
      return BusinessHours(
        sunday: '24 Hours',
        monday: '24 Hours',
        tuesday: '24 Hours',
        wednesday: '24 Hours',
        thursday: '24 Hours',
        friday: '24 Hours',
        saturday: '24 Hours',
      );
    }
    return BusinessHours(
      sunday: data['sunday'] ?? '   09:00 ص - 6:00م',
      monday: data['monday'] ?? '09:00 ص - 6:00م',
      tuesday: data['tuesday'] ?? '09:00 ص - 6:00م',
      wednesday: data['wednesday'] ?? '09:00 ص - 6:00م',
      thursday: data['thursday'] ?? '09:00 ص - 6:00م',
      friday: data['friday'] ?? '09:00 ص - 6:00م',
      saturday: data['saturday'] ?? '09:00 ص - 6:00م',
    );
  }

  factory BusinessHours.empty({bool is24Hours = false}) {
    if (is24Hours) {
      return BusinessHours(
        sunday: '24 Hours',
        monday: '24 Hours',
        tuesday: '24 Hours',
        wednesday: '24 Hours',
        thursday: '24 Hours',
        friday: '24 Hours',
        saturday: '24 Hours',
      );
    }

    return BusinessHours(
      sunday: '09:00 - 18:00',
      monday: '09:00 - 18:00',
      tuesday: '09:00 - 18:00',
      wednesday: '09:00 - 18:00',
      thursday: '09:00 - 18:00',
      friday: '09:00 - 18:00',
      saturday: '09:00 - 18:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sunday': sunday,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
    };
  }

  // أضف هذه الدالة لتمكين copyWith
  BusinessHours copyWith({
    String? sunday,
    String? monday,
    String? tuesday,
    String? wednesday,
    String? thursday,
    String? friday,
    String? saturday,
  }) {
    return BusinessHours(
      sunday: sunday ?? this.sunday,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
    );
  }
}