import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicines_presenter.dart';
import 'medicines_style.dart';

export 'medicine_row.dart';

// =========================
// Helpers (breakpoints)
// =========================
class _MedBp {
  static bool isNarrow(BuildContext c) => MediaQuery.of(c).size.width < 1050;
  static bool isVeryNarrow(BuildContext c) => MediaQuery.of(c).size.width < 820;
}

// =========================
// Loading State
// =========================
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final boxW = w < 600 ? w * 0.92 : 520.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: boxW),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: MedicinesTableStyle.loadingGradient,
            borderRadius: MedicinesTableStyle.cardBorderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                    MedicinesTableStyle.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل البيانات...',
                style: TextStyle(
                  color: MedicinesTableStyle.mediumText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// Empty State
// =========================
class EmptyState extends StatelessWidget {
  final VoidCallback? onAddMedicine;
  const EmptyState({super.key, this.onAddMedicine});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w < 700 ? 20.0 : 40.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w < 700 ? w * 0.95 : 620),
        child: Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            borderRadius: MedicinesTableStyle.cardBorderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: w < 700 ? 24 : 60),
              Icon(
                Icons.not_interested,
                size: w < 700 ? 60 : 80,
                color: MedicinesTableStyle.lightText,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد اصناف للعرض',
                style: TextStyle(
                  fontSize: w < 700 ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  color: MedicinesTableStyle.mediumText,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAddMedicine != null) ...[
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onAddMedicine,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة دواء'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// Table Header (Responsive Columns)
// =========================
class MedicinesTableHeader extends StatelessWidget {
  const MedicinesTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = _MedBp.isNarrow(context);
    final veryNarrow = _MedBp.isVeryNarrow(context);

    // في الشاشات الصغيرة نقلل الأعمدة ونركز على المهم
    // - veryNarrow: صنف + كمية + حالة + إجراءات
    // - narrow: صنف + تصنيف + سعر + كمية + حالة + إجراءات
    // - wide: الكل
    final columns = <_HeaderCol>[
      _HeaderCol('الصنف', Icons.medication, flex: 2, show: true),
      _HeaderCol('التصنيف', Icons.category, flex: 1, show: !veryNarrow),
      _HeaderCol('السعر', Icons.monetization_on, flex: 1, show: !veryNarrow),
      _HeaderCol('الكمية', Icons.inventory, flex: 1, show: true),
      _HeaderCol('المورد', Icons.business, flex: 1, show: !narrow),
      _HeaderCol('الصلاحية', Icons.calendar_today, flex: 1, show: !narrow),
      _HeaderCol('الحالة', Icons.info, flex: 1, show: true),
    ];

    return Container(
      padding: MedicinesTableStyle.headerPadding,
      decoration: BoxDecoration(
        gradient: MedicinesTableStyle.headerGradient,
        borderRadius: MedicinesTableStyle.headerBorderRadius,
      ),
      child: Row(
        children: [
          ...columns.where((c) => c.show).map((c) => _buildHeaderCell(c)),
          SizedBox(
            width: narrow ? 120 : 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_vert,
                  size: MedicinesTableStyle.headerIconSize,
                  color: Colors.white.withOpacity(0.9),
                ),
                if (!veryNarrow) ...[
                  const SizedBox(width: 10),
                  Text('الإجراءات', style: MedicinesTableStyle.headerText),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(_HeaderCol c) {
    return Expanded(
      flex: c.flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            c.icon,
            size: MedicinesTableStyle.headerIconSize,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          Text(c.title, style: MedicinesTableStyle.headerText),
        ],
      ),
    );
  }
}

class _HeaderCol {
  final String title;
  final IconData icon;
  final int flex;
  final bool show;

  _HeaderCol(this.title, this.icon, {required this.flex, required this.show});
}

// =========================
// Table Footer (Wrap بدل Row ثابت)
// =========================
class MedicinesTableFooter extends StatelessWidget {
  final MedicinesPresenter presenter;
  const MedicinesTableFooter({super.key, required this.presenter});

  @override
  Widget build(BuildContext context) {
    final stats = presenter.getStatistics();
    final narrow = _MedBp.isNarrow(context);

    return Container(
      padding: MedicinesTableStyle.footerPadding,
      decoration: BoxDecoration(
        color: MedicinesTableStyle.lightBackground,
        borderRadius: MedicinesTableStyle.footerBorderRadius,
        border: Border(
          top: BorderSide(color: MedicinesTableStyle.borderColor, width: 1),
        ),
      ),
      child: narrow ? _buildNarrowFooter(stats) : _buildWideFooter(stats),
    );
  }

  Widget _buildWideFooter(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildStatItem('عدد الأصناف', stats['total'].toString(),
                  Icons.medication, MedicinesTableStyle.primaryColor),
              const SizedBox(width: 16),
              if (stats['lowStockCount'] > 0)
                _buildStatItem('منخفض', stats['lowStockCount'].toString(),
                    Icons.warning, MedicinesTableStyle.warningColor),
              if (stats['expiredCount'] > 0) ...[
                const SizedBox(width: 16),
                _buildStatItem('منتهي', stats['expiredCount'].toString(),
                    Icons.error, MedicinesTableStyle.dangerColor),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Icon(Icons.access_time_filled,
                size: MedicinesTableStyle.statIconSize,
                color: MedicinesTableStyle.mediumText),
            const SizedBox(width: 8),
            Text(
              DateFormat('hh:mm a | yyyy/MM/dd').format(DateTime.now()),
              style: MedicinesTableStyle.footerText,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowFooter(Map<String, dynamic> stats) {
    final chips = <Widget>[
      _buildStatItem('عدد الأصناف', stats['total'].toString(),
          Icons.medication, MedicinesTableStyle.primaryColor),
      if (stats['lowStockCount'] > 0)
        _buildStatItem('منخفض', stats['lowStockCount'].toString(),
            Icons.warning, MedicinesTableStyle.warningColor),
      if (stats['expiredCount'] > 0)
        _buildStatItem('منتهي', stats['expiredCount'].toString(),
            Icons.error, MedicinesTableStyle.dangerColor),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.access_time_filled,
                size: MedicinesTableStyle.statIconSize,
                color: MedicinesTableStyle.mediumText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('hh:mm a | yyyy/MM/dd').format(DateTime.now()),
                style: MedicinesTableStyle.footerText,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: MedicinesTableStyle.statIconSize, color: color),
          const SizedBox(width: 6),
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
