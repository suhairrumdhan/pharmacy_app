class PharmacySettings {
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String licenseNumber;
  final String status;
  final bool is24Hours;
  final bool isOnline;
  final String taxNumber;
  final double taxRate;
  final String currency;
  final BusinessHours businessHours;

  PharmacySettings({
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.licenseNumber,
    required this.status,
    required this.is24Hours,
    required this.isOnline,
    required this.taxNumber,
    required this.taxRate,
    required this.currency,
    required this.businessHours,
  });

  factory PharmacySettings.fromMap(Map<String, dynamic> data) {
    return PharmacySettings(
      name: data['name'] ?? '',
      ownerName: data['ownerName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      status: data['status'] ?? '',
      is24Hours: data['is24Hours'] ?? false,
      isOnline: data['isOnline'] ?? false,
      taxNumber: data['taxNumber'] ?? '',
      taxRate: (data['taxRate'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'ريال',
      businessHours: BusinessHours.fromMap(data['businessHours'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerName': ownerName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'licenseNumber': licenseNumber,
      'status': status,
      'is24Hours': is24Hours,
      'isOnline': isOnline,
      'taxNumber': taxNumber,
      'taxRate': taxRate,
      'currency': currency,
      'businessHours': businessHours.toMap(),
    };
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
}