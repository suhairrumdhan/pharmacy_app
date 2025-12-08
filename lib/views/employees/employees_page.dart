// views/employees_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/employee_controller.dart';
import '../../models/employee_model.dart';

class EmployeesPage extends StatelessWidget {
  EmployeesPage({super.key});
  final EmployeeController employeeController = Get.put(EmployeeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              employeeController.loadEmployees();
              employeeController.loadRoles();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEmployeeDialog,
          ),
        ],
      ),
      body: Obx(() {
        if (employeeController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (employeeController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(employeeController.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    employeeController.loadEmployees();
                    employeeController.loadRoles();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // إحصائيات سريعة
              _buildStatsCard(),
              const SizedBox(height: 20),

              // الأدوار
              Expanded(
                flex: 1,
                child: _buildRolesSection(),
              ),
              const SizedBox(height: 20),

              // قائمة الموظفين
              Expanded(
                flex: 3,
                child: _buildEmployeesList(),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = employeeController.getEmployeeStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('إجمالي الموظفين', '${stats['total']}', Icons.people),
            _buildStatItem('نشطين', '${stats['active']}', Icons.check_circle, Colors.green),
            _buildStatItem('غير نشطين', '${stats['inactive']}', Icons.remove_circle, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRolesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأدوار والصلاحيات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: employeeController.roles
                    .map((role) => _buildRoleChip(role))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(EmployeeRole role) {
    final employeeCount = employeeController.getEmployeesByRole(role.id).length;

    return GestureDetector(
      onTap: () => _showRoleDetailsDialog(role),
      child: Chip(
        backgroundColor: _getRoleColor(role.id),
        label: Text('${role.name} ($employeeCount)'),
        avatar: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(employeeCount.toString()),
        ),
        deleteIcon: role.isEditable ? const Icon(Icons.edit) : null,
        onDeleted: role.isEditable
            ? () => _showEditRoleDialog(role)
            : null,
      ),
    );
  }

  Color _getRoleColor(String roleId) {
    switch (roleId) {
      case 'owner':
        return Colors.red.shade100;
      case 'manager':
        return Colors.blue.shade100;
      case 'pharmacist':
        return Colors.green.shade100;
      case 'assistant':
        return Colors.orange.shade100;
      case 'cashier':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget _buildEmployeesList() {
    return Card(
      child: Obx(() {
        if (employeeController.employees.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد موظفين'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: employeeController.employees.length,
          itemBuilder: (context, index) {
            final employee = employeeController.employees[index];
            final role = employeeController.getRoleById(employee.roleId);

            return _buildEmployeeCard(employee, role);
          },
        );
      }),
    );
  }

  Widget _buildEmployeeCard(PharmacyEmployee employee, EmployeeRole? role) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: employee.isActive ? Colors.green : Colors.grey,
          child: Text(
            employee.fullName.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(employee.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${employee.username}'),
            if (role != null) Text(role.name),
            Text(employee.isActive ? 'نشط' : 'غير نشط'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                employee.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: employee.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => employeeController.toggleEmployeeStatus(employee.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditEmployeeDialog(employee),
            ),
          ],
        ),
        onTap: () => _showEmployeeDetailsDialog(employee),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    Get.defaultDialog(
      title: 'إضافة موظف جديد',
      content: _EmployeeForm(
        onSubmit: (employeeData) async {
          final success = await employeeController.addEmployee(
            fullName: employeeData['fullName']!,
            username: employeeData['username']!,
            password: employeeData['password']!,
            email: employeeData['email']!,
            phoneNumber: employeeData['phoneNumber']!,
            roleId: employeeData['roleId']!,
          );

          if (success) {
            Get.back();
            Get.snackbar('تم', 'تم إضافة الموظف بنجاح');
          }
        },
      ),
    );
  }

  void _showEditEmployeeDialog(PharmacyEmployee employee) {
    Get.defaultDialog(
      title: 'تعديل موظف',
      content: _EmployeeForm(
        employee: employee,
        onSubmit: (employeeData) async {
          final updatedEmployee = employee.copyWith(
            fullName: employeeData['fullName'],
            username: employeeData['username'],
            email: employeeData['email'],
            phoneNumber: employeeData['phoneNumber'],
            roleId: employeeData['roleId'],
          );

          final success = await employeeController.updateEmployee(updatedEmployee);

          if (success) {
            Get.back();
            Get.snackbar('تم', 'تم تحديث الموظف بنجاح');
          }
        },
      ),
    );
  }

  void _showEmployeeDetailsDialog(PharmacyEmployee employee) {
    final role = employeeController.getRoleById(employee.roleId);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Text(
                    employee.fullName.substring(0, 1),
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('الاسم الكامل', employee.fullName),
              _buildDetailRow('اسم المستخدم', '@${employee.username}'),
              _buildDetailRow('البريد الإلكتروني', employee.email),
              _buildDetailRow('رقم الهاتف', employee.phoneNumber),
              _buildDetailRow('الدور', role?.name ?? 'غير محدد'),
              _buildDetailRow('تاريخ الانضمام',
                  '${employee.joinDate.day}/${employee.joinDate.month}/${employee.joinDate.year}'),
              _buildDetailRow('الحالة', employee.isActive ? 'نشط' : 'غير نشط'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل'),
                    onPressed: () {
                      Get.back();
                      _showEditEmployeeDialog(employee);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _confirmDeleteEmployee(employee),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showRoleDetailsDialog(EmployeeRole role) {
    Get.dialog(
      AlertDialog(
        title: Text(role.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(role.description),
              const SizedBox(height: 16),
              const Text('الصلاحيات:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: role.permissions
                    .map((permission) => Chip(
                  label: Text(_getPermissionName(permission)),
                  backgroundColor: Colors.blue.shade50,
                ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(EmployeeRole role) {
    // TODO: تنفيذ نموذج تعديل الدور
    Get.snackbar('تعديل', 'نافذة تعديل الدور قيد التطوير');
  }

  String _getPermissionName(Permission permission) {
    final names = {
      Permission.viewOrders: 'عرض الطلبات',
      Permission.editOrders: 'تعديل الطلبات',
      Permission.deleteOrders: 'حذف الطلبات',
      Permission.updateOrderStatus: 'تحديث حالة الطلب',
      Permission.viewProducts: 'عرض المنتجات',
      Permission.addProducts: 'إضافة منتجات',
      Permission.editProducts: 'تعديل المنتجات',
      Permission.deleteProducts: 'حذف المنتجات',
      Permission.manageInventory: 'إدارة المخزون',
      Permission.viewCustomers: 'عرض العملاء',
      Permission.editCustomers: 'تعديل العملاء',
      Permission.viewReports: 'عرض التقارير',
      Permission.generateReports: 'إنشاء تقارير',
      Permission.viewEmployees: 'عرض الموظفين',
      Permission.addEmployees: 'إضافة موظفين',
      Permission.editEmployees: 'تعديل الموظفين',
      Permission.deleteEmployees: 'حذف موظفين',
      Permission.manageRoles: 'إدارة الأدوار',
      Permission.viewSettings: 'عرض الإعدادات',
      Permission.editSettings: 'تعديل الإعدادات',
      Permission.processSales: 'معالجة المبيعات',
      Permission.viewSalesHistory: 'عرض سجل المبيعات',
      Permission.applyDiscounts: 'تطبيق الخصومات',
      Permission.managePromotions: 'إدارة العروض',
      Permission.manageAll: 'إدارة كاملة',
      Permission.pharmacyOwner: 'مالك الصيدلية',
    };

    return names[permission] ?? permission.toString();
  }

  void _confirmDeleteEmployee(PharmacyEmployee employee) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل أنت متأكد من حذف الموظف ${employee.fullName}؟',
      textConfirm: 'نعم، احذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        final success = await employeeController.deleteEmployee(employee.id);
        if (success) {
          Get.back();
          Get.snackbar('تم', 'تم حذف الموظف بنجاح');
        }
      },
    );
  }
}

// نموذج إدخال بيانات الموظف
class _EmployeeForm extends StatefulWidget {
  final PharmacyEmployee? employee;
  final Function(Map<String, String>) onSubmit;

  const _EmployeeForm({
    this.employee,
    required this.onSubmit,
  });

  @override
  __EmployeeFormState createState() => __EmployeeFormState();
}

class __EmployeeFormState extends State<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRoleId;

  @override
  void initState() {
    super.initState();

    if (widget.employee != null) {
      _fullNameController.text = widget.employee!.fullName;
      _usernameController.text = widget.employee!.username;
      _emailController.text = widget.employee!.email;
      _phoneController.text = widget.employee!.phoneNumber;
      _selectedRoleId = widget.employee!.roleId;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeController = Get.find<EmployeeController>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الاسم الكامل';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.account_circle),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم المستخدم';
                }
                if (value.length < 3) {
                  return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (widget.employee == null)
              Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'البريد الإلكتروني غير صالح';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم الهاتف';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Obx(() {
              return DropdownButtonFormField<String>(
                value: _selectedRoleId,
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  prefixIcon: Icon(Icons.work),
                ),
                items: employeeController.roles
                    .where((role) => role.isEditable || widget.employee?.roleId == role.id)
                    .map((role) => DropdownMenuItem(
                  value: role.id,
                  child: Text(role.name),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoleId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الدور';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(widget.employee == null ? 'إضافة' : 'تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final employeeData = {
        'fullName': _fullNameController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'roleId': _selectedRoleId!,
      };

      widget.onSubmit(employeeData);
    }
  }
}