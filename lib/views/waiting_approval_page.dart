import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'home_page.dart';

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Waiting for Approval"),
        backgroundColor: Colors.orange[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions,
                size: 80,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 20),
              const Text(
                "Your pharmacy account is pending approval",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                "We have received your registration request and it is under review. "
                    "You will be notified once approved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // ---------- زر التحقق ----------
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () async {
                  bool approved = await controller.checkApprovalStatus();

                  if (approved) {
                    Get.offAll(() => const HomePage());
                  } else {
                    Get.snackbar(
                      "Still Pending",
                      "Your account is still waiting for approval",
                      backgroundColor: Colors.orange[200],
                      colorText: Colors.black,
                    );
                  }
                },
                child: const Text(
                  "Check Approval Status",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: controller.logout,
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
