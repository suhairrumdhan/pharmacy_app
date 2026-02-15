import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/inventory_model.dart';
import '../add_medicine_dialog.dart';
import 'medicine_row.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';
import 'medicines_components.dart';
import '../medicine_details_sheet.dart';

class MedicinesTable extends StatelessWidget {
  const MedicinesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = MedicinesPresenter();

    return Obx(() {
      if (presenter.isLoading) {
        return const LoadingState();
      }

      if (presenter.filteredMedicines.isEmpty) {
        return const EmptyState();
      }

      return _buildResponsiveTable(context, presenter);
    });
  }

  Widget _buildResponsiveTable(BuildContext context, MedicinesPresenter presenter) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // ✅ إذا العرض ضيق نخلي Scroll أفقي للـTable
        final bool needHScroll = w < 1050;
        final double minTableWidth = 1050;

        final table = Container(
          decoration: BoxDecoration(
            borderRadius: MedicinesTableStyle.tableBorderRadius,
            gradient: MedicinesTableStyle.tableGradient,
            boxShadow: MedicinesTableStyle.tableShadow,
          ),
          child: Column(
            children: [
              const MedicinesTableHeader(),
              Expanded(child: _buildMedicinesList(presenter)),
              MedicinesTableFooter(presenter: presenter),
            ],
          ),
        );

        if (!needHScroll) return table;

        // ✅ Horizontal scroll + scrollbar للديسكتوب
        return ClipRRect(
          borderRadius: MedicinesTableStyle.tableBorderRadius,
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: SizedBox(width: minTableWidth, child: table),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicinesList(MedicinesPresenter presenter) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
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
            onDelete: () => _showDeleteDialog(medicine, presenter),
          );
        },
      ),
    );
  }

  // ✅ Responsive details dialog (بدل 1400×900 ثابت)
  void _showMedicineDetails(Medicine medicine) {
    final ctx = Get.context!;
    final w = MediaQuery.of(ctx).size.width;
    final h = MediaQuery.of(ctx).size.height;

    final bool isWide = w >= 1200;
    final double dialogW = isWide ? 1200 : w * 0.94;
    final double dialogH = isWide ? 850 : h * 0.88;

    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: w < 900 ? 12 : 24,
          vertical: h < 800 ? 12 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogW, maxHeight: dialogH),
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
    const unitNames = {
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
    Get.dialog(
      AddMedicineDialog(medicine: medicine),
      barrierDismissible: true,
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
            Text('هل أنت متأكد من حذف هذا الدواء؟',
                style: TextStyle(color: MedicinesTableStyle.mediumText)),
            const SizedBox(height: 8),
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
            child: Text('إلغاء', style: TextStyle(color: MedicinesTableStyle.mediumText)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              presenter.deleteMedicine(medicine.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicinesTableStyle.dangerColor,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
