import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pharmacy_notifications_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/pharmacy_orders_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../models/pharmacy_order_model.dart';
import '../home_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final PharmacyOrdersController controller;

  final RxBool showArchive = false.obs;

  static const int archiveAfterDays = 7;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PharmacyOrdersController(), permanent: true);
    final pharmacyId = Get.find<AuthController>().pharmacyId;
    controller.startListening(pharmacyId);
  }

  bool _isClosedStatus(String status) {
    return status == 'completed' ||
        status == 'cancelled' ||
        status == 'rejected';
  }

  bool _isArchivedOrder(PharmacyOrderModel order) {
    if (!_isClosedStatus(order.status)) return false;

    final date = order.updatedAt ?? order.completedAt ?? order.cancelledAt ?? order.createdAt;
    if (date == null) return false;

    return DateTime.now().difference(date).inDays >= archiveAfterDays;
  }

  List<PharmacyOrderModel> _visibleOrders(List<PharmacyOrderModel> orders) {
    if (showArchive.value) {
      return orders.where(_isArchivedOrder).toList();
    }

    return orders.where((o) => !_isArchivedOrder(o)).toList();
  }

  Map<String, List<PharmacyOrderModel>> _groupByDate(List<PharmacyOrderModel> orders) {
    final map = <String, List<PharmacyOrderModel>>{};

    for (final order in orders) {
      final date = order.createdAt ?? order.updatedAt ?? DateTime.now();
      final key = _dateGroupLabel(date);
      map.putIfAbsent(key, () => []);
      map[key]!.add(order);
    }

    return map;
  }

  String _dateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'اليوم';
    if (d == today.subtract(const Duration(days: 1))) return 'أمس';

    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '--';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.year}/${date.month}/${date.day} - $h:$m';
  }

  PharmacyOrderModel? _latestSelectedOrder() {
    final selected = controller.selectedOrder.value;
    if (selected == null) return null;

    return controller.allOrders.firstWhereOrNull((o) => o.id == selected.id) ?? selected;
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

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

      final doc = await chatRef.get();

      if (!doc.exists) {
        await chatRef.set({
          "chatId": chatId,
          "orderId": order.id,
          "pharmacyId": pharmacyId,
          "userId": userId,
          "userName": order.userName,
          "beneficiaryId": order.beneficiaryId,
          "beneficiaryName": order.beneficiaryName,
          "beneficiaryType": order.beneficiaryType,
          "relationLabel": order.relationLabel,
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

    return Obx(() {
      final archivedCount = controller.allOrders.where(_isArchivedOrder).length;

      return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'إدارة الطلبات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showArchive.value = !showArchive.value;
                    controller.clearSelectedOrder();
                  },
                  icon: Icon(showArchive.value ? Icons.inbox_outlined : Icons.archive_outlined),
                  label: Text(
                    showArchive.value
                        ? 'عرض الطلبات النشطة'
                        : 'الأرشيف ($archivedCount)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: statuses.map((status) {
                final isSelected = controller.selectedStatus.value == status;
                final count = controller.getCountForStatus(status);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    controller.changeStatusFilter(status);
                    controller.clearSelectedOrder();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _statusColor(status).withOpacity(.12)
                          : Colors.grey.shade50,
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
          ],
        ),
      );
    });
  }

  Widget _buildOrdersList(PharmacyOrdersController controller) {
    return Obx(() {
      final filtered = _visibleOrders(controller.currentOrders);
      final grouped = _groupByDate(filtered);

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

      if (filtered.isEmpty) {
        return _buildPanel(
          child: Center(
            child: Text(
              showArchive.value
                  ? 'لا توجد طلبات مؤرشفة'
                  : 'لا توجد طلبات في هذا القسم',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      final entries = grouped.entries.toList();

      return _buildPanel(
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: entries.length,
          itemBuilder: (context, groupIndex) {
            final entry = entries[groupIndex];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateHeader(entry.key),
                const SizedBox(height: 10),
                ...entry.value.map((order) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _orderCard(order),
                  );
                }),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _dateHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _orderCard(PharmacyOrderModel order) {
    return Obx(() {
      final isSelected = controller.selectedOrder.value?.id == order.id;

      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          controller.selectOrder(order);

          if (Get.isRegistered<PharmacyNotificationsController>()) {
            await Get.find<PharmacyNotificationsController>()
                .markOrderAsRead(order.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? _statusColor(order.status).withOpacity(.08) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _statusColor(order.status) : Colors.grey.shade200,
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
              const SizedBox(height: 4),
              Text(
                'تاريخ الطلب: ${_formatDateTime(order.createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (order.isFamily && (order.relationLabel?.trim().isNotEmpty ?? false)) ...[
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
                  _miniInfoChip(Icons.medication_outlined, '${order.medicinesCount} أدوية'),
                  if (order.hasInsurance)
                    _miniInfoChip(Icons.shield_outlined, order.primaryInsurance),
                  if (order.totalPrice != null)
                    _miniInfoChip(
                      Icons.payments_outlined,
                      '${order.totalPrice!.toStringAsFixed(1)} د.ل',
                    ),
                  if (_isArchivedOrder(order))
                    _miniInfoChip(Icons.archive_outlined, 'مؤرشف'),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOrderDetails(PharmacyOrdersController controller) {
    return Obx(() {
      final order = _latestSelectedOrder();

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
            children: [
              Expanded(
                child: SingleChildScrollView(
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

                      const SizedBox(height: 8),

                      Text(
                        'تاريخ الطلب: ${_formatDateTime(order.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _detailCard('المستخدم', order.userName, Icons.person_outline),
                          _detailCard(
                            'نوع المستفيد',
                            order.isFamily ? 'فرد من العائلة' : 'صاحب الحساب',
                            Icons.groups_2_outlined,
                          ),
                          if (order.isFamily)
                            _detailCard(
                              'صلة القرابة',
                              order.relationLabel?.isNotEmpty == true
                                  ? order.relationLabel!
                                  : '-',
                              Icons.family_restroom_outlined,
                            ),
                          _detailCard(
                            'مصدر الطلب',
                            order.requestSource == 'prescription' ? 'روشتة' : 'إدخال يدوي',
                            Icons.receipt_long_outlined,
                          ),
                          _detailCard(
                            'عدد الأدوية',
                            '${order.medicinesCount}',
                            Icons.medication_outlined,
                          ),
                          if (order.hasInsurance)
                            _detailCard(
                              'التأمين',
                              order.primaryInsurance,
                              Icons.shield_outlined,
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),


                      const Text(
                        'الأدوية المطلوبة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _medicinesBox(order),

                      const SizedBox(height: 18),
                      _buildOrderHealthProfile(order),




                      if (order.userNote?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        _noteBox('ملاحظة المستخدم', order.userNote!),
                      ],

                      if (order.pharmacyNote?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _noteBox('ملاحظة الصيدلية', order.pharmacyNote!),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _buildActionSection(controller, order),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOrderHealthProfile(PharmacyOrderModel order) {
    final hasAnyHealthData =
        order.hasHealthData ||
            (order.gender?.trim().isNotEmpty ?? false) ||
            order.age != null ||
            (order.bloodType?.trim().isNotEmpty ?? false) ||
            order.allergies.isNotEmpty ||
            order.healthConditions.isNotEmpty ||
            order.currentMedications.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasAnyHealthData
              ? Colors.green.withOpacity(.22)
              : Colors.grey.shade200,
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
              CircleAvatar(
                radius: 19,
                backgroundColor: Colors.green.withOpacity(.10),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'الملف الصحي للمستفيد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _healthStatusChip(hasAnyHealthData),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'بيانات المستفيد الصحية المرتبطة بهذا الطلب',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          if (!hasAnyHealthData)
            _emptyHealthBox()
          else ...[
            Column(
              children: [
                _healthInfoTile(
                  title: 'المستفيد',
                  value: order.beneficiaryName,
                  icon: Icons.person_outline,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 8),
                _healthInfoTile(
                  title: 'الجنس',
                  value: _cleanText(order.gender),
                  icon: Icons.people_outline,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _healthInfoTile(
                  title: 'العمر',
                  value: order.age == null ? 'غير محدد' : '${order.age} سنة',
                  icon: Icons.cake_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _healthInfoTile(
                  title: 'فصيلة الدم',
                  value: _cleanText(order.bloodType),
                  icon: Icons.bloodtype_outlined,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            _healthListSection(
              title: 'الحساسيات',
              items: order.allergies,
              icon: Icons.warning_amber_rounded,
              color: Colors.redAccent,
              emptyText: 'لا توجد حساسيات مسجلة',
            ),

            const SizedBox(height: 12),

            _healthListSection(
              title: 'الأمراض المزمنة',
              items: order.healthConditions,
              icon: Icons.monitor_heart_outlined,
              color: Colors.deepOrange,
              emptyText: 'لا توجد أمراض مزمنة مسجلة',
            ),

            const SizedBox(height: 12),

            _healthListSection(
              title: 'الأدوية الحالية',
              items: order.currentMedications,
              icon: Icons.medication_liquid_outlined,
              color: Colors.blue,
              emptyText: 'لا توجد أدوية حالية مسجلة',
            ),
          ],
        ],
      ),
    );
  }

  Widget _healthStatusChip(bool hasData) {
    final color = hasData ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasData ? Icons.check_circle_outline : Icons.info_outline,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            hasData ? 'متوفر' : 'غير مكتمل',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHealthBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'لا توجد بيانات صحية محفوظة لهذا المستفيد داخل الطلب.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthInfoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.10),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthListSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (items.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.20)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _cleanText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'غير محدد' : text;
  }

  Widget _medicinesBox(PharmacyOrderModel order) {
    return Container(
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
                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildActionSection(
      PharmacyOrdersController controller,
      PharmacyOrderModel order,
      ) {
    if (showArchive.value) {
      return const SizedBox.shrink();
    }

    if (order.status == 'cancelled') {
      return _closedMessage('هذا الطلب ملغي، لذلك لا توجد إجراءات إضافية عليه.', Colors.red);
    }

    if (order.status == 'completed') {
      return _closedMessage('تم تسليم هذا الطلب بالفعل.', Colors.green);
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
            label: 'إنشاء فاتورة وتجهيز الطلب',
            color: Colors.green,
            onPressed: () async {
              final salesController = Get.find<SalesController>();
              await salesController.createInvoiceFromOrder(order);

              final navController = Get.find<NavigationController>();
              navController.goToPage(2);

              Get.snackbar(
                'تم',
                'تم فتح الفاتورة في شاشة المبيعات، احفظها لإرسال إشعار الجاهزية',
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

  Widget _closedMessage(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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