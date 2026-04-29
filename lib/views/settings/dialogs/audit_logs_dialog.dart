import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/audit_log_model.dart';
import '../../../services/audit_log_service.dart';

class AuditLogsDialog extends StatelessWidget {
  AuditLogsDialog({super.key});

  final AuditLogService _auditLogService = AuditLogService();
  final AuthController _authController = Get.find<AuthController>();

  final RxString _searchQuery = ''.obs;

  String get pharmacyId => _authController.pharmacyId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1180,
          maxHeight: 900,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildLogsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: _buildLogsRow(
        isHeader: true,
        actionChild: _headerText('الإجراء'),
        performerChild: _headerText('المنفذ'),
        statusChild: _headerText('الحالة'),
        timeChild: _headerText('الوقت'),
      ),
    );
  }

  Widget _buildLogCard(AuditLogModel log) {
    final performerName =
    (log.performedBy['name'] ?? log.performedBy['username'] ?? 'غير معروف')
        .toString();

    final performerSubtitle =
    (log.performedBy['role'] ?? log.performedBy['roleId'] ?? log.sourceLabel)
        .toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue.shade50.withOpacity(0.42),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: _buildLogsRow(
        actionChild: _buildActionChip(log),
        performerChild: _buildPersonInfo(
          name: performerName,
          subtitle: performerSubtitle,
        ),
        statusChild: _buildStatusChip(log),
        timeChild: _buildTimeChip(log),
      ),
    );
  }

  Widget _buildLogsRow({
    required Widget actionChild,
    required Widget performerChild,
    required Widget statusChild,
    required Widget timeChild,
    bool isHeader = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 22,
          child: Align(
            alignment: Alignment.center,
            child: isHeader ? actionChild : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: actionChild,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 34,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: performerChild,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 16,
          child: Align(
            alignment: Alignment.center,
            child: isHeader ? statusChild : FittedBox(
              fit: BoxFit.scaleDown,
              child: statusChild,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 28,
          child: Align(
            alignment: Alignment.centerLeft,
            child: isHeader ? timeChild : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: timeChild,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.blue.shade100.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Iconsax.note_1,
              color: Colors.orange.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجل العمليات',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'عرض جميع العمليات المسجلة داخل النظام',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                color: Colors.red.shade400,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildSearchBox(),
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          icon: Iconsax.activity,
          label: 'Live Logs',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Iconsax.search_normal, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (value) => _searchQuery.value = value.trim(),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنفذ أو الهدف أو الإجراء أو الموديول...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.blue.shade300,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<AuditLogModel>>(
              stream: _auditLogService.watchLogs(pharmacyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ أثناء تحميل سجل العمليات',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];

                return Obx(() {
                  final filteredLogs = _applySearch(logs, _searchQuery.value);

                  if (filteredLogs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final log = filteredLogs[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showLogDetails(log),
                        child: _buildLogCard(log),
                      );
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _headerText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.blue.shade800,
      ),
    );
  }
  void _showLogDetails(AuditLogModel log) {
    final performerName =
    (log.performedBy['name'] ?? log.performedBy['username'] ?? 'غير معروف')
        .toString();

    final performerRole =
    (log.performedBy['role'] ?? log.performedBy['roleId'] ?? '')
        .toString();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
            maxHeight: 820,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100.withOpacity(0.75),
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.document_text,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تفاصيل العملية',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailsGrid(log),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'المنفذ',
                          icon: Iconsax.user,
                          child: Column(
                            children: [
                              _buildKeyValueRow('الاسم', performerName),
                              _buildKeyValueRow(
                                  'الدور', performerRole.isEmpty ? '-' : performerRole),
                              _buildKeyValueRow(
                                  'المعرف', log.performedBy['id']?.toString() ?? '-'),
                              _buildKeyValueRow('النوع',
                                  log.performedBy['type']?.toString() ?? '-'),
                              _buildKeyValueRow('اسم المستخدم',
                                  log.performedBy['username']?.toString() ?? '-'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'الهدف',
                          icon: Iconsax.tag_user,
                          child: Column(
                            children: [
                              _buildKeyValueRow('النوع', log.targetType),
                              _buildKeyValueRow('المعرف', log.targetId),
                              _buildKeyValueRow(
                                'الاسم',
                                log.hasTargetName ? log.targetName! : '-',
                              ),
                              _buildKeyValueRow(
                                'المسار',
                                log.hasEntityPath ? log.entityPath! : '-',
                                isMultiline: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'التفاصيل',
                          icon: Iconsax.note_text,
                          child: _buildDetailsMap(log.details),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
  Widget _buildDetailsGrid(AuditLogModel log) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMiniInfoCard('الإجراء', log.actionLabel, Iconsax.flash_1, Colors.orange),
        _buildMiniInfoCard('الموديول', log.moduleLabel, Iconsax.category, Colors.blue),
        _buildMiniInfoCard('الحالة', log.statusLabel, Iconsax.tick_circle, _statusMaterialColor(log.status)),
        _buildMiniInfoCard('المصدر', log.sourceLabel, Iconsax.monitor, Colors.indigo),
        _buildMiniInfoCard('الوقت', log.formattedTime.isEmpty ? '-' : log.formattedTime,
            Iconsax.calendar_1, Colors.green),
      ],
    );
  }

  Widget _buildMiniInfoCard(
      String title,
      String value,
      IconData icon,
      MaterialColor color,
      ) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
  Widget _buildDetailsMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return Text(
        'لا توجد تفاصيل إضافية',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;

        if (value is Map) {
          final nested = Map<String, dynamic>.from(value);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _beautifyKey(key),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 10),
                ...nested.entries.map(
                      (nestedEntry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            _beautifyKey(nestedEntry.key),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDynamicValue(nestedEntry.value),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  _beautifyKey(key),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDynamicValue(value),
                  style: TextStyle(
                    fontSize: 12.8,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _beautifyKey(String key) {
    switch (key) {
      case 'note':
        return 'ملاحظة';
      case 'newValues':
        return 'القيم الجديدة';
      case 'oldValues':
        return 'القيم السابقة';
      case 'changedFields':
        return 'الحقول المعدلة';
      case 'deletedSnapshot':
        return 'البيانات المحذوفة';
      default:
        return key;
    }
  }

  String _formatDynamicValue(dynamic value) {
    if (value == null) return '-';

    if (value is List) {
      if (value.isEmpty) return '[]';
      return value.map((e) => e.toString()).join('، ');
    }

    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    if (value is DateTime) {
      return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} '
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }

    if (value is bool) {
      return value ? 'نعم' : 'لا';
    }

    return value.toString();
  }
  Widget _buildKeyValueRow(
      String label,
      String value, {
        bool isMultiline = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(AuditLogModel log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.clock,
            size: 15,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            _formatCardTime(log.timestamp ?? log.createdAt),
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
  String _formatCardTime(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final date =
        '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$date  •  $time';
  }
  Widget _buildActionChip(AuditLogModel log) {
    final color = _statusMaterialColor(log.status);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.shade200),
        ),
        child: Text(
          log.actionLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color.shade800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusChip(AuditLogModel log) {
    final color = _statusMaterialColor(log.status);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade200),
        ),
        child: Text(
          log.statusLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonInfo({
    required String name,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,

      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Iconsax.user,
            color: Colors.blue.shade700,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.note_1,
            size: 46,
            color: Colors.blue.shade200,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد عمليات لعرضها',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ستظهر هنا العمليات المسجلة تلقائيًا',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  List<AuditLogModel> _applySearch(List<AuditLogModel> logs, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return logs;

    return logs.where((log) {
      final performerName =
      (log.performedBy['name'] ?? '').toString().toLowerCase();
      final performerUsername =
      (log.performedBy['username'] ?? '').toString().toLowerCase();
      final performerRole =
      (log.performedBy['role'] ?? log.performedBy['roleId'] ?? '')
          .toString()
          .toLowerCase();

      final targetName = (log.targetName ?? '').toLowerCase();
      final targetId = log.targetId.toLowerCase();
      final action = log.action.toLowerCase();
      final actionLabel = log.actionLabel.toLowerCase();
      final module = log.module.toLowerCase();
      final moduleLabel = log.moduleLabel.toLowerCase();
      final status = log.status.toLowerCase();
      final statusLabel = log.statusLabel.toLowerCase();
      final source = log.source.toLowerCase();
      final sourceLabel = log.sourceLabel.toLowerCase();

      return performerName.contains(q) ||
          performerUsername.contains(q) ||
          performerRole.contains(q) ||
          targetName.contains(q) ||
          targetId.contains(q) ||
          action.contains(q) ||
          actionLabel.contains(q) ||
          module.contains(q) ||
          moduleLabel.contains(q) ||
          status.contains(q) ||
          statusLabel.contains(q) ||
          source.contains(q) ||
          sourceLabel.contains(q);
    }).toList();
  }

  MaterialColor _statusMaterialColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}