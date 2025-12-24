import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendanceManagementDialog extends StatelessWidget {
  final RxString _currentTime = DateFormat('HH:mm:ss').format(DateTime.now()).obs;
  final RxBool _isClockedIn = false.obs;
  final RxString _clockInTime = ''.obs;
  final RxString _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now()).obs;
  final RxString _selectedShift = 'صباحي'.obs;

  // بيانات الورديات التفصيلية
  final List<Shift> shifts = [
    Shift(name: 'صباحي', startTime: '08:00', endTime: '16:00'),
    Shift(name: 'مسائي', startTime: '16:00', endTime: '00:00'),
    Shift(name: 'ليلي', startTime: '00:00', endTime: '08:00'),
  ];

  // بيانات الموظفين مع سجلات الحضور التفصيلية
  final List<Employee> employees = [
    Employee(
      id: '1',
      name: 'محمد علي',
      position: 'مدير مبيعات',
      username: 'mohamed',
      password: '123456',
      shifts: {
        '2024-01-14': [
          AttendanceRecord(
            date: '2024-01-14',
            shift: 'صباحي',
            clockIn: '08:05',
            clockOut: '16:10',
            status: 'مكتمل',
            lateMinutes: 5,
          )
        ],
      },
    ),
    Employee(
      id: '2',
      name: 'سارة خالد',
      position: 'محاسبة',
      username: 'sara',
      password: '123456',
      shifts: {
        '2024-01-14': [
          AttendanceRecord(
            date: '2024-01-14',
            shift: 'مسائي',
            clockIn: '16:15',
            clockOut: '00:05',
            status: 'مكتمل',
            lateMinutes: 15,
          )
        ],
      },
    ),
    Employee(
      id: '3',
      name: 'أحمد محمد',
      position: 'مندوب مبيعات',
      username: 'ahmed',
      password: '123456',
      shifts: {
        '2024-01-14': [
          AttendanceRecord(
            date: '2024-01-14',
            shift: 'صباحي',
            clockIn: '07:55',
            clockOut: '16:00',
            status: 'مكتمل',
            lateMinutes: 0,
          )
        ],
      },
    ),
    Employee(
      id: '4',
      name: 'فاطمة عبدالله',
      position: 'سكرتيرة',
      username: 'fatima',
      password: '123456',
      shifts: {
        '2024-01-14': [
          AttendanceRecord(
            date: '2024-01-14',
            shift: 'صباحي',
            clockIn: '08:00',
            clockOut: null,
            status: 'قيد العمل',
            lateMinutes: 0,
          )
        ],
      },
    ),
  ];

  AttendanceManagementDialog({super.key}) {
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      _currentTime.value = DateFormat('HH:mm:ss').format(DateTime.now());
      _updateTime();
    });
  }

  // تسجيل دخول الموظف الحالي (للمستخدم)
  void _clockInOut() {
    if (!_isClockedIn.value) {
      _isClockedIn.value = true;
      _clockInTime.value = DateFormat('HH:mm').format(DateTime.now());
      Get.snackbar(
        'تم تسجيل الحضور',
        'تم تسجيل الحضور الساعة ${_clockInTime.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      _isClockedIn.value = false;
      final clockOutTime = DateFormat('HH:mm').format(DateTime.now());
      Get.snackbar(
        'تم تسجيل الانصراف',
        'تم تسجيل الانصراف الساعة $clockOutTime',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  // إدارة موظف (للمدير)
  void _manageEmployee(Employee employee) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إدارة ${employee.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'الوظيفة: ${employee.position}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // تعديل الورديات للموظف
            const Text(
              'تعديل الورديات:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),

            // التاريخ
            Obx(() => Row(
              children: [
                const Text('التاريخ: '),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedDate.value),
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(),
                      ),
                    ),
                  ),
                ),
              ],
            )),

            const SizedBox(height: 10),

            // نوع الوردية
            Obx(() => Row(
              children: [
                const Text('الوردية: '),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedShift.value,
                    onChanged: (value) {
                      _selectedShift.value = value!;
                    },
                    items: shifts.map((shift) {
                      return DropdownMenuItem(
                        value: shift.name,
                        child: Text('${shift.name} (${shift.startTime} - ${shift.endTime})'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )),

            const SizedBox(height: 20),

            // أزرار التحكم
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _assignShift(employee, _selectedDate.value, _selectedShift.value);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text(
                      'تعيين وردية',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _viewEmployeeAttendance(employee);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text(
                      'سجل الحضور',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.toNamed('/employee-details', arguments: employee);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text(
                'تفاصيل الموظف',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _selectedDate.value = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _assignShift(Employee employee, String date, String shift) {
    Get.snackbar(
      'تم التعيين',
      'تم تعيين وردية $shift للموظف ${employee.name} بتاريخ $date',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _viewEmployeeAttendance(Employee employee) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'سجل حضور ${employee.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  for (var entry in employee.shifts.entries)
                    for (var record in entry.value)
                      _buildAttendanceCard(record),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(record.status),
          child: Text(
            record.shift.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('تاريخ: ${record.date}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوردية: ${record.shift}'),
            Text('الدخول: ${record.clockIn} ${record.lateMinutes > 0 ? '(متأخر ${record.lateMinutes} دقيقة)' : ''}'),
            if (record.clockOut != null) Text('الخروج: ${record.clockOut}'),
            Text('الحالة: ${record.status}'),
          ],
        ),
        trailing: Icon(
          record.status == 'مكتمل' ? Icons.check_circle : Icons.access_time,
          color: record.status == 'مكتمل' ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return Colors.green;
      case 'قيد العمل':
        return Colors.orange;
      case 'متأخر':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
            maxHeight: 900,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),

                // Main Content
                Expanded(
                  child: Row(
                    children: [
                      // Left Section - Attendance Clock & Controls
                      Expanded(
                        flex: 3,
                        child: _buildLeftSection(),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.blue.shade100,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Right Section - Employee Management
                      Expanded(
                        flex: 7,
                        child: _buildRightSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          const Text(
            'نظام إدارة الحضور والورديات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            'التاريخ: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current Time Display
          Obx(() => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade100,
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.access_time, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                Text(
                  _currentTime.value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'الوقت الحالي',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 30),

          // Employee Quick Actions
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'إجراءات سريعة للمدير',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.bottomSheet(_buildShiftManagement());
                        },
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('إدارة الورديات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.toNamed('/attendance-report');
                        },
                        icon: const Icon(Icons.assignment, size: 18),
                        label: const Text('تقارير'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed('/add-employee');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة موظف جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Clock In/Out Button
          Obx(() => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isClockedIn.value ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _isClockedIn.value ? Colors.red.shade300 : Colors.green.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'تسجيل الحضور الشخصي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  _isClockedIn.value ? Icons.logout : Icons.login,
                  size: 40,
                  color: _isClockedIn.value ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _clockInOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isClockedIn.value ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isClockedIn.value ? 'تسجيل الانصراف' : 'تسجيل الحضور',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isClockedIn.value && _clockInTime.isNotEmpty)
                  Text(
                    'تم تسجيل الحضور الساعة ${_clockInTime.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShiftManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'إدارة الورديات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          ...shifts.map((shift) => ListTile(
            leading: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getShiftColor(shift.name),
                shape: BoxShape.circle,
              ),
            ),
            title: Text('${shift.name}: ${shift.startTime} - ${shift.endTime}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editShift(shift),
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteShift(shift),
                  color: Colors.red,
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _addNewShift,
            icon: const Icon(Icons.add),
            label: const Text('إضافة وردية جديدة'),
          ),
        ],
      ),
    );
  }

  void _editShift(Shift shift) {
    Get.defaultDialog(
      title: 'تعديل الوردية',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: shift.startTime,
            decoration: const InputDecoration(labelText: 'وقت البداية'),
          ),
          TextFormField(
            initialValue: shift.endTime,
            decoration: const InputDecoration(labelText: 'وقت النهاية'),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        child: const Text('حفظ'),
      ),
    );
  }

  void _deleteShift(Shift shift) {
    Get.defaultDialog(
      title: 'حذف الوردية',
      content: Text('هل أنت متأكد من حذف وردية ${shift.name}؟'),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('حذف'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('إلغاء'),
      ),
    );
  }

  void _addNewShift() {
    Get.defaultDialog(
      title: 'إضافة وردية جديدة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'اسم الوردية'),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'وقت البداية'),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'وقت النهاية'),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        child: const Text('إضافة'),
      ),
    );
  }

  Widget _buildRightSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: Colors.blue, size: 24),
              SizedBox(width: 10),
              Text(
                'إدارة الموظفين والورديات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'اضغط على أي موظف لإدارة وردياته وسجلات الحضور',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 20),

          // جدول الموظفين
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الموظف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'الوظيفة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'الحالة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'إجراءات',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Employees List
                  Expanded(
                    child: ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                employee.name.substring(0, 1),
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    employee.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    employee.position,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildEmployeeStatus(employee),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () => _manageEmployee(employee),
                                        color: Colors.blue,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history, size: 18),
                                        onPressed: () => _viewEmployeeAttendance(employee),
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _manageEmployee(employee),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Stats
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('عدد الموظفين', employees.length.toString(), Icons.people),
                _buildStatItem('حاضرين اليوم', '3', Icons.check_circle),
                _buildStatItem('متأخرين', '1', Icons.watch_later),
                _buildStatItem('إجازات', '0', Icons.beach_access),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeStatus(Employee employee) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecords = employee.shifts[today];

    if (todayRecords == null || todayRecords.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.circle, size: 10, color: Colors.grey),
          SizedBox(width: 5),
          Text(
            'لا توجد وردية',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    final activeRecord = todayRecords.firstWhere(
          (record) => record.status == 'قيد العمل',
      orElse: () => todayRecords.last,
    );

    Color statusColor;
    String statusText;

    switch (activeRecord.status) {
      case 'قيد العمل':
        statusColor = Colors.green;
        statusText = 'قيد العمل';
        break;
      case 'مكتمل':
        statusColor = Colors.blue;
        statusText = 'مكتمل';
        break;
      case 'متأخر':
        statusColor = Colors.orange;
        statusText = 'متأخر';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير محدد';
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: statusColor),
        const SizedBox(width: 5),
        Text(
          statusText,
          style: TextStyle(fontSize: 12, color: statusColor),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Color _getShiftColor(String shiftName) {
    switch (shiftName) {
      case 'صباحي':
        return Colors.green;
      case 'مسائي':
        return Colors.orange;
      case 'ليلي':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}

class Shift {
  final String name;
  final String startTime;
  final String endTime;

  Shift({
    required this.name,
    required this.startTime,
    required this.endTime,
  });
}

class Employee {
  final String id;
  final String name;
  final String position;
  final String username;
  final String password;
  final Map<String, List<AttendanceRecord>> shifts;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.username,
    required this.password,
    required this.shifts,
  });
}

class AttendanceRecord {
  final String date;
  final String shift;
  final String clockIn;
  final String? clockOut;
  final String status;
  final int lateMinutes;

  AttendanceRecord({
    required this.date,
    required this.shift,
    required this.clockIn,
    this.clockOut,
    required this.status,
    required this.lateMinutes,
  });
}