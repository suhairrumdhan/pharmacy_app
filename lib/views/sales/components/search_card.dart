import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../controllers/sales_controller.dart';
import '../../../models/inventory_model.dart';
import '../dialogs/barcode_scanner_dialog.dart';

class SearchCard extends StatefulWidget {
  final SalesController salesController;
  final Function(Medicine)? onMedicineAdded;

  const SearchCard({
    super.key,
    required this.salesController,
    this.onMedicineAdded,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  late TextEditingController _textController;
  late Worker _searchQueryWorker;

  Timer? _debounceTimer;
  String _lastSearchQuery = '';


  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // التركيز التلقائي بعد أول بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.salesController.searchFocusNode.requestFocus();
    });

    // 🔒 ضمان بقاء التركيز دائمًا على حقل البحث
    widget.salesController.searchFocusNode.addListener(() {
      if (!widget.salesController.searchFocusNode.hasFocus && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.salesController.searchFocusNode.requestFocus();
          }
        });
      }
    });

    // مزامنة النص مع searchQuery (بأمان)
    _searchQueryWorker = ever<String>(
      widget.salesController.searchQuery,
          (query) {
        if (!mounted) return;
        if (_textController.text != query) {
          _textController.text = query;
        }
      },
    );
  }



  void _performSearch(String query) {
    // إذا كان البحث نفسه السابق، لا تكرر
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;

    // إلغاء البحث السابق
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    // بحث فوري لكن مع debounce بسيط
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      widget.salesController.search(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    // إذا كان باركود (8 أرقام أو أكثر)
    if (RegExp(r'^[0-9]{8,}$').hasMatch(query)) {
      await widget.salesController.handleSmartSearch(query);
    } else {
      // بحث عادي فوري
      await widget.salesController.searchMedicines(query);
    }
  }

  void _clearSearch() {
    // طباعة للتحقق
    print('🧹 SearchCard: تنظيف البحث يدوياً');

    // تنظيف من الـ Controller أولاً
    widget.salesController.searchQuery.value = '';
    widget.salesController.searchResults.clear();

    // ثم تنظيف الحقل المحلي
    _textController.clear();

    _lastSearchQuery = '';

    // إعادة التركيز على الحقل
    widget.salesController.searchFocusNode.requestFocus();
  }
  Future<void> _handleBarcodeScan() async {
    try {
      // مسح البحث القديم أولاً
      _clearSearch();

      // فتح الماسح الضوئي
      final barcode = await showDialog<String?>(
        context: context,
        builder: (_) => BarcodeScannerDialog(salesController: widget.salesController),
        barrierDismissible: false,
      );

      if (barcode != null && barcode.isNotEmpty) {
        // البحث تلقائياً عن الباركود
        _textController.text = barcode;
        widget.salesController.searchQuery.value = barcode;
        await _executeSearch(barcode);
      }
    } finally {
      // العودة للتركيز على حقل البحث
      widget.salesController.searchFocusNode.requestFocus();
    }
  }

  void _handleSearchSubmitted(String value) {
    if (value.isNotEmpty) {
      final results = widget.salesController.searchResults;

      if (results.length == 1 && !widget.salesController.isBarcodeInput(value)) {
        widget.salesController.addMedicineToSale(results.first);
        _clearSearch();
      }
    }

    // ضمان إعادة التركيز
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.salesController.searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchQueryWorker.dispose();
    _textController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, right: 8), // تعديل المسافة حسب الحاجة
                    child: Icon(
                      Iconsax.search_normal,  // أو أي أيقونة أخرى من Iconsax
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: TextField(
                        focusNode: widget.salesController.searchFocusNode,
                        controller: _textController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم، الباركود أو الاسم العلمي...',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: _textController.text.isEmpty
                              ? IconButton(
                            icon: Icon(
                              Iconsax.close_circle,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                            tooltip: 'مسح البحث',
                          )
                              : null,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          _performSearch(value);
                        },

                        onSubmitted: _handleSearchSubmitted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // مؤشر حالة البحث
              Obx(() => widget.salesController.isLoading.value
                  ? LinearProgressIndicator(
                backgroundColor: Colors.blue.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                minHeight: 2,
              )
                  : const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}