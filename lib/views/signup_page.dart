import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.put(AuthController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Registration"),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Pharmacy Registration",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // معلومات الحساب الأساسية
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Account Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  onChanged: (value) => controller.email.value = value,
                ),
                const SizedBox(height: 15),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  onChanged: (value) => controller.password.value = value,
                ),

                const SizedBox(height: 25),

                // معلومات الصيدلية
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Pharmacy Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Pharmacy Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_pharmacy),
                  ),
                  onChanged: (value) => controller.pharmacyName.value = value,
                ),
                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Owner Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (value) => controller.ownerName.value = value,
                ),
                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "License Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  onChanged: (value) => controller.licenseNumber.value = value,
                ),
                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => controller.phoneNumber.value = value,
                ),
                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                  onChanged: (value) => controller.address.value = value,
                ),

                const SizedBox(height: 25),
                Obx(() {
                  return controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _validateForm(controller) ? controller.signUpPharmacy : null,
                    child: const Text(
                      "Register Pharmacy",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Get.to(() => const LoginPage()),
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _validateForm(AuthController controller) {
    return controller.email.value.isNotEmpty &&
        controller.password.value.isNotEmpty &&
        controller.pharmacyName.value.isNotEmpty &&
        controller.ownerName.value.isNotEmpty &&
        controller.licenseNumber.value.isNotEmpty &&
        controller.phoneNumber.value.isNotEmpty &&
        controller.address.value.isNotEmpty;
  }
}