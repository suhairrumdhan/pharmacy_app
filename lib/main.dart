import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/login_page.dart';
import 'package:window_manager/window_manager.dart';

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

  runApp(const MyApp());
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
