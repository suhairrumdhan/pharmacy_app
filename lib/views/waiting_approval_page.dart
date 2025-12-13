import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'home_page.dart';
import '../services/firestore_service.dart'; // ← أضف هذا الاستيراد

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find();
    final FirestoreService firestoreService = FirestoreService(); // ← أنشئ كائن

    // تحديد الألوان الرئيسية
    final Color primaryColor = Colors.orange[700]!;
    final Color primaryContrastColor = Colors.white;
    final Color backgroundColor = Colors.white;
    final Color textPrimaryColor = Colors.grey[800]!;
    final Color textSecondaryColor = Colors.grey[600]!;
    final Color buttonTextColor = primaryContrastColor;
    final Color linkColor = primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("انتظر حتى يتم الموافقة على طلب التسجيل"),
        backgroundColor: primaryColor,
        foregroundColor: primaryContrastColor,
        elevation: 2,
      ),
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // ← تغيير هنا
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.pending_actions,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                "حالة التسجيل معلقة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "لقد استلمنا طلب تسجيل صيدليتك "
                    "سنعلمك عند قبول الطلب",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondaryColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),

              // ---------- زر التحقق ----------
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: primaryColor,
              //     foregroundColor: buttonTextColor,
              //     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              //     textStyle: const TextStyle(
              //       fontSize: 16,
              //       fontWeight: FontWeight.w600,
              //     ),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     elevation: 2,
              //     shadowColor: Colors.black.withOpacity(0.1),
              //   ),
              //   // onPressed: () async {
              //   //   Get.dialog(
              //   //     Center(
              //   //       child: CircularProgressIndicator(color: Colors.orange[700]),
              //   //     ),
              //   //     barrierDismissible: false,
              //   //   );
              //   //
              //   //   try {
              //   //     // استخدم FirestoreService مباشرة
              //   //     final user = FirebaseAuth.instance.currentUser;
              //   //     if (user == null) {
              //   //       Get.back();
              //   //       Get.snackbar("خطأ", "لا يوجد مستخدم مسجل", backgroundColor: Colors.red);
              //   //       return;
              //   //     }
              //   //
              //   //     final result = await firestoreService.checkApprovalStatus(user.uid);
              //   //     Get.back();
              //   //
              //   //     // التحقق من null بطريقة آمنة
              //   //     bool approved = result != null &&
              //   //         result['exists'] == true &&
              //   //         result['status'] == "approved";
              //   //
              //   //     if (approved) {
              //   //       bool reloginSuccess = await controller.reLoginAfterApproval();
              //   //       if (reloginSuccess) {
              //   //         await Future.delayed(Duration(milliseconds: 500));
              //   //         Get.offAll(() => const HomePage());
              //   //       } else {
              //   //         Get.snackbar(
              //   //           "تنبيه",
              //   //           "تمت الموافقة ولكن هناك مشكلة في التحميل",
              //   //           backgroundColor: Colors.orange,
              //   //         );
              //   //       }
              //   //     } else {
              //   //       Get.snackbar(
              //   //         "الطلب معلق",
              //   //         "طلبك قيد المعالجة",
              //   //         backgroundColor: Colors.orange[100],
              //   //         colorText: Colors.grey[800]!,
              //   //       );
              //   //     }
              //   //   } catch (e) {
              //   //     Get.back();
              //   //     Get.snackbar("خطأ", e.toString(), backgroundColor: Colors.red);
              //   //   }
              //   // },
              //   child: const Text("التحقق من حالة الطلب"),
              // ),

              const SizedBox(height: 20),

              // ---------- زر تسجيل الخروج ----------
              TextButton(
                onPressed: controller.logout,
                style: TextButton.styleFrom(
                  foregroundColor: linkColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text("تسجيل الخروج"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}