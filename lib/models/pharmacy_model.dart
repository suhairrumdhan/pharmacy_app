import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String email;
  final String pharmacyName;
  final String ownerName;
  final String licenseNumber;
  final String phoneNumber;
  final String address;
  final double latitude;
  final double longitude;
  final String status; // approved / pending / rejected

  PharmacyModel({
    required this.id,
    required this.email,
    required this.pharmacyName,
    required this.ownerName,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory PharmacyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PharmacyModel(
      id: doc.id,
      email: data['email'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'pharmacyName': pharmacyName,
      'ownerName': ownerName,
      'licenseNumber': licenseNumber,
      'phoneNumber': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
