import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../models/inventory_model.dart';
import '../views/inventory/widgets/quick_alerts.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class InventoryController extends GetxController {
  final RxList<Medicine> medicines = <Medicine>[].obs;
  final RxList<Medicine> filteredMedicines = <Medicine>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString currentFilter = 'all'.obs;
  final RxMap<String, dynamic> pharmacyData = <String, dynamic>{}.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get pharmacy ID from current user
  String? get _pharmacyId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void onInit() {
    super.onInit();
    loadPharmacyData();
    loadMedicines();
  }

  // Load pharmacy data
  Future<void> loadPharmacyData() async {
    final uid = _pharmacyId;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection("pharmacies").doc(uid).get();
      if (doc.exists) {
        pharmacyData.value = doc.data()!;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل بيانات الصيدلية: $e');
    }
  }

  // Get reference to medicines collection for current pharmacy
  CollectionReference get _medicinesCollection {
    final pharmacyId = _pharmacyId;
    if (pharmacyId == null) {
      throw Exception('Pharmacy ID not available');
    }
    return _firestore.collection('pharmacies').doc(pharmacyId).collection('medicines');
  }

  // Getter for low stock medicines
  List<Medicine> get lowStockMedicines {
    return medicines.where((medicine) {
      if (medicine.minStockLevel == null) return false;
      return medicine.quantity <= (medicine.minStockLevel ?? 0);
    }).toList();
  }

  // Getter for expired medicines
  List<Medicine> get expiredMedicines {
    return medicines.where((medicine) {
      return medicine.expiryDate != null && medicine.expiryDate!.isBefore(DateTime.now());
    }).toList();
  }

  // Getter for recent alerts - FIXED
  List<QuickAlert> get recentAlerts {
    final List<QuickAlert> generatedAlerts = [];

    for (final medicine in lowStockMedicines) {
      generatedAlerts.add(QuickAlert(
        type: 'low_stock',
        message: '${medicine.name} (${medicine.scientificName}) منخفض المخزون (${medicine.quantity} متبقي)',
        date: DateTime.now(),
      ));
    }

    for (final medicine in expiredMedicines) {
      generatedAlerts.add(QuickAlert(
        type: 'expired',
        message: '${medicine.name} (${medicine.scientificName}) منتهي الصلاحية',
        date: DateTime.now(),
      ));
    }

    generatedAlerts.sort((a, b) => b.date.compareTo(a.date));
    return generatedAlerts.take(10).toList();
  }

  // Load medicines from Firestore (now nested under pharmacies)
  Future<void> loadMedicines() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _medicinesCollection
          .orderBy('lastUpdated', descending: true)
          .get();

      medicines.assignAll(
        snapshot.docs.map((doc) {
          final data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          return Medicine.fromMap(data);
        }).toList(),
      );

      filteredMedicines.assignAll(medicines);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل الأدوية: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Search medicines
  void searchMedicines(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // Filter medicines
  void filterMedicines(String filter) {
    currentFilter.value = filter;
    _applyFilters();
  }

  // Apply both search and filter
  void _applyFilters() {
    List<Medicine> result = medicines;

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((medicine) {
        final name = medicine.name.toLowerCase();
        final sci = medicine.scientificName.toLowerCase();
        final category = (medicine.category ?? '').toLowerCase();
        final barcode = (medicine.barcode ?? '').toLowerCase();
        final supplier = (medicine.supplier ?? '').toLowerCase();

        return name.contains(q) ||
            sci.contains(q) ||
            category.contains(q) ||
            barcode.contains(q) ||
            supplier.contains(q);
      }).toList();
    }

    switch (currentFilter.value) {
      case 'low_stock':
        result = result.where((medicine) => medicine.isLowStock).toList();
        break;
      case 'expired':
        result = result.where((medicine) => medicine.isExpired).toList();
        break;
      case 'good':
        result = result.where((medicine) => !medicine.isLowStock && !medicine.isExpired).toList();
        break;
      default:
        break;
    }

    filteredMedicines.assignAll(result);
  }

  // Add medicine to Firestore
  Future<void> addMedicine(Medicine medicine) async {
    try {
      final data = medicine.toMap(forFirestore: true);
      // If id exists and you want to use it as doc id, use set; otherwise add generates id.
      if (medicine.id.isNotEmpty) {
        await _medicinesCollection.doc(medicine.id).set(data);
      } else {
        final docRef = await _medicinesCollection.add(data);
        // Update the medicine with the generated ID
        await docRef.update({'id': docRef.id});
      }
      await loadMedicines();
      Get.snackbar('نجاح', 'تم إضافة الدواء بنجاح', backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة الدواء: $e', backgroundColor: Colors.red);
    }
  }

  // Update medicine (now in nested collection)
  Future<void> updateMedicine(String id, Medicine updatedMedicine) async {
    try {
      await _medicinesCollection.doc(id).update(updatedMedicine.toMap(forFirestore: true));
      await loadMedicines();
      Get.snackbar('نجاح', 'تم تحديث الدواء بنجاح', backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث الدواء: $e', backgroundColor: Colors.red);
    }
  }

  // Update stock quantity (now in nested collection)
  Future<void> updateStock(String id, int newQuantity) async {
    try {
      await _medicinesCollection.doc(id).update({
        'quantity': newQuantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      await loadMedicines();
      Get.snackbar('نجاح', 'تم تحديث المخزون بنجاح', backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث المخزون: $e', backgroundColor: Colors.red);
    }
  }

  // Delete medicine (now from nested collection)
  Future<void> deleteMedicine(String id) async {
    try {
      await _medicinesCollection.doc(id).delete();
      await loadMedicines();
      Get.snackbar('نجاح', 'تم حذف الدواء بنجاح', backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف الدواء: $e', backgroundColor: Colors.red);
    }
  }

  // Import from CSV (uses batch write for performance)
  // mapping: Map<fieldName, columnIndex> where fieldName can be:
  // id, name, scientificName, description, category, purchasePrice, sellingPrice,
  // unit, unitsPerPackage, sellByPiece, piecePrice, quantity, minStockLevel,
  // supplier, expiryDate, barcode, imageUrl
  Future<void> importFromCSV(String filePath, Map<String, int> mapping) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();

      final List<Medicine> parsed = await _parseCSVToMedicines(csvString, mapping);

      if (parsed.isEmpty) {
        Get.snackbar('تنبيه', 'لم يتم العثور على صفوف صالحة للاستيراد');
        return;
      }

      // Batch write to Firestore
      final WriteBatch batch = _firestore.batch();
      final docRefBase = _medicinesCollection;

      for (final med in parsed) {
        final docRef = docRefBase.doc(med.id.isNotEmpty ? med.id : null);
        batch.set(docRef, med.toMap(forFirestore: true));
      }

      await batch.commit();
      await loadMedicines();

      Get.snackbar(
        'نجاح',
        'تم استيراد ${parsed.length} عنصر بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في استيراد الملف: $e', backgroundColor: Colors.red);
    }
  }

  // Export to CSV
  Future<void> exportToCSV() async {
    try {
      if (medicines.isEmpty) {
        Get.snackbar('تنبيه', 'لا توجد بيانات للتصدير');
        return;
      }

      // إنشاء محتوى CSV
      final List<List<dynamic>> csvData = [];

      // العناوين (إنجليزية لأعمدة قابلة لإعادة الاستيراد)
      csvData.add([
        'id',
        'name',
        'scientificName',
        'description',
        'category',
        'purchasePrice',
        'sellingPrice',
        'unit',
        'unitsPerPackage',
        'sellByPiece',
        'piecePrice',
        'quantity',
        'minStockLevel',
        'supplier',
        'expiryDate',
        'barcode',
        'imageUrl',
        'lastUpdated'
      ]);

      // البيانات
      for (final medicine in medicines) {
        csvData.add([
          medicine.id,
          medicine.name,
          medicine.scientificName,
          medicine.description ?? '',
          medicine.category ?? '',
          medicine.purchasePrice?.toString() ?? '',
          medicine.sellingPrice?.toString() ?? '',
          medicine.unit?.name ?? '',
          medicine.unitsPerPackage?.toString() ?? '',
          medicine.sellByPiece.toString(),
          medicine.piecePrice?.toString() ?? '',
          medicine.quantity.toString(),
          medicine.minStockLevel?.toString() ?? '',
          medicine.supplier ?? '',
          medicine.expiryDate != null ? DateFormat('yyyy-MM-dd').format(medicine.expiryDate!) : '',
          medicine.barcode ?? '',
          medicine.imageUrl ?? '',
          medicine.lastUpdated?.toIso8601String() ?? '',
        ]);
      }

      // تحويل إلى نص CSV
      final String csvContent = const ListToCsvConverter().convert(csvData);

      // حفظ الملف
      final String outputFile = '/storage/emulated/Download/medicines_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final File file = File(outputFile);
      await file.writeAsString(csvContent);

      Get.snackbar(
        'نجاح التصدير',
        'تم تصدير البيانات إلى: $outputFile',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ في التصدير',
        'فشل في تصدير البيانات: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<List<Medicine>> _parseCSVToMedicines(String csvString, Map<String, int> mapping) async {
    try {
      debugPrint('Starting CSV parsing with mapping: $mapping');

      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

      if (csvTable.isEmpty) return [];

      final headers = csvTable.first;
      debugPrint('Headers found: $headers');

      final List<Medicine> parsed = [];

      for (int i = 1; i < csvTable.length; i++) {
        try {
          final row = csvTable[i];
          final med = _mapRowToMedicine(row, headers, mapping);

          // تحقق من الاسم فقط
          if (med.name.trim().isEmpty) {
            debugPrint('Row ${i + 1} skipped: missing required name');
            continue;
          }

          // تحقق من الكمية فقط
          if (med.quantity < 0) {
            debugPrint('Row ${i + 1} skipped: invalid quantity');
            continue;
          }

          parsed.add(med);
        } catch (e) {
          debugPrint('خطأ في تحويل الصف ${i + 1}: $e');
          continue;
        }
      }

      debugPrint('Total parsed items: ${parsed.length}');
      return parsed;
    } catch (e) {
      debugPrint('Error in _parseCSVToMedicines: $e');
      return [];
    }
  }

  Medicine _mapRowToMedicine(List<dynamic> row, List<dynamic> headers, Map<String, int> mapping) {
    // دالة مساعدة لاستخراج القيمة من الصف
    dynamic getValue(String field) {
      if (!mapping.containsKey(field)) return null;

      final int? idx = mapping[field];
      if (idx == null || idx < 0 || idx >= row.length) return null;

      final val = row[idx];
      if (val == null) return null;

      return val.toString().trim();
    }

    // توليد معرف فريد
    String generateId() => 'med_${DateTime.now().millisecondsSinceEpoch}_${row.hashCode}';

    // استخراج القيم
    final id = getValue('id')?.toString() ?? generateId();
    final name = getValue('name')?.toString() ?? '';

    // الاسم العلمي الآن اختياري - إذا كان فارغاً نستخدم الاسم العادي
    String scientificNameValue = getValue('scientificName')?.toString() ?? '';
    final scientificName = scientificNameValue.isNotEmpty ? scientificNameValue : name;

    final description = getValue('description')?.toString();
    final category = getValue('category')?.toString();
    final purchasePrice = _parseDouble(getValue('purchasePrice')?.toString());
    final sellingPrice = _parseDouble(getValue('sellingPrice')?.toString());
    final unit = _parseUnitFromString(getValue('unit')?.toString());
    final unitsPerPackage = _parseInt(getValue('unitsPerPackage')?.toString());
    final sellByPiece = _parseBool(getValue('sellByPiece')?.toString());
    final piecePrice = _parseDouble(getValue('piecePrice')?.toString());
    final quantity = _parseInt(getValue('quantity')?.toString()) ?? 0;
    final minStockLevel = _parseInt(getValue('minStockLevel')?.toString());
    final supplier = getValue('supplier')?.toString();
    final expiryDate = _parseDate(getValue('expiryDate')?.toString());
    final barcode = getValue('barcode')?.toString();
    final imageUrl = getValue('imageUrl')?.toString();

    // إنشاء كائن الدواء
    final medicine = Medicine(
      id: id,
      name: name,
      scientificName: scientificName,
      quantity: quantity,
      description: description,
      category: category,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      unit: unit,
      unitsPerPackage: unitsPerPackage,
      sellByPiece: sellByPiece,
      piecePrice: piecePrice,
      minStockLevel: minStockLevel,
      supplier: supplier,
      expiryDate: expiryDate,
      barcode: barcode,
      imageUrl: imageUrl,
      lastUpdated: DateTime.now(),
    );

    return medicine;
  }

  // ========== HELPER METHODS ==========

  bool _parseBool(String? value) {
    if (value == null) return false;
    final v = value.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'نعم' || v == 'yes' || v == 'صحيح';
  }

  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return double.tryParse(value.replaceAll(',', '').trim());
    } catch (e) {
      return null;
    }
  }

  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return int.tryParse(value.replaceAll(',', '').trim());
    } catch (e) {
      return null;
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      final formats = [
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('yyyy/MM/dd'),
        DateFormat('dd-MM-yyyy'),
      ];

      for (final format in formats) {
        try {
          return format.parse(dateString.trim());
        } catch (_) {
          continue;
        }
      }

      // try direct parse
      return DateTime.tryParse(dateString.trim());
    } catch (e) {
      return null;
    }
  }

  // Parse UnitType from string
  UnitType? _parseUnitFromString(String? s) {
    if (s == null || s.isEmpty) return null;
    final key = s.trim();
    for (final u in UnitType.values) {
      if (u.name == key) return u;
    }
    return null;
  }

  // Get medicine by ID
  Medicine? getMedicineById(String id) {
    try {
      return medicines.firstWhere((medicine) => medicine.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get medicines by category
  List<Medicine> getMedicinesByCategory(String category) {
    return medicines.where((medicine) => (medicine.category ?? '') == category).toList();
  }

  // Get categories list
  List<String> get categories {
    final allCategories = medicines.map((medicine) => medicine.category ?? 'عام').toSet().toList();
    allCategories.sort();
    return allCategories;
  }

  // Calculate total inventory value
  double get totalInventoryValue {
    return medicines.fold(0.0, (sum, medicine) {
      final purchasePrice = medicine.purchasePrice ?? 0;
      return sum + (medicine.quantity * purchasePrice);
    });
  }

  // Calculate total inventory selling value
  double get totalInventorySellingValue {
    return medicines.fold(0.0, (sum, medicine) {
      final sellingPrice = medicine.sellingPrice ?? 0;
      return sum + (medicine.quantity * sellingPrice);
    });
  }

  // Get total items count
  int get totalItemsCount {
    return medicines.fold(0, (sum, medicine) => sum + medicine.quantity);
  }

  // Get unique medicines count
  int get uniqueMedicinesCount {
    return medicines.length;
  }

  // Get low stock count
  int get lowStockCount {
    return lowStockMedicines.length;
  }

  // Get expired count
  int get expiredCount {
    return expiredMedicines.length;
  }

  // Bulk update medicines
  Future<void> bulkUpdateMedicines(List<Medicine> updatedMedicines) async {
    try {
      isLoading.value = true;
      final WriteBatch batch = _firestore.batch();

      for (final medicine in updatedMedicines) {
        final docRef = _medicinesCollection.doc(medicine.id);
        batch.update(docRef, medicine.toMap(forFirestore: true));
      }

      await batch.commit();
      await loadMedicines();

      Get.snackbar(
        'نجاح',
        'تم تحديث ${updatedMedicines.length} عنصر بنجاح',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في التحديث الجماعي: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // Get statistics
  Map<String, dynamic> get statistics {
    return {
      'totalValue': totalInventoryValue,
      'sellingValue': totalInventorySellingValue,
      'totalItems': totalItemsCount,
      'uniqueItems': uniqueMedicinesCount,
      'lowStock': lowStockCount,
      'expired': expiredCount,
      'categoriesCount': categories.length,
    };
  }

  // Search medicine by barcode
  Medicine? searchByBarcode(String barcode) {
    try {
      return medicines.firstWhere(
            (medicine) => medicine.barcode != null && medicine.barcode == barcode,
      );
    } catch (e) {
      return null;
    }
  }

  // Get medicines expiring soon (within 30 days)
  List<Medicine> get expiringSoonMedicines {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    return medicines.where((medicine) {
      if (medicine.expiryDate == null) return false;
      return medicine.expiryDate!.isAfter(now) &&
          medicine.expiryDate!.isBefore(thirtyDaysFromNow);
    }).toList();
  }
}