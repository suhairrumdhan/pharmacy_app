import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';

class BusinessHoursCard extends StatefulWidget {
  final BusinessHours hours;

  const BusinessHoursCard({Key? key, required this.hours}) : super(key: key);

  @override
  State<BusinessHoursCard> createState() => _BusinessHoursCardState();
}

class _BusinessHoursCardState extends State<BusinessHoursCard> {
  late BusinessHours _currentHours;
  late Map<String, Map<String, TimeOfDay>> _editingTimes;
  late SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _currentHours = widget.hours;
    _initializeEditingTimes();
  }

  void _initializeEditingTimes() {
    _editingTimes = {};

    final days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

    for (var day in days) {
      final timeString = _getDayTimeString(day);
      final times = timeString.split(' - ');

      _editingTimes[day] = {
        'start': _parseTimeString(times[0]),
        'end': _parseTimeString(times[1]),
      };
    }
  }

  String _getDayTimeString(String day) {
    switch (day) {
      case 'sunday': return _currentHours.sunday;
      case 'monday': return _currentHours.monday;
      case 'tuesday': return _currentHours.tuesday;
      case 'wednesday': return _currentHours.wednesday;
      case 'thursday': return _currentHours.thursday;
      case 'friday': return _currentHours.friday;
      case 'saturday': return _currentHours.saturday;
      default: return '09:00 ص - 05:00 م';
    }
  }

  void _updateDayTime(String day, String newTime) {
    setState(() {
      switch (day) {
        case 'sunday':
          _currentHours = _currentHours.copyWith(sunday: newTime);
          break;
        case 'monday':
          _currentHours = _currentHours.copyWith(monday: newTime);
          break;
        case 'tuesday':
          _currentHours = _currentHours.copyWith(tuesday: newTime);
          break;
        case 'wednesday':
          _currentHours = _currentHours.copyWith(wednesday: newTime);
          break;
        case 'thursday':
          _currentHours = _currentHours.copyWith(thursday: newTime);
          break;
        case 'friday':
          _currentHours = _currentHours.copyWith(friday: newTime);
          break;
        case 'saturday':
          _currentHours = _currentHours.copyWith(saturday: newTime);
          break;
      }
    });

    // حفظ في Firebase
    _controller.saveBusinessHours(_currentHours);
  }

  Future<void> _showTimePickerForDay(String day, String type) async {
    final currentTime = _editingTimes[day]?[type] ?? TimeOfDay(hour: 9, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (time != null) {
      setState(() {
        _editingTimes[day]![type] = time;

        // تحديث السلسلة الكاملة
        final startTime = _editingTimes[day]!['start']!;
        final endTime = _editingTimes[day]!['end']!;
        final newTimeString = '${_formatTime(startTime)} - ${_formatTime(endTime)}';

        _updateDayTime(day, newTimeString);
      });
    }
  }

  TimeOfDay _parseTimeString(String timeText) {
    try {
      final isPM = timeText.contains('م');
      final cleanTime = timeText
          .replaceAll('ص', '')
          .replaceAll('م', '')
          .replaceAll(' ', '')
          .trim();

      final parts = cleanTime.split(':');
      if (parts.length != 2) return TimeOfDay(hour: 9, minute: 0);

      int hour = int.tryParse(parts[0]) ?? 9;
      int minute = int.tryParse(parts[1]) ?? 0;

      if (isPM && hour < 12) {
        hour += 12;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');

    if (hour == 0) {
      return '12:$minute ص';
    } else if (hour < 12) {
      return '$hour:$minute ص';
    } else if (hour == 12) {
      return '12:$minute م';
    } else {
      return '${hour - 12}:$minute م';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      {'name': 'الأحد', 'key': 'sunday'},
      {'name': 'الإثنين', 'key': 'monday'},
      {'name': 'الثلاثاء', 'key': 'tuesday'},
      {'name': 'الأربعاء', 'key': 'wednesday'},
      {'name': 'الخميس', 'key': 'thursday'},
      {'name': 'الجمعة', 'key': 'friday'},
      {'name': 'السبت', 'key': 'saturday'},
    ];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان مع الأيقونة
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'أوقات العمل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),

              // الأيام في قائمة مدمجة
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: List.generate(days.length, (index) {
                    final day = days[index];
                    final dayKey = day['key'] as String;
                    final timeString = _getDayTimeString(dayKey);
                    final times = timeString.split(' - ');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              day['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade400,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  // وقت البداية
                                  InkWell(
                                    onTap: () => _showTimePickerForDay(dayKey, 'start'),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            times[0],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // سهم الفاصل
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: Colors.blue.shade500,
                                    ),
                                  ),

                                  // وقت النهاية
                                  InkWell(
                                    onTap: () => _showTimePickerForDay(dayKey, 'end'),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            times.length > 1 ? times[1] : '05:00 م',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Spacer(),

                                  // أيقونة تغيير كامل الوقت (اختياري)
                                  InkWell(
                                    onTap: () async {
                                      // إذا أردت فتح منتقي لوقت البداية أولاً
                                      await _showTimePickerForDay(dayKey, 'start');
                                      await Future.delayed(Duration(milliseconds: 300));
                                      await _showTimePickerForDay(dayKey, 'end');
                                    },
                                    child: Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// دالة استخدام قديمة (للتوافق)
Widget buildBusinessHoursCard(BuildContext context, BusinessHours hours) {
  return BusinessHoursCard(hours: hours);
}