import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/inventory_model.dart';

class MedicinesPresenter {
  final InventoryController controller = Get.find<InventoryController>();

  List<Medicine> get filteredMedicines => controller.filteredMedicines;
  bool get isLoading => controller.isLoading.value;

  // Helper Methods

  Color getStockColor(Medicine medicine) {
    if (medicine.isExpired) return Colors.red;
    if (medicine.isLowStock) return Colors.orange;
    if (medicine.quantity > 50) return Colors.green;
    return Colors.blue;
  }

  Color getExpiryColor(int daysRemaining) {
    if (daysRemaining < 0) return Colors.red;
    if (daysRemaining <= 7) return Colors.red.shade600;
    if (daysRemaining <= 30) return Colors.orange;
    if (daysRemaining <= 90) return Colors.amber.shade700;
    return Colors.green;
  }

  String getExpiryText(int daysRemaining) {
    if (daysRemaining < 0) return 'منتهي';
    if (daysRemaining == 0) return 'ينتهي اليوم';
    if (daysRemaining == 1) return 'غداً';
    if (daysRemaining <= 7) return '$daysRemaining أيام';
    if (daysRemaining <= 30) return '${(daysRemaining / 7).ceil()} أسابيع';
    return '${(daysRemaining / 30).ceil()} أشهر';
  }

  Map<String, dynamic> getStatusInfo(Medicine medicine) {
    if (medicine.isExpired) {
      return {
        'icon': Icons.error,
        'bgColor': Colors.red.shade50,
        'iconColor': Colors.red.shade700,
        'text': 'منتهي',
      };
    } else if (medicine.isLowStock) {
      return {
        'icon': Icons.warning,
        'bgColor': Colors.orange.shade50,
        'iconColor': Colors.orange.shade700,
        'text': 'منخفض',
      };
    } else {
      return {
        'icon': Icons.check_circle,
        'bgColor': Colors.green.shade50,
        'iconColor': Colors.green.shade700,
        'text': 'متوفر',
      };
    }
  }

  String getUnitName(UnitType? unit) {
    if (unit == null) return 'وحدة';

    switch (unit) {
      case UnitType.Tablet:
        return 'قرص';
      case UnitType.Capsule:
        return 'كبسولة';
      case UnitType.Syrup:
        return 'شراب';
      case UnitType.Drops:
        return 'قطرة';
      case UnitType.Bottle:
        return 'زجاجة';
      case UnitType.Ampoule:
        return 'أمبولة';
      case UnitType.Vial:
        return 'قارورة';
      case UnitType.Ointment:
        return 'مرهم';
      case UnitType.Cream:
        return 'كريم';
      case UnitType.Gel:
        return 'جيل';
      case UnitType.Spray:
        return 'بخاخ';
      case UnitType.Patch:
        return 'لصقة';
      case UnitType.Powder:
        return 'مسحوق';
      case UnitType.Sachet:
        return 'كيس';
      case UnitType.Suppository:
        return 'تحاميل';
      case UnitType.Inhaler:
        return 'استنشاق';
      case UnitType.Suspension:
        return 'معلق';
      case UnitType.Solution:
        return 'محلول';
      case UnitType.Lotion:
        return 'لوشن';
      case UnitType.Strip:
        return 'شريط';
      case UnitType.Tube:
        return 'أنبوب';
    }
  }

  // Statistics
  Map<String, dynamic> getStatistics() {
    final medicines = filteredMedicines;
    final total = medicines.length;
    final totalStock = medicines.fold(0, (sum, medicine) => sum + medicine.quantity);
    final lowStockCount = medicines.where((m) => m.isLowStock).length;
    final expiredCount = medicines.where((m) => m.isExpired).length;

    return {
      'total': total,
      'totalStock': totalStock,
      'lowStockCount': lowStockCount,
      'expiredCount': expiredCount,
    };
  }

  // Action Methods
  void deleteMedicine(String id) {
    controller.deleteMedicine(id);
  }
}