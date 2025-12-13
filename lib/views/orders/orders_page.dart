import 'package:flutter/cupertino.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // شريط الإحصائيات السريعة
          //_buildQuickStats(),
          const SizedBox(height: 24),

          // شريط الأدوات
         // _buildToolbar(context),
          const SizedBox(height: 24),

        ],
      ),
    );
  }
}
