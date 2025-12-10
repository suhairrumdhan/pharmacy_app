// lib/views/inventory/widgets/medicines_table.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/inventory_model.dart';
import 'medicine_row.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';
import 'medicines_components.dart';
import '../medicine_details_sheet.dart'; // ✅ استيراد الويدجت الجديد

class MedicinesTable extends StatelessWidget {
  const MedicinesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = MedicinesPresenter();

    return Obx(() {
      if (presenter.filteredMedicines.isEmpty) {
        return EmptyState();
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
          MedicinesTableHeader(),
          Expanded(
            child: _buildMedicinesList(presenter),
          ),
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
          onViewDetails: () {
            _showMedicineDetails(medicine);
          },
          onEdit: () {
            _showEditDialog(medicine);
          },
          onUpdateStock: () {
            _showStockUpdateDialog(medicine);
          },
          onDelete: () {
            _showDeleteDialog(medicine, presenter);
          },
        );
      },
    );
  }

  // ✅ الآن الدالة أصبحت بسيطة جداً
  void _showMedicineDetails(Medicine medicine) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(20), // مسافة من الأطراف
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1400, // ✅ حجم أكبر
            maxHeight: 900, // ✅ حجم أكبر
          ),
          child: MedicineDetailsSheet(
            medicine: medicine,
            onEditPressed: () {
              Get.back();
              _showEditDialog(medicine);
            },
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
  String _getUnitName(UnitType? unit) {
    if (unit == null) return 'وحدة';

    final unitNames = {
      UnitType.Tablet: 'قرص',
      UnitType.Capsule: 'كبسولة',
      UnitType.Syrup: 'شراب',
      UnitType.Drops: 'قطرة',
      UnitType.Bottle: 'زجاجة',
      UnitType.Ampoule: 'أمبولة',
      UnitType.Vial: 'قارورة',
      UnitType.Ointment: 'مرهم',
      UnitType.Cream: 'كريم',
      UnitType.Gel: 'جل',
      UnitType.Spray: 'سبراي',
      UnitType.Patch: 'لصقة',
      UnitType.Powder: 'مسحوق',
      UnitType.Sachet: 'كيس',
      UnitType.Suppository: 'تحميلة',
      UnitType.Inhaler: 'بخاخ',
      UnitType.Suspension: 'معلق',
      UnitType.Solution: 'محلول',
      UnitType.Lotion: 'لوشن',
      UnitType.Strip: 'شريط',
      UnitType.Tube: 'أنبوب',
    };

    return unitNames[unit] ?? unit.name;
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