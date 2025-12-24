// lib/views/suppliers/suppliers_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/supplier_controller.dart';
import '../../models/supplier_model.dart';
import 'add_edit_supplier_dialog.dart';
import 'supplier_details_dialog.dart';

class SuppliersPage extends StatelessWidget {
  final SupplierController controller = Get.put(SupplierController());

  SuppliersPage({super.key});

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

            // جدول الموردين
            Expanded(
              child: _buildSuppliersTable(),
            ),
          ],
        ),
      ),
    );
  }

// في SuppliersPage أضف زر ديباجنغ

  Widget _buildStatsCards() {
    return Obx(() {
      final stats = controller.supplierStats;
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
              icon: Icons.group,
              value: '${stats['totalSuppliers']}',
              label: 'إجمالي الموردين',
              color: Colors.blue,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Icons.check_circle,
              value: '${stats['activeSuppliers']}',
              label: 'موردين فعالين',
              color: Colors.green,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Icons.pause_circle,
              value: '${stats['suspendedSuppliers'] ?? 0}',
              label: 'موردين معلقين',
              color: Colors.orange,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              icon: Icons.medical_services,
              value: '${stats['totalMedications']}',
              label: 'أدوية متاحة',
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
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الإضافة مع تدرج لوني
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A73E8),
                  Color(0xFF42a5f5),
                ],
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
                  AddEditSupplierDialog(),
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
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'إضافة مورد جديد',
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

          // حقل البحث المحسّن
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
                    Icons.search,
                    color: Colors.blue.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => controller.searchQuery.value = value,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن مورد بالاسم، الهاتف، أو المسؤول...',
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
                      cursorColor: Colors.blue.shade600,
                    ),
                  ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // زر التحديث المحسّن
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
                Icons.refresh_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
              onPressed: controller.fetchSuppliers,
              splashRadius: 24,
              tooltip: 'تحديث القائمة',
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSuppliersTable() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      }

      final suppliers = controller.filteredSuppliers;

      if (suppliers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              Text(
                controller.searchQuery.isEmpty
                    ? 'لا يوجد موردين مسجلين'
                    : 'لا توجد نتائج للبحث',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (controller.searchQuery.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة أول مورد'),
                    onPressed: () => Get.dialog(
                      AddEditSupplierDialog(),
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

      return _buildTable(suppliers);
    });
  }

  Widget _buildTable(List<Supplier> suppliers) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FBFF),
            Color(0xFFEFF6FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس الجدول
          _buildTableHeader(),
          // قائمة الموردين
          Expanded(
            child: _buildSuppliersList(suppliers),
          ),
          // تذييل الجدول
          _buildTableFooter(suppliers.length),
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
          bottom: BorderSide(
            color: Colors.blue.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'اسم المورد',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
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
            ),
          ),
          Expanded(
            child: Text(
              'الهاتف',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'عدد الأدوية',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersList(List<Supplier> suppliers) {
    return ListView.separated(
      itemCount: suppliers.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.blue.shade50,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return _buildSupplierRow(supplier, index);
      },
    );
  }

  Widget _buildSupplierRow(Supplier supplier, int index) {
    final isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.blue.shade50,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // اسم المورد
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
                      Icons.business,
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
                          supplier.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // الشخص المسؤول
            Expanded(
              child: Text(
                supplier.contactPerson,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
            ),

            // الهاتف
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 14,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    supplier.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            // عدد الأدوية
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: supplier.suppliedMedications.isEmpty
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: supplier.suppliedMedications.isEmpty
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${supplier.suppliedMedications.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: supplier.suppliedMedications.isEmpty
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // الحالة
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(supplier.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(supplier.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(supplier.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      supplier.status,
                      style: TextStyle(
                        color: _getStatusColor(supplier.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // الإجراءات
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // زر العرض
                  _buildActionButton(
                    icon: Icons.visibility_outlined,
                    color: Colors.blue,
                    tooltip: 'عرض التفاصيل',
                    onPressed: () => _showSupplierDetails(supplier),
                  ),
                  const SizedBox(width: 8),

                  // زر التعديل
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    color: Colors.orange,
                    tooltip: 'تعديل',
                    onPressed: () => Get.dialog(
                      AddEditSupplierDialog(supplier: supplier),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // زر الحذف
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    tooltip: 'حذف',
                    onPressed: () => _showDeleteDialog(supplier),
                  ),
                ],
              ),
            ),
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
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: color,
        ),
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
        border: Border(
          top: BorderSide(
            color: Colors.blue.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'إجمالي الموردين: $count',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Obx(() {
            final stats = controller.supplierStats;
            return Text(
              'الحد الائتماني الإجمالي: ${stats['totalCreditLimit']} ر.س',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showSupplierDetails(Supplier supplier) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
            maxHeight: 600,
          ),
          child: SupplierDetailsDialog(supplier: supplier),
        ),
      ),
      barrierDismissible: true,
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

  void _showDeleteDialog(Supplier supplier) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'حذف ${supplier.name}',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف هذا المورد؟',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (supplier.suppliedMedications.isNotEmpty)
              Text(
                'يورد ${supplier.suppliedMedications.length} دواء',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),

          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSupplier(supplier.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}