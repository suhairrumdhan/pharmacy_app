class ValidationUtils {
  static bool isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}