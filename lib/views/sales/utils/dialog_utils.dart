import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DialogUtils {
  // ======================== دالة showDialog الآمنة ========================
  static Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = false,
    bool useRootNavigator = true,
  }) async {
    try {
      // التحقق من أن الـ context صالح
      if (!context.mounted) {
        print('⚠️ Context غير صالح لعرض dialog');
        return null;
      }

      // استخدام Navigator.of مع useRootNavigator: true
      return await showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
      );
    } catch (e, stackTrace) {
      print('❌ خطأ في عرض dialog: $e');
      print('📜 Stack trace: $stackTrace');
      return null;
    }
  }

  // ======================== دالة Get.dialog الآمنة ========================
  static Future<T?> showGetDialog<T>({
    required Widget Function() builder, // ✅ غيرت من WidgetBuilder إلى Function()
    bool barrierDismissible = false,
    Duration? transitionDuration,
    Curve? transitionCurve,
  }) async {
    try {
      return await Get.dialog<T>(
        builder(), // ✅ الآن يمكن استدعاء builder بدون معاملات
        barrierDismissible: barrierDismissible,
        transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
        transitionCurve: transitionCurve ?? Curves.easeOut,
      );
    } catch (e, stackTrace) {
      print('❌ خطأ في عرض Get.dialog: $e');
      print('📜 Stack trace: $stackTrace');
      return null;
    }
  }

  // ======================== دالة showSnackbar الآمنة ========================
  static void showSafeSnackbar({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
    Color backgroundColor = const Color(0xFF323232),
    Color textColor = Colors.white,
    bool showProgressIndicator = false,
    Color progressColor = Colors.white,
  }) {
    // تأخير عرض snackbar لتجنب مشاكل الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

        Get.rawSnackbar(
          title: title,
          message: message,
          duration: duration,
          snackPosition: position,
          backgroundColor: backgroundColor,
          borderRadius: 8,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          animationDuration: const Duration(milliseconds: 300),
          shouldIconPulse: true,
          icon: showProgressIndicator
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: progressColor,
            ),
          )
              : null,
        );
      } catch (e) {
        print('❌ خطأ في عرض snackbar: $e');
      }
    });
  }

  // ======================== دالة عرض dialog تحميل ========================
  static Future<void> showLoadingDialog({
    required BuildContext context,
    String message = 'جاري المعالجة...',
    bool barrierDismissible = false,
  }) async {
    await showSafeDialog(
      context: context,
      builder: (_) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  // ======================== دالة تأكيد ========================
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color confirmColor = Colors.blue,
    Color cancelColor = Colors.grey,
    bool useGetDialog = false,
  }) async {
    if (useGetDialog) {
      return await showGetDialog<bool>(
        builder: () => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                cancelText,
                style: TextStyle(color: cancelColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
              ),
              child: Text(confirmText),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } else {
      return await showSafeDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(color: cancelColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }
  }

  // ======================== دالة dialog مع خيارات ========================
  static Future<int?> showOptionsDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    List<IconData>? icons,
    List<Color>? colors,
  }) async {
    return await showSafeDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(options.length, (index) {
            return ListTile(
              leading: icons != null && index < icons.length
                  ? Icon(
                icons[index],
                color: colors != null && index < colors.length
                    ? colors[index]
                    : Colors.blue,
              )
                  : null,
              title: Text(options[index]),
              onTap: () => Navigator.of(context).pop(index),
            );
          }),
        ),
      ),
    );
  }

  // ======================== دالة عرض خطأ ========================
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'حسناً',
  }) async {
    await showSafeDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // ======================== دالة عرض نجاح ========================
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'حسناً',
  }) async {
    await showSafeDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // ======================== دالة إغلاق جميع dialogs ========================
  static void closeAllDialogs() {
    try {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    } catch (e) {
      print('❌ خطأ في إغلاق dialogs: $e');
    }
  }

  // ======================== دالة التحقق من وجود dialog مفتوح ========================
  static bool isDialogOpen() {
    return Get.isDialogOpen ?? false;
  }
}