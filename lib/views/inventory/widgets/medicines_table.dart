import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '';
import '../../../models/inventory_model.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';
import 'medicines_components.dart';
import '../../../controllers/inventory_controller.dart';

class MedicinesTable extends StatelessWidget {
  const MedicinesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = MedicinesPresenter();

    return Obx(() {
      if (presenter.isLoading) {
        return LoadingState();
      }

      if (presenter.filteredMedicines.isEmpty) {
        return EmptyState(
          onAddMedicine: () {
            // TODO: Add new medicine
          },
        );
      }

      return _buildTable(presenter);
    });
  }

  Widget _buildTable(MedicinesPresenter presenter) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: MedicinesTableStyle.tableBorderRadius,
        gradient: MedicinesTableStyle.tableGradient,
        boxShadow: MedicinesTableStyle.tableShadow,
      ),
      child: Column(
        children: [
          // Table Header
          MedicinesTableHeader(),

          // Table Body
          Expanded(
            child: _buildMedicinesList(presenter),
          ),

          // Table Footer
          MedicinesTableFooter(presenter: presenter),
        ],
      ),
    );
  }

  Widget _buildMedicinesList(MedicinesPresenter presenter) {
    return ListView.separated(
      itemCount: presenter.filteredMedicines.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: MedicinesTableStyle.borderColor,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final medicine = presenter.filteredMedicines[index];
        return MedicineRow(
          medicine: medicine,
          index: index,
          presenter: presenter,
          onViewDetails: () => _showMedicineDetails(medicine),
          onEdit: () => _showEditDialog(medicine),
          onUpdateStock: () => _showStockUpdateDialog(medicine),
          onDelete: () => _showDeleteDialog(medicine, presenter),
        );
      },
    );
  }

  // Action Dialogs
  void _showMedicineDetails(Medicine medicine) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تفاصيل الدواء',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MedicinesTableStyle.darkText,
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: Icon(
                        Icons.close,
                        color: MedicinesTableStyle.mediumText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Medicine Card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MedicinesTableStyle.primaryColor.withOpacity(0.1),
                        MedicinesTableStyle.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: MedicinesTableStyle.cardBorderRadius,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: MedicinesTableStyle.headerGradient,
                              borderRadius: MedicinesTableStyle.cardBorderRadius,
                            ),
                            child: Icon(
                              Icons.medication,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicine.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: MedicinesTableStyle.darkText,
                                  ),
                                ),
                                Text(
                                  medicine.scientificName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: MedicinesTableStyle.mediumText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Details Grid
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildDetailItem('الصنف', medicine.category ?? 'غير محدد', Icons.category),
                          _buildDetailItem('المورد', medicine.supplier ?? 'غير محدد', Icons.business),
                          _buildDetailItem('سعر البيع', '${medicine.sellingPrice?.toStringAsFixed(2) ?? '0.00'} د.ل', Icons.money),
                          _buildDetailItem('سعر الشراء', '${medicine.purchasePrice?.toStringAsFixed(2) ?? '0.00'} د.ل', Icons.shopping_cart),
                          _buildDetailItem('الكمية', '${medicine.quantity} ${_getUnitName(medicine.unit)}', Icons.inventory),
                          if (medicine.expiryDate != null)
                            _buildDetailItem('تاريخ الانتهاء', DateFormat('dd/MM/yyyy').format(medicine.expiryDate!), Icons.calendar_today),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: Get.back,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MedicinesTableStyle.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: MedicinesTableStyle.buttonBorderRadius,
                      ),
                    ),
                    child: Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: MedicinesTableStyle.cardBorderRadius,
        border: Border.all(color: MedicinesTableStyle.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: MedicinesTableStyle.primaryColor,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: MedicinesTableStyle.lightText,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MedicinesTableStyle.mediumText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUnitName(UnitType? unit) {
    final presenter = MedicinesPresenter();
    return presenter.getUnitName(unit);
  }

  void _showEditDialog(Medicine medicine) {
    Get.defaultDialog(
      title: 'تعديل ${medicine.name}',
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: MedicinesTableStyle.darkText,
      ),
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'سيتم فتح نافذة التعديل الكاملة للدواء',
          style: TextStyle(
            color: MedicinesTableStyle.mediumText,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text(
            'إلغاء',
            style: TextStyle(color: MedicinesTableStyle.mediumText),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            // TODO: Implement edit functionality
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MedicinesTableStyle.primaryColor,
          ),
          child: Text('متابعة'),
        ),
      ],
    );
  }

  void _showStockUpdateDialog(Medicine medicine) {
    Get.defaultDialog(
      title: 'تحديث مخزون ${medicine.name}',
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: MedicinesTableStyle.secondaryColor,
      ),
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'الكمية الحالية: ${medicine.quantity} ${_getUnitName(medicine.unit)}',
          style: TextStyle(
            color: MedicinesTableStyle.mediumText,
            fontSize: 14,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text(
            'إلغاء',
            style: TextStyle(color: MedicinesTableStyle.mediumText),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            // TODO: Implement stock update functionality
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MedicinesTableStyle.secondaryColor,
          ),
          child: Text('تحديث'),
        ),
      ],
    );
  }

  void _showDeleteDialog(Medicine medicine, MedicinesPresenter presenter) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'حذف ${medicine.name}',
          style: TextStyle(
            color: MedicinesTableStyle.dangerColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف هذا الدواء؟',
              style: TextStyle(
                color: MedicinesTableStyle.mediumText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'الكمية الحالية: ${medicine.quantity} ${_getUnitName(medicine.unit)}',
              style: TextStyle(
                color: MedicinesTableStyle.lightText,
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
              style: TextStyle(color: MedicinesTableStyle.mediumText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              presenter.deleteMedicine(medicine.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicinesTableStyle.dangerColor,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }
}