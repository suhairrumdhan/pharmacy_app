import 'dart:async';
import '../services/pharmacy_order_notifications_service.dart';
import '../../controllers/settings_controller.dart';
import 'package:get/get.dart';
import '../services/pharmacy_order_notifications_service.dart';
import '../models/pharmacy_order_model.dart';
import '../services/pharmacy_orders_service.dart';

class PharmacyOrdersController extends GetxController {
  final PharmacyOrdersService _service = PharmacyOrdersService.instance;

  StreamSubscription? _ordersSubscription;

  final RxList<PharmacyOrderModel> allOrders = <PharmacyOrderModel>[].obs;

  final RxList<PharmacyOrderModel> pendingOrders = <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> reviewingOrders = <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> confirmedOrders = <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> partiallyConfirmedOrders =
      <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> rejectedOrders = <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> readyOrders = <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> completedOrders = <PharmacyOrderModel>[].obs;
  final RxList<PharmacyOrderModel> cancelledOrders = <PharmacyOrderModel>[].obs;

  final Rxn<PharmacyOrderModel> selectedOrder = Rxn<PharmacyOrderModel>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString pharmacyId = ''.obs;
  SettingsController get _settingsController => Get.find<SettingsController>();
  void startListening(String currentPharmacyId) {

    if (currentPharmacyId.trim().isEmpty) {
      errorMessage.value = 'معرف الصيدلية غير صالح';
      return;
    }

    pharmacyId.value = currentPharmacyId;
    isLoading.value = true;
    errorMessage.value = '';

    _ordersSubscription?.cancel();

    _ordersSubscription = _service.getOrdersStream(currentPharmacyId).listen(
          (snapshot) {
        for (final doc in snapshot.docs) {
          print('📦 order doc: ${doc.id}');
          print(doc.data());
        }

        final orders = snapshot.docs
            .map((doc) => PharmacyOrderModel.fromFirestore(doc.id, doc.data()))
            .toList();

        allOrders.assignAll(orders);
        _rebuildBuckets();
        isLoading.value = false;
      },
      onError: (error) {
        print('🔴 orders stream error = $error');
        errorMessage.value = 'فشل في تحميل الطلبات: $error';
        isLoading.value = false;
      },
    );
  }
  void _rebuildBuckets() {
    pendingOrders.assignAll(
      allOrders.where((o) => o.status == 'pending').toList(),
    );

    reviewingOrders.assignAll(
      allOrders.where((o) => o.status == 'reviewing').toList(),
    );

    confirmedOrders.assignAll(
      allOrders.where((o) => o.status == 'confirmed').toList(),
    );

    partiallyConfirmedOrders.assignAll(
      allOrders.where((o) => o.status == 'partiallyConfirmed').toList(),
    );

    rejectedOrders.assignAll(
      allOrders.where((o) => o.status == 'rejected').toList(),
    );

    readyOrders.assignAll(
      allOrders.where((o) => o.status == 'ready').toList(),
    );

    completedOrders.assignAll(
      allOrders.where((o) => o.status == 'completed').toList(),
    );

    cancelledOrders.assignAll(
      allOrders.where((o) => o.status == 'cancelled').toList(),
    );
  }

  List<PharmacyOrderModel> get currentOrders {
    switch (selectedStatus.value) {
      case 'all':
        return allOrders;
      case 'pending':
        return pendingOrders;
      case 'reviewing':
        return reviewingOrders;
      case 'confirmed':
        return confirmedOrders;
      case 'partiallyConfirmed':
        return partiallyConfirmedOrders;
      case 'rejected':
        return rejectedOrders;
      case 'ready':
        return readyOrders;
      case 'completed':
        return completedOrders;
      case 'cancelled':
        return cancelledOrders;
      default:
        return allOrders;
    }
  }

  int getCountForStatus(String status) {
    switch (status) {
      case 'all':
        return allOrders.length;
      case 'pending':
        return pendingOrders.length;
      case 'reviewing':
        return reviewingOrders.length;
      case 'confirmed':
        return confirmedOrders.length;
      case 'partiallyConfirmed':
        return partiallyConfirmedOrders.length;
      case 'rejected':
        return rejectedOrders.length;
      case 'ready':
        return readyOrders.length;
      case 'completed':
        return completedOrders.length;
      case 'cancelled':
        return cancelledOrders.length;
      default:
        return allOrders.length;
    }
  }

  void changeStatusFilter(String status) {
    selectedStatus.value = status;
  }

  void selectOrder(PharmacyOrderModel order) {
    selectedOrder.value = order;
    selectedOrder.refresh();

  }

  void clearSelectedOrder() {
    selectedOrder.value = null;
    selectedOrder.refresh();

  }


  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String changedById,
    required String changedByType,
    String? note,
  }) async {
    if (orderId.trim().isEmpty) {
      Get.snackbar('خطأ', 'معرف الطلب غير صالح');
      return;
    }

    try {
      final order = allOrders.firstWhereOrNull((o) => o.id == orderId);

      await _service.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
        statusLabel: _statusLabel(newStatus),
        changedById: changedById,
        changedByType: changedByType,
        note: note,
      );

      if (order != null && order.userId.trim().isNotEmpty) {
        final pharmacyName =
        _settingsController.currentSettings.name.trim().isNotEmpty
            ? _settingsController.currentSettings.name.trim()
            : 'الصيدلية';
      }

    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث حالة الطلب: $e');
    }
  }

  List<Map<String, dynamic>> _buildDeliveredMedicinesPayload(
      PharmacyOrderModel order,
      ) {
    return order.medicines.map((m) {
      final requestedName = m.requestedName.trim();
      final matchedName = (m.matchedMedicineName ?? m.name).trim();

      return {
        'requestedName': requestedName.isNotEmpty ? requestedName : matchedName,
        'medicineId': m.matchedMedicineId,
        'medicineName': matchedName.isNotEmpty ? matchedName : requestedName,
        'matchedMedicineName': matchedName.isNotEmpty ? matchedName : requestedName,
        'strength': m.strength,
        'dosage': m.strength,
        'dosageForm': m.dosageForm,
        'route': m.dosageForm,
        'quantity': m.quantity,
        'estimatedPrice': m.price,
        'availableAtSelection': m.available ?? true,
        'soldByPiece': m.soldByPiece,
        'unit': m.unit,
        'imageUrl': m.imageUrl,
        'source': 'pharmacy_completed_order',
      };
    }).toList();
  }

  Future<void> markAsReviewing({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'reviewing',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  Future<void> markAsConfirmed({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'confirmed',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  Future<void> markAsPartiallyConfirmed({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'partiallyConfirmed',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  Future<void> markAsRejected({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'rejected',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  Future<void> markAsReady({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'ready',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  Future<void> markAsCompleted({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'completed',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  Future<void> markAsCancelled({
    required String orderId,
    required String changedById,
    String? note,
  }) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'cancelled',
      changedById: changedById,
      changedByType: 'pharmacy',
      note: note,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'معلقة';
      case 'reviewing':
        return 'قيد المراجعة';
      case 'confirmed':
        return 'تم التأكيد';
      case 'partiallyConfirmed':
        return 'متوفر جزئيًا';
      case 'rejected':
        return 'مرفوض';
      case 'ready':
        return 'جاهز';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  @override
  void onClose() {
    _ordersSubscription?.cancel();
    super.onClose();
  }
}