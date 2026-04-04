// lib/views/insurance/add_edit_insurance_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../controllers/insurance_company_controller.dart';
import '../../models/insurance_company_model.dart';

class AddEditInsuranceDialog extends StatefulWidget {
  final InsuranceCompany? company;

  const AddEditInsuranceDialog({super.key, this.company});

  @override
  State<AddEditInsuranceDialog> createState() => _AddEditInsuranceDialogState();
}

class _AddEditInsuranceDialogState extends State<AddEditInsuranceDialog> {
  final _formKey = GlobalKey<FormState>();
  final InsuranceCompanyController controller = Get.find<InsuranceCompanyController>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;
  late TextEditingController _discountPercentageController;
  late String _status;
  late TextEditingController _notesController;

  // إضافة حقول التاريخ
  late DateTime _contractStartDate;
  late DateTime? _contractEndDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _codeController = TextEditingController(text: widget.company?.code ?? '');
    _phoneController = TextEditingController(text: widget.company?.phone ?? '');
    _addressController = TextEditingController(text: widget.company?.address ?? '');
    _contactPersonController = TextEditingController(text: widget.company?.contactPerson ?? '');

    _discountPercentageController = TextEditingController(
        text: widget.company?.discountPercentage.toString() ?? '0.0'
    );
    _status = widget.company?.status ?? 'فعال';
    _notesController = TextEditingController(text: widget.company?.notes ?? '');

    // تهيئة حقول التاريخ
    _contractStartDate = widget.company?.contractStartDate ?? DateTime.now();
    _contractEndDate = widget.company?.contractEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _discountPercentageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // دالة اختيار التاريخ - تم التعديل لاستخدام Theme
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // استخدم Navigator.of(context).push بدلاً من showDatePicker مباشرة
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
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
          child: DatePickerDialog(
            initialDate: isStartDate ? _contractStartDate : (_contractEndDate ?? DateTime.now()),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _contractStartDate = picked;
        } else {
          _contractEndDate = picked;
        }
      });
    }
  }
  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final company = InsuranceCompany(
      id: widget.company?.id ?? '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      contactPerson: _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      discountPercentage: double.parse(_discountPercentageController.text),
      contractStartDate: _contractStartDate,
      contractEndDate: _contractEndDate,
      status: _status,
      notes: _notesController.text.trim(),
      createdAt: widget.company?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.company == null) {
        await controller.addInsuranceCompany(company);
        Get.snackbar(
          'تمت الإضافة',
          'تمت إضافة شركة التأمين بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        await controller.updateInsuranceCompany(company.id, company);
        Get.snackbar(
          'تم التحديث',
          'تم تحديث بيانات الشركة بنجاح',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
      Get.back();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ البيانات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.company != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // الهيدر
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF42a5f5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEdit ? Iconsax.edit_2 : Iconsax.add,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'تعديل شركة تأمين' : 'إضافة شركة تأمين جديدة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // المحتوى
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // الصف الأول
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _nameController,
                                  label: 'اسم الشركة *',
                                  icon: Iconsax.building,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال اسم الشركة';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _codeController,
                                  label: 'الكود الموحد *',
                                  icon: Iconsax.code,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'يرجى إدخال الكود الموحد';
                                    }

                                    final code = value.trim().toUpperCase();
                                    final regex = RegExp(r'^[A-Z0-9]+$');

                                    if (!regex.hasMatch(code)) {
                                      return 'الكود يجب أن يحتوي على حروف إنجليزية كبيرة وأرقام فقط';
                                    }

                                    if (code.length < 4) {
                                      return 'الكود قصير جدًا';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: _buildTextField(
                                  controller: _phoneController,
                                  label: 'رقم الهاتف *',
                                  icon: Iconsax.call,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال رقم الهاتف';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // الشخص المسؤول
                          Row(
                            children: [
                              Expanded(
                                child:
                                  _buildTextField(
                                    controller: _addressController,
                                    label: 'العنوان',
                                    icon: Iconsax.location,
                                  ),

                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: _buildTextField(
                                  controller: _contactPersonController,
                                  label: 'اسم الشخص المسؤول',
                                  icon: Iconsax.user,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // الصف الأخير
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _discountPercentageController,
                                  label: 'نسبة الخصم % *',
                                  icon: Iconsax.percentage_circle,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال نسبة الخصم';
                                    }
                                    final discount = double.tryParse(value);
                                    if (discount == null || discount < 0 || discount > 100) {
                                      return 'يجب أن تكون النسبة بين 0 و 100';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  value: _status,
                                  label: 'الحالة *',
                                  icon: Iconsax.status,
                                  items: const ['فعال', 'معلق', 'متوقف'],
                                  onChanged: (value) {
                                    setState(() => _status = value!);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // تاريخ العقد
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تاريخ بداية العقد *',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _selectDate(context, true),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.white,
                                          border: Border.all(color: Colors.blue.shade100, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Iconsax.calendar_1,
                                              color: Colors.blue.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              DateFormat('yyyy/MM/dd').format(_contractStartDate),
                                              style: TextStyle(
                                                color: Colors.blue.shade900,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تاريخ نهاية العقد',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _selectDate(context, false),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.white,
                                          border: Border.all(color: Colors.blue.shade100, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Iconsax.calendar_1,
                                              color: Colors.blue.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _contractEndDate != null
                                                    ? DateFormat('yyyy/MM/dd').format(_contractEndDate!)
                                                    : 'اختر تاريخ الانتهاء',
                                                style: TextStyle(
                                                  color: _contractEndDate != null
                                                      ? Colors.blue.shade900
                                                      : Colors.grey.shade400,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                          ),

                          const SizedBox(height: 16),

                          // الملاحظات
                          _buildTextField(
                            controller: _notesController,
                            label: 'ملاحظات',
                            icon: Iconsax.note,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 32),

                          // أزرار الحفظ والإلغاء
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1A73E8), Color(0xFF42a5f5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _saveCompany,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isLoading)
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          else
                                            Icon(
                                              isEdit ? Iconsax.edit_2 : Iconsax.save_2,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isLoading ? 'جاري الحفظ...' : (isEdit ? 'تحديث' : 'حفظ'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: Get.back,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 16,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Iconsax.close_circle, color: Colors.grey),
                                          SizedBox(width: 12),
                                          Text(
                                            'إلغاء',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: Colors.blue.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 12),
                child: Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'أدخل $label',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: Colors.blue.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 12),
                child: Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: value,
                  onChanged: onChanged,
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(Iconsax.arrow_down_1, color: Colors.blue.shade600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}