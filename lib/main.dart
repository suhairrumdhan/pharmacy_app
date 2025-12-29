// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/login_page.dart';
import 'package:window_manager/window_manager.dart';

// ✅ استيراد الـ Controllers
import 'controllers/auth_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/insurance_company_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Window Manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
  );

  // اجعل التطبيق يفتح ماكسمايز
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize(); // ← هنا التكبير تلقائي
    await windowManager.show();
    await windowManager.focus();
  });

  // ✅ تهيئة Controllers الأساسية هنا
  _initializeControllers();

  runApp(const MyApp());
}

// ✅ دالة لتهيئة Controllers
void _initializeControllers() {
  print('🚀 بدء تهيئة Controllers...');

  try {
    // 1. AuthController (الأساسي)
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
      print('✅ تم تهيئة AuthController');
    }

    // 2. InventoryController (مطلوب في SalesPage)
    if (!Get.isRegistered<InventoryController>()) {
      Get.put(InventoryController(), permanent: true);
      print('✅ تم تهيئة InventoryController');
    }

    // 3. InsuranceCompanyController (مطلوب في SalesPage)
    if (!Get.isRegistered<InsuranceCompanyController>()) {
      Get.put(InsuranceCompanyController(), permanent: true);
      print('✅ تم تهيئة InsuranceCompanyController');
    }

    print('🎉 تم تهيئة جميع Controllers بنجاح');
  } catch (e, stackTrace) {
    print('❌ خطأ في تهيئة Controllers: $e');
    print('📜 Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Desktop System',
      home: const LoginPage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),

      // منع التكبير والتصغير بالماوس
      builder: (context, child) {
        return Scaffold(
          body: GestureDetector(
            onScaleStart: (details) {},
            onScaleUpdate: (details) {},
            onScaleEnd: (details) {},
            child: child,
          ),
        );
      },
    );
  }
}