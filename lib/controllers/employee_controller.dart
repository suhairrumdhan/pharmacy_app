
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/employee_model.dart';

class EmployeeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // القوائم المفتعلة للبيانات التجريبية
  final RxList<Employee> employees = <Employee>[].obs;
  final RxList<Employee> filteredEmployees = <Employee>[].obs;

  // حالة البحث والفلترة
  final RxString searchText = ''.obs;
  final RxString selectedFilter = 'الجميع'.obs;

  // بيانات الموظف الحالي
  final Rx<Employee?> currentEmployee = Rx<Employee?>(null);

  // متغيرات التحكم
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final RxString selectedRole = 'صيدلي'.obs;
  final Rx<DateTime> hiringDate = DateTime.now().obs;
  final RxString contractType = 'دوام كامل'.obs;
  final RxString status = 'نشط'.obs;
  final RxString idCardUrl = ''.obs;
  final RxList<String> certificatesUrls = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    //upload from firebse
    setupSearchListener();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    usernameCtrl.dispose();
    codeCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }


  void setupSearchListener() {
    ever(searchText, (_) => filterEmployees());
    ever(selectedFilter, (_) => filterEmployees());
  }

  void filterEmployees() {
    if (searchText.isEmpty && selectedFilter.value == 'الجميع') {
      filteredEmployees.assignAll(employees);
      return;
    }

    var filtered = employees.where((employee) {
      bool matchesSearch = searchText.isEmpty ||
          employee.name.contains(searchText.value) ||
          employee.username.contains(searchText.value) ||
          employee.password.contains(searchText.value) ||
          employee.phone.contains(searchText.value);

      bool matchesFilter = selectedFilter.value == 'الجميع' ||
          employee.status == selectedFilter.value ||
          employee.role == selectedFilter.value;

      return matchesSearch && matchesFilter;
    }).toList();

    filteredEmployees.assignAll(filtered);
  }

  Future<void> addEmployee() async {
    if (_validateFields()) {
      final newEmployee = Employee(
        id: const Uuid().v4(),
        name: nameCtrl.text,
        username: usernameCtrl.text,
        password: passwordCtrl.text,
        phone: phoneCtrl.text,
        role: selectedRole.value,
        hiringDate: hiringDate.value,
        contractType: contractType.value,
        status: status.value,
        idCardUrl: idCardUrl.value,
        certificatesUrls: certificatesUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      // إضافة إلى Firestore (تعليق مؤقت للبيانات التجريبية)
      // await _firestore.collection('employees').doc(newEmployee.id).set(newEmployee.toMap());

      // إضافة إلى القائمة المحلية
      employees.add(newEmployee);
      filterEmployees();

      // إعادة تعيين الحقول
      _resetFields();

      Get.snackbar(
        'نجاح',
        'تم إضافة الموظف بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateEmployee() async {
    if (currentEmployee.value != null && _validateFields()) {
      final updatedEmployee = currentEmployee.value!.copyWith(
        name: nameCtrl.text,
        username: usernameCtrl.text,
        password: passwordCtrl.text,
        phone: phoneCtrl.text,
        role: selectedRole.value,
        hiringDate: hiringDate.value,
        contractType: contractType.value,
        status: status.value,
        idCardUrl: idCardUrl.value,
        certificatesUrls: certificatesUrls,
        updatedAt: DateTime.now(),
      );

      // تحديث في Firestore
      // await _firestore.collection('employees').doc(updatedEmployee.id).update(updatedEmployee.toMap());
      // تحديث القائمة المحلية
      final index = employees.indexWhere((e) => e.id == updatedEmployee.id);
      if (index != -1) {
        employees[index] = updatedEmployee;
        filterEmployees();
      }

      Get.snackbar(
        'نجاح',
        'تم تحديث بيانات الموظف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteEmployee() async {
    if (currentEmployee.value != null) {
      // حذف منطقي في Firestore
      // await _firestore.collection('employees').doc(currentEmployee.value!.id).update({'isDeleted': true});

      // حذف من القائمة المحلية
      employees.removeWhere((e) => e.id == currentEmployee.value!.id);
      filterEmployees();

      _resetFields();

      Get.snackbar(
        'تم الحذف',
        'تم حذف الموظف بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void loadEmployeeForEdit(Employee employee) {
    currentEmployee.value = employee;
    nameCtrl.text = employee.name;
    usernameCtrl.text = employee.username;
    passwordCtrl.text = employee.password;
    phoneCtrl.text = employee.phone;
    selectedRole.value = employee.role;
    hiringDate.value = employee.hiringDate;
    contractType.value = employee.contractType;
    status.value = employee.status;
    idCardUrl.value = employee.idCardUrl;
    certificatesUrls.assignAll(employee.certificatesUrls);
  }

  bool _validateFields() {
    if (nameCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إدخال الاسم');
      return false;
    }
    if (usernameCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إدخال اسم المستخدم');
      return false;
    }
    if (passwordCtrl.text.isEmpty && currentEmployee.value == null) {
      Get.snackbar('خطأ', 'الرجاء إدخال كلمة المرور');
      return false;
    }
    if (phoneCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إدخال رقم الهاتف');
      return false;
    }
    return true;
  }

  void _resetFields() {
    currentEmployee.value = null;
    nameCtrl.clear();
    usernameCtrl.clear();
    codeCtrl.clear();
    phoneCtrl.clear();
    passwordCtrl.clear();
    selectedRole.value = 'صيدلي';
    hiringDate.value = DateTime.now();
    contractType.value = 'دوام كامل';
    status.value = 'نشط';
    idCardUrl.value = '';
    certificatesUrls.clear();
  }

  // دالة لاختيار التاريخ
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: hiringDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.blue,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.blue[900],
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != hiringDate.value) {
      hiringDate.value = picked;
    }
  }

  // دوال رفع الملفات
  Future<void> uploadIdCard() async {
    // منطق رفع صورة البطاقة
    // idCardUrl.value = await uploadFile();
  }

  Future<void> uploadCertificate() async {
    // منطق رفع الشهادات
    // certificatesUrls.add(await uploadFile());
  }
}




