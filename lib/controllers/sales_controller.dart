// lib/controllers/sales_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_model.dart';
import '../models/sales_model.dart';
import '../models/insurance_company_model.dart';
import 'auth_controller.dart';
import 'inventory_controller.dart';
import 'insurance_company_controller.dart';
class SalesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // حالة الفاتورة الحالية
  final Rx<Sale> currentSale = Sale(
    invoiceNumber: Sale.generateInvoiceNumber(),
    pharmacyId: '',
    items: [],
    subtotal: 0.0,
    total: 0.0,
    paymentMethod: PaymentMethod.cash,
    saleDate: DateTime.now(),
  ).obs;

  // بيانات إضافية
  final RxList<Medicine> searchResults = <Medicine>[].obs;
  final RxList<InsuranceCompany> insuranceCompanies = <InsuranceCompany>[].obs;
  final Rx<InsuranceCompany?> selectedInsuranceCompany = Rx<InsuranceCompany?>(null);
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxString barcodeInput = ''.obs;
  StreamSubscription? _barcodeSubscription;

  // متغيرات الدفع
  final RxDouble cashReceived = 0.0.obs;
  final RxDouble changeAmount = 0.0.obs;
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // مراجع Firebase
  String get pharmacyId {
    try {
      final authController = Get.find<AuthController>();
      return authController.pharmacyId;
    } catch (e) {
      print('❌ خطأ في الحصول على pharmacyId: $e');
      return '';
    }
  }

  CollectionReference get salesCollection {
    final id = pharmacyId;
    if (id.isEmpty) {
      throw Exception('لم يتم تحديد الصيدلية');
    }
    return _firestore
        .collection('pharmacies')
        .doc(id)
        .collection('sales');
  }

  @override
  void onInit() {
    super.onInit();
    print('🚀 SalesController onInit');

    // انتظر قليلاً ثم قم بالتهيئة
    Future.delayed(Duration.zero, () {
      _initializeEmployeeData();
      loadInsuranceCompanies();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ SalesController onReady');

    // بديل: تهيئة هنا بعد أن يكون كل شيء جاهز
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEmployeeData();
      loadInsuranceCompanies();
    });
  }

  @override
  void onClose() {
    _barcodeSubscription?.cancel();
    super.onClose();
  }

  // تهيئة بيانات الموظف - محسنة
  void _initializeEmployeeData() {
    try {
      print('🔍 بدء تهيئة بيانات الموظف...');

      final authController = Get.find<AuthController>();
      final currentUser = authController.currentEmployee.value;

      print('📊 بيانات الموظف: $currentUser');

      if (currentUser != null && currentUser is Map<String, dynamic>) {
        currentSale.update((sale) {
          sale?.employeeId = currentUser['id']?.toString() ?? '';
          sale?.employeeName = currentUser['name']?.toString() ?? 'موظف';
          sale?.pharmacyId = pharmacyId;
        });
        print('✅ تم تعيين بيانات الموظف: ${currentUser['name']}');
      } else {
        currentSale.update((sale) {
          sale?.employeeId = _auth.currentUser?.uid ?? '';
          sale?.employeeName = 'المالك';
          sale?.pharmacyId = pharmacyId;
        });
        print('✅ تم تعيين بيانات المالك');
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في تهيئة بيانات الموظف: $e');
      print('📜 Stack trace: $stackTrace');

      // القيم الافتراضية في حالة الخطأ
      currentSale.update((sale) {
        sale?.employeeId = _auth.currentUser?.uid ?? '';
        sale?.employeeName = 'المالك';
        sale?.pharmacyId = pharmacyId;
      });
    }
  }

  // تحميل شركات التأمين - محسن
  Future<void> loadInsuranceCompanies() async {
    try {
      print('🔍 بدء تحميل شركات التأمين...');
      isLoading.value = true;

      final pharmacyId = this.pharmacyId;
      if (pharmacyId.isEmpty) {
        print('⚠️ pharmacyId فارغ، انتظر...');
        await Future.delayed(const Duration(seconds: 1));
      }

      final insuranceController = Get.find<InsuranceCompanyController>();

      // انتظر حتى يتم تحميل البيانات
      await insuranceController.fetchInsuranceCompanies();

      // التحقق من صحة البيانات
      if (insuranceController.companies.isNotEmpty) {
        print('✅ تم تحميل ${insuranceController.companies.length} شركة تأمين');

        // نسخ البيانات بشكل آمن
        insuranceCompanies.clear();

        for (var company in insuranceController.companies) {
          if (company is InsuranceCompany) {
            insuranceCompanies.add(company);
            print('   - ${company.name} (${company.discountPercentage}%)');
          }
        }
      } else {
        print('⚠️ لا توجد شركات تأمين متاحة');
        insuranceCompanies.clear();
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في loadInsuranceCompanies: $e');
      print('📜 Stack trace: $stackTrace');
      insuranceCompanies.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // تسجيل النشاط - محسن
  Future<void> _logSaleActivity() async {
    try {
      final authController = Get.find<AuthController>();
      final actor = authController.currentEmployee.value;

      String employeeName = 'المالك';
      String employeeId = _auth.currentUser?.uid ?? '';

      if (actor != null && actor is Map<String, dynamic>) {
        employeeName = actor['name']?.toString() ?? 'موظف';
        employeeId = actor['id']?.toString() ?? '';
      }

      await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('audit_logs')
          .add({
        'action': 'create_sale',
        'targetId': currentSale.value.id,
        'invoiceNumber': currentSale.value.invoiceNumber,
        'totalAmount': currentSale.value.total,
        'itemsCount': currentSale.value.items.length,
        'performedBy': employeeName,
        'userId': employeeId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('📝 تم تسجيل النشاط للفاتورة #${currentSale.value.invoiceNumber}');
    } catch (e) {
      print('❌ فشل في تسجيل النشاط: $e');
    }
  }



  // البحث عن الأدوية
  Future<void> searchMedicines(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();
      final allMedicines = inventoryController.medicines;

      // البحث بالاسم أو الباركود أو الاسم العلمي
      final results = allMedicines.where((medicine) {
        final nameMatch = medicine.name.toLowerCase().contains(query.toLowerCase());
        final sciMatch = medicine.scientificName.toLowerCase().contains(query.toLowerCase());
        final barcodeMatch = medicine.barcode != null &&
            medicine.barcode!.toLowerCase().contains(query.toLowerCase());
        return nameMatch || sciMatch || barcodeMatch;
      }).toList();

      searchResults.assignAll(results);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في البحث: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // البحث بالباركود
  Future<void> searchByBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();
      final medicine = inventoryController.searchByBarcode(barcode);

      if (medicine != null) {
        searchResults.assignAll([medicine]);
        // إضافة تلقائية للمنتج
        addMedicineToSale(medicine);
      } else {
        Get.snackbar('غير موجود', 'لم يتم العثور على منتج بهذا الباركود');
        searchResults.clear();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في البحث بالباركود: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // إضافة منتج للفاتورة
  void addMedicineToSale(Medicine medicine, {int quantity = 1}) {
    if (medicine.quantity < quantity) {
      _safeSnackbar(
        'مخزون غير كافي',
        'المخزون المتوفر: ${medicine.quantity} فقط',
      );
      return;
    }

    final items = currentSale.value.items;

    final existingIndex =
    items.indexWhere((item) => item.medicineId == medicine.id);

    if (existingIndex >= 0) {
      updateQuantity(
        existingIndex,
        items[existingIndex].quantity + quantity,
      );
    } else {
      final unitPrice =
      medicine.sellByPiece && medicine.piecePrice != null
          ? medicine.piecePrice!
          : medicine.sellingPrice ?? 0.0;

      final saleItem = SaleItem(
        medicineId: medicine.id,
        name: medicine.name,
        scientificName: medicine.scientificName,
        barcode: medicine.barcode,
        unitPrice: unitPrice,
        quantity: quantity,
        total: unitPrice * quantity,
      );

      currentSale.update((sale) {
        sale?.items.add(saleItem);
        sale?.calculateTotal();
      });

      _safeSnackbar(
        'تمت الإضافة',
        'تم إضافة ${medicine.name} للفاتورة',
      );
    }

    searchResults.clear();
    searchQuery.value = '';
  }
  void _safeSnackbar(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rawSnackbar(
        title: title,
        message: message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    });
  }

  // تحديث كمية صنف
  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    // التحقق من المخزون
    final medicineId = currentSale.value.items[index].medicineId;
    final inventoryController = Get.find<InventoryController>();
    final medicine = inventoryController.getMedicineById(medicineId);

    if (medicine != null && medicine.quantity < newQuantity) {
      Get.snackbar('مخزون غير كافي', 'المخزون المتوفر: ${medicine.quantity} فقط');
      return;
    }

    currentSale.update((sale) {
      sale?.updateQuantity(index, newQuantity);
    });
  }

  // حذف صنف
  void removeItem(int index) {
    currentSale.update((sale) {
      sale?.removeItem(index);
    });
    Get.snackbar('تم الحذف', 'تم حذف الصنف من الفاتورة');
  }

  // تطبيق خصم على الفاتورة
  void applyDiscount(double discountAmount) {
    currentSale.update((sale) {
      sale?.discount = discountAmount;
      sale?.calculateTotal();
    });
  }

  // اختيار شركة تأمين - مـصـحـح
  void selectInsuranceCompany(InsuranceCompany? company) {
    if (company == null) {
      selectedInsuranceCompany.value = null;
      currentSale.update((sale) {
        sale?.insuranceCompanyId = null;
        sale?.insuranceCompanyName = null;
        sale?.insuranceDiscount = null;
        sale?.paymentMethod = PaymentMethod.cash;
        sale?.calculateTotal();
      });
      return;
    }

    // التحقق من صحة الكائن
    if (company is! InsuranceCompany) {
      print('❌ نوع غير صالح لشركة التأمين: ${company.runtimeType}');
      Get.snackbar('خطأ', 'بيانات شركة التأمين غير صالحة');
      return;
    }

    selectedInsuranceCompany.value = company;

    currentSale.update((sale) {
      sale?.insuranceCompanyId = company.id;
      sale?.insuranceCompanyName = company.name;
      sale?.insuranceDiscount = (sale.subtotal * company.discountPercentage / 100);
      sale?.paymentMethod = PaymentMethod.insurance;
      sale?.calculateTotal();
    });

    print('✅ تم اختيار شركة التأمين: ${company.name}');
  }

  // تغيير طريقة الدفع
  void changePaymentMethod(PaymentMethod method) {
    currentSale.update((sale) {
      sale?.paymentMethod = method;

      // إعادة تعيين بيانات التأمين إذا كانت الطريقة غير تأمين
      if (method != PaymentMethod.insurance) {
        sale?.insuranceCompanyId = null;
        sale?.insuranceCompanyName = null;
        sale?.insuranceDiscount = null;
        selectedInsuranceCompany.value = null;
      }

      sale?.calculateTotal();
    });
  }

  // إدخال المبلغ المستلم (للدفع النقدي)
  void setCashReceived(double amount) {
    cashReceived.value = amount;
    changeAmount.value = amount - currentSale.value.total;
    if (changeAmount.value < 0) changeAmount.value = 0;
  }

  // حفظ الفاتورة
  Future<bool> saveSale() async {
    if (currentSale.value.items.isEmpty) {
      Get.snackbar('فاتورة فارغة', 'أضف منتجات للفاتورة أولاً');
      return false;
    }

    isLoading.value = true;

    try {
      // 1. تحديث المخزون
      await _updateInventoryStock();

      // 2. حفظ بيانات الزبون
      currentSale.update((sale) {
        sale?.customerName = customerNameController.text.trim();
        sale?.customerPhone = customerPhoneController.text.trim();
        sale?.notes = notesController.text.trim();
        sale?.saleDate = DateTime.now();
      });

      // 3. حفظ في Firebase
      final saleDoc = salesCollection.doc();
      currentSale.value.id = saleDoc.id;

      await saleDoc.set(currentSale.value.toMap());

      // 4. تسجيل في سجل النشاطات
      await _logSaleActivity();

      // 5. إعادة تعيين الفاتورة
      resetSale();

      Get.snackbar(
        'تمت العملية بنجاح',
        'تم حفظ الفاتورة #${currentSale.value.invoiceNumber}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حفظ الفاتورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث المخزون بعد البيع
  Future<void> _updateInventoryStock() async {
    try {
      final inventoryController = Get.find<InventoryController>();

      for (final item in currentSale.value.items) {
        final medicine = inventoryController.getMedicineById(item.medicineId);
        if (medicine != null) {
          final newQuantity = medicine.quantity - item.quantity;
          await inventoryController.updateStock(medicine.id, newQuantity);
        }
      }
    } catch (e) {
      throw Exception('فشل في تحديث المخزون: $e');
    }
  }

  void resetSale() {
    currentSale.value = Sale(
      invoiceNumber: Sale.generateInvoiceNumber(),
      pharmacyId: pharmacyId,
      items: [],
      subtotal: 0.0,
      total: 0.0,
      paymentMethod: PaymentMethod.cash,
      saleDate: DateTime.now(),
    );

    // إعادة تعيين بيانات الموظف
    _initializeEmployeeData();

    // إعادة تعيين حقول الزبون
    customerNameController.clear();
    customerPhoneController.clear();
    notesController.clear();
    cashReceived.value = 0.0;
    changeAmount.value = 0.0;
    selectedInsuranceCompany.value = null;
    searchResults.clear();
    searchQuery.value = '';
  }

  // الحصول على تقارير المبيعات
  Future<List<Sale>> getSalesReport(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await salesCollection
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate.add(Duration(days: 1))))
          .orderBy('saleDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Sale.fromMap({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
          .toList();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب التقرير: $e');
      return [];
    }
  }

  // الحصول على فاتورة بواسطة الرقم
  Future<Sale?> getSaleByInvoiceNumber(String invoiceNumber) async {
    try {
      final querySnapshot = await salesCollection
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Sale.fromMap({
          'id': querySnapshot.docs.first.id,
          ...querySnapshot.docs.first.data() as Map<String, dynamic>
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // حذف فاتورة
  Future<bool> deleteSale(String saleId) async {
    try {
      await salesCollection.doc(saleId).update({'isDeleted': true});
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف الفاتورة');
      return false;
    }
  }

  // إحصائيات سريعة
  Future<Map<String, dynamic>> getTodaySalesStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final sales = await getSalesReport(startOfDay, endOfDay);

      final totalSales = sales.length;
      final totalAmount = sales.fold(0.0, (sum, sale) => sum + sale.total);
      final cashSales = sales.where((s) => s.paymentMethod == PaymentMethod.cash).length;
      final cardSales = sales.where((s) => s.paymentMethod == PaymentMethod.card).length;
      final insuranceSales = sales.where((s) => s.paymentMethod == PaymentMethod.insurance).length;

      return {
        'totalSales': totalSales,
        'totalAmount': totalAmount,
        'cashSales': cashSales,
        'cardSales': cardSales,
        'insuranceSales': insuranceSales,
        'averageSale': totalSales > 0 ? totalAmount / totalSales : 0,
      };
    } catch (e) {
      return {
        'totalSales': 0,
        'totalAmount': 0.0,
        'cashSales': 0,
        'cardSales': 0,
        'insuranceSales': 0,
        'averageSale': 0.0,
      };
    }
  }

  // تفعيل الماسح الضوئي
  void toggleBarcodeScanner() {
    isScanning.value = !isScanning.value;
  }

  // دالة مساعدة لعرض شركات التأمين
  Widget buildInsuranceDropdown() {
    return Obx(() {
      if (insuranceCompanies.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            isLoading.value ? 'جاري التحميل...' : 'لا توجد شركات تأمين',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return DropdownButtonFormField<InsuranceCompany>(
        value: selectedInsuranceCompany.value,
        items: insuranceCompanies.map((company) {
          return DropdownMenuItem<InsuranceCompany>(
            value: company,
            child: Text(
              '${company.name} (خصم ${company.discountPercentage}%)',
            ),
          );
        }).toList(),
        onChanged: (company) => selectInsuranceCompany(company),
        decoration: InputDecoration(
          labelText: 'شركة التأمين',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    });
  }
}