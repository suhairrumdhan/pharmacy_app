import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'sign_up/signup_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.put(AuthController());

    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "تسجيل الدخول",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // حقل البريد الإلكتروني
              TextField(
                decoration: const InputDecoration(
                  labelText: "البريد الإلكتروني",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.email.value = value,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 15),

              // حقل كلمة المرور
              TextField(
                decoration: const InputDecoration(
                  labelText: "كلمة المرور",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => controller.password.value = value,
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
                    // ✅ **تعديل: استدعاء دالة login المعدلة**
                    onPressed: () async {
                      // التحقق من ملء الحقول
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
    );
  }
}