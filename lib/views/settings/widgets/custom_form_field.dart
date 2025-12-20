import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CustomFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? errorText;
  final bool isPassword;
  final bool readOnly;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final int maxLines;

  const CustomFormField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.errorText,
    this.isPassword = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasError ? Colors.red.shade700 : Colors.blue.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasError
                        ? Colors.red.shade100.withOpacity(0.4)
                        : Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: isPassword,
                readOnly: readOnly,
                keyboardType: keyboardType,
                maxLines: maxLines,
                onTap: onTap,
                cursorColor: Colors.blue.shade600,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    icon,
                    color: hasError
                        ? Colors.red.shade400
                        : Colors.blue.shade600,
                    size: 20,
                  ),
                  hintText: 'أدخل هنا...',
                  hintStyle: TextStyle(
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  suffixIcon: isPassword
                      ? IconButton(
                    icon: Icon(
                      Iconsax.eye,
                      color: Colors.blue.shade600.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () {},
                  )
                      : null,
                ),
              ),
            ),
          ),
        ),

        // 🔴 رسالة الخطأ
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}