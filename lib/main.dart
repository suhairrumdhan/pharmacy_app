// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'controllers/finance_controller.dart';
import 'firebase_options.dart';
import 'views/login_page.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/auth_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/insurance_company_controller.dart';
import 'controllers/purchase_controller.dart';
import 'controllers/supplier_controller.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await windowManager.ensureInitialized();

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Desktop System',
      initialBinding: InitialBinding(),
      home: const LoginPage(),
      theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
    ),

    );
  }
}
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<InventoryController>(() => InventoryController(), fenix: true);
    Get.lazyPut<InsuranceCompanyController>(
          () => InsuranceCompanyController(),
      fenix: true,
    );
    Get.lazyPut<FinanceController>(() => FinanceController());
    Get.lazyPut<SupplierController>(() => SupplierController(), fenix: true);
    Get.lazyPut<PurchaseController>(() => PurchaseController(), fenix: true);
  }
}