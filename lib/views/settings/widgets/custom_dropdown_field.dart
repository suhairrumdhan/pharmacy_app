import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String? errorText;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: value,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      icon,
                      color: hasError
                          ? Colors.red.shade400
                          : Colors.blue.shade600,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  icon: Icon(
                    Iconsax.arrow_down_1,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  items: items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: onChanged,
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