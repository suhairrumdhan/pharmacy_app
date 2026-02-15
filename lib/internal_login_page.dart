import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pharmacy_desktop/views/home_page.dart';
import '../controllers/auth_controller.dart';

class InternalLoginPage extends StatefulWidget {
  const InternalLoginPage({super.key});

  @override
  State<InternalLoginPage> createState() => _InternalLoginPageState();
}

class _InternalLoginPageState extends State<InternalLoginPage> {
  final AuthController controller = Get.find<AuthController>();

  final usernameFocus = FocusNode();
  final passwordFocus = FocusNode();
  bool showPassword = false;

  @override
  void dispose() {
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Responsive card width
    final double cardWidth = size.width >= 1200
        ? 420
        : size.width >= 900
        ? 420
        : size.width >= 600
        ? 420
        : size.width * 0.92;

    // Responsive padding
    final double cardPadding = size.width < 600 ? 16 : 20;

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية - صورة
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // طبقة شفافة
          Container(color: Colors.black.withOpacity(0.35)),

          // المحتوى
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(blurRadius: 18, color: Colors.black26),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.badge_outlined,
                            color: Colors.lightBlueAccent.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "تسجيل دخول الموظفين",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "ادخل اسم المستخدم وكلمة المرور الخاصة بالموظف",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Username
                    TextField(
                      focusNode: usernameFocus,
                      decoration: InputDecoration(
                        labelText: "اسم المستخدم",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) => controller.internalUsername.value = value.trim(),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocus),
                    ),

                    const SizedBox(height: 14),

                    // Password
                    TextField(
                      focusNode: passwordFocus,
                      obscureText: !showPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: "كلمة المرور",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: IconButton(
                          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => showPassword = !showPassword),
                        ),
                      ),
                      onChanged: (value) => controller.internalPassword.value = value,
                      onSubmitted: (_) async => _validateAndLogin(),
                    ),

                    const SizedBox(height: 18),

                    // Login button
                    Obx(() {
                      return controller.isInternalLoading.value
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(),
                      )
                          : SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _validateAndLogin,
                          child: const Text(
                            "تسجيل الدخول",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Actions row (Back to owner / Logout owner)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("خروج نهائي"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        onPressed: () async {
                          await controller.logoutOwnerSecure(); // يطلب كلمة مرور المالك
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndLogin() async {
    if (controller.internalUsername.value.trim().isEmpty ||
        controller.internalPassword.value.isEmpty) {
      Get.snackbar(
        "تنبيه",
        "يرجى ملء جميع الحقول",
        backgroundColor: Colors.lightBlueAccent,
      );
      return;
    }
    await _loginInternal();
  }

  Future<void> _loginInternal() async {
    try {
      final pharmacyId = controller.userId; // uid الصيدلية (مالك Firebase)
      if (pharmacyId == null || pharmacyId.isEmpty) {
        Get.snackbar(
          "خطأ",
          "لم يتم العثور على معرف الصيدلية (تأكد أن المالك مسجل دخول)",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final success = await controller.loginInternal(pharmacyId: pharmacyId);

      if (success) {
        Get.offAll(() => const HomePage());
      } else {
        Get.snackbar(
          "خطأ",
          "اسم المستخدم أو كلمة المرور خاطئة",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء تسجيل الدخول: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}
