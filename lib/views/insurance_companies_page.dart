import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InsuranceCompaniesPage extends StatelessWidget {
  const InsuranceCompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'شركات التأمين',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // هنا يمكنك إضافة محتوى صفحة شركات التأمين
        ],
      ),
    );
  }
}