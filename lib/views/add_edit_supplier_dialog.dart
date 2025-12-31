// lib/views/suppliers/add_edit_supplier_dialog.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Added iconsax import
import '../../controllers/supplier_controller.dart';
import '../../models/supplier_model.dart';

class AddEditSupplierDialog extends StatefulWidget {
  final Supplier? supplier;

  const AddEditSupplierDialog({this.supplier, super.key});

  @override
  _AddEditSupplierDialogState createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final SupplierController controller = Get.find();

  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  late DateTime _contractStartDate;
  late DateTime? _contractEndDate;
  late String _status;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _nameController = TextEditingController(text: supplier?.name ?? '');
    _contactPersonController = TextEditingController(text: supplier?.contactPerson ?? '');
    _phoneController = TextEditingController(text: supplier?.phone ?? '');
    _addressController = TextEditingController(text: supplier?.address ?? '');
    _notesController = TextEditingController(text: supplier?.notes ?? '');

    _contractStartDate = supplier?.contractStartDate ?? DateTime.now();
    _contractEndDate = supplier?.contractEndDate;
    _status = supplier?.status ?? 'فعال';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              widget.supplier == null ? Iconsax.add : Iconsax.edit_2,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.supplier == null ? 'إضافة مورد جديد' : 'تعديل بيانات المورد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Iconsax.close_circle,
                            color: Colors.red.shade600,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Two-column fields
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Row 1: اسم المورد والشخص المسؤول
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildEditField(
                                      label: 'اسم المورد *',
                                      icon: Iconsax.shop,
                                      controller: _nameController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى إدخال اسم المورد';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildEditField(
                                      label: 'الشخص المسؤول *',
                                      icon: Iconsax.user,
                                      controller: _contactPersonController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى إدخال اسم الشخص المسؤول';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Row 2: رقم الهاتف والحالة
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildEditField(
                                      label: 'رقم الهاتف *',
                                      icon: Iconsax.call,
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى إدخال رقم الهاتف';
                                        }
                                        if (value.length < 10) {
                                          return 'رقم الهاتف غير صالح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatusDropdown(),
                                  ),
                                ],
                              ),
                            ),

                            // العنوان
                            SizedBox(
                              width: double.infinity,
                              child: _buildEditField(
                                label: 'العنوان *',
                                icon: Iconsax.location,
                                controller: _addressController,
                                maxLines: 2,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال العنوان';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // تاريخ التعاقد
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildDateField(
                                      label: 'تاريخ بدء التعاقد',
                                      icon: Iconsax.calendar_1,
                                      date: _contractStartDate,
                                      onDateSelected: (date) {
                                        setState(() {
                                          _contractStartDate = date;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDateField(
                                      label: 'تاريخ نهاية التعاقد (اختياري)',
                                      icon: Iconsax.calendar_1,
                                      date: _contractEndDate,
                                      isOptional: true,
                                      onDateSelected: (date) {
                                        setState(() {
                                          _contractEndDate = date;
                                        });
                                      },
                                      onClear: () {
                                        setState(() {
                                          _contractEndDate = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ملاحظات
                            SizedBox(
                              width: double.infinity,
                              child: _buildEditField(
                                label: 'ملاحظات',
                                icon: Iconsax.note,
                                controller: _notesController,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      Get.back(closeOverlays: true),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.close_circle,
                                        color: Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: _saveSupplier,
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.supplier == null ? Iconsax.add : Iconsax.tick_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.supplier == null ? 'إضافة' : 'حفظ التعديلات',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                cursorColor: Colors.blue.shade600,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
                validator: validator,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    icon,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  hintText: 'أدخل هنا...',
                  hintStyle: TextStyle(
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  filled: false,
                  errorStyle: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            'الحالة',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Iconsax.status,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  hintText: 'اختر الحالة',
                  hintStyle: TextStyle(
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                icon: Icon(
                  Iconsax.arrow_down_1,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
                dropdownColor: Colors.blue.shade50,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
                items: ['فعال', 'معلق', 'متوقف']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
    bool isOptional = false,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                border: Border.all(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: date ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.blue.shade700,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.grey.shade900,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selectedDate != null) {
                            onDateSelected(selectedDate);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            date != null
                                ? DateFormat('yyyy-MM-dd').format(date)
                                : isOptional
                                ? 'غير محدد'
                                : 'يرجى تحديد التاريخ',
                            style: TextStyle(
                              fontSize: 15,
                              color: date != null
                                  ? Colors.blue.shade900
                                  : Colors.blue.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Iconsax.calendar_edit,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.blue.shade700,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.grey.shade900,
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (selectedDate != null) {
                          onDateSelected(selectedDate);
                        }
                      },
                    ),
                    if (isOptional && date != null)
                      IconButton(
                        icon: Icon(
                          Iconsax.close_circle,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        onPressed: onClear,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supplier = Supplier(
          id: widget.supplier?.id ?? '',
          name: _nameController.text,
          contactPerson: _contactPersonController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          contractStartDate: _contractStartDate,
          contractEndDate: _contractEndDate,
          status: _status,
          notes: _notesController.text,
        );

        if (widget.supplier == null) {
          await controller.addSupplier(supplier);
          Get.snackbar(
            'نجاح',
            'تم إضافة المورد بنجاح',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
          );
        } else {
          await controller.updateSupplier(widget.supplier!.id, supplier);
          Get.snackbar(
            'نجاح',
            'تم تحديث بيانات المورد بنجاح',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
          );
        }

        Get.back(closeOverlays: true);
      } catch (e) {
        Get.snackbar(
          'خطأ',
          'فشل في حفظ بيانات المورد',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    }
  }
}