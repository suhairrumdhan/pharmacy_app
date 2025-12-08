import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_model.dart';

class AddMedicineController extends GetxController {
  final InventoryController inventoryController = Get.find();

  // Form controllers
  final nameController = TextEditingController();
  final scientificNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final quantityController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final minStockController = TextEditingController(text: '10');
  final supplierController = TextEditingController();
  final barcodeController = TextEditingController();
  final newCategoryController = TextEditingController();
  final unitsPerPackageController = TextEditingController();

  // Corrected Reactive state
  final expiryDate = Rx<DateTime>(DateTime.now().add(const Duration(days: 365)));
  final selectedCategory = Rx<String?>(null);
  final selectedUnit = Rx<UnitType>(UnitType.Tablet);
  final categories = <String>[].obs;
  final isLoadingCategories = true.obs;
  final sellByPiece = false.obs;
  final piecePriceCalculated = Rx<double?>(null);

  // Alternative syntax (also valid):
  // var expiryDate = Rx<DateTime>(DateTime.now().add(const Duration(days: 365)));
  // Rx<String?> selectedCategory = Rx<String?>(null);
  // Rx<UnitType> selectedUnit = Rx<UnitType>(UnitType.Tablet);
  // RxList<String> categories = <String>[].obs;
  // RxBool isLoadingCategories = true.obs;
  // RxBool sellByPiece = false.obs;
  // Rx<double?> piecePriceCalculated = Rx<double?>(null);

  // Get pharmacy ID
  String? get pharmacyId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();

    // Add listeners for piece price calculation
    unitsPerPackageController.addListener(_calculatePiecePrice);
    sellingPriceController.addListener(_calculatePiecePrice);
  }

  @override
  void onClose() {
    nameController.dispose();
    scientificNameController.dispose();
    descriptionController.dispose();
    purchasePriceController.dispose();
    quantityController.dispose();
    sellingPriceController.dispose();
    minStockController.dispose();
    supplierController.dispose();
    barcodeController.dispose();
    newCategoryController.dispose();
    unitsPerPackageController.dispose();
    super.onClose();
  }
  int? get unitsPerPackage {
    if (unitsPerPackageController.text.isEmpty) return null;
    return int.tryParse(unitsPerPackageController.text);
  }

  // Load categories from Firestore
  Future<void> _loadCategories() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();
        if (data != null && data['categories'] != null && data['categories'] is List) {
          List<dynamic> categoryList = data['categories'];
          categories.value = categoryList.map((category) => category.toString()).toList();
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // Add new category to Firestore
  Future<void> addNewCategory() async {
    if (newCategoryController.text.trim().isEmpty) return;

    String newCategory = newCategoryController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .update({
        'categories': FieldValue.arrayUnion([newCategory])
      });

      if (!categories.contains(newCategory)) {
        categories.add(newCategory);
      }
      selectedCategory.value = newCategory;
      newCategoryController.clear();

      Get.snackbar(
        'نجاح',
        'تم إضافة التصنيف الجديد بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إضافة التصنيف الجديد',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Calculate piece price
  void _calculatePiecePrice() {
    if (sellByPiece.value &&
        unitsPerPackageController.text.isNotEmpty &&
        sellingPriceController.text.isNotEmpty) {
      try {
        int units = int.parse(unitsPerPackageController.text);
        double sellingPrice = double.parse(sellingPriceController.text);
        if (units > 0 && sellingPrice > 0) {
          piecePriceCalculated.value = sellingPrice / units;
          return;
        }
      } catch (e) {
        // Continue to set to null
      }
    }
    piecePriceCalculated.value = null;
  }

  // Update expiry date
  void updateExpiryDate(DateTime date) {
    expiryDate.value = date;
  }

  // Update selected unit
  void updateSelectedUnit(UnitType? unit) {
    if (unit != null) {
      selectedUnit.value = unit;
    }
  }

  // Toggle sell by piece
  void toggleSellByPiece(bool value) {
    sellByPiece.value = value;
    if (value) {
      _calculatePiecePrice();
    } else {
      piecePriceCalculated.value = null;
    }
  }

  // Update selected category
  void updateSelectedCategory(String? category) {
    selectedCategory.value = category;
  }

  // Add medicine to inventory
  Future<void> addMedicine() async {
    try {
      // Data validation
      if (selectedUnit.value == null) {
        throw Exception('يرجى اختيار وحدة القياس');
      }

      // Convert data
      int quantity = int.parse(quantityController.text);
      double? purchasePrice;
      if (purchasePriceController.text.isNotEmpty) {
        purchasePrice = double.tryParse(purchasePriceController.text);
      }

      double sellingPrice = double.parse(sellingPriceController.text);

      int? unitsPerPackage;
      if (unitsPerPackageController.text.isNotEmpty) {
        unitsPerPackage = int.tryParse(unitsPerPackageController.text);
      }

      int? minStockLevel;
      if (minStockController.text.isNotEmpty) {
        minStockLevel = int.tryParse(minStockController.text);
      }

      String? scientificName = scientificNameController.text.trim();
      if (scientificName.isEmpty) {
        scientificName = null;
      }

      final newMedicine = Medicine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text,
        scientificName: scientificName,
        quantity: quantity,
        description: descriptionController.text.isEmpty ? null : descriptionController.text,
        category: selectedCategory.value,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        unit: selectedUnit.value,
        unitsPerPackage: unitsPerPackage,
        sellByPiece: sellByPiece.value,
        piecePrice: piecePriceCalculated.value,
        minStockLevel: minStockLevel,
        supplier: supplierController.text.isEmpty ? null : supplierController.text,
        expiryDate: expiryDate.value,
        barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
        lastUpdated: DateTime.now(),
      );

      // Add to inventory
      await inventoryController.addMedicine(newMedicine);

      // Show success message
      Get.snackbar(
        'نجاح',
        'تم إضافة الدواء بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // ✨ نظف الحقول بعد الإضافة
      clearForm();

      return Future.value();
    } catch (e) {
      throw Exception('حدث خطأ أثناء إضافة الدواء: $e');
    }
  }

  // Validate form
  bool validateForm() {
    if (nameController.text.isEmpty) return false;
    if (quantityController.text.isEmpty || int.tryParse(quantityController.text) == null) return false;
    if (sellingPriceController.text.isEmpty || double.tryParse(sellingPriceController.text) == null) return false;
    return true;
  }

  // Get unit name
  String getUnitName(UnitType unit) {
    switch (unit) {
      case UnitType.Tablet: return 'قرص';
      case UnitType.Capsule: return 'كبسولة';
      case UnitType.Syrup: return 'شراب';
      case UnitType.Drops: return 'قطرة';
      case UnitType.Bottle: return 'زجاجة';
      case UnitType.Ampoule: return 'أمبولة';
      case UnitType.Vial: return 'قارورة';
      case UnitType.Ointment: return 'مرهم';
      case UnitType.Cream: return 'كريم';
      case UnitType.Gel: return 'جيل';
      case UnitType.Spray: return 'بخاخ';
      case UnitType.Patch: return 'لصقة';
      case UnitType.Powder: return 'مسحوق';
      case UnitType.Sachet: return 'كيس';
      case UnitType.Suppository: return 'تحاميل';
      case UnitType.Inhaler: return 'استنشاق';
      case UnitType.Suspension: return 'معلق';
      case UnitType.Solution: return 'محلول';
      case UnitType.Lotion: return 'لوشن';
      case UnitType.Strip: return 'شريط';
      case UnitType.Tube: return 'أنبوب';
      default: return 'وحدة غير معروفة';
    }
  }

  // Clear all fields
  void clearForm() {
    nameController.clear();
    scientificNameController.clear();
    descriptionController.clear();
    purchasePriceController.clear();
    quantityController.clear();
    sellingPriceController.clear();
    minStockController.clear();
    supplierController.clear();
    barcodeController.clear();
    unitsPerPackageController.clear();
    selectedCategory.value = null;
    selectedUnit.value = UnitType.Tablet;
    sellByPiece.value = false;
    piecePriceCalculated.value = null;
    expiryDate.value = DateTime.now().add(const Duration(days: 365));
  }
}