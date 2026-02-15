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
  final AuthController controller = Get.find<AuthController>();

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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black26),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "تسجيل دخول المالك",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        focusNode: emailFocus,
                        decoration: const InputDecoration(
                          labelText: "البريد الإلكتروني",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => controller.email.value = value.trim(),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(passwordFocus);
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        focusNode: passwordFocus,
                        obscureText: !showPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: "كلمة المرور",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => showPassword = !showPassword),
                          ),
                        ),
                        onChanged: (value) => controller.password.value = value,
                        onSubmitted: (_) => controller.loginOwner(),
                      ),

                      const SizedBox(height: 25),

                      Obx(() {
                        final loading = controller.isAuthLoading.value;
                        return loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                              backgroundColor: Colors.lightBlueAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: loading ? null : controller.loginOwner,
                            child: const Text("تسجيل الدخول"),
                          ),
                        );
                      }),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () => Get.to(() => SignUpPage()),
                        child: const Text("ليس لديك حساب؟ قم بالتسجيل"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
