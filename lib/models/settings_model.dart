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
  final bool notificationsEnabled;
  final String? imageUrl;
  final PharmacyLocation location;
  final BusinessHours businessHours;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const PharmacySettings({
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
    required this.notificationsEnabled,
    required this.imageUrl,
    required this.location,
    required this.businessHours,
    required this.createdAt,
    required this.updatedAt,
  });

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
      notificationsEnabled: true,
      imageUrl: null,
      location: PharmacyLocation.empty(),
      businessHours: BusinessHours.empty(),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  factory PharmacySettings.fromMap(
      Map<String, dynamic> data,
      String documentId, {
        Map<String, dynamic>? generalData,
        Map<String, dynamic>? businessHoursData,
      }) {
    final locationMap = data['location'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['location'])
        : <String, dynamic>{};

    final general = generalData ?? <String, dynamic>{};
    final business = businessHoursData ?? <String, dynamic>{};

    return PharmacySettings(
      uid: data['id']?.toString() ??
          data['uid']?.toString() ??
          documentId,
      name: data['pharmacyName']?.toString() ??
          data['name']?.toString() ??
          '',
      ownerName: data['ownerName']?.toString() ?? '',
      ownerIdNumber: data['ownerIdNumber']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      address: locationMap['address']?.toString() ??
          data['address']?.toString() ??
          '',
      licenseNumber: data['licenseNumber']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      is24Hours: (general['is24Hours'] ?? data['is24Hours'] ?? false) == true,
      isOnline: (general['isOnline'] ?? data['isOnline'] ?? false) == true,
      notificationsEnabled:
      (general['notificationsEnabled'] ?? true) == true,
      imageUrl: data['imageUrl']?.toString(),
      location: PharmacyLocation.fromMap(locationMap),
      businessHours: BusinessHours.fromMap(
        business,
        is24Hours: (general['is24Hours'] ?? data['is24Hours'] ?? false) == true,
      ),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt']
          : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt']
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'pharmacyName': name,
      'ownerName': ownerName,
      'ownerIdNumber': ownerIdNumber,
      'email': email,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'status': status,
      'is24Hours': is24Hours,
      'isOnline': isOnline,
      'imageUrl': imageUrl,
      'location': location.copyWith(address: address).toMap(),
      'businessHours': businessHours.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  PharmacySettings copyWith({
    String? uid,
    String? name,
    String? ownerName,
    String? ownerIdNumber,
    String? email,
    String? phoneNumber,
    String? address,
    String? licenseNumber,
    String? status,
    bool? is24Hours,
    bool? isOnline,
    bool? notificationsEnabled,
    String? imageUrl,
    bool clearImageUrl = false,
    PharmacyLocation? location,
    BusinessHours? businessHours,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return PharmacySettings(
      uid: uid ?? this.uid,
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
      notificationsEnabled:
      notificationsEnabled ?? this.notificationsEnabled,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      location: location ?? this.location,
      businessHours: businessHours ?? this.businessHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PharmacyLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PharmacyLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory PharmacyLocation.empty() {
    return const PharmacyLocation(
      latitude: 0.0,
      longitude: 0.0,
      address: '',
    );
  }

  factory PharmacyLocation.fromMap(Map<String, dynamic> data) {
    return PharmacyLocation(
      latitude: _parseDouble(
        data['latitude'] ?? data['lat'],
      ) ??
          0.0,
      longitude: _parseDouble(
        data['longitude'] ?? data['lng'],
      ) ??
          0.0,
      address: data['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  PharmacyLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return PharmacyLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
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

  const BusinessHours({
    required this.sunday,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
  });

  factory BusinessHours.empty({bool is24Hours = false}) {
    if (is24Hours) {
      return const BusinessHours(
        sunday: '24 Hours',
        monday: '24 Hours',
        tuesday: '24 Hours',
        wednesday: '24 Hours',
        thursday: '24 Hours',
        friday: '24 Hours',
        saturday: '24 Hours',
      );
    }

    return const BusinessHours(
      sunday: '09:00 - 18:00',
      monday: '09:00 - 18:00',
      tuesday: '09:00 - 18:00',
      wednesday: '09:00 - 18:00',
      thursday: '09:00 - 18:00',
      friday: '09:00 - 18:00',
      saturday: '09:00 - 18:00',
    );
  }

  factory BusinessHours.fromMap(
      Map<String, dynamic> data, {
        bool is24Hours = false,
      }) {
    if (is24Hours) {
      return const BusinessHours(
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
      sunday: data['sunday']?.toString() ?? '09:00 - 18:00',
      monday: data['monday']?.toString() ?? '09:00 - 18:00',
      tuesday: data['tuesday']?.toString() ?? '09:00 - 18:00',
      wednesday: data['wednesday']?.toString() ?? '09:00 - 18:00',
      thursday: data['thursday']?.toString() ?? '09:00 - 18:00',
      friday: data['friday']?.toString() ?? '09:00 - 18:00',
      saturday: data['saturday']?.toString() ?? '09:00 - 18:00',
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