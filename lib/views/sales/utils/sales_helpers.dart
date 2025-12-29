import 'package:flutter/material.dart';

class SalesHelpers {
  // دالة مساعدة لتحويل الأرقام إلى صيغة نقدية
  static String formatCurrency(double amount, {bool includeSymbol = true}) {
    final formatted = amount.toStringAsFixed(2);
    return includeSymbol ? '$formatted ر.س' : formatted;
  }

  // دالة مساعدة للتحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^[0-9]{10}$');
    return regex.hasMatch(phone);
  }

  // دالة مساعدة للحصول على لون حالة المخزون
  static Color getStockColor(int quantity, int threshold) {
    if (quantity == 0) return Colors.red;
    if (quantity <= threshold) return Colors.orange;
    return Colors.green;
  }

  // دالة مساعدة لتنسيق التاريخ والوقت
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  // دالة مساعدة لحساب المبلغ المتبقي
  static double calculateChange(double total, double received) {
    return received > total ? received - total : 0.0;
  }

  // دالة مساعدة لحساب الإجمالي بعد الخصم
  static double calculateDiscount(double price, double? discountPercentage, double? discountAmount) {
    if (discountAmount != null) {
      return price - discountAmount;
    }
    if (discountPercentage != null) {
      return price * (1 - discountPercentage / 100);
    }
    return price;
  }
}