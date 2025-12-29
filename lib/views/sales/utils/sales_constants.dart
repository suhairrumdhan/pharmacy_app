import 'package:flutter/material.dart';

class SalesConstants {
  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color secondaryColor = Color(0xFF3498DB);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color dangerColor = Color(0xFFE74C3C);
  static const Color infoColor = Color(0xFF1ABC9C);

  // أبعاد التطبيق
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // نصوابت النص
  static const String appTitle = 'نظام إدارة الصيدلية';
  static const String salesTitle = 'نقطة البيع';
  static const String searchHint = 'ابحث عن دواء...';
  static const String emptyCartMessage = 'السلة فارغة';
  static const String addProductsHint = 'ابحث وأضف منتجات للفاتورة';

  // رسائل التأكيد
  static const String confirmSale = 'تأكيد عملية البيع';
  static const String saleSuccess = 'تم حفظ الفاتورة بنجاح';
  static const String printReceipt = 'طباعة الفاتورة';
  static const String receiptSent = 'سيتم إرسال الفاتورة للطباعة';

  // رسائل الأخطاء
  static const String noProductsFound = 'لم يتم العثور على منتجات';
  static const String lowStockWarning = 'المخزون منخفض';
  static const String insufficientStock = 'المخزون غير كافي';
  static const String invalidPhone = 'رقم الهاتف غير صالح';

  // نصوابت الدفع
  static const String cashPayment = 'نقدي';
  static const String cardPayment = 'بطاقة';
  static const String insurancePayment = 'تأمين';
  static const String receivedAmount = 'المبلغ المستلم';
  static const String remainingAmount = 'المبلغ المتبقي';
  static const String missingAmount = 'ناقص';

  // نصوابت شركات التأمين
  static const String selectInsurance = 'اختر شركة التأمين';
  static const String insuranceDiscount = 'خصم';
}