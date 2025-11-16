import 'package:get/get.dart';
import '../models/inventory_model.dart';

class InventoryController extends GetxController {
  var medicines = <Medicine>[].obs;
  var filteredMedicines = <Medicine>[].obs;
  var isLoading = false.obs;
  var lowStockMedicines = <Medicine>[].obs;
  var expiredMedicines = <Medicine>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMedicines();
  }

  void loadMedicines() {
    isLoading(true);

    // TODO: جلب البيانات من Firestore
    medicines.value = [
      Medicine(
        id: '1',
        name: 'بانادول',
        description: 'مسكن للألم وخافض للحرارة',
        category: 'مسكنات',
        price: 15.0,
        quantity: 20,
        minStockLevel: 10,
        supplier: 'شركة الأدوية',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        barcode: '123456789',
        lastUpdated: DateTime.now(),
      ),
      Medicine(
        id: '2',
        name: 'فيتامين سي',
        description: 'مكمل غذائي',
        category: 'فيتامينات',
        price: 45.0,
        quantity: 5,
        minStockLevel: 10,
        supplier: 'شركة الفيتامينات',
        expiryDate: DateTime.now().add(const Duration(days: 200)),
        barcode: '987654321',
        lastUpdated: DateTime.now(),
      ),
      Medicine(
        id: '3',
        name: 'أموكسيسيلين',
        description: 'مضاد حيوي',
        category: 'مضادات حيوية',
        price: 35.0,
        quantity: 15,
        minStockLevel: 5,
        supplier: 'شركة الأدوية',
        expiryDate: DateTime.now().subtract(const Duration(days: 10)),
        barcode: '456789123',
        lastUpdated: DateTime.now(),
      ),
    ];

    _filterMedicines();
    _checkAlerts();
    isLoading(false);
  }

  void _filterMedicines() {
    if (searchQuery.isEmpty) {
      filteredMedicines.value = medicines;
    } else {
      filteredMedicines.value = medicines.where((medicine) =>
      medicine.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          medicine.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
          medicine.barcode.contains(searchQuery)
      ).toList();
    }
  }

  void _checkAlerts() {
    lowStockMedicines.value = medicines.where((medicine) => medicine.isLowStock).toList();
    expiredMedicines.value = medicines.where((medicine) => medicine.isExpired).toList();
  }

  void searchMedicines(String query) {
    searchQuery.value = query;
    _filterMedicines();
  }

  void addMedicine(Medicine medicine) {
    medicines.add(medicine);
    _filterMedicines();
    _checkAlerts();
    // TODO: حفظ في Firestore
  }

  void updateMedicine(Medicine updatedMedicine) {
    final index = medicines.indexWhere((med) => med.id == updatedMedicine.id);
    if (index != -1) {
      medicines[index] = updatedMedicine;
      _filterMedicines();
      _checkAlerts();
      // TODO: تحديث في Firestore
    }
  }

  void deleteMedicine(String medicineId) {
    medicines.removeWhere((med) => med.id == medicineId);
    _filterMedicines();
    _checkAlerts();
    // TODO: حذف من Firestore
  }

  void updateStock(String medicineId, int newQuantity) {
    final medicine = medicines.firstWhere((med) => med.id == medicineId);
    final updatedMedicine = Medicine(
      id: medicine.id,
      name: medicine.name,
      description: medicine.description,
      category: medicine.category,
      price: medicine.price,
      quantity: newQuantity,
      minStockLevel: medicine.minStockLevel,
      supplier: medicine.supplier,
      expiryDate: medicine.expiryDate,
      barcode: medicine.barcode,
      lastUpdated: DateTime.now(),
    );
    updateMedicine(updatedMedicine);
  }
}