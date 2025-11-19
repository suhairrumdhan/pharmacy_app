import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';

class HealthRecordPanel extends StatelessWidget {
  final ChatController chatController = Get.find();

  HealthRecordPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (chatController.selectedChatId.value.isEmpty) {
        return _buildEmptyState();
      }

      return FutureBuilder<Map<String, dynamic>?>(
        future: _getUserHealthData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNoDataState();
          }

          final userData = snapshot.data!;
          return _buildHealthRecord(userData, context);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'اختر محادثة لعرض السجل الصحي',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_Colors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل السجل الصحي...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد سجل صحي',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم إضافة معلومات صحية بعد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserHealthData() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatController.selectedChatId.value)
          .get();

      if (!chatDoc.exists) return null;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final userId = chatData['userId'];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching user health data: $e');
      return null;
    }
  }

  Widget _buildHealthRecord(Map<String, dynamic> userData, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(userData),
          const SizedBox(height: 28),
          _buildSectionTitle('المعلومات الشخصية', Icons.person_outline),
          const SizedBox(height: 12),
          _buildPersonalInfo(userData, context),
          const SizedBox(height: 24),
          _buildSectionTitle('الحساسيات', Icons.warning_outlined),
          const SizedBox(height: 12),
          _buildListCard(userData['allergies'] ?? [], _Colors.allergy, context),
          const SizedBox(height: 24),
          _buildSectionTitle('الأمراض المزمنة', Icons.medical_services_outlined),
          const SizedBox(height: 12),
          _buildListCard(userData['healthConditions'] ?? [], _Colors.condition, context),
          const SizedBox(height: 24),
          _buildSectionTitle('الأدوية الحالية', Icons.medication_outlined),
          const SizedBox(height: 12),
          _buildListCard(userData['currentMedications'] ?? [], _Colors.medication, context),
          const SizedBox(height: 24),
          _buildSectionTitle('معلومات إضافية', Icons.info_outline),
          const SizedBox(height: 12),
          _buildAdditionalInfo(userData, context),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Colors.primary.withOpacity(0.1),
            _Colors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _Colors.primary.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: (userData['profileImageUrl'] != null || userData['photoUrl'] != null)
                  ? Image.network(
                userData['profileImageUrl'] ?? userData['photoUrl']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(),
              )
                  : _buildPlaceholderAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['name'] ?? 'مريض',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _Colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.bloodtype_outlined,
                      size: 16,
                      color: _Colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'فصيلة الدم: ${userData['bloodType'] ?? 'غير محدد'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (userData['dateOfBirth'] != null)
                  Row(
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(userData['dateOfBirth']),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _Colors.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: _Colors.primary,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _Colors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: _Colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _Colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(Map<String, dynamic> userData, BuildContext context) {
    return _buildInfoCard(
      children: [
        _buildCopyableInfoRow('الاسم الكامل', userData['name'] ?? 'غير محدد', Icons.person, context),
        _buildCopyableInfoRow('البريد الإلكتروني', userData['email'] ?? 'غير محدد', Icons.email_outlined, context),
        _buildCopyableInfoRow('رقم الهاتف', userData['phone'] ?? 'غير محدد', Icons.phone_outlined, context),
        _buildCopyableInfoRow('النوع', userData['gender'] ?? 'غير محدد', Icons.people_outlined, context),
        _buildCopyableInfoRow('فصيلة الدم', userData['bloodType'] ?? 'غير محدد', Icons.bloodtype_outlined, context),
        _buildCopyableInfoRow('تاريخ الميلاد', _formatDate(userData['dateOfBirth']), Icons.cake_outlined, context),
      ],
    );
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> userData, BuildContext context) {
    return _buildInfoCard(
      children: [
        _buildCopyableInfoRow(
          'حالة السجل الصحي',
          (userData['healthInfoCompleted'] ?? false) ? 'مكتمل' : 'غير مكتمل',
          (userData['healthInfoCompleted'] ?? false) ? Icons.check_circle_outlined : Icons.pending_outlined,
          context,
          valueColor: (userData['healthInfoCompleted'] ?? false) ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCopyableInfoRow(String label, String value, IconData icon, BuildContext context, {Color? valueColor}) {
    return GestureDetector(
      onTap: () {
        _copyToClipboard(value, label, context);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _Colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: _Colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: valueColor ?? Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.content_copy,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(List<dynamic> items, Color color, BuildContext context) {
    if (items.isEmpty) {
      return _buildInfoCard(
        children: [
          Center(
            child: Text(
              'لا توجد عناصر',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return _buildInfoCard(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                _copyToClipboard(item.toString(), "العنصر", context);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.3,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.content_copy,
                        size: 12,
                        color: color.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  Future<void> _copyToClipboard(String text, String fieldName, BuildContext context) async {
    if (text == 'غير محدد') return;

    await Clipboard.setData(ClipboardData(text: text));

    // Show snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $fieldName: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _Colors.primary,
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'غير محدد';
    }
  }
}

class _Colors {
  static const Color primary = Color(0xFF2E8B57); // Sea Green - Medical theme
  static const Color allergy = Color(0xFFFF6B6B); // Soft Red for allergies
  static const Color condition = Color(0xFF4ECDC4); // Teal for conditions
  static const Color medication = Color(0xFF45B7D1); // Blue for medications
}