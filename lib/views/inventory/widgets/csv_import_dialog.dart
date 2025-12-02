import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CSVImportDialog extends StatefulWidget {
  final List<dynamic> headers;

  const CSVImportDialog({super.key, required this.headers});

  @override
  State<CSVImportDialog> createState() => _CSVImportDialogState();
}

class _CSVImportDialogState extends State<CSVImportDialog> {
  final Map<String, int> mapping = {};

  final List<String> systemFields = [
    "name",
    "category",
    "purchasePrice",
    "sellingPrice",
    "quantity",
    "barcode"
  ];

  final Map<String, String> displayNames = {
    "name": "اسم الدواء",
    "category": "الفئة",
    "purchasePrice": "سعر الشراء",
    "sellingPrice": "سعر البيع",
    "quantity": "الكمية",
    "barcode": "الباركود",
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("ربط الأعمدة"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: systemFields.map((field) {
          return Row(
            children: [
              Expanded(child: Text(displayNames[field]!)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: mapping[field],
                hint: const Text("اختر"),
                items: List.generate(widget.headers.length, (i) {
                  return DropdownMenuItem(
                    value: i,
                    child: Text(widget.headers[i].toString()),
                  );
                }),
                onChanged: (v) {
                  setState(() => mapping[field] = v!);
                },
              ),
            ],
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () {
            if (mapping["name"] == null) {
              Get.snackbar("خطأ", "يجب اختيار عمود اسم الدواء");
              return;
            }
            Get.back(result: mapping);
          },
          child: const Text("موافق"),
        ),
      ],
    );
  }
}
