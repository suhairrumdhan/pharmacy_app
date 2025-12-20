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

          // طبقة شفافة لتعتيم الخلفية قليلاً
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // محتوى تسجيل الدخول
          Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black26)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "تسجيل دخول الموظفين",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // حقل Username
                  TextField(
                    focusNode: usernameFocus,
                    decoration: const InputDecoration(
                      labelText: "اسم المستخدم",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => controller.internalUsername.value = value,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(passwordFocus);
                    },
                  ),

                  const SizedBox(height: 15),

                  // حقل Password
                  TextField(
                    focusNode: passwordFocus,
                    obscureText: !showPassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) => controller.internalPassword.value = value,
                    onSubmitted: (_) async {
                      if (controller.internalUsername.value.isEmpty ||
                          controller.internalPassword.value.isEmpty) {
                        Get.snackbar(
                          "تنبيه",
                          "يرجى ملء جميع الحقول",
                          backgroundColor: Colors.lightBlueAccent,
                        );
                        return;
                      }
                      await _loginInternal();
                    },
                  ),

                  const SizedBox(height: 25),

                  // زر تسجيل الدخول
                  Obx(() {
                    return controller.isLoading.value
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: Colors.lightBlueAccent[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (controller.internalUsername.value.isEmpty ||
                              controller.internalPassword.value.isEmpty) {
                            Get.snackbar(
                              "تنبيه",
                              "يرجى ملء جميع الحقول",
                              backgroundColor: Colors.lightBlueAccent,
                            );
                            return;
                          }
                          await _loginInternal();
                        },
                        child: const Text("تسجيل الدخول"),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginInternal() async {
    try {
      final pharmacyId = controller.userId!; // uid الصيدلية

      bool success = await controller.loginInternal(pharmacyId: pharmacyId);

      if (success) {
        // بعد نجاح تسجيل الدخول للموظف، انتقل للهوم
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
