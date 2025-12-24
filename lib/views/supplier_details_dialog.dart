// lib/views/suppliers/supplier_details_dialog.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../models/supplier_model.dart';

class SupplierDetailsDialog extends StatelessWidget {
  final Supplier supplier;
  const SupplierDetailsDialog({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return  ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 900),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Iconsax.buildings_2,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تفاصيل المورد - ${supplier.name}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Iconsax.close_circle,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Make ONLY the content scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // المعلومات الأساسية
                      _buildSection(
                        title: 'المعلومات الأساسية',
                        icon: Iconsax.information,
                        children: [
                          _buildDetailRow(
                            icon: Iconsax.user,
                            label: 'الشخص المسؤول',
                            value: supplier.contactPerson,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Iconsax.call,
                            label: 'رقم الهاتف',
                            value: supplier.phone,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Iconsax.location,
                            label: 'العنوان',
                            value: supplier.address,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // معلومات التعاقد
                      _buildSection(
                        title: 'معلومات التعاقد',
                        icon: Iconsax.document,
                        children: [
                          _buildDetailRow(
                            icon: Iconsax.calendar_1,
                            label: 'تاريخ بدء التعاقد',
                            value: DateFormat('yyyy-MM-dd').format(supplier.contractStartDate),
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Iconsax.calendar_tick,
                            label: 'تاريخ نهاية التعاقد',
                            value: supplier.contractEndDate != null
                                ? DateFormat('yyyy-MM-dd').format(supplier.contractEndDate!)
                                : 'غير محدد',
                            color: supplier.contractEndDate != null
                                ? Colors.blue.shade700
                                : Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          _buildStatusRow(
                            status: supplier.status,
                            color: _getStatusColor(supplier.status),
                          ),
                        ],
                      ),

                      // الأدوية الموردة
                      if (supplier.suppliedMedications.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'الأدوية الموردة',
                          icon: Iconsax.health,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: supplier.suppliedMedications
                                  .map((medication) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  medication,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                                  .toList(),
                            ),
                            if (supplier.suppliedMedications.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  '${supplier.suppliedMedications.length} دواء',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],

                      // الملاحظات
                      if (supplier.notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'ملاحظات',
                          icon: Iconsax.note_text,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                supplier.notes,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // المعلومات الإضافية
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'المعلومات الإضافية',
                        icon: Iconsax.calendar,
                        children: [
                          _buildDetailRow(
                            icon: Iconsax.calendar_add,
                            label: 'تاريخ الإنشاء',
                            value: DateFormat('yyyy-MM-dd HH:mm').format(supplier.createdAt),
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Iconsax.refresh,
                            label: 'آخر تحديث',
                            value: DateFormat('yyyy-MM-dd HH:mm').format(supplier.updatedAt),
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () => Get.back(),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.close_circle,
                                      color: Colors.grey.shade600,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'إغلاق',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () => Get.back(),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.tick_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تم',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  icon,
                  color: Colors.blue.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String status,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Iconsax.status,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الحالة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'فعال':
        return Colors.green;
      case 'معلق':
        return Colors.orange;
      case 'متوقف':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}