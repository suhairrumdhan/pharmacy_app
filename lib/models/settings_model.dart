// models/settings_model.dart

class PharmacySettings {
  final String id; // أضفنا حقل ID
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String licenseNumber;
  final String status;
  final bool is24Hours;
  final bool isOnline;
  final String currency;
  final BusinessHours businessHours;

  PharmacySettings({
    required this.id, // مطلوب الآن
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.licenseNumber,
    required this.status,
    required this.is24Hours,
    required this.isOnline,
    required this.currency,
    required this.businessHours,
  });

  factory PharmacySettings.fromMap(Map<String, dynamic> data) {
    return PharmacySettings(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      ownerName: data['ownerName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      status: data['status'] ?? '',
      is24Hours: data['is24Hours'] ?? false,
      isOnline: data['isOnline'] ?? false,
      currency: data['currency'] ?? 'دينار',
      businessHours: BusinessHours.fromMap(data['businessHours'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'licenseNumber': licenseNumber,
      'status': status,
      'is24Hours': is24Hours,
      'isOnline': isOnline,
      'currency': currency,
      'businessHours': businessHours.toMap(),
    };
  }

  PharmacySettings copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? email,
    String? phoneNumber,
    String? address,
    String? licenseNumber,
    String? status,
    bool? is24Hours,
    bool? isOnline,
    String? currency,
    BusinessHours? businessHours,
  }) {
    return PharmacySettings(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      is24Hours: is24Hours ?? this.is24Hours,
      isOnline: isOnline ?? this.isOnline,
      currency: currency ?? this.currency,
      businessHours: businessHours ?? this.businessHours,
    );
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

  factory BusinessHours.fromMap(Map<String, dynamic> data) {
    return BusinessHours(
      sunday: data['sunday'] ?? '09:00 - 18:00',
      monday: data['monday'] ?? '09:00 - 18:00',
      tuesday: data['tuesday'] ?? '09:00 - 18:00',
      wednesday: data['wednesday'] ?? '09:00 - 18:00',
      thursday: data['thursday'] ?? '09:00 - 18:00',
      friday: data['friday'] ?? '09:00 - 18:00',
      saturday: data['saturday'] ?? '09:00 - 18:00',
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