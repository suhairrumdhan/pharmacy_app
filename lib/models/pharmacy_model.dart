import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String email;
  final String pharmacyName;
  final String ownerName;
  final String licenseNumber;
  final String licenseFileUrl;
  final String ownerIdFileUrl;
  final String phoneNumber;
  final Map<String, dynamic> location;
  final String ownerIdNumber;
  final bool is24Hours;
  final bool isOnline;
  final String status;
  final DateTime requestDate;

  const PharmacyModel({
    required this.id,
    required this.email,
    required this.pharmacyName,
    required this.ownerName,
    required this.licenseNumber,
    required this.licenseFileUrl,
    required this.ownerIdFileUrl,
    required this.phoneNumber,
    required this.location,
    required this.ownerIdNumber,
    required this.is24Hours,
    required this.isOnline,
    required this.status,
    required this.requestDate,
  });

  double get latitude => (location['latitude'] as num?)?.toDouble() ?? 0.0;
  double get longitude => (location['longitude'] as num?)?.toDouble() ?? 0.0;
  String get address => (location['address'] ?? '').toString();

  factory PharmacyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PharmacyModel(
      id: doc.id,
      email: data['email'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      licenseFileUrl: data['licenseFileUrl'] ?? '',
      ownerIdFileUrl: data['ownerIdFileUrl'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      location: Map<String, dynamic>.from(data['location'] ?? {}),
      ownerIdNumber: data['ownerIdNumber'] ?? '',
      is24Hours: data['is24Hours'] ?? false,
      isOnline: data['isOnline'] ?? false,
      status: data['status'] ?? 'pending',
      requestDate: data['requestDate'] != null
          ? (data['requestDate'] is Timestamp
          ? (data['requestDate'] as Timestamp).toDate()
          : DateTime.parse(data['requestDate'].toString()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'pharmacyName': pharmacyName,
      'ownerName': ownerName,
      'licenseNumber': licenseNumber,
      'licenseFileUrl': licenseFileUrl,
      'ownerIdFileUrl': ownerIdFileUrl,
      'phoneNumber': phoneNumber,
      'location': location,
      'ownerIdNumber': ownerIdNumber,
      'is24Hours': is24Hours,
      'isOnline': isOnline,
      'status': status,
      'requestDate': Timestamp.fromDate(requestDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PharmacyModel copyWith({
    String? id,
    String? email,
    String? pharmacyName,
    String? ownerName,
    String? licenseNumber,
    String? licenseFileUrl,
    String? ownerIdFileUrl,
    String? phoneNumber,
    Map<String, dynamic>? location,
    String? ownerIdNumber,
    bool? is24Hours,
    bool? isOnline,
    String? status,
    DateTime? requestDate,
  }) {
    return PharmacyModel(
      id: id ?? this.id,
      email: email ?? this.email,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      ownerName: ownerName ?? this.ownerName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseFileUrl: licenseFileUrl ?? this.licenseFileUrl,
      ownerIdFileUrl: ownerIdFileUrl ?? this.ownerIdFileUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      ownerIdNumber: ownerIdNumber ?? this.ownerIdNumber,
      is24Hours: is24Hours ?? this.is24Hours,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
    );
  }
}