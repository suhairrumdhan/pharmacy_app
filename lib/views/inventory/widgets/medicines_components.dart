import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';
import '../../../models/inventory_model.dart';
// في أعلى medicines_components.dart
export 'medicine_row.dart'; // إذا أردت تصديرها
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
        borderRadius: MedicinesTableStyle.cardBorderRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 70),

          Icon(
            Icons.not_interested,
            size: 80,
            color: MedicinesTableStyle.lightText,
          ),
          SizedBox(height: 30),
          Text(
            'لا توجد اصناف للعرض',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MedicinesTableStyle.mediumText,
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Table Header Component
// Table Header Component
class MedicinesTableHeader extends StatelessWidget {
  const MedicinesTableHeader({super.key});

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
          // الأعمدة المرنة
          _buildHeaderCell('الصنف', Icons.medication, 2),
          _buildHeaderCell('التصنيف', Icons.category, 1),
          _buildHeaderCell('السعر', Icons.monetization_on, 1),
          _buildHeaderCell('الكمية', Icons.inventory, 1),
          _buildHeaderCell('المورد', Icons.business, 1),
          _buildHeaderCell('الصلاحية', Icons.calendar_today, 1),
          _buildHeaderCell('الحالة', Icons.info, 1),

          // العمود الأخير بعرض ثابت
          SizedBox(
            width: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_vert,
                  size: MedicinesTableStyle.headerIconSize,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 10),
                Text(
                  'الإجراءات',
                  style: MedicinesTableStyle.headerText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // الأعمدة المرنة فقط
  Widget _buildHeaderCell(String title, IconData icon, int flex) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: MedicinesTableStyle.headerIconSize,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: MedicinesTableStyle.headerText,
          ),
        ],
      ),
    );
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