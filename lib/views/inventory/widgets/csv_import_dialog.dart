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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Important notes section
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ملاحظات هامة:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  const Text("• حقل 'الاسم' (name) مطلوب للاستيراد"),
                  const Text("• حقل 'الاسم العلمي' (scientificName) اختياري"),
                  Text("• إذا لم تختار 'الاسم العلمي'، سيتم استخدام الاسم العادي",
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text("ملف CSV يحتوي على ${widget.headers.length} عمود",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mapping fields
            ...systemFields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
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
                        setState(() {
                          if (v != null) {
                            mapping[field] = v;
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
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