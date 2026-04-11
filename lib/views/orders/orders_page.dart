import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/pharmacy_orders_controller.dart';
import '../../models/pharmacy_order_model.dart';
import '../chat/chat_page.dart';
import '../home_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late PharmacyOrdersController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PharmacyOrdersController(), permanent: true);
    final pharmacyId = Get.find<AuthController>().pharmacyId;
    controller.startListening(pharmacyId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildHeader(controller),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: _buildOrdersList(controller),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 14,
                  child: _buildOrderDetails(controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderChat(
      PharmacyOrdersController controller,
      PharmacyOrderModel order,
      ) async {
    try {
      final pharmacyId = controller.pharmacyId.value;
      final userId = order.userId;
      final chatId = 'order_${order.id}';

      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId);

      final doc = await chatRef.get();

      if (!doc.exists) {
        await chatRef.set({
          "chatId": chatId,
          "orderId": order.id,
          "pharmacyId": pharmacyId,
          "userId": userId,
          "userName": order.userName,

          // معلومات المستفيد
          "beneficiaryId": order.beneficiaryId,
          "beneficiaryName": order.beneficiaryName,
          "beneficiaryType": order.beneficiaryType,
          "relationLabel": order.relationLabel,

          // snapshot صحي للطلب
          "healthSnapshot": {
            "name": order.beneficiaryName,
            "gender": order.gender,
            "age": order.age,
            "bloodType": order.bloodType,
            "allergies": order.allergies,
            "healthConditions": order.healthConditions,
            "currentMedications": order.currentMedications,
            "hasHealthData": order.hasHealthData,
          },

          "lastMessage": "",
          "lastMessageType": "text",
          "lastMessageTime": FieldValue.serverTimestamp(),
          "pharmacyUnreadCount": 0,
          "userUnreadCount": 0,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      final navController = Get.find<NavigationController>();
      final chatController = Get.find<ChatController>();

      navController.goToPage(9);
      chatController.loadMessages(chatId);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر فتح المحادثة: $e');
    }
  }

  Widget _buildHeader(PharmacyOrdersController controller) {
    final statuses = [
      'all',
      'pending',
      'reviewing',
      'confirmed',
      'partiallyConfirmed',
      'ready',
      'completed',
      'rejected',
      'cancelled',
    ];

    return Obx(
          () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.white,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: statuses.map((status) {
            final isSelected = controller.selectedStatus.value == status;
            final count = controller.getCountForStatus(status);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => controller.changeStatusFilter(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _statusColor(status).withOpacity(.12) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _statusColor(status) : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: isSelected ? _statusColor(status) : Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? _statusColor(status) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList(PharmacyOrdersController controller) {
    return Obx(() {
      final orders = controller.currentOrders;

      if (controller.isLoading.value) {
        return _buildPanel(
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildPanel(
          child: Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      if (orders.isEmpty) {
        return _buildPanel(
          child: const Center(
            child: Text(
              'لا توجد طلبات في هذا القسم',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      return _buildPanel(
        child: ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];

            return Obx(() {
              final isSelected = controller.selectedOrder.value?.id == order.id;

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => controller.selectOrder(order),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _statusColor(order.status).withOpacity(.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? _statusColor(order.status)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.035),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.beneficiaryName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _statusChip(order.status, order.statusLabel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'بواسطة: ${order.userName}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (order.isFamily &&
                          (order.relationLabel?.trim().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        Text(
                          'صلة القرابة: ${order.relationLabel}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniInfoChip(
                            Icons.medication_outlined,
                            '${order.medicinesCount} أدوية',
                          ),
                          if (order.hasInsurance)
                            _miniInfoChip(
                              Icons.shield_outlined,
                              order.primaryInsurance,
                            ),
                          if (order.totalPrice != null)
                            _miniInfoChip(
                              Icons.payments_outlined,
                              '${order.totalPrice!.toStringAsFixed(1)} د.ل',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      );
    });
  }

  Widget _buildOrderDetails(PharmacyOrdersController controller) {
    return Obx(() {
      final order = controller.selectedOrder.value;

      if (order == null) {
        return _buildPanel(
          child: const Center(
            child: Text(
              'اختر طلبًا من القائمة لعرض التفاصيل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      return _buildPanel(
          child: Padding(

            padding: const EdgeInsets.all(18),
            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.beneficiaryName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _statusChip(order.status, order.statusLabel),
                  ],
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _detailCard('المستخدم', order.userName, Icons.person_outline),
                    _detailCard('نوع المستفيد', order.isFamily ? 'فرد من العائلة' : 'صاحب الحساب', Icons.groups_2_outlined),
                    if (order.isFamily)
                      _detailCard('صلة القرابة', order.relationLabel?.isNotEmpty == true ? order.relationLabel! : '-', Icons.family_restroom_outlined),
                    _detailCard('مصدر الطلب', order.requestSource == 'prescription' ? 'روشتة' : 'إدخال يدوي', Icons.receipt_long_outlined),
                    _detailCard('عدد الأدوية', '${order.medicinesCount}', Icons.medication_outlined),
                    if (order.hasInsurance)
                      _detailCard('التأمين', order.primaryInsurance, Icons.shield_outlined),
                  ],
                ),

                const SizedBox(height: 18),
                const Text(
                  'الأدوية المطلوبة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: order.medicines.map((m) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue.withOpacity(.08),
                              child: const Icon(Icons.medication, size: 18, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (m.strength?.isNotEmpty == true) m.strength,
                                      if (m.dosageForm?.isNotEmpty == true) m.dosageForm,
                                      'الكمية: ${m.quantity}',
                                    ].whereType<String>().join(' • '),
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            if (m.price != null)
                              Text(
                                '${m.price!.toStringAsFixed(1)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (order.userNote?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _noteBox('ملاحظة المستخدم', order.userNote!),
                ],

                if (order.pharmacyNote?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _noteBox('ملاحظة الصيدلية', order.pharmacyNote!),
                ],

                const Spacer(),
                _buildActionSection(controller, order),
              ],
            ),
          ),

      );
    });
  }

  Widget _buildActionSection(
      PharmacyOrdersController controller,
      PharmacyOrderModel order,
      ) {
    if (order.status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(.18)),
        ),
        child: const Text(
          'هذا الطلب ملغي، لذلك لا توجد إجراءات إضافية عليه.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    if (order.status == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(.18)),
        ),
        child: const Text(
          'تم تسليم هذا الطلب بالفعل.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    if (order.status == 'rejected') {
      return Row(
        children: [
          Expanded(
            child: _primaryActionButton(
              label: 'إعادة للمراجعة',
              color: Colors.blue,
              onPressed: () {
                controller.markAsReviewing(
                  orderId: order.id,
                  changedById: controller.pharmacyId.value,
                );
              },
            ),
          ),
        ],
      );
    }

    if (order.status == 'pending') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _primaryActionButton(
            label: 'بدء المراجعة',
            color: Colors.blue,
            onPressed: () {
              controller.markAsReviewing(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
          _primaryActionButton(
            label: 'إلغاء الطلب',
            color: Colors.red,
            onPressed: () {
              controller.markAsCancelled(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
        ],
      );
    }

    if (order.status == 'reviewing') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _primaryActionButton(
            label: 'تأكيد كامل',
            color: Colors.teal,
            onPressed: () {
              controller.markAsConfirmed(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
          _primaryActionButton(
            label: 'تأكيد جزئي',
            color: Colors.orange,
            onPressed: () {
              controller.markAsPartiallyConfirmed(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
          _primaryActionButton(
            label: 'رفض الطلب',
            color: Colors.red,
            onPressed: () {
              controller.markAsRejected(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
          _primaryActionButton(
            label: 'مراسلة المستخدم',
            color: Colors.indigo,
            onPressed: () => _openOrderChat(controller, order),
          ),
        ],
      );
    }

    if (order.status == 'confirmed' || order.status == 'partiallyConfirmed') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _primaryActionButton(
            label: 'تحديد كجاهز',
            color: Colors.green,
            onPressed: () {
              controller.markAsReady(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
          _primaryActionButton(
            label: 'إلغاء الطلب',
            color: Colors.red,
            onPressed: () {
              controller.markAsCancelled(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
        ],
      );
    }

    if (order.status == 'ready') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _primaryActionButton(
            label: 'تم التسليم',
            color: Colors.green,
            onPressed: () {
              controller.markAsCompleted(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
          _primaryActionButton(
            label: 'إلغاء الطلب',
            color: Colors.red,
            onPressed: () {
              controller.markAsCancelled(
                orderId: order.id,
                changedById: controller.pharmacyId.value,
              );
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
      ),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(22),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(.045),
      //       blurRadius: 16,
      //       offset: const Offset(0, 8),
      //     ),
      //   ],
      // ),
      child: child,
    );
  }

  Widget _statusChip(String status, String label) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _miniInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(String title, String value, IconData icon) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.withOpacity(.08),
            child: Icon(icon, size: 18, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteBox(String title, String note) {
    return Container(

      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: TextStyle(color: Colors.grey.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _primaryActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return 'الكل';
      case 'pending':
        return 'معلقة';
      case 'reviewing':
        return 'قيد المراجعة';
      case 'confirmed':
        return 'تم التأكيد';
      case 'partiallyConfirmed':
        return 'متوفر جزئيًا';
      case 'ready':
        return 'جاهز';
      case 'completed':
        return 'تم التسليم';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'all':
        return Colors.indigo;
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'confirmed':
        return Colors.teal;
      case 'partiallyConfirmed':
        return Colors.deepOrange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'rejected':
        return Colors.redAccent;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }
}