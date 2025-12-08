import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print("✅ SharedPreferences initialized successfully");
    } catch (e) {
      print("❌ Error initializing SharedPreferences: $e");
      rethrow;
    }
  }

  // حفظ كلمة المرور مؤقتاً
  Future<void> saveTemporaryPassword(String email, String password) async {
    try {
      final key = 'temp_password_${email.trim()}';
      await _prefs.setString(key, password);
      print("🔐 كلمة المرور محفوظة مؤقتاً للمستخدم: $email");
    } catch (e) {
      print("⚠️ خطأ في حفظ كلمة المرور: $e");
    }
  }

  // جلب كلمة المرور المحفوظة
  String? getTemporaryPassword(String email) {
    final key = 'temp_password_${email.trim()}';
    return _prefs.getString(key);
  }

  // حفظ بيانات تسجيل الدخول
  Future<void> saveLoginCredentials(String email, String password) async {
    try {
      final key = 'user_password_$email';
      await _prefs.setString(key, password);
      print("🔐 كلمة المرور محفوظة لإعادة الاستخدام");
    } catch (e) {
      print("⚠️ خطأ في حفظ بيانات الدخول: $e");
    }
  }

  // جلب بيانات تسجيل الدخول
  String? getLoginCredentials(String email) {
    final key = 'user_password_$email';
    return _prefs.getString(key);
  }

  // مسح بيانات معينة
  Future<void> removeKey(String key) async {
    await _prefs.remove(key);
  }

  // مسح كل البيانات
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}