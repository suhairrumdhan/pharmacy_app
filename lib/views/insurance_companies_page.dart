// lib/views/insurance/insurance_companies_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../controllers/insurance_company_controller.dart';
import '../../models/insurance_company_model.dart';
import 'add_edit_insurance_dialog.dart';
import 'insurance_company_details_dialog.dart';

class InsuranceCompaniesPage extends StatelessWidget {
  final InsuranceCompanyController controller = Get.put(InsuranceCompanyController());

  InsuranceCompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(),
            const SizedBox(height: 20),
            _buildActionBar(),
            const SizedBox(height: 20),
            Expanded(child: _buildCompaniesTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Obx(() {
      final stats = controller.companyStats;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue.shade50, Colors.green.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            _buildStatItem(
              icon: Iconsax.building,
              value: '${stats['totalCompanies']}',
              label: 'إجمالي الشركات',
              color: Colors.blue,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Iconsax.tick_circle,
              value: '${stats['activeCompanies']}',
              label: 'شركات فعالة',
              color: Colors.green,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Iconsax.calendar_remove,
              value: '${stats['expiredContracts'] ?? 0}',
              label: 'عقود منتهية',
              color: Colors.orange,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Iconsax.calendar_tick,
              value: '${stats['expiringSoonContracts'] ?? 0}',
              label: 'تنتهي قريبًا',
              color: Colors.purple,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الإضافة
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF42a5f5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.dialog(
                  AddEditInsuranceDialog(),
                  barrierDismissible: false,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'إضافة شركة تأمين',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // حقل البحث
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.shade50,
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Iconsax.search_normal,
                    color: Colors.blue.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => controller.searchQuery.value = value,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن شركة تأمين...',
                        hintStyle: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // زر التحديث
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade100,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Iconsax.refresh,
                color: Colors.blue.shade700,
                size: 24,
              ),
              onPressed: controller.fetchInsuranceCompanies,
              tooltip: 'تحديث القائمة',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesTable() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final companies = controller.filteredCompanies;

      if (companies.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.building,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              Text(
                controller.searchQuery.isEmpty
                    ? 'لا يوجد شركات تأمين مسجلة'
                    : 'لا توجد نتائج للبحث',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                ),
              ),
              if (controller.searchQuery.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Iconsax.add),
                    label: const Text('إضافة أول شركة تأمين'),
                    onPressed: () => Get.dialog(
                      AddEditInsuranceDialog(),
                      barrierDismissible: false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        );
      }

      return _buildTable(companies);
    });
  }

  Widget _buildTable(List<InsuranceCompany> companies) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس الجدول
          _buildTableHeader(),
          // قائمة الشركات
          Expanded(child: _buildCompaniesList(companies)),
          // تذييل الجدول
          _buildTableFooter(companies.length),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'اسم الشركة',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'الكود',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
              textAlign: TextAlign.center, // إضافة هذه الخاصية لتوسيط النص

            ),
          ),
          Expanded(
            child: Text(
              'الشخص المسؤول',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
              textAlign: TextAlign.center, // إضافة هذه الخاصية لتوسيط النص

            ),
          ),
          Expanded(
            child: Text(
              'نسبة الخصم',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
              textAlign: TextAlign.center, // إضافة هذه الخاصية لتوسيط النص

            ),
          ),
          Expanded(
            child: Text(
              'الحالة',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
              textAlign: TextAlign.center, // إضافة هذه الخاصية لتوسيط النص

            ),
          ),
          Expanded(
            child: Text(
              'الإجراءات',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
              textAlign: TextAlign.center, // إضافة هذه الخاصية لتوسيط النص

            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesList(List<InsuranceCompany> companies) {
    return ListView.separated(
      itemCount: companies.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.blue.shade50,
      ),
      itemBuilder: (context, index) {
        final company = companies[index];
        return _buildCompanyRow(company, index);
      },
    );
  }

  Widget _buildCompanyRow(InsuranceCompany company, int index) {
    final isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.blue.shade50,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [

            // اسم الشركة
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.building,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          company.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // الكود
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Text(
                  company.code,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 15),

            // الشخص المسؤول
            Expanded(
              child: Text(
                company.contactPerson,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center, // إضافة هذه الخاصية لتوسيط النص
              ),
            ),
            const SizedBox(width: 15),

            // نسبة الخصم
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade50,
                      Colors.green.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 1),
                ),
                child: Text(
                  company.formattedDiscount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // الحالة
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(company.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(company.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getStatusColor(company.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      company.status,
                      style: TextStyle(
                        color: _getStatusColor(company.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),

            // الإجراءات
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildActionButton(
                    icon: Iconsax.eye,
                    color: Colors.blue,
                    tooltip: 'عرض التفاصيل',
                    onPressed: () => _showCompanyDetails(company),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Iconsax.edit_2,
                    color: Colors.orange,
                    tooltip: 'تعديل',
                    onPressed: () => Get.dialog(
                      AddEditInsuranceDialog(company: company),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Iconsax.trash,
                    color: Colors.red,
                    tooltip: 'حذف',
                    onPressed: () => _showDeleteDialog(company),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),

          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildTableFooter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.blue.shade100, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'إجمالي الشركات: $count',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
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

  void _showCompanyDetails(InsuranceCompany company) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: InsuranceCompanyDetailsDialog(company: company),
        ),
      ),
    );
  }

  void _showDeleteDialog(InsuranceCompany company) {
    Get.dialog(
      AlertDialog(
        title: Text('حذف ${company.name}'),
        content: const Text('هل أنت متأكد من حذف هذه الشركة؟'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteInsuranceCompany(company.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}