import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';
import '../../../models/inventory_model.dart';

// Loading State Component
class LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: MedicinesTableStyle.loadingGradient,
          borderRadius: MedicinesTableStyle.cardBorderRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(MedicinesTableStyle.primaryColor),
            ),
            SizedBox(height: 20),
            Text(
              'جاري تحميل البيانات...',
              style: TextStyle(
                color: MedicinesTableStyle.mediumText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty State Component
class EmptyState extends StatelessWidget {
  final VoidCallback? onAddMedicine;

  const EmptyState({this.onAddMedicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: MedicinesTableStyle.emptyStateGradient,
        borderRadius: MedicinesTableStyle.cardBorderRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_rounded,
            size: 80,
            color: MedicinesTableStyle.lightText,
          ),
          SizedBox(height: 20),
          Text(
            'لا توجد اصناف للعرض',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MedicinesTableStyle.mediumText,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'قم بإضافة اصناف جديدة لبدء إدارة المخزون',
            style: TextStyle(
              color: MedicinesTableStyle.lightText,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: onAddMedicine,
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicinesTableStyle.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: MedicinesTableStyle.buttonBorderRadius,
              ),
              elevation: 2,
            ),
            child: Text('إضافة صنف جديد'),
          ),
        ],
      ),
    );
  }
}

// Table Header Component
class MedicinesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MedicinesTableStyle.headerPadding,
      decoration: BoxDecoration(
        gradient: MedicinesTableStyle.headerGradient,
        borderRadius: MedicinesTableStyle.headerBorderRadius,
      ),
      child: Row(
        children: [
          _buildHeaderCell('الصنف', Icons.medication, 2),
          _buildHeaderCell('التصنيف', Icons.category, 1),
          _buildHeaderCell('السعر', Icons.monetization_on, 1),
          _buildHeaderCell('الكمية', Icons.inventory, 1),
          _buildHeaderCell('المورد', Icons.business, 1),
          _buildHeaderCell('الصلاحية', Icons.calendar_today, 1),
          _buildHeaderCell('الحالة', Icons.info, 1),
          SizedBox(
            width: 160,
            child: _buildHeaderCell('الإجراءات', Icons.more_vert, null),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, IconData icon, int? flex) {
    return Expanded(
      flex: flex ?? 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: MedicinesTableStyle.headerIconSize,
            color: Colors.white.withOpacity(0.9),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: MedicinesTableStyle.headerText,
          ),
        ],
      ),
    );
  }
}

// Medicine Row Component
class MedicineRow extends StatelessWidget {
  final Medicine medicine;
  final int index;
  final MedicinesPresenter presenter;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;

  const MedicineRow({
    required this.medicine,
    required this.index,
    required this.presenter,
    required this.onViewDetails,
    required this.onEdit,
    required this.onUpdateStock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: index.isEven
              ? [Colors.white, Colors.white]
              : [Colors.grey.shade50, Colors.grey.shade50],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          onLongPress: () => _showQuickActions(context),
          hoverColor: MedicinesTableStyle.primaryColor.withOpacity(0.1),
          splashColor: MedicinesTableStyle.primaryColor.withOpacity(0.2),
          child: Padding(
            padding: MedicinesTableStyle.rowPadding,
            child: Row(
              children: [
                // Medicine Name
                Expanded(
                  flex: 2,
                  child: _buildMedicineInfo(),
                ),

                // Category
                Expanded(
                  flex: 1,
                  child: _buildCategory(),
                ),

                // Pricing
                Expanded(
                  flex: 1,
                  child: _buildPricing(),
                ),

                // Stock
                Expanded(
                  flex: 1,
                  child: _buildStockInfo(),
                ),

                // Supplier
                Expanded(
                  flex: 1,
                  child: _buildSupplier(),
                ),

                // Expiry
                Expanded(
                  flex: 1,
                  child: _buildExpiryDate(),
                ),

                // Status
                Expanded(
                  flex: 1,
                  child: _buildStatusBadge(),
                ),

                // Actions
                SizedBox(
                  width: 160,
                  child: _buildActionButtons(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Medicine Icon
        Container(
          width: MedicinesTableStyle.medicineIconSize,
          height: MedicinesTableStyle.medicineIconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600,
                Colors.purple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: MedicinesTableStyle.cardBorderRadius,
            boxShadow: MedicinesTableStyle.medicineIconShadow,
          ),
          child: Icon(
            Icons.medication,
            size: 22,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12),

        // Medicine Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trade Name
              Text(
                medicine.name,
                style: MedicinesTableStyle.medicineNameText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Scientific Name
              Text(
                medicine.scientificName,
                style: MedicinesTableStyle.scientificNameText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Barcode
              if (medicine.barcode != null && medicine.barcode!.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: MedicinesTableStyle.chipBorderRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 16,
                        color: MedicinesTableStyle.lightText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        medicine.barcode!,
                        style: TextStyle(
                          fontSize: 14,
                          color: MedicinesTableStyle.mediumText,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategory() {
    return Center(
      child: Container(
        padding: MedicinesTableStyle.cellPadding,
        decoration: BoxDecoration(
          borderRadius: MedicinesTableStyle.badgeBorderRadius,
        ),
        child: Text(
          medicine.category ?? 'عام',
          style: MedicinesTableStyle.categoryText.copyWith(
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Selling Price
        Container(
          padding: MedicinesTableStyle.cellPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MedicinesTableStyle.secondaryColor.withOpacity(0.1),
                MedicinesTableStyle.secondaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: MedicinesTableStyle.cardBorderRadius,
            border: Border.all(color: MedicinesTableStyle.secondaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                medicine.sellingPrice?.toStringAsFixed(2) ?? '0.00',
                style: MedicinesTableStyle.priceText,
              ),
              SizedBox(width: 2),
              Text(
                'د.ل',
                style: TextStyle(
                  fontSize: 10,
                  color: MedicinesTableStyle.secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    final stockColor = presenter.getStockColor(medicine);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Quantity
        Container(
          width: MedicinesTableStyle.stockCircleSize,
          height: MedicinesTableStyle.stockCircleSize,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                stockColor.withOpacity(0.2),
                stockColor.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: stockColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              medicine.quantity.toString(),
              style: MedicinesTableStyle.stockText.copyWith(
                color: stockColor,
              ),
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildSupplier() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            medicine.supplier ?? 'غير محدد',
            style: MedicinesTableStyle.supplierText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDate() {
    if (medicine.expiryDate == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: MedicinesTableStyle.lightText,
            ),
            SizedBox(height: 4),
            Text(
              'لا يوجد',
              style: MedicinesTableStyle.scientificNameText,
            ),
          ],
        ),
      );
    }

    final daysRemaining = medicine.expiryDate!.difference(DateTime.now()).inDays;
    final expiryColor = presenter.getExpiryColor(daysRemaining);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: MedicinesTableStyle.cellPadding,
            decoration: BoxDecoration(
              color: expiryColor.withOpacity(0.1),
              borderRadius: MedicinesTableStyle.chipBorderRadius,
            ),
            child: Text(
              DateFormat('dd/MM/yy').format(medicine.expiryDate!),
              style: MedicinesTableStyle.expiryText.copyWith(
                color: expiryColor,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            presenter.getExpiryText(daysRemaining),
            style: TextStyle(
              fontSize: 10,
              color: expiryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusInfo = presenter.getStatusInfo(medicine);
    return Center(
      child: Container(
        padding: MedicinesTableStyle.cellPadding,
        decoration: BoxDecoration(
          color: statusInfo['bgColor'],
          borderRadius: MedicinesTableStyle.badgeBorderRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusInfo['icon'],
              size: 12,
              color: statusInfo['iconColor'],
            ),
            SizedBox(width: 4),
            Text(
              statusInfo['text'],
              style: MedicinesTableStyle.statusText.copyWith(
                color: statusInfo['iconColor'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          Icons.remove_red_eye,
          MedicinesTableStyle.primaryColor,
          'عرض',
          onViewDetails,
        ),
        _buildActionButton(
          Icons.edit,
          MedicinesTableStyle.secondaryColor,
          'تعديل',
          onEdit,
        ),
        _buildActionButton(
          Icons.inventory,
          MedicinesTableStyle.warningColor,
          'مخزون',
          onUpdateStock,
        ),
        _buildActionButton(
          Icons.delete,
          MedicinesTableStyle.dangerColor,
          'حذف',
          onDelete,
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return Padding(
      padding: MedicinesTableStyle.actionButtonPadding,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: MedicinesTableStyle.cardBorderRadius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: MedicinesTableStyle.cardBorderRadius,
            child: Container(
              width: MedicinesTableStyle.actionButtonSize,
              height: MedicinesTableStyle.actionButtonSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: MedicinesTableStyle.cardBorderRadius,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                size: MedicinesTableStyle.actionIconSize,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    // TODO: Implement quick actions
  }
}

// Table Footer Component
class MedicinesTableFooter extends StatelessWidget {
  final MedicinesPresenter presenter;

  const MedicinesTableFooter({required this.presenter});

  @override
  Widget build(BuildContext context) {
    final stats = presenter.getStatistics();

    return Container(
      padding: MedicinesTableStyle.footerPadding,
      decoration: BoxDecoration(
        color: MedicinesTableStyle.lightBackground,
        borderRadius: MedicinesTableStyle.footerBorderRadius,
        border: Border(
          top: BorderSide(color: MedicinesTableStyle.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Statistics
          Expanded(
            child: Row(
              children: [
                _buildStatItem('عدد الأصناف', stats['total'].toString(),
                    Icons.medication, MedicinesTableStyle.primaryColor),
                SizedBox(width: 16),
                if (stats['lowStockCount'] > 0) ...[
                  SizedBox(width: 16),
                  _buildStatItem('منخفض', stats['lowStockCount'].toString(),
                      Icons.warning, MedicinesTableStyle.warningColor),
                ],
                if (stats['expiredCount'] > 0) ...[
                  SizedBox(width: 16),
                  _buildStatItem('منتهي', stats['expiredCount'].toString(),
                      Icons.error, MedicinesTableStyle.dangerColor),
                ],
              ],
            ),
          ),

          // Update Time
          Row(
            children: [
              Icon(
                Icons.access_time_filled,
                size: MedicinesTableStyle.statIconSize,
                color: MedicinesTableStyle.mediumText,
              ),
              SizedBox(width: 8),
              Text(
                DateFormat('hh:mm a | yyyy/MM/dd').format(DateTime.now()),
                style: MedicinesTableStyle.footerText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: MedicinesTableStyle.statItemPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: MedicinesTableStyle.chipBorderRadius,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: MedicinesTableStyle.statIconSize,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            '$label: $value',
            style: MedicinesTableStyle.footerText.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}