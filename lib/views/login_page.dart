import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'sign_up/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController controller = Get.put(AuthController());

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  bool showPassword = false;

  @override
  void dispose() {
    emailFocus.dispose();
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
                image: AssetImage('assets/images/bg.jpg'), // ضع هنا مسار صورتك
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
                color: Colors.white.withOpacity(0.9), // صندوق شبه شفاف
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black26)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "تسجيل الدخول",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // البريد الإلكتروني
                  TextField(
                    focusNode: emailFocus,
                    decoration: const InputDecoration(
                      labelText: "البريد الإلكتروني",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => controller.email.value = value,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(passwordFocus);
                    },
                  ),

                  const SizedBox(height: 15),

                  // كلمة المرور
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
                    onChanged: (value) => controller.password.value = value,
                    onSubmitted: (_) async {
                      if (controller.email.value.isEmpty ||
                          controller.password.value.isEmpty) {
                        Get.snackbar(
                          "تنبيه",
                          "يرجى ملء جميع الحقول",
                          backgroundColor: Colors.lightBlueAccent,
                        );
                        return;
                      }
                      await controller.login();
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
                          if (controller.email.value.isEmpty ||
                              controller.password.value.isEmpty) {
                            Get.snackbar(
                              "تنبيه",
                              "يرجى ملء جميع الحقول",
                              backgroundColor: Colors.lightBlueAccent,
                            );
                            return;
                          }

                          await controller.login();
                        },
                        child: const Text("تسجيل الدخول"),
                      ),
                    );
                  }),

                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Get.to(() => const SignUpPage()),
                    child: const Text("ليس لديك حساب؟ قم بالتسجيل"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
