import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';
import '../../../models/inventory_model.dart';

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
          onTap: () {
            print('🖱️ Row tapped for: ${medicine.name}');
            onViewDetails();
          },
          onLongPress: () => _showQuickActions(context),
          hoverColor: MedicinesTableStyle.primaryColor.withOpacity(0.1),
          splashColor: MedicinesTableStyle.primaryColor.withOpacity(0.2),
          child: Padding(
            padding: MedicinesTableStyle.rowPadding,
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildMedicineInfo()),
                Expanded(flex: 1, child: _buildCategory()),
                Expanded(flex: 1, child: _buildPricing()),
                Expanded(flex: 1, child: _buildStockInfo()),
                Expanded(flex: 1, child: _buildSupplier()),
                Expanded(flex: 1, child: _buildExpiryDate()),
                Expanded(flex: 1, child: _buildStatusBadge()),
                SizedBox(width: 160, child: _buildActionButtons()),
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
        SizedBox(width: 12),
        buildMedicineImage(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: MedicinesTableStyle.medicineNameText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                medicine.scientificName,
                style: MedicinesTableStyle.scientificNameText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
                      Icon(Icons.qr_code, size: 16, color: MedicinesTableStyle.lightText),
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
          style: MedicinesTableStyle.categoryText,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
              style: MedicinesTableStyle.stockText.copyWith(color: stockColor),
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
            Icon(Icons.calendar_today, size: 20, color: MedicinesTableStyle.lightText),
            SizedBox(height: 4),
            Text('لا يوجد', style: MedicinesTableStyle.scientificNameText),
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
              style: MedicinesTableStyle.expiryText.copyWith(color: expiryColor),
            ),
          ),
          SizedBox(height: 4),
          Text(
            presenter.getExpiryText(daysRemaining),
            style: TextStyle(fontSize: 10, color: expiryColor),
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
            Icon(statusInfo['icon'], size: 12, color: statusInfo['iconColor']),
            SizedBox(width: 4),
            Text(
              statusInfo['text'],
              style: MedicinesTableStyle.statusText.copyWith(color: statusInfo['iconColor']),
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
        // زر العين - للعرض
        _buildActionButton(
          Icons.remove_red_eye,
          MedicinesTableStyle.primaryColor,
          'عرض',
          onViewDetails, // ✅ صحيح
        ),

        // زر القلم - للتعديل
        _buildActionButton(
          Icons.edit,
          MedicinesTableStyle.secondaryColor,
          'تعديل',
          onEdit, // ✅ يجب أن يكون onEdit
        ),

        // زر المخزون - لتحديث المخزون
        _buildActionButton(
          Icons.inventory,
          MedicinesTableStyle.warningColor,
          'مخزون',
          onUpdateStock, // ✅ يجب أن يكون onUpdateStock
        ),

        // زر الحذف - للحذف
        _buildActionButton(
          Icons.delete,
          MedicinesTableStyle.dangerColor,
          'حذف',
          onDelete, // ✅ يجب أن يكون onDelete
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
              child: Icon(icon, size: MedicinesTableStyle.actionIconSize, color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMedicineImage() {
    if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty) {
      return Container(
        width: MedicinesTableStyle.medicineIconSize,
        height: MedicinesTableStyle.medicineIconSize,
        decoration: BoxDecoration(
          borderRadius: MedicinesTableStyle.cardBorderRadius,
          border: Border.all(color: Colors.blue.shade300, width: 1),
          boxShadow: MedicinesTableStyle.medicineIconShadow,
        ),
        child: ClipRRect(
          borderRadius: MedicinesTableStyle.cardBorderRadius,
          child: Image.network(
            medicine.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          ),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: MedicinesTableStyle.medicineIconSize,
      height: MedicinesTableStyle.medicineIconSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: MedicinesTableStyle.cardBorderRadius,
        boxShadow: MedicinesTableStyle.medicineIconShadow,
      ),
      child: Icon(
        Icons.medication,
        size: MedicinesTableStyle.medicineIconSize * 0.4,
        color: Colors.white,
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    print('⚡ Quick actions for: ${medicine.name}');
    // TODO: Implement quick actions
  }
}