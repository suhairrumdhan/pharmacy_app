import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/chat_controller.dart';

class HealthRecordPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final ChatController chatController = Get.find();

  HealthRecordPanel({
    super.key,
    this.onClose,
  });

  static const Color primary = Color(0xFF2563A9);
  static const Color softBg = Color(0xFFF7F9FC);
  static const Color borderColor = Color(0xFFE5EAF0);
  static const Color danger = Color(0xFFE5484D);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (chatController.selectedChatId.value.isEmpty) {
        return _emptyState(
          icon: Icons.health_and_safety_outlined,
          title: 'اختر محادثة',
          subtitle: 'سيظهر الملف الصحي للمستفيد هنا.',
        );
      }

      return FutureBuilder<Map<String, dynamic>?>(
        future: _getHealthSnapshot(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingState();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _emptyState(
              icon: Icons.info_outline,
              title: 'لا يوجد ملف صحي',
              subtitle: 'لا توجد بيانات صحية محفوظة مع هذا الطلب.',
            );
          }

          return _buildPanel(snapshot.data!);
        },
      );
    });
  }

  Future<Map<String, dynamic>?> _getHealthSnapshot() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatController.selectedChatId.value)
          .get();

      if (!chatDoc.exists) return null;

      final data = chatDoc.data();
      final snapshot = data?['healthSnapshot'];

      if (snapshot is Map) {
        return Map<String, dynamic>.from(snapshot);
      }

      return null;
    } catch (e) {
      debugPrint('Error loading health snapshot: $e');
      return null;
    }
  }

  Widget _buildPanel(Map<String, dynamic> data) {
    final selected = chatController.selectedConversation;
    final userImage = selected == null
        ? null
        : chatController.getUserProfileImage(selected.userId);

    final name = _clean(data['name'], fallback: selected?.userName ?? 'مريض');
    final gender = _clean(data['gender']);
    final age = data['age'] == null ? 'غير محدد' : '${data['age']} سنة';
    final bloodType = _clean(data['bloodType']);

    final allergies = _toList(data['allergies']);
    final conditions = _toList(data['healthConditions']);
    final medications = _toList(data['currentMedications']);

    final hasRiskData =
        allergies.isNotEmpty || conditions.isNotEmpty || medications.isNotEmpty;

    return Container(
      color: softBg,
      child: Column(
        children: [
          _topHeader(
            name: name,
            imageUrl: userImage,
            hasRiskData: hasRiskData,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryGrid(
                    gender: gender,
                    age: age,
                    bloodType: bloodType,
                  ),

                  const SizedBox(height: 14),

                  _importantNotice(allergies),

                  const SizedBox(height: 14),

                  _sectionCard(
                    title: 'الحساسيات',
                    icon: Icons.warning_amber_rounded,
                    color: danger,
                    items: allergies,
                    emptyText: 'لا توجد حساسيات مسجلة',
                    important: true,
                  ),

                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'الأمراض المزمنة',
                    icon: Icons.monitor_heart_outlined,
                    color: primary,
                    items: conditions,
                    emptyText: 'لا توجد أمراض مزمنة مسجلة',
                  ),

                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'الأدوية الحالية',
                    icon: Icons.medication_outlined,
                    color: primary,
                    items: medications,
                    emptyText: 'لا توجد أدوية حالية مسجلة',
                  ),

                  const SizedBox(height: 12),

                  _smallHint(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader({
    required String name,
    required String? imageUrl,
    required bool hasRiskData,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          _avatar(imageUrl, radius: 28),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الملف الصحي',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasRiskData
                        ? primary.withOpacity(.08)
                        : Colors.grey.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: hasRiskData
                          ? primary.withOpacity(.16)
                          : Colors.grey.withOpacity(.16),
                    ),
                  ),
                  child: Text(
                    hasRiskData ? 'بيانات صحية متوفرة' : 'بيانات محدودة',
                    style: TextStyle(
                      color: hasRiskData ? primary : textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'إخفاء الملف الصحي',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: textMuted,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? imageUrl, {required double radius}) {
    final cleanUrl = imageUrl?.trim();

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withOpacity(.09),
        border: Border.all(color: primary.withOpacity(.14)),
      ),
      child: ClipOval(
        child: cleanUrl != null && cleanUrl.isNotEmpty
            ? Image.network(
          cleanUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(radius),
        )
            : _avatarFallback(radius),
      ),
    );
  }

  Widget _avatarFallback(double radius) {
    return Icon(
      Icons.person_outline,
      color: primary,
      size: radius,
    );
  }

  Widget _summaryGrid({
    required String gender,
    required String age,
    required String bloodType,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                title: 'النوع',
                value: gender,
                icon: Icons.wc_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryTile(
                title: 'العمر',
                value: age,
                icon: Icons.cake_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _summaryTile(
          title: 'فصيلة الدم',
          value: bloodType,
          icon: Icons.bloodtype_outlined,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _importantNotice(List<String> allergies) {
    if (allergies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(.16)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 19),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'لا توجد حساسيات مسجلة في هذا الطلب.',
                style: TextStyle(
                  color: textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: danger.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, color: danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: تحقق من الحساسية قبل تأكيد أو صرف الدواء.',
              style: TextStyle(
                color: danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required String emptyText,
    bool important = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: important && items.isNotEmpty
              ? color.withOpacity(.22)
              : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${items.length}',
                style: TextStyle(
                  color: items.isEmpty ? textMuted : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: textMuted,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.14)),
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

  Widget _smallHint() {
    return Text(
      'ملاحظة: البيانات المعروضة مأخوذة من سجل الطلب وقت إنشاء المحادثة.',
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _loadingState() {
    return Container(
      color: softBg,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: softBg,
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _clean(dynamic value, {String fallback = 'غير محدد'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<String> _toList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}