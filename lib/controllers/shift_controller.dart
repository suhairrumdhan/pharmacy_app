// controllers/shift_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/sales_model.dart';
import '../models/shift_model.dart';

class ShiftController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<Shift> activeShift = Rxn<Shift>();
  final RxList<Shift> shifts = <Shift>[].obs;

  final isLoading = false.obs;
  final isMutating = false.obs;

  // -----------------------
  // Helpers / Paths
  // -----------------------
  String get pharmacyId {
    try {
      return Get.find<AuthController>().pharmacyId;
    } catch (_) {
      return '';
    }
  }

  CollectionReference<Map<String, dynamic>> get _shiftsCol {
    final id = pharmacyId;
    if (id.isEmpty) throw Exception('pharmacyId فارغ');
    return _firestore.collection('pharmacies').doc(id).collection('shifts');
  }

  DocumentReference<Map<String, dynamic>> get _shiftStateDoc {
    final id = pharmacyId;
    if (id.isEmpty) throw Exception('pharmacyId فارغ');
    return _firestore.collection('pharmacies').doc(id).collection('meta').doc('shiftState');
  }

  Future<void> _ensureShiftStateExists() async {
    final snap = await _shiftStateDoc.get();
    if (!snap.exists) {
      await _shiftStateDoc.set({
        'activeShiftId': null,
        'status': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  void _snack(String title, String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rawSnackbar(
        title: title,
        message: msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    });
  }

  // -----------------------
  // Load
  // -----------------------
  Future<void> loadShifts({int limit = 50}) async {
    final pid = pharmacyId;
    if (pid.isEmpty) return;

    try {
      isLoading.value = true;

      await _ensureShiftStateExists();
      await _loadActiveShiftFromState();

      final qs = await _shiftsCol.orderBy('openedAt', descending: true).limit(limit).get();
      shifts.assignAll(qs.docs.map((d) => Shift.fromDoc(d)).toList());
    } catch (e, st) {
      debugPrint('❌ loadShifts: $e\n$st');
      _snack('خطأ', 'فشل تحميل الورديات');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadActiveShiftFromState() async {
    final stateSnap = await _shiftStateDoc.get();
    final state = stateSnap.data() ?? {};
    final activeId = (state['activeShiftId'] ?? '').toString();

    if (activeId.isEmpty) {
      activeShift.value = null;
      return;
    }

    final shiftSnap = await _shiftsCol.doc(activeId).get();
    if (!shiftSnap.exists) {
      // تنظيف state لو id غلط
      await _shiftStateDoc.set({
        'activeShiftId': null,
        'status': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      activeShift.value = null;
      return;
    }

    activeShift.value = Shift.fromDoc(shiftSnap);
  }

  // -----------------------
  // Open (NO TRANSACTION)
  // -----------------------
  Future<void> openShift({
    required double openingCash,
    String? notes,
  }) async {
    final pid = pharmacyId;
    if (pid.isEmpty) {
      _snack('خطأ', 'لم يتم تحديد الصيدلية');
      return;
    }
    if (openingCash < 0) {
      _snack('تحقق', 'رصيد الافتتاح لا يمكن أن يكون سالب');
      return;
    }

    try {
      isMutating.value = true;

      await _ensureShiftStateExists();

      // ✅ منع فتح وردية ثانية
      final stateSnap = await _shiftStateDoc.get();
      final state = stateSnap.data() ?? {};
      final existingActiveId = (state['activeShiftId'] ?? '').toString();
      if (existingActiveId.isNotEmpty) {
        _snack('غير مسموح', 'يوجد وردية مفتوحة بالفعل');
        await _loadActiveShiftFromState();
        return;
      }

      final auth = Get.find<AuthController>();
      final actor = auth.actorInfo;

      final shiftRef = _shiftsCol.doc();
      final batch = _firestore.batch();

      batch.set(shiftRef, {
        'pharmacyId': pid,
        'status': 'open',
        'openedAt': FieldValue.serverTimestamp(),
        'openedBy': actor,

        'openingCash': openingCash,

        // totals
        'cashTotal': 0.0,
        'cardTotal': 0.0,

        // ✅ Insurance smart totals
        'insuranceBilledTotal': 0.0,
        'insuranceCollectedTotal': 0.0,
        'insurancePendingTotal': 0.0,

        'salesCount': 0,
        'refundsCount': 0,

        // drawer check
        'closingCash': null,
        'expectedDrawerCash': null,
        'drawerDiff': null,

        'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ سجل الوردية النشطة
      batch.set(_shiftStateDoc, {
        'activeShiftId': shiftRef.id,
        'status': 'open',
        'openedAt': FieldValue.serverTimestamp(),
        'openedBy': actor,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      await loadShifts();
      _snack('تم', 'تم فتح وردية جديدة');
    } catch (e, st) {
      debugPrint('❌ openShift: $e\n$st');
      _snack('خطأ', 'فشل فتح الوردية');
    } finally {
      isMutating.value = false;
    }
  }

  // -----------------------
  // Close (NO TRANSACTION)
  // -----------------------
  Future<void> closeShift({
    required double closingCash,
    String? notes,
  }) async {
    if (closingCash < 0) {
      _snack('تحقق', 'الكاش داخل الدرج لا يمكن أن يكون سالب');
      return;
    }

    try {
      isMutating.value = true;

      await _ensureShiftStateExists();

      final stateSnap = await _shiftStateDoc.get();
      final state = stateSnap.data() ?? {};
      final activeId = (state['activeShiftId'] ?? '').toString();

      if (activeId.isEmpty) {
        _snack('غير موجود', 'لا توجد وردية نشطة لإغلاقها');
        await _loadActiveShiftFromState();
        return;
      }

      final ref = _shiftsCol.doc(activeId);
      final snap = await ref.get();
      if (!snap.exists) {
        await _shiftStateDoc.set({
          'activeShiftId': null,
          'status': 'none',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _snack('خطأ', 'الوردية غير موجودة');
        await loadShifts();
        return;
      }

      final data = snap.data() ?? {};
      final status = (data['status'] ?? '').toString();
      if (status != 'open') {
        await _shiftStateDoc.set({
          'activeShiftId': null,
          'status': 'none',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _snack('تنبيه', 'الوردية مغلقة مسبقاً');
        await loadShifts();
        return;
      }

      final auth = Get.find<AuthController>();
      final actor = auth.actorInfo;

      final openingCash = _toDouble(data['openingCash']);
      final cashTotal = _toDouble(data['cashTotal']);
      final expectedDrawerCash = openingCash + cashTotal;
      final drawerDiff = closingCash - expectedDrawerCash;

      final existingNotes = data['notes']?.toString();
      final newNotes = (notes?.trim().isEmpty ?? true) ? existingNotes : notes!.trim();

      final batch = _firestore.batch();

      batch.update(ref, {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': actor,

        'closingCash': closingCash,
        'expectedDrawerCash': expectedDrawerCash,
        'drawerDiff': drawerDiff,

        'notes': newNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ تصفير state
      batch.set(_shiftStateDoc, {
        'activeShiftId': null,
        'status': 'none',
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': actor,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      await loadShifts();

      if (drawerDiff.abs() < 0.0001) {
        _snack('تم', 'تم إغلاق الوردية (الكاش مطابق ✅)');
      } else if (drawerDiff > 0) {
        _snack('تنبيه', 'زيادة في الدرج: ${drawerDiff.toStringAsFixed(2)} د.ل');
      } else {
        _snack('تنبيه', 'عجز في الدرج: ${drawerDiff.abs().toStringAsFixed(2)} د.ل');
      }
    } catch (e, st) {
      debugPrint('❌ closeShift: $e\n$st');
      _snack('خطأ', 'فشل إغلاق الوردية');
    } finally {
      isMutating.value = false;
    }
  }

  // -----------------------
  // Guards
  // -----------------------
  void ensureActiveShiftOrThrow() {
    final s = activeShift.value;
    if (s == null || !s.isOpen) {
      throw Exception('لا توجد وردية نشطة');
    }
  }

  // -----------------------
  // Sales → update shift totals (NO TRANSACTION)
  // -----------------------
  Future<void> registerSaleOnShift({
    required double total,
    required PaymentMethod method,
    required bool isRefund,
  }) async {
    await _ensureShiftStateExists();

    final state = (await _shiftStateDoc.get()).data() ?? {};
    final activeId = (state['activeShiftId'] ?? '').toString();
    if (activeId.isEmpty) return;

    final ref = _shiftsCol.doc(activeId);
    final incTotal = isRefund ? -total : total;

    final updates = <String, dynamic>{
      'salesCount': FieldValue.increment(isRefund ? 0 : 1),
      'refundsCount': FieldValue.increment(isRefund ? 1 : 0),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    switch (method) {
      case PaymentMethod.cash:
        updates['cashTotal'] = FieldValue.increment(incTotal);
        break;
      case PaymentMethod.card:
        updates['cardTotal'] = FieldValue.increment(incTotal);
        break;
      case PaymentMethod.insurance:
      // ✅ التأمين: فواتير + مستحق
        updates['insuranceBilledTotal'] = FieldValue.increment(incTotal);
        updates['insurancePendingTotal'] = FieldValue.increment(incTotal);
        break;
    }

    try {
      await ref.update(updates);
      await _loadActiveShiftFromState();
    } catch (e, st) {
      debugPrint('❌ registerSaleOnShift: $e\n$st');
    }
  }

  // -----------------------
  // Collect insurance (NO TRANSACTION)
  // -----------------------
  Future<void> collectInsuranceOnShift({
    required double amount,
    required PaymentMethod method, // cash or card only
    String? note,
  }) async {
    if (amount <= 0) {
      _snack('تحقق', 'أدخل مبلغ صحيح');
      return;
    }
    if (method == PaymentMethod.insurance) {
      _snack('تحقق', 'تحصيل التأمين لازم يكون كاش أو بطاقة');
      return;
    }

    await _ensureShiftStateExists();

    final state = (await _shiftStateDoc.get()).data() ?? {};
    final activeId = (state['activeShiftId'] ?? '').toString();
    if (activeId.isEmpty) {
      _snack('تنبيه', 'لا توجد وردية نشطة');
      return;
    }

    final ref = _shiftsCol.doc(activeId);

    try {
      // ✅ قراءة pending مرة واحدة
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final pending = _toDouble(data['insurancePendingTotal']);
      final take = amount > pending ? pending : amount;

      if (take <= 0) {
        _snack('تنبيه', 'لا يوجد مستحقات تأمين للتحصيل');
        return;
      }

      final field = method == PaymentMethod.cash ? 'cashTotal' : 'cardTotal';

      // ✅ Update واحد بدون transaction
      await ref.update({
        field: FieldValue.increment(take),
        'insuranceCollectedTotal': FieldValue.increment(take),
        'insurancePendingTotal': FieldValue.increment(-take),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!(note?.trim().isEmpty ?? true)) 'notes': note!.trim(),
      });

      await _loadActiveShiftFromState();
      _snack('تم', 'تم تحصيل التأمين بنجاح');
    } catch (e, st) {
      debugPrint('❌ collectInsuranceOnShift: $e\n$st');
      _snack('خطأ', 'فشل تحصيل التأمين');
    }
  }
}
