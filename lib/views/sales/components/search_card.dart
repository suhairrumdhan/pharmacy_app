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

    // ✅ فوكس افتراضي بعد أول بناء (لكن باحترام allowAutoFocusSearch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.salesController.focusSearchIfAllowed();
    });

    // مزامنة النص مع searchQuery (بأمان)
    _searchQueryWorker = ever<String>(
      widget.salesController.searchQuery,
          (query) {
        if (!mounted) return;
        if (_textController.text != query) {
          _textController.text = query;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
        // ✅ لو الفراغ رجّع الفوكس (لكن بشرط السماح)
        if (query.isEmpty) {
          widget.salesController.focusSearchIfAllowed();
        }
      },
    );
  }


  void _performSearch(String query) {
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      widget.salesController.search(query);
    });
  }
  void _clearSearch() {
    widget.salesController.searchQuery.value = '';
    widget.salesController.searchResults.clear();
    _textController.clear();
    _lastSearchQuery = '';
    widget.salesController.focusSearchIfAllowed();
  }

  Future<void> _handleSearchSubmitted(String value) async {
    if (value.isEmpty) {
      widget.salesController.focusSearchIfAllowed();
      return;
    }

    final results = widget.salesController.searchResults;

    // لو نتيجة واحدة (مش باركود) نخلي Enter يضيف مباشرة
    if (results.length == 1 && !widget.salesController.isBarcodeInput(value)) {
      final med = results.first;

      // ✅ Refund mode لازم فاتورة أصل
      if (widget.salesController.refundMode.value &&
          widget.salesController.originalSale.value == null) {
        Get.rawSnackbar(
          title: 'مطلوب',
          message: 'حمّل الفاتورة الأصلية أولاً قبل إضافة أصناف للترجيع',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        widget.salesController.focusSearchIfAllowed();
        return;
      }

      // ✅ بيع/ترجيع
      if (widget.salesController.refundMode.value) {
        await widget.salesController.addMedicineToRefund(med);
      } else {
        widget.salesController.addMedicineToSale(med);
      }

      _clearSearch();
    }

    widget.salesController.focusSearchIfAllowed();
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
                        onTap: () {
                          // ✅ أول ما المستخدم يضغط البحث نرجع السماح للفوكس الإجباري
                          widget.salesController.resumeAutoFocus();
                        },
                        onEditingComplete: () {
                          // ✅ بعد ما يكمل الكتابة نخلي البحث يحتفظ بالفوكس لو مسموح
                          widget.salesController.focusSearchIfAllowed();
                        },
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