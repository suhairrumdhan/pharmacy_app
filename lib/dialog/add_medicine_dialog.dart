import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_model.dart';

class AddMedicineDialog extends StatefulWidget {
  const AddMedicineDialog({super.key});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final InventoryController inventoryController = Get.find();
  final _formKey = GlobalKey<FormState>();

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
  final stripsPerBoxController = TextEditingController(text: '0');

  DateTime expiryDate = DateTime.now().add(const Duration(days: 365));

  // متغيرات للقائمة المنسدلة
  String? selectedCategory;
  UnitType? selectedUnit = UnitType.piece;
  List<String> categories = [];
  bool isLoadingCategories = true;

  // متغيرات إضافية
  bool sellByStrip = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // دالة لتحميل التصنيفات من الصيدلية الحالية
  Future<void> _loadCategories() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(_pharmacyId)
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();
        if (data != null && data['categories'] != null && data['categories'] is List) {
          List<dynamic> categoryList = data['categories'];
          setState(() {
            categories = categoryList.map((category) => category.toString()).toList();
            isLoadingCategories = false;
          });
          return;
        }
      }

      // إذا لم توجد تصنيفات، نستخدم القيمة الافتراضية
      setState(() {
        isLoadingCategories = false;
      });

    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // دالة لإضافة تصنيف جديد وحفظه في Firestore
  Future<void> _addNewCategory() async {
    if (newCategoryController.text.trim().isEmpty) {
      return;
    }

    String newCategory = newCategoryController.text.trim();

    try {
      // تحديث مصفوفة categories في الصيدلية
      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(_pharmacyId)
          .update({
        'categories': FieldValue.arrayUnion([newCategory])
      });

      // تحديث الواجهة
      setState(() {
        if (!categories.contains(newCategory)) {
          categories.add(newCategory);
        }
        selectedCategory = newCategory;
        newCategoryController.clear();
      });

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

    // إغلاق dialog الإضافة
    Navigator.of(context).pop();
  }

  // دالة لعرض dialog لإضافة تصنيف جديد
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'إضافة تصنيف جديد',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            TextField(
              controller: newCategoryController,
              decoration: InputDecoration(
                labelText: 'التصنيف الجديد',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.add),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: (_) => _addNewCategory(),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addNewCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text('إضافة', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // الحصول على ID الصيدلية الحالية
  String? get _pharmacyId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildBasicInfo(),
                      const SizedBox(height: 16),
                      _buildPurchaseInfo(),
                      const SizedBox(height: 16),
                      _buildSellingInfo(),
                      const SizedBox(height: 16),
                      _buildAdditionalInfo(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication, size: 32, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة صنف جديد',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'أدخل معلومات الدواء بشكل كامل',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection(
      title: 'المعلومات الأساسية',
      icon: Icons.info,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'اسم الصنف التجاري',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.medication),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال اسم الصنف';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: scientificNameController,
          decoration: InputDecoration(
            labelText: 'الاسم العلمي (الإنجليزي)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.science),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال الاسم العلمي';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: 'الوصف (اختياري)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.description),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        isLoadingCategories
            ? _buildLoadingWidget()
            : _buildCategoryDropdown(),
      ],
    );
  }

  Widget _buildPurchaseInfo() {
    return _buildSection(
      title: 'معلومات الشراء والمخزون',
      icon: Icons.shopping_cart,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: purchasePriceController,
                decoration: InputDecoration(
                  labelText: 'سعر الشراء',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال سعر الشراء';
                  }
                  if (double.tryParse(value) == null) {
                    return 'يرجى إدخال سعر صحيح';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'وحدة القياس',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UnitType>(
                    value: selectedUnit,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('اختر الوحدة'),
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: UnitType.values.map((unit) {
                      String unitName = _getUnitName(unit);
                      return DropdownMenuItem<UnitType>(
                        value: unit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(unitName),
                        ),
                      );
                    }).toList(),
                    onChanged: (UnitType? newValue) {
                      setState(() {
                        selectedUnit = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'الكمية المتاحة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الكمية';
                  }
                  if (int.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: unitsPerPackageController,
                decoration: InputDecoration(
                  labelText: 'عدد الوحدات في العبوة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'مثال: 10 قطع في العلبة',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSellingInfo() {
    double? stripPrice = 0;
    if (sellByStrip && stripsPerBoxController.text.isNotEmpty) {
      try {
        int stripsPerBox = int.parse(stripsPerBoxController.text);
        if (stripsPerBox > 0 && sellingPriceController.text.isNotEmpty) {
          double sellingPrice = double.parse(sellingPriceController.text);
          stripPrice = sellingPrice / stripsPerBox;
        }
      } catch (e) {
        stripPrice = 0;
      }
    }

    return _buildSection(
      title: 'معلومات البيع',
      icon: Icons.sell,
      children: [
        TextFormField(
          controller: sellingPriceController,
          decoration: InputDecoration(
            labelText: 'سعر البيع للوحدة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.money),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال سعر البيع';
            }
            if (double.tryParse(value) == null) {
              return 'يرجى إدخال سعر صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: sellByStrip,
                    onChanged: (value) {
                      setState(() {
                        sellByStrip = value ?? false;
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  const Text('البيع بالشريط', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.local_pharmacy, color: Colors.blue.shade700),
                ],
              ),
              if (sellByStrip) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: stripsPerBoxController,
                  decoration: InputDecoration(
                    labelText: 'عدد الأشرطة في العلبة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
              if (sellByStrip && stripPrice != null && stripPrice > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'سعر الشريط: ${stripPrice.toStringAsFixed(2)} د.ع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return _buildSection(
      title: 'المعلومات الإضافية',
      icon: Icons.more_horiz,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: minStockController,
                decoration: InputDecoration(
                  labelText: 'الحد الأدنى للمخزون',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.warning),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: supplierController,
                decoration: InputDecoration(
                  labelText: 'المورد',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.business),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: barcodeController,
          decoration: InputDecoration(
            labelText: 'الباركود (اختياري)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.qr_code),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Text('تاريخ انتهاء الصلاحية:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _selectExpiryDate,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
                icon: Icon(Icons.calendar_month, color: Colors.orange.shade700),
                label: Text(
                  _formatDate(expiryDate),
                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              icon: const Icon(Icons.cancel, color: Colors.grey),
              label: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة الدواء', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'الفئة (اختياري)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('اختر التصنيف'),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('لا يوجد'),
              ),
            ),
            ...categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                ),
              );
            }).toList(),
            const DropdownMenuItem<String>(
              value: 'add_new',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('إضافة تصنيف جديد'),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue == 'add_new') {
              _showAddCategoryDialog();
            } else {
              setState(() {
                selectedCategory = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Text('جاري تحميل التصنيفات...', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != expiryDate) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _getUnitName(UnitType unit) {
    switch (unit) {
      case UnitType.piece:
        return 'قطعة';
      case UnitType.strip:
        return 'شريط';
      case UnitType.box:
        return 'صندوق';
      case UnitType.bottle:
        return 'زجاجة';
      case UnitType.ml:
        return 'مل';
    }
  }

  void _addMedicine() async {
    if (_formKey.currentState!.validate()) {
      if (selectedUnit == null) {
        Get.snackbar('خطأ', 'يرجى اختيار وحدة القياس',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      try {
        // تحويل البيانات
        int quantity = int.parse(quantityController.text);
        double purchasePrice = double.parse(purchasePriceController.text);
        double sellingPrice = double.parse(sellingPriceController.text);

        int? unitsPerPackage;
        if (unitsPerPackageController.text.isNotEmpty) {
          unitsPerPackage = int.tryParse(unitsPerPackageController.text);
        }

        int? stripsPerBox;
        if (sellByStrip && stripsPerBoxController.text.isNotEmpty) {
          stripsPerBox = int.tryParse(stripsPerBoxController.text);
        }

        double? stripPrice;
        if (sellByStrip && stripsPerBox != null && stripsPerBox > 0) {
          stripPrice = sellingPrice / stripsPerBox;
        }

        int? minStockLevel;
        if (minStockController.text.isNotEmpty) {
          minStockLevel = int.tryParse(minStockController.text);
        }

        final newMedicine = Medicine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text,
          scientificName: scientificNameController.text,
          quantity: quantity,
          description: descriptionController.text.isEmpty ? null : descriptionController.text,
          category: selectedCategory,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          unit: selectedUnit,
          unitsPerPackage: unitsPerPackage,
          sellByStrip: sellByStrip,
          stripsPerBox: stripsPerBox,
          stripPrice: stripPrice,
          minStockLevel: minStockLevel,
          supplier: supplierController.text.isEmpty ? null : supplierController.text,
          expiryDate: expiryDate,
          barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
          lastUpdated: DateTime.now(),
        );

        await inventoryController.addMedicine(newMedicine);

        Get.snackbar(
          'نجاح',
          'تم إضافة الدواء بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Navigator.pop(context);
      } catch (e) {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء إضافة الدواء: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
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
    stripsPerBoxController.dispose();
    super.dispose();
  }
}