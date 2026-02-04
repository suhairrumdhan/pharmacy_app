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
  FocusNode searchFocusNode = FocusNode();

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


  ///////////
  //late FocusNode searchFocusNode;


  // متغيرات التحكم في التهيئة
  bool _initialized = false;
  bool _employeeDataInitialized = false;
  bool _insuranceCompaniesLoaded = false;

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
  Future<void> onInit() async {
    super.onInit();
    if (_initialized) {
      return;
    }
    try {
      await Get.putAsync(() async {
        final controller = Get.find<AuthController>();
        // الانتظار حتى تكون بيانات الصيدلية جاهزة
        while (!controller.isPharmacyLoaded.value) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return controller;
      });
      await Get.putAsync(() async => Get.find<InventoryController>());
      await initializeEmployeeData();
      await loadInsuranceCompanies();
      _initialized = true;
    } catch (e, stackTrace) {
      print('📜 Stack trace: $stackTrace');
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    _barcodeSubscription?.cancel();
    searchFocusNode.dispose();
    _initialized = false;
    _employeeDataInitialized = false;
    _insuranceCompaniesLoaded = false;
    super.onClose();
  }


  /////*************************////////////////

  final RxList<Sale> activeInvoices = <Sale>[].obs; // قائمة الفواتير النشطة
  final RxInt currentInvoiceIndex = 0.obs; // الفهرس الحالي (0 للفاتورة الأساسية)

  // ===== دالة للتبديل بين الفواتير =====
  void switchToNextInvoice() {
    if (activeInvoices.isEmpty) {
      // إذا لا توجد فواتير، ننشئ واحدة جديدة
      createNewInvoice();
      return;
    }

    // حفظ الفاتورة الحالية
    _saveCurrentInvoice();

    // التبديل للفاتورة التالية (دائري)
    currentInvoiceIndex.value =
        (currentInvoiceIndex.value + 1) % activeInvoices.length;

    // تحميل الفاتورة الجديدة
    _loadInvoice(currentInvoiceIndex.value);
  }

  void switchToPreviousInvoice() {
    if (activeInvoices.isEmpty) return;

    // حفظ الفاتورة الحالية
    _saveCurrentInvoice();

    // التبديل للفاتورة السابقة (دائري)
    currentInvoiceIndex.value =
        (currentInvoiceIndex.value - 1 + activeInvoices.length) % activeInvoices.length;

    // تحميل الفاتورة الجديدة
    _loadInvoice(currentInvoiceIndex.value);
  }

  void _saveCurrentInvoice() {
    if (currentSale.value.items.isEmpty) return;

    // إذا كانت فاتورة جديدة، نضيفها للقائمة
    if (currentInvoiceIndex.value >= activeInvoices.length) {
      activeInvoices.add(currentSale.value);
    } else {
      // إذا كانت موجودة، نحدثها
      activeInvoices[currentInvoiceIndex.value] = currentSale.value;
    }
  }

  void _loadInvoice(int index) {
    if (index < activeInvoices.length) {
      currentSale.value = Sale.fromMap(activeInvoices[index].toMap());
      currentSale.refresh();
    }
  }

  // ===== تعديل دالة createNewInvoice =====
  void createNewInvoice() {
    // حفظ الفاتورة الحالية
    _saveCurrentInvoice();

    // إنشاء فاتورة جديدة
    resetSale();

    // إضافتها للقائمة
    activeInvoices.add(currentSale.value);
    currentInvoiceIndex.value = activeInvoices.length - 1;

    Get.snackbar(
      'فاتورة جديدة',
      'تم إنشاء فاتورة #${currentSale.value.invoiceNumber}',
      duration: const Duration(seconds: 2),
    );
  }

  // ===== دالة لحذف الفاتورة الحالية =====
  void deleteCurrentInvoice() {
    if (activeInvoices.isEmpty) return;

    Get.defaultDialog(
      title: 'حذف الفاتورة',
      middleText: 'هل تريد حذف هذه الفاتورة؟',
      textConfirm: 'نعم',
      textCancel: 'لا',
      onConfirm: () {
        activeInvoices.removeAt(currentInvoiceIndex.value);

        if (activeInvoices.isEmpty) {
          // إذا لا توجد فواتير، ننشئ واحدة جديدة
          resetSale();
          activeInvoices.add(currentSale.value);
        } else {
          // التحميل للفاتورة السابقة
          currentInvoiceIndex.value =
              (currentInvoiceIndex.value - 1 + activeInvoices.length) % activeInvoices.length;
          _loadInvoice(currentInvoiceIndex.value);
        }

        Get.back();
      },
    );
  }
  /////////*********************/////////////////

  Future<void> initializeEmployeeData() async {
    // حماية من التهيئة المزدوجة
    if (_employeeDataInitialized) {
      print('⚠️ بيانات الموظف تم تهيئتها مسبقاً');
      return;
    }

    try {
      _employeeDataInitialized = true;
      print('🔍 === بدء تهيئة بيانات الموظف للفاتورة ===');

      // 1. الحصول على AuthController
      final authController = Get.find<AuthController>();

      // 2. جلب معلومات منفذ البيع
      final actorInfo = await authController.getSaleActorInfo();

      // 3. تعيين البيانات في الفاتورة
      currentSale.update((sale) {
        sale?.employeeId = actorInfo['id']?.toString() ?? '';
        sale?.employeeName = actorInfo['name']?.toString() ?? 'موظف';
        sale?.pharmacyId = actorInfo['pharmacyId']?.toString() ?? pharmacyId;
      });

    } catch (e, stackTrace) {
      _employeeDataInitialized = false; // إعادة تعيين في حالة الخطأ

      // البيانات الاحتياطية
      _setFallbackData();
    }
  }

  void _setFallbackData() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    final userEmail = user?.email ?? '';
    final nameFromEmail = userEmail.split('@').first;

    currentSale.update((sale) {
      sale?.employeeId = userId;
      sale?.employeeName = nameFromEmail.isNotEmpty ? nameFromEmail : 'موظف';
      sale?.pharmacyId = pharmacyId;
    });

  }

  Future<void> loadInsuranceCompanies() async {
    // حماية من التحميل المزدوج
    if (_insuranceCompaniesLoaded) {
      print('⚠️ شركات التأمين تم تحميلها مسبقاً');
      return;
    }

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

        _insuranceCompaniesLoaded = true;
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

  Future<List<Medicine>> searchMedicinesWithSuggestions(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return [];
    }

    isLoading.value = true;
    try {
      final inventoryController = Get.find<InventoryController>();
      final allMedicines = inventoryController.medicines;

      // البحث في عدة حقول
      final results = allMedicines.where((medicine) {
        final nameMatch = medicine.name.toLowerCase().contains(query.toLowerCase());
        final sciMatch = medicine.scientificName.toLowerCase().contains(query.toLowerCase());
        final barcodeMatch = medicine.barcode != null &&
            medicine.barcode!.toLowerCase().contains(query.toLowerCase());

        // بحث جزئي في بداية النص (لتحسين الاقتراحات)
        final nameStartsWith = medicine.name.toLowerCase().startsWith(query.toLowerCase());
        final sciStartsWith = medicine.scientificName.toLowerCase().startsWith(query.toLowerCase());

        return nameMatch || sciMatch || barcodeMatch || nameStartsWith || sciStartsWith;
      }).toList();

      // ترتيب النتائج: التي تبدأ بالكلمة أولاً
      results.sort((a, b) {
        final aStartsWithName = a.name.toLowerCase().startsWith(query.toLowerCase());
        final bStartsWithName = b.name.toLowerCase().startsWith(query.toLowerCase());
        final aStartsWithSci = a.scientificName.toLowerCase().startsWith(query.toLowerCase());
        final bStartsWithSci = b.scientificName.toLowerCase().startsWith(query.toLowerCase());

        if (aStartsWithName || aStartsWithSci) return -1;
        if (bStartsWithName || bStartsWithSci) return 1;
        return a.name.compareTo(b.name);
      });

      searchResults.assignAll(results);
      return results;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في البحث: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }
  // دالة للتعرف إذا كان النص باركود
  bool isBarcodeInput(String text) {
    return RegExp(r'^[0-9]{8,}$').hasMatch(text);
  }
  // دالة للتعامل مع البحث الذكي
  Future<void> handleSmartSearch(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    final results = await searchMedicinesWithSuggestions(query);

    // إذا كان باركود وكانت هناك نتيجة واحدة، أضفها تلقائياً
    if (isBarcodeInput(query) && results.length == 1) {
      addMedicineToSale(results.first);
      searchQuery.value = '';
      searchResults.clear();
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


  Future<void> search(String query) async {
    searchQuery.value = query;

    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    if (isBarcodeInput(query)) {
      await handleSmartSearch(query);
    } else {
      await searchMedicines(query);
    }
  }

  void addMedicineToSale(Medicine medicine, {int quantity = 1, bool sellAsPiece = false}) {
    // ===== تحقق من المخزون =====
    if (medicine.quantity < quantity) {
      _safeSnackbar(
        'مخزون غير كافي',
        'المخزون المتوفر: ${medicine.quantity} فقط',
      );
      return;
    }

    final items = currentSale.value.items;

    // ===== تحقق إذا الصنف موجود مسبقًا =====
    final existingIndex = items.indexWhere(
            (item) => item.medicineId == medicine.id && item.sellAsPiece == sellAsPiece
    );

    if (existingIndex >= 0) {
      // تحديث الكمية + إعادة حساب total للصنف
      items[existingIndex].quantity += quantity;
      items[existingIndex].calculateTotal();
    } else {
      // ===== حساب السعر حسب الاختيار =====
      final unitPrice = sellAsPiece && medicine.piecePrice != null
          ? medicine.piecePrice!
          : medicine.sellingPrice ?? 0.0;

      final saleItem = SaleItem(
        medicineId: medicine.id,
        name: medicine.name,
        scientificName: medicine.scientificName,
        barcode: medicine.barcode,
        unitPrice: unitPrice,
        quantity: quantity,
        sellAsPiece: sellAsPiece,
        total: unitPrice * quantity,
      );

      items.add(saleItem);
    }

    // ===== تحديث المجموع في الفاتورة =====
    currentSale.update((sale) {
      sale?.calculateTotal();
    });

    // ⬇️⬇️⬇️ أضف هذا السطر هنا ⬇️⬇️⬇️
    _clearSearchAfterAdd(); // تنظيف البحث بعد الإضافة

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

  void _clearSearchAfterAdd() {
    // تفريغ حقل البحث ونتائج البحث
    searchQuery.value = '';
    searchResults.clear();

    // إضافة تأخير بسيط لضمان تحديث الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // يمكن إضافة أي عمليات إضافية هنا إذا لزم الأمر
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
  }

  // تطبيق خصم على الفاتورة
  void applyDiscount(double discountAmount) {
    currentSale.update((sale) {
      sale?.discount = discountAmount;
      sale?.calculateTotal();
    });
  }
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

  Future<bool> saveSale() async {
    if (currentSale.value.items.isEmpty) {
      // ✅ استخدام الطريقة الآمنة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.rawSnackbar(
          title: 'فاتورة فارغة',
          message: 'أضف منتجات للفاتورة أولاً',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
      return false;
    }

    bool success = false;

    try {
      isLoading.value = true;

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
      resetSale();
      success = true;
    } catch (e) {
      success = false;
    } finally {
      isLoading.value = false;
    }

    return success;
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
// في sales_controller.dart
  void resetSale() {
    // توليد رقم فاتورة جديد فقط
    currentSale.update((sale) {
      sale?.invoiceNumber = Sale.generateInvoiceNumber();
      sale?.items.clear();
      sale?.subtotal = 0.0;
      sale?.total = 0.0;
      sale?.discount = null;
      sale?.insuranceCompanyId = null;
      sale?.insuranceCompanyName = null;
      sale?.insuranceDiscount = null;
      sale?.paymentMethod = PaymentMethod.cash;
      sale?.saleDate = DateTime.now();
    });
    // إعادة تعيين حقول الزبون
    customerNameController.clear();
    customerPhoneController.clear();
    notesController.clear();
    cashReceived.value = 0.0;
    changeAmount.value = 0.0;
    selectedInsuranceCompany.value = null;
    searchResults.clear();
    searchQuery.value = '';
    _focusSearchField();
  }

  void _focusSearchField() {
    // استخدام addPostFrameCallback لضمان أن الواجهة جاهزة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchFocusNode.hasFocus) {
      } else {
        searchFocusNode.requestFocus();
      }
    });
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