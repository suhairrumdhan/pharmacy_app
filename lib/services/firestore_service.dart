import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/security/default_permissions.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<bool> pharmacyExists(String uid) async {
    final doc =
    await _firestore.collection('pharmacies').doc(uid).get();
    return doc.exists;
  }

  Future<void> createPharmacyFromRequest(
      String uid,
      Map<String, dynamic> requestData,
      ) async {
    try {
      final pharmacyRef = _firestore.collection('pharmacies').doc(uid);
      final employeeRef = pharmacyRef.collection('employees').doc('admin');
      final settingsRef = pharmacyRef.collection('settings').doc('general');
      final rolesRef = pharmacyRef.collection('roles');
      final permissionsRef = pharmacyRef.collection('permissions');

      final batch = _firestore.batch();

      // 1️⃣ الصيدلية
      batch.set(pharmacyRef, {
        'id': uid,
        'email': requestData['email'] ?? '',
        'pharmacyName': requestData['pharmacyName'] ?? '',
        'ownerName': requestData['ownerName'] ?? '',
        'licenseNumber': requestData['licenseNumber'] ?? '',
        'licenseFileUrl': requestData['licenseFileUrl'] ?? '',
        'ownerIdFileUrl': requestData['ownerIdFileUrl'] ?? '',
        'phoneNumber': requestData['phoneNumber'] ?? '',
        'locationCoordinates': requestData['locationCoordinates'] ?? {},
        'location': requestData['location'] ?? {},
        'ownerIdNumber': requestData['ownerIdNumber'] ?? '',
        'is24Hours': requestData['is24Hours'] ?? false,
        'isOnline': true,
        'status': 'approved',
        'approvedDate': FieldValue.serverTimestamp(),
        'approvedBy': 'admin',
        'imageUrl': requestData['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ الموظف admin
      batch.set(employeeRef, {
        'username': 'admin',
        'password': 'admin',
        'roleId' : 'admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Roles الافتراضية
      for (final role in DefaultPermissions.defaultRoles) {
        batch.set(
          rolesRef.doc(role['id']),
          {
            ...role,
          },
        );
      }

      // 4️⃣ Permissions لكل Role
      batch.set(permissionsRef.doc('admin'), {
        'permissions': DefaultPermissions.adminPermissions,
      });

      batch.set(permissionsRef.doc('pharmacist'), {
        'permissions': DefaultPermissions.pharmacistPermissions,
      });

      batch.set(permissionsRef.doc('cashier'), {
        'permissions': DefaultPermissions.cashierPermissions,
      });

      // 5️⃣ Settings
      batch.set(settingsRef, {
        'is24Hours': requestData['is24Hours'] ?? false,
        'notificationsEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }



  Future<List<Map<String, dynamic>>> getEmployees(String pharmacyId) async {
    try {
      final snapshot = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ خطأ في جلب الموظفين: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEmployeeByCredentials({
    required String pharmacyId,
    required String username,
    required String password,
  }) async {
    try {
      final query = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('employees')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password) // ⚠️ لاحقاً يمكن تشفير الباسوورد
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null; // الموظف غير موجود أو غير نشط
      }

      return query.docs.first.data();
    } catch (e) {
      print("❌ خطأ في جلب الموظف: $e");
      return null;
    }
  }


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