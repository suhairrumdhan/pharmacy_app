import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
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

  // Reactive state
  final expiryDate = Rx<DateTime>(DateTime.now().add(const Duration(days: 365)));
  final selectedCategory = Rx<String?>(null);
  final selectedUnit = Rx<UnitType>(UnitType.Tablet);
  final categories = <String>[].obs;
  final isLoadingCategories = true.obs;
  final sellByPiece = false.obs;
  final piecePriceCalculated = Rx<double?>(null);
  final isAddingMedicine = false.obs;

  // Image related variables
  final medicineImage = Rx<File?>(null);
  final medicineImageUrl = Rx<String?>(null);
  final isUploadingImage = false.obs;
  final ImagePicker _imagePicker = ImagePicker();
  // متغيرات الموردين
  final RxList<Map<String, dynamic>> suppliers = <Map<String, dynamic>>[].obs;
  final RxString selectedSupplierId = RxString('');
  final RxString selectedSupplierName = RxString('');
  final RxBool isLoadingSuppliers = false.obs;

  final isEditMode = false.obs;
  String? editingMedicineId;
  bool _initialized = false;

  // Get pharmacy ID
  String? get pharmacyId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    loadSuppliers(); // ← أضف هذا السطر

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


  void init(Medicine? medicine) {
    if (_initialized) return;
    _initialized = true;

    if (medicine == null) {
      isEditMode.value = false;
      editingMedicineId = null;
      clearForm();
      return;
    }

    isEditMode.value = true;
    editingMedicineId = medicine.id;

    nameController.text = medicine.name;
    scientificNameController.text = medicine.scientificName;
    descriptionController.text = medicine.description ?? '';
    quantityController.text = medicine.quantity.toString();
    minStockController.text = medicine.minStockLevel?.toString() ?? '';
    purchasePriceController.text = medicine.purchasePrice?.toString() ?? '';
    sellingPriceController.text = medicine.sellingPrice?.toString() ?? '';
    supplierController.text = medicine.supplier ?? '';
    barcodeController.text = medicine.barcode ?? '';

    selectedCategory.value = medicine.category;
    selectedUnit.value = medicine.unit ?? UnitType.Tablet;

    unitsPerPackageController.text = medicine.unitsPerPackage?.toString() ?? '';
    sellByPiece.value = medicine.sellByPiece;
    piecePriceCalculated.value = medicine.piecePrice;

    expiryDate.value = medicine.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    medicineImageUrl.value = medicine.imageUrl;
  }

  int? get unitsPerPackage {
    if (unitsPerPackageController.text.isEmpty) return null;
    return int.tryParse(unitsPerPackageController.text);
  }

  // دالة لتحميل الموردين من Firestore
  Future<void> loadSuppliers() async {
    try {
      if (pharmacyId == null) {
        print('❌ No pharmacy ID available');
        return;
      }

      isLoadingSuppliers.value = true;
      suppliers.clear();

      print('📡 Loading suppliers for pharmacy: $pharmacyId');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('suppliers')
          .orderBy('name')
          .get();

      print('📊 Found ${querySnapshot.docs.length} suppliers');

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        suppliers.add({
          'id': doc.id,
          'name': data['name']?.toString() ?? 'بدون اسم',
          'phone': data['phone']?.toString() ?? '',
          'address': data['address']?.toString() ?? '',
          'contactPerson': data['contactPerson']?.toString() ?? '',
        });
      }

      // إضافة خيار "بدون مورد"
      suppliers.insert(0, {
        'id': '',
        'name': 'بدون مورد',
        'phone': '',
        'address': '',
        'contactPerson': '',
      });

      print('✅ Loaded ${suppliers.length} suppliers total');

    } catch (e, stackTrace) {
      print('❌ Error loading suppliers: $e');
      print('📝 Stack trace: $stackTrace');

      Get.snackbar(
        'تحذير',
        'تعذر تحميل قائمة الموردين. يمكنك إدخال اسم المورد يدوياً.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  // دالة لتحديث المورد المختار
  void updateSelectedSupplier(String? supplierId) {
    if (supplierId == null || supplierId.isEmpty) {
      selectedSupplierId.value = '';
      selectedSupplierName.value = '';
      supplierController.clear();
      return;
    }

    selectedSupplierId.value = supplierId;

    // البحث عن المورد في القائمة
    final selectedSupplier = suppliers.firstWhere(
          (supplier) => supplier['id'] == supplierId,
      orElse: () => {'id': '', 'name': '', 'phone': '', 'address': '', 'contactPerson': ''},
    );

    selectedSupplierName.value = selectedSupplier['name'] ?? '';
    supplierController.text = selectedSupplier['name'] ?? '';
  }

  // Load categories from Firestore
  Future<void> _loadCategories() async {
    try {
      if (pharmacyId == null) {
        throw Exception('غير مسجل دخول. يرجى تسجيل الدخول أولاً');
      }

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
      Get.snackbar(
        'خطأ في تحميل التصنيفات',
        'تعذر تحميل قائمة التصنيفات. ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // Add new category to Firestore
  Future<void> addNewCategory() async {
    try {
      if (newCategoryController.text.trim().isEmpty) {
        throw Exception('يرجى إدخال اسم التصنيف الجديد');
      }

      if (pharmacyId == null) {
        throw Exception('غير مسجل دخول. يرجى تسجيل الدخول أولاً');
      }

      String newCategory = newCategoryController.text.trim();

      // Check if category already exists
      if (categories.contains(newCategory)) {
        throw Exception('هذا التصنيف موجود بالفعل');
      }

      // Validate category name
      if (newCategory.length < 2) {
        throw Exception('اسم التصنيف يجب أن يكون على الأقل حرفين');
      }

      if (newCategory.length > 50) {
        throw Exception('اسم التصنيف طويل جداً (الحد الأقصى 50 حرف)');
      }

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
        'تم إضافة التصنيف "$newCategory" بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ في إضافة التصنيف',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Function to pick image from files (for desktop)
  Future<void> pickImageFromFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Check file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          throw Exception('حجم الملف كبير جداً. الحد الأقصى 5MB');
        }

        // Check if path is not null
        if (file.path != null) {
          medicineImage.value = File(file.path!);
          medicineImageUrl.value = null;

          Get.snackbar(
            'تم اختيار الصورة',
            'تم اختيار الصورة بنجاح',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          throw Exception('تعذر الوصول إلى الملف المحدد');
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ في اختيار الصورة',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Function to pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        medicineImage.value = File(pickedFile.path);
        medicineImageUrl.value = null;

        Get.snackbar(
          'تم التقاط الصورة',
          'تم التقاط الصورة بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ في الكاميرا',
        'تعذر الوصول إلى الكاميرا: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Upload image to Firebase Storage with progress tracking
  Future<String?> uploadImageToFirebase() async {
    if (medicineImage.value == null) {
      return null;
    }

    try {
      isUploadingImage.value = true;

      if (pharmacyId == null) {
        throw Exception('غير مسجل دخول. يرجى تسجيل الدخول أولاً');
      }

      final File imageFile = medicineImage.value!;

      // Generate unique file name
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_getFileName(imageFile.path)}';

      // Create reference to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('medicine_images')
          .child(pharmacyId!)
          .child(fileName);

      // Determine content type
      final String extension = imageFile.path.split('.').last.toLowerCase();
      final String contentType = _getContentType(extension);

      // Metadata for the file
      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': pharmacyId!,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': imageFile.path.split('/').last,
        },
      );

      // Create upload task
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        metadata,
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      });

      // Wait for upload to complete
      await uploadTask;

      // Check if upload was successful
      if (uploadTask.snapshot.state == TaskState.success) {
        // Get download URL
        final String downloadUrl = await storageRef.getDownloadURL();

        // Store the URL locally
        medicineImageUrl.value = downloadUrl;

        // Clear the local file reference
        medicineImage.value = null;

        isUploadingImage.value = false;

        Get.snackbar(
          'تم رفع الصورة',
          'تم رفع الصورة بنجاح إلى السحابة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        return downloadUrl;
      } else {
        throw Exception('فشل رفع الملف: ${uploadTask.snapshot.state}');
      }
    } catch (e) {
      isUploadingImage.value = false;

      print('Error uploading image: $e');
      Get.snackbar(
        'خطأ في رفع الصورة',
        'تعذر رفع الصورة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return null;
    }
  }

  // Helper function to get file name without path
  String _getFileName(String path) {
    return path.split('/').last;
  }

  // Helper function to get content type
  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImageFromFirebase(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.path.split('/o/')[1].split('?')[0];
      final decodedPath = Uri.decodeComponent(path);

      final Reference storageRef = FirebaseStorage.instance.ref().child(decodedPath);

      await storageRef.delete();

      Get.snackbar(
        'تم الحذف',
        'تم حذف الصورة بنجاح من السحابة',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error deleting image: $e');
      Get.snackbar(
        'خطأ في حذف الصورة',
        'تعذر حذف الصورة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Remove image
  void removeImage() {
    // If there's a URL, it means the image is already uploaded
    if (medicineImageUrl.value != null) {
      medicineImageUrl.value = null;
    }

    // Clear local file
    medicineImage.value = null;

    Get.snackbar(
      'تم',
      'تم إزالة الصورة',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
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

  // Validate barcode
  Future<String?> _validateBarcode(String barcode) async {
    try {
      // Check if barcode is not empty
      if (barcode.trim().isEmpty) {
        return null; // Barcode is optional
      }


      // Check if pharmacy ID exists
      if (pharmacyId == null) {
        throw Exception('غير مسجل دخول. يرجى تسجيل الدخول أولاً');
      }

      // Check if barcode already exists in Firebase
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('medicines')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('الباركود "$barcode" مستخدم بالفعل لصنف آخر');
      }

      return barcode;
    } catch (e) {
      rethrow;
    }
  }

  // Validate all required fields
  Map<String, String> validateRequiredFields() {
    final errors = <String, String>{};

    // Validate medicine name
    final name = nameController.text.trim();
    if (name.isEmpty) {
      errors['name'] = 'يرجى إدخال اسم الدواء';
    } else if (name.length < 2) {
      errors['name'] = 'اسم الدواء قصير جداً. يجب أن يحتوي على حرفين على الأقل';
    }

    // Validate quantity
    final quantityText = quantityController.text.trim();
    // Validate quantity - only digits allowed
    if (quantityText.isEmpty) {
      errors['quantity'] = 'يرجى إدخال كمية الدواء';
    } else if (!RegExp(r'^\d+$').hasMatch(quantityText)) {
      errors['quantity'] = 'الكمية يجب أن تحتوي على أرقام فقط بدون أحرف أو رموز';
    } else {
      final quantity = int.parse(quantityText);
      if (quantity <= 0) {
        errors['quantity'] = 'الكمية يجب أن تكون أكبر من صفر';
      } else if (quantity > 1000000) {
        errors['quantity'] = 'الكمية كبيرة جدًا. الحد الأقصى المسموح به هو 1,000,000';
      }
    }

    // Validate selling price
    // Validate selling price - digits and decimal only
    final sellingPriceText = sellingPriceController.text.trim();
    if (sellingPriceText.isEmpty) {
      errors['sellingPrice'] = 'يرجى إدخال سعر البيع';
    } else if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(sellingPriceText)) {
      errors['sellingPrice'] = 'سعر البيع يجب أن يحتوي على أرقام فقط ويمكن أن يحتوي على فاصلة عشرية واحدة';
    } else {
      final sellingPrice = double.parse(sellingPriceText);
      if (sellingPrice <= 0) {
        errors['sellingPrice'] = 'سعر البيع يجب أن يكون أكبر من صفر';
      } else if (sellingPrice > 1000000) {
        errors['sellingPrice'] = 'سعر البيع كبير جدًا. الحد الأقصى المسموح به هو 1,000,000';
      }
    }

    // Validate purchase price (optional)
    // Validate purchase price (optional) - digits and decimal only
    final purchasePriceText = purchasePriceController.text.trim();
    if (purchasePriceText.isNotEmpty) {
      if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(purchasePriceText)) {
        errors['purchasePrice'] = 'سعر الشراء يجب أن يحتوي على أرقام فقط ويمكن أن يحتوي على فاصلة عشرية واحدة';
      } else {
        final purchasePrice = double.parse(purchasePriceText);
        if (purchasePrice < 0) {
          errors['purchasePrice'] = 'سعر الشراء يجب أن يكون أكبر من صفر';
        } else if (purchasePrice > 1000000) {
          errors['purchasePrice'] = 'سعر الشراء كبير جدًا. الحد الأقصى المسموح به هو 1,000,000';
        }
        else if (purchasePrice == 0) {
          errors['purchasePrice'] = 'أدخل سعر الشراء';
        }
      }
    }


    // Validate units per package (if sell by piece is enabled)

// Validate units per package (if sell by piece) - only digits
    if (sellByPiece.value) {
      final unitsText = unitsPerPackageController.text.trim();
      if (unitsText.isEmpty) {
        errors['unitsPerPackage'] = 'يرجى إدخال عدد الوحدات في العبوة عند البيع بالقطعة';
      } else if (!RegExp(r'^\d+$').hasMatch(unitsText)) {
        errors['unitsPerPackage'] = 'عدد الوحدات يجب أن يحتوي على أرقام فقط بدون أحرف أو رموز';
      } else {
        final units = int.parse(unitsText);
        if (units <= 0) {
          errors['unitsPerPackage'] = 'عدد الوحدات يجب أن يكون أكبر من صفر';
        } else if (units > 10000) {
          errors['unitsPerPackage'] = 'عدد الوحدات كبير جدًا. الحد الأقصى المسموح به هو 10,000';
        }
      }
    }

    // Validate expiry date
    if (expiryDate.value.isBefore(DateTime.now())) {
      errors['expiryDate'] = 'تاريخ انتهاء الصلاحية يجب أن يكون في المستقبل';
    }

    return errors;
  }

  // Add medicine to inventory with proper error handling
  Future<void> addMedicine() async {
    try {
      // Start loading
      isAddingMedicine.value = true;

      // Validate all required fields
      final fieldErrors = validateRequiredFields();
      if (fieldErrors.isNotEmpty) {
        final errorMessage = fieldErrors.entries
            .map((e) => '• ${e.value}')
            .join('\n');
        throw Exception('يوجد أخطاء في البيانات:\n$errorMessage');
      }

      // Validate barcode
      String? barcode;
      if (barcodeController.text.trim().isNotEmpty) {
        barcode = await _validateBarcode(barcodeController.text.trim());
      }

      // Check pharmacy ID
      if (pharmacyId == null) {
        throw Exception('غير مسجل دخول. يرجى تسجيل الدخول أولاً');
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

      // تحديد المورد
      String? supplier;
      String? supplierIdForUpdate;

      if (selectedSupplierId.value.isNotEmpty) {
        // استخدام المورد المختار من القائمة
        supplier = selectedSupplierName.value;
        supplierIdForUpdate = selectedSupplierId.value;
      } else if (supplierController.text.trim().isNotEmpty) {
        // استخدام المورد المدخل يدوياً
        supplier = supplierController.text.trim();
      }

      // Upload image if exists
      String? imageUrl;
      if (medicineImage.value != null) {
        imageUrl = await uploadImageToFirebase();
        if (imageUrl == null) {
          Get.snackbar(
            'تنبيه',
            'تم إضافة الدواء بدون صورة بسبب خطأ في الرفع',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      } else if (medicineImageUrl.value != null) {
        imageUrl = medicineImageUrl.value;
      }

      // Generate medicine ID
      final String medicineId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create medicine object
      final newMedicine = Medicine(
        id: medicineId,
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
        supplier: supplier,
        expiryDate: expiryDate.value,
        barcode: barcode,
        imageUrl: imageUrl,
        lastUpdated: DateTime.now(),
      );

      // Add to inventory
      await inventoryController.addMedicine(newMedicine);

      // ⬇️⬇️⬇️ **إضافة الدواء إلى قائمة الأدوية للمورد (إذا كان هناك مورد)** ⬇️⬇️⬇️
      if (supplierIdForUpdate != null && supplierIdForUpdate.isNotEmpty) {
        try {
          // تحديث قائمة الأدوية في المورد
          await FirebaseFirestore.instance
              .collection('pharmacies')
              .doc(pharmacyId)
              .collection('suppliers')
              .doc(supplierIdForUpdate)
              .update({
            'suppliedMedications': FieldValue.arrayUnion([medicineId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ تم تحديث المورد ${selectedSupplierName.value} بإضافة الدواء $medicineId');

          // يمكنك إضافة رسالة نجاح إضافية
          Get.snackbar(
            'تم تحديث المورد',
            'تم إضافة الدواء إلى قائمة أدوية المورد ${selectedSupplierName.value}',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
          );

        } catch (e) {
          print('⚠️ تحذير: لم يتم تحديث قائمة أدوية المورد: $e');
          // لا توقف العملية إذا فشل تحديث المورد
          Get.snackbar(
            'تنبيه',
            'تم إضافة الدواء ولكن لم يتم تحديث المورد',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }

      // Show success message
      Get.snackbar(
        'تمت الإضافة بنجاح ✓',
        'تم إضافة الدواء "${nameController.text}" إلى المخزون\nالكمية: $quantity\nسعر البيع: $sellingPrice ر.س${supplier != null ? '\nالمورد: $supplier' : ''}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );

      // Clear form
      clearForm();

    } catch (e) {
      print('Error adding medicine: $e');

      // Show detailed error message
      Get.snackbar(
        'خطأ في إضافة الدواء',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );

      rethrow;
    } finally {
      isAddingMedicine.value = false;
    }
  }

  Future<void> submit() async {
    if (isEditMode.value) {
      await updateMedicine();
    } else {
      await addMedicine();
    }
  }

  Future<void> updateMedicine() async {
    try {
      isAddingMedicine.value = true;

      // ✅ نفس التحقق
      final fieldErrors = validateRequiredFields();
      if (fieldErrors.isNotEmpty) {
        final errorMessage = fieldErrors.entries.map((e) => '• ${e.value}').join('\n');
        throw Exception('يوجد أخطاء في البيانات:\n$errorMessage');
      }

      if (editingMedicineId == null || editingMedicineId!.isEmpty) {
        throw Exception('معرف الدواء غير موجود للتحديث');
      }

      // ✅ barcode: في التعديل لازم نتأكد ما يصطدمش مع دواء آخر
      String? barcode;
      final b = barcodeController.text.trim();
      if (b.isNotEmpty) {
        // تحقق: نفس الباركود مسموح لو هو نفس الدواء
        final q = await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(pharmacyId)
            .collection('medicines')
            .where('barcode', isEqualTo: b)
            .limit(1)
            .get();

        if (q.docs.isNotEmpty && q.docs.first.id != editingMedicineId) {
          throw Exception('الباركود "$b" مستخدم بالفعل لصنف آخر');
        }
        barcode = b;
      }

      int quantity = int.parse(quantityController.text);
      double? purchasePrice =
      purchasePriceController.text.isNotEmpty ? double.tryParse(purchasePriceController.text) : null;
      double sellingPrice = double.parse(sellingPriceController.text);

      int? unitsPerPackage =
      unitsPerPackageController.text.isNotEmpty ? int.tryParse(unitsPerPackageController.text) : null;

      int? minStockLevel =
      minStockController.text.isNotEmpty ? int.tryParse(minStockController.text) : null;

      String? scientificName = scientificNameController.text.trim();
      if (scientificName.isEmpty) scientificName = null;

      // المورد
      String? supplier;
      if (selectedSupplierId.value.isNotEmpty) {
        supplier = selectedSupplierName.value;
      } else if (supplierController.text.trim().isNotEmpty) {
        supplier = supplierController.text.trim();
      }

      // ✅ الصورة: لو اختار صورة جديدة ارفعها، غير هيك خليك على القديمة
      String? imageUrl = medicineImageUrl.value;
      if (medicineImage.value != null) {
        final uploaded = await uploadImageToFirebase();
        if (uploaded != null) imageUrl = uploaded;
      }

      final updated = Medicine(
        id: editingMedicineId!,
        name: nameController.text.trim(),
        scientificName: scientificName,
        quantity: quantity,
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        category: selectedCategory.value,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        unit: selectedUnit.value,
        unitsPerPackage: unitsPerPackage,
        sellByPiece: sellByPiece.value,
        piecePrice: piecePriceCalculated.value,
        minStockLevel: minStockLevel,
        supplier: supplier,
        expiryDate: expiryDate.value,
        barcode: barcode,
        imageUrl: imageUrl,
        lastUpdated: DateTime.now(),
      );

      await inventoryController.updateMedicine(editingMedicineId!, updated);

      Get.snackbar(
        'تم التحديث ✓',
        'تم تحديث "${updated.name}" بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );

      clearForm();
      Get.back(); // اقفل الديالوج بعد التحديث

    } catch (e) {
      Get.snackbar(
        'خطأ في التحديث',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );
      rethrow;
    } finally {
      isAddingMedicine.value = false;
    }
  }


  // Validate form for UI feedback
  Map<String, String?> validateFormForUI() {
    return validateRequiredFields();
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
    newCategoryController.clear();
    selectedCategory.value = null;
    selectedUnit.value = UnitType.Tablet;
    sellByPiece.value = false;
    piecePriceCalculated.value = null;
    medicineImage.value = null;
    medicineImageUrl.value = null;
    isUploadingImage.value = false;
    expiryDate.value = DateTime.now().add(const Duration(days: 365));
  }

  // Check if image is selected (either local or uploaded)
  bool get hasImage => medicineImage.value != null || medicineImageUrl.value != null;

  dynamic get displayImage {
    if (medicineImage.value != null) {
      return medicineImage.value!;
    } else if (medicineImageUrl.value != null) {
      return medicineImageUrl.value!;
    }
    return null;
  }

  // Quick check if form can be submitted
  bool get canSubmit {
    return nameController.text.trim().isNotEmpty &&
        quantityController.text.trim().isNotEmpty &&
        sellingPriceController.text.trim().isNotEmpty &&
        !isAddingMedicine.value;
  }

}