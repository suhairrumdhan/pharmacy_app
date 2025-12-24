// lib/views/insurance/insurance_company_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../models/insurance_company_model.dart';

class InsuranceCompanyDetailsDialog extends StatelessWidget {
  final InsuranceCompany company;

  const InsuranceCompanyDetailsDialog({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // الهيدر
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF42a5f5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.building,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // المحتوى
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // البطاقة الرئيسية
                    _buildMainCard(),
                    const SizedBox(height: 24),

                    // معلومات الاتصال
                    _buildContactInfoCard(),
                    const SizedBox(height: 24),

                    // معلومات الخصم
                    _buildDiscountCard(),
                    const SizedBox(height: 24),

                    // الملاحظات
                    if (company.notes.isNotEmpty) ...[
                      _buildNotesCard(),
                      const SizedBox(height: 24),
                    ],

                    // تاريخ الإنشاء والتحديث
                    _buildDatesCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // الحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حالة الشركة',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(company.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(company.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(company.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      company.status,
                      style: TextStyle(
                        color: _getStatusColor(company.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // العنوان
          if (company.address.isNotEmpty) ...[
            _buildInfoRow(
              icon: Iconsax.location,
              title: 'العنوان',
              value: company.address,
            ),
            const SizedBox(height: 16),
          ],

          // تاريخ الإنشاء
          _buildInfoRow(
            icon: Iconsax.calendar_add,
            title: 'تاريخ الإنشاء',
            value: _formatDate(company.createdAt),
          ),

          // تاريخ التحديث
          if (company.updatedAt != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Iconsax.calendar_edit,
              title: 'آخر تحديث',
              value: _formatDate(company.updatedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.call_calling,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات الاتصال',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الهاتف
          _buildContactRow(
            icon: Iconsax.call,
            value: company.phone,
          ),
          const SizedBox(height: 12),

          // الشخص المسؤول
          if (company.contactPerson.isNotEmpty) ...[
            _buildContactRow(
              icon: Iconsax.user,
              value: company.contactPerson,
            ),
            const SizedBox(height: 12),
          ],

        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.percentage_circle,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات الخصم',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Center(
            child: Column(
              children: [
                Text(
                  'نسبة الخصم',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Text(
                    company.formattedDiscount,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'يتم تطبيق هذه النسبة على جميع الأدوية المشمولة',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.purple.shade50, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.note_text,
                color: Colors.purple.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ملاحظات',
                style: TextStyle(
                  color: Colors.purple.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              company.notes,
              style: TextStyle(
                color: Colors.purple.shade800,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.calendar_add,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تاريخ الإنشاء',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(company.createdAt),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          if (company.updatedAt != null) ...[
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.calendar_edit,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'آخر تحديث',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(company.updatedAt!),
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade600,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}