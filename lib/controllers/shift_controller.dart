import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/sales_model.dart';
import '../models/shift_model.dart';
import '../services/audit_log_service.dart';

class ShiftController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<Shift> activeShift = Rxn<Shift>();
  final RxList<Shift> shifts = <Shift>[].obs;

  final isLoading = false.obs;
  final isMutating = false.obs;

  // ===================== Helpers =====================
  AuthController get _auth => Get.find<AuthController>();
  final AuditLogService _auditLogService = AuditLogService();

  Map<String, dynamic> get _actor =>
      Map<String, dynamic>.from(_auth.actorInfo);

  String get pharmacyId => _auth.pharmacyId;

  String get actorId => (_auth.actorInfo['id'] ?? '').toString();
  String get actorType => (_auth.actorInfo['type'] ?? '').toString(); // 'owner' | 'employee'

  String get actorKey => '$actorType:$actorId';

  bool get isOwner => actorType == 'owner';

  // ✅ Permissions (حسب تسمية الصلاحيات اللي تبيها)
  bool get canViewShift => _auth.can('shifts.history.view') || isOwner;        // يشوف سجل وردياته
  bool get canViewAll => _auth.can('shifts.view_all') || isOwner;      // يشوف الكل

  bool get canOpenShift => _auth.can('shifts.open') || isOwner;
  bool get canCloseShift => _auth.can('shifts.close') || isOwner;

  bool get canCloseAny => _auth.can('shifts.close_any') || isOwner;


  Future<void> _logOpenShift(Shift shift, double openingCash) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: pharmacyId,
        action: AuditActions.openShift,
        module: AuditModules.shifts,
        targetType: AuditTargetTypes.shift,
        targetId: shift.id,
        targetName: shift.openedByName,
        performedBy: _actor,
        details: {
          'note': 'تم فتح وردية',
          'newValues': {
            'openingCash': openingCash,
            'openedBy': shift.openedByName,
          },
        },
        entityPath: 'pharmacies/$pharmacyId/shifts/${shift.id}',
      );
    } catch (_) {}
  }

  Future<void> _logCloseShift({
    required Shift shift,
    required double closingCash,
  }) async {
    try {
      await _auditLogService.logSuccess(
        pharmacyId: pharmacyId,
        action: AuditActions.closeShift,
        module: AuditModules.shifts,
        targetType: AuditTargetTypes.shift,
        targetId: shift.id,
        targetName: shift.openedByName,
        performedBy: _actor,
        details: {
          'note': 'تم إغلاق وردية',
          'oldValues': {
            'openingCash': shift.openingCash,
            'cashTotal': shift.cashTotal,
          },
          'newValues': {
            'closingCash': closingCash,
            'expectedDrawerCash': shift.expectedDrawerCash,
            'drawerDiff': shift.drawerDiff,
          },
        },
        entityPath: 'pharmacies/$pharmacyId/shifts/${shift.id}',
      );
    } catch (_) {}
  }

  CollectionReference<Map<String, dynamic>> get _shiftsCol {
    if (pharmacyId.isEmpty) throw Exception('pharmacyId فارغ');
    return _firestore.collection('pharmacies').doc(pharmacyId).collection('shifts');
  }

  DocumentReference<Map<String, dynamic>> _shiftStateDocFor(String aKey) {
    if (pharmacyId.isEmpty) throw Exception('pharmacyId فارغ');
    return _firestore.collection('pharmacies').doc(pharmacyId).collection('shift_states').doc(aKey);
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

  Future<void> _ensureStateExists(String aKey) async {
    final doc = _shiftStateDocFor(aKey);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'actorKey': aKey,
        'activeShiftId': null,
        'status': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ===================== Load =====================
  Future<void> loadShifts({int limit = 50}) async {
    if (pharmacyId.isEmpty) return;

    if (!canViewShift) {
      shifts.clear();
      activeShift.value = null;
      return;
    }

    try {
      isLoading.value = true;

      await _ensureStateExists(actorKey);
      await _loadMyActiveShiftFromState();

      Query<Map<String, dynamic>> q =
      _shiftsCol.orderBy('openedAt', descending: true).limit(limit);

      // ✅ الافتراضي: يشوف شفتاته فقط
      if (!canViewAll) {
        q = q.where('openedByKey', isEqualTo: actorKey);
      }

      final qs = await q.get();
      shifts.assignAll(qs.docs.map((d) => Shift.fromDoc(d)).toList());
    } catch (e, st) {
      debugPrint('❌ loadShifts: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMyActiveShiftFromState() async {
    final stateDoc = _shiftStateDocFor(actorKey);
    final stateSnap = await stateDoc.get();
    final state = stateSnap.data() ?? {};
    final activeId = (state['activeShiftId'] ?? '').toString();

    if (activeId.isEmpty) {
      activeShift.value = null;
      return;
    }

    final shiftSnap = await _shiftsCol.doc(activeId).get();
    if (!shiftSnap.exists) {
      await stateDoc.set({
        'activeShiftId': null,
        'status': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      activeShift.value = null;
      return;
    }

    activeShift.value = Shift.fromDoc(shiftSnap);
  }

  // ===================== Details (مع حماية) =====================
  Future<Shift?> getShiftDetailsById(String shiftId) async {
    if (pharmacyId.isEmpty) return null;

    if (!canViewShift) {
      return null;
    }

    try {
      final doc = await _shiftsCol.doc(shiftId).get();
      if (!doc.exists) return null;

      final shift = Shift.fromDoc(doc);

      // ✅ لو ما عنده show.shifts.all ممنوع يشوف غيره
      if (!canViewAll && shift.openedByKey.isNotEmpty && shift.openedByKey != actorKey) {
        return null;
      }

      return shift;
    } catch (e, st) {
      debugPrint('❌ getShiftDetailsById: $e\n$st');
      return null;
    }
  }

  // ===================== Open Shift (my) =====================
  Future<void> openShift({required double openingCash, String? notes}) async {
    if (pharmacyId.isEmpty) {
      _snack('خطأ', 'لم يتم تحديد الصيدلية');
      return;
    }
    if (!canOpenShift) {
      _snack('غير مسموح', 'لا تملك صلاحية فتح وردية');
      return;
    }
    if (openingCash < 0) {
      _snack('تحقق', 'رصيد الافتتاح لا يمكن أن يكون سالب');
      return;
    }

    try {
      isMutating.value = true;

      await _ensureStateExists(actorKey);

      final stateDoc = _shiftStateDocFor(actorKey);
      final state = (await stateDoc.get()).data() ?? {};
      final existingActiveId = (state['activeShiftId'] ?? '').toString();

      if (existingActiveId.isNotEmpty) {
        _snack('غير مسموح', 'لديك وردية مفتوحة بالفعل');
        await _loadMyActiveShiftFromState();
        return;
      }

      final actor = _auth.actorInfo;
      final displayName = (actor['name'] ?? actor['username'] ?? actorType).toString();

      final shiftRef = _shiftsCol.doc();
      final batch = _firestore.batch();

      batch.set(shiftRef, {
        'pharmacyId': pharmacyId,
        'status': 'open',
        'openedAt': FieldValue.serverTimestamp(),
        'openedBy': actor,
        'openedByKey': actorKey,
        'openedById': actorId,
        'openedByType': actorType,
        'openedByName': displayName,
        'openingCash': openingCash,
        'cashTotal': 0.0,
        'cardTotal': 0.0,
        'insuranceBilledTotal': 0.0,
        'salesCount': 0,
        'refundsCount': 0,
        'closingCash': null,
        'expectedDrawerCash': null,
        'drawerDiff': null,
        'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(stateDoc, {
        'actorKey': actorKey,
        'activeShiftId': shiftRef.id,
        'status': 'open',
        'openedAt': FieldValue.serverTimestamp(),
        'openedBy': actor,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      final createdShift = Shift(
        id: shiftRef.id,
        pharmacyId: pharmacyId,
        status: ShiftStatus.open,
        openedByName: displayName,
        openingCash: openingCash,
      );

      await _logOpenShift(createdShift, openingCash);

      await loadShifts();
      _snack('تم', 'تم فتح وردية جديدة');
    } catch (e, st) {
      debugPrint('❌ openShift: $e\n$st');
      _snack('خطأ', 'فشل فتح الوردية');
    } finally {
      isMutating.value = false;
    }
  }

  // ===================== Close Shift (my) =====================
  Future<void> closeShift({required double closingCash, String? notes}) async {
    if (closingCash < 0) {
      _snack('تحقق', 'الكاش داخل الدرج لا يمكن أن يكون سالب');
      return;
    }
    if (!canCloseShift) {
      _snack('غير مسموح', 'لا تملك صلاحية إغلاق وردية');
      return;
    }

    try {
      isMutating.value = true;

      await _ensureStateExists(actorKey);

      final stateDoc = _shiftStateDocFor(actorKey);
      final state = (await stateDoc.get()).data() ?? {};
      final activeId = (state['activeShiftId'] ?? '').toString();

      if (activeId.isEmpty) {
        _snack('غير موجود', 'لا توجد وردية نشطة لإغلاقها');
        await _loadMyActiveShiftFromState();
        return;
      }

      await _closeShiftById(
        shiftId: activeId,
        stateDoc: stateDoc,
        closingCash: closingCash,
        notes: notes,
      );
    } catch (e, st) {
      debugPrint('❌ closeShift: $e\n$st');
      _snack('خطأ', 'فشل إغلاق الوردية');
    } finally {
      isMutating.value = false;
    }
  }

  // ✅ admin/owner/permission: close_any
  Future<void> closeShiftByActorKey({
    required String targetActorKey,
    required double closingCash,
    String? notes,
  }) async {
    if (!canCloseAny) {
      _snack('غير مسموح', 'لا تملك صلاحية إغلاق شفتات الآخرين');
      return;
    }
    if (closingCash < 0) {
      _snack('تحقق', 'الكاش داخل الدرج لا يمكن أن يكون سالب');
      return;
    }

    try {
      isMutating.value = true;

      await _ensureStateExists(targetActorKey);

      final stateDoc = _shiftStateDocFor(targetActorKey);
      final state = (await stateDoc.get()).data() ?? {};
      final activeId = (state['activeShiftId'] ?? '').toString();

      if (activeId.isEmpty) {
        _snack('غير موجود', 'لا توجد وردية نشطة لهذا المستخدم');
        return;
      }

      await _closeShiftById(
        shiftId: activeId,
        stateDoc: stateDoc,
        closingCash: closingCash,
        notes: notes,
      );

      await _auditLogService.logSuccess(
        pharmacyId: pharmacyId,
        action: AuditActions.closeShiftByAdmin,
        module: AuditModules.shifts,
        targetType: AuditTargetTypes.shift,
        targetId: activeId,
        targetName: targetActorKey,
        performedBy: _actor,
        details: {
          'note': 'تم إغلاق وردية بواسطة الإدارة',
          'newValues': {
            'closingCash': closingCash,
          },
        },
      );

    } finally {
      isMutating.value = false;
    }
  }

  Future<void> _closeShiftById({
    required String shiftId,
    required DocumentReference<Map<String, dynamic>> stateDoc,
    required double closingCash,
    String? notes,
  }) async {
    final ref = _shiftsCol.doc(shiftId);
    final snap = await ref.get();

    if (!snap.exists) {
      await stateDoc.set({
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
      await stateDoc.set({
        'activeShiftId': null,
        'status': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _snack('تنبيه', 'الوردية مغلقة مسبقاً');
      await loadShifts();
      return;
    }

    final actor = _auth.actorInfo;
    final openingCash = _toDouble(data['openingCash']);
    final cashTotal = _toDouble(data['cashTotal']);

    final expectedDrawerCash = openingCash + cashTotal;
    final drawerDiff = closingCash - expectedDrawerCash;

    final noteTrim = (notes ?? '').trim();
    if (drawerDiff.abs() >= 0.01 && noteTrim.isEmpty) {
      return;
    }

    final existingNotes = data['notes']?.toString();
    final newNotes = noteTrim.isEmpty ? existingNotes : noteTrim;

    final batch = _firestore.batch();

    batch.update(ref, {
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': actor,
      'closedByKey': actorKey,
      'closedById': actorId,
      'closedByType': actorType,
      'closedByName': (actor['name'] ?? actor['username'] ?? actorType).toString(),
      'closingCash': closingCash,
      'expectedDrawerCash': expectedDrawerCash,
      'drawerDiff': drawerDiff,
      'notes': newNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(stateDoc, {
      'activeShiftId': null,
      'status': 'none',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': actor,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final shift = Shift.fromDoc(snap);
    await batch.commit();

    await _logCloseShift(
      shift: shift,
      closingCash: closingCash,
    );
    await loadShifts();
  }

  // ===================== Guards =====================
  bool get hasOpenShift => activeShift.value != null && activeShift.value!.isOpen;

  String activeShiftIdOrThrow() {
    final s = activeShift.value;
    if (s == null || !s.isOpen) throw Exception('لا توجد وردية نشطة');
    return s.id;
  }

  void ensureActiveShiftOrThrow() => activeShiftIdOrThrow();

  // ===================== Update totals from Sale =====================
  Future<void> registerSaleOnShift({
    required double total,
    required PaymentMethod method,
    required bool isRefund,
  }) async {
    await _ensureStateExists(actorKey);

    final state = (await _shiftStateDocFor(actorKey).get()).data() ?? {};
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
        updates['insuranceBilledTotal'] = FieldValue.increment(incTotal);
        break;
    }

    try {
      await ref.update(updates);
      await _loadMyActiveShiftFromState();
    } catch (e, st) {
      debugPrint('❌ registerSaleOnShift: $e\n$st');
    }
  }
}