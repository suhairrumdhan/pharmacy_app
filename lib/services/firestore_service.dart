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

  Future<void> createPharmacyFromRequest(String uid, Map<String, dynamic> requestData) async {
    try {
      Map<String, dynamic> locationData = {
        'latitude': requestData['latitude'] ?? '',
        'longitude': requestData['longitude'] ?? '',
        'address': requestData['address'] ?? '',
      };

      if (requestData.containsKey('location') && requestData['location'] is Map) {
        locationData = requestData['location'];
      }

      final pharmacyRef = _firestore.collection('pharmacies').doc(uid);
      final employeeRef = pharmacyRef.collection('employees').doc('admin');
      final settingsRef = pharmacyRef.collection('settings').doc('general');

      final batch = _firestore.batch();

      // 1. إنشاء الصيدلية
      batch.set(pharmacyRef, {
        'uid': uid,
        'name': requestData['pharmacyName'] ?? '',
        'ownerName': requestData['ownerName'] ?? '',
        'email': requestData['email'] ?? '',
        'phoneNumber': requestData['phoneNumber'] ?? '',
        'licenseNumber': requestData['licenseNumber'] ?? '',
        'location': locationData,
        'status': 'approved',
        'userType': 'pharmacy',
        'isOnline': true,
        'is24Hours': requestData['is24Hours'] ?? false,
        'imageUrl': requestData['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. إنشاء الموظف الافتراضي admin
      batch.set(employeeRef, {
        'username': 'admin',
        'password': 'admin', // ⚠️ يفضل تشفيرها لاحقاً
        'role': 'admin',
        'isActive': true,
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. إنشاء الإعدادات الافتراضية
      batch.set(settingsRef, {
        'language': 'ar',
        'is24Hours': requestData['is24Hours'] ?? false,
        'notificationsEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تنفيذ كل العمليات دفعة واحدة
      await batch.commit();

      print("✅ تم إنشاء الصيدلية وموظف admin والإعدادات بنجاح");
    } catch (e) {
      print("❌ فشل في إنشاء الصيدلية أو البيانات الافتراضية: $e");
      rethrow;
    }
  }

  // جلب بيانات الصيدلية

  Future<Map<String, dynamic>?> getPharmacyData(String uid) async {
    try {
      // أولاً: البحث في مجموعة pharmacies
      final pharmacyDoc = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(uid)
          .get();

      if (pharmacyDoc.exists) {
        return pharmacyDoc.data();
      }

      // ثانياً: البحث في pharmacyRequests (حالة الانتظار)
      final requestDoc = await FirebaseFirestore.instance
          .collection('pharmacyRequests')
          .doc(uid)
          .get();

      if (requestDoc.exists) {
        return requestDoc.data();
      }

      return null;
    } catch (e) {
      print('Error getting pharmacy data: $e');
      return null;
    }
  }
}