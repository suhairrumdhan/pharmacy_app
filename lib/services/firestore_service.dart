import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إنشاء طلب الصيدلية
  Future<void> createPharmacyRequest({
    required String userId,
    required String email,
    required String pharmacyName,
    required String ownerName,
    required String licenseNumber,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('pharmacyRequests').doc(userId).set({
        'userId': userId,
        'email': email.trim(),
        'pharmacyName': pharmacyName.trim(),
        'ownerName': ownerName.trim(),
        'licenseNumber': licenseNumber.trim(),
        'phoneNumber': phoneNumber.trim(),
        'address': address.trim(),
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'description': address.trim(),
        },
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'userType': 'pharmacy',
      });
      print("✅ طلب الصيدلية مخلوق في Firestore");
    } catch (e) {
      print("❌ فشل في حفظ طلب الصيدلية: $e");
      rethrow;
    }
  }

  // التحقق من حالة الموافقة
  Future<Map<String, dynamic>?> checkApprovalStatus(String uid) async {
    try {
      // البحث في pharmacies أولاً
      final pharmacyDoc = await _firestore.collection('pharmacies').doc(uid).get();
      if (pharmacyDoc.exists) {
        final data = pharmacyDoc.data()!;
        return {
          'exists': true,
          'collection': 'pharmacies',
          'data': data,
          'status': data['status'] ?? 'pending',
          'userType': data['userType'] ?? 'pharmacy',
        };
      }

      // البحث في pharmacyRequests
      final requestDoc = await _firestore.collection('pharmacyRequests').doc(uid).get();
      if (requestDoc.exists) {
        final data = requestDoc.data()!;
        return {
          'exists': true,
          'collection': 'pharmacyRequests',
          'data': data,
          'status': data['status'] ?? 'pending',
        };
      }

      return {'exists': false};
    } catch (e) {
      print("❌ خطأ في التحقق من حالة الموافقة: $e");
      rethrow;
    }
  }

  // إنشاء صيدلية من طلب معتمد
  Future<void> createPharmacyFromRequest(String uid, Map<String, dynamic> requestData) async {
    try {
      Map<String, dynamic> locationData = {
        'latitude': requestData['latitude'] ?? '',
        'longitude': requestData['longitude'] ?? '',
        'description': requestData['address'] ?? '',
      };

      if (requestData.containsKey('location') && requestData['location'] is Map) {
        locationData = requestData['location'];
      }

      await _firestore.collection('pharmacies').doc(uid).set({
        'uid': uid,
        'name': requestData['pharmacyName'] ?? '',
        'ownerName': requestData['ownerName'] ?? '',
        'email': requestData['email'] ?? '',
        'phoneNumber': requestData['phoneNumber'] ?? '',
        'licenseNumber': requestData['licenseNumber'] ?? '',
        'address': requestData['address'] ?? '',
        'location': locationData,
        'status': 'approved',
        'userType': 'pharmacy',
        'isOnline': true,
        'is24Hours': requestData['is24Hours'] ?? false,
        'imageUrl': requestData['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ تم إنشاء الصيدلية في كولكشن pharmacies");
    } catch (e) {
      print("❌ فشل في إنشاء الصيدلية: $e");
      rethrow;
    }
  }

  // جلب بيانات الصيدلية
  Future<Map<String, dynamic>?> getPharmacyData(String uid) async {
    try {
      final doc = await _firestore.collection("pharmacies").doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("❌ خطأ في جلب بيانات الصيدلية: $e");
      return null;
    }
  }
}