import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../controllers/settings_controller.dart';
import '../../../models/settings_model.dart';

class BusinessHoursCard extends StatefulWidget {
  final BusinessHours hours;
  final bool isDisabled;

  const BusinessHoursCard({
    super.key,
    required this.hours,
    this.isDisabled = false,
  });

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

  @override
  void didUpdateWidget(covariant BusinessHoursCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hours != widget.hours ||
        oldWidget.isDisabled != widget.isDisabled) {
      _currentHours = widget.hours;
      _initializeEditingTimes();
    }
  }

  void _initializeEditingTimes() {
    _editingTimes = {};

    final days = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ];

    for (final day in days) {
      final safe = _normalizeTimeRange(_getDayTimeString(day));
      final times = safe.split(' - ');

      _editingTimes[day] = {
        'start': _parseTimeString(times[0]),
        'end': _parseTimeString(times.length > 1 ? times[1] : '05:00 م'),
      };
    }
  }

  String _normalizeTimeRange(String value) {
    final text = value.trim();

    if (text.isEmpty ||
        text == '24 Hours' ||
        text == '24 ساعة' ||
        text == 'مغلق' ||
        !text.contains('-')) {
      return '09:00 - 17:00';
    }

    final parts = text.split(RegExp(r'\s*-\s*'));
    if (parts.length != 2) {
      return '09:00 - 17:00';
    }

    final start = _parseTimeString(parts[0]);
    final end = _parseTimeString(parts[1]);

    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _getDayTimeString(String day) {
    switch (day) {
      case 'sunday':
        return _currentHours.sunday;
      case 'monday':
        return _currentHours.monday;
      case 'tuesday':
        return _currentHours.tuesday;
      case 'wednesday':
        return _currentHours.wednesday;
      case 'thursday':
        return _currentHours.thursday;
      case 'friday':
        return _currentHours.friday;
      case 'saturday':
        return _currentHours.saturday;
      default:
        return '09:00 ص - 05:00 م';
    }
  }

  Future<void> _updateDayTime(String day, String newTime) async {
    if (widget.isDisabled) return;

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

    await _controller.saveBusinessHours(_currentHours);
  }

  Future<void> _showTimePickerForDay(String day, String type) async {
    if (widget.isDisabled) return;

    final currentTime =
        _editingTimes[day]?[type] ?? const TimeOfDay(hour: 9, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (time == null) return;

    _editingTimes[day]![type] = time;

    final startTime = _editingTimes[day]!['start']!;
    final endTime = _editingTimes[day]!['end']!;
    final newTimeString = '${_formatTime(startTime)} - ${_formatTime(endTime)}';

    await _updateDayTime(day, newTimeString);
  }

  TimeOfDay _parseTimeString(String timeText) {
    try {
      var text = timeText.trim();

      final isPM = text.contains('م') || text.toLowerCase().contains('pm');
      final isAM = text.contains('ص') || text.toLowerCase().contains('am');

      text = text
          .replaceAll('ص', '')
          .replaceAll('م', '')
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .replaceAll('am', '')
          .replaceAll('pm', '')
          .replaceAll(' ', '')
          .trim();

      final parts = text.split(':');
      if (parts.length < 2) return const TimeOfDay(hour: 9, minute: 0);

      int hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return const TimeOfDay(hour: 9, minute: 0);
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
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

    return Opacity(
      opacity: widget.isDisabled ? 0.50 : 1,
      child: IgnorePointer(
        ignoring: widget.isDisabled,
        child: Card(
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
                colors: widget.isDisabled
                    ? [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ]
                    : [
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
                  _buildHeader(),



                  const SizedBox(height:40),

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
                        final timeString =
                        _normalizeTimeRange(_getDayTimeString(dayKey));
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
                                margin:
                                const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isDisabled
                                      ? Colors.grey.shade500
                                      : Colors.blue.shade400,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.isDisabled
                                        ? Colors.grey.withOpacity(0.08)
                                        : Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.isDisabled
                                          ? Colors.grey.withOpacity(0.15)
                                          : Colors.blue.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      _buildTimeButton(
                                        text: times.isNotEmpty
                                            ? times[0]
                                            : '09:00 ص',
                                        onTap: () => _showTimePickerForDay(
                                          dayKey,
                                          'start',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Icon(
                                          Iconsax.arrow_right_2,
                                          size: 14,
                                          color: widget.isDisabled
                                              ? Colors.grey.shade500
                                              : Colors.blue.shade500,
                                        ),
                                      ),
                                      _buildTimeButton(
                                        text: times.length > 1
                                            ? times[1]
                                            : '05:00 م',
                                        onTap: () => _showTimePickerForDay(
                                          dayKey,
                                          'end',
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () async {
                                          await _showTimePickerForDay(
                                            dayKey,
                                            'start',
                                          );
                                          await Future.delayed(
                                            const Duration(milliseconds: 300),
                                          );
                                          await _showTimePickerForDay(
                                            dayKey,
                                            'end',
                                          );
                                        },
                                        child: Icon(
                                          Iconsax.edit_2,
                                          size: 14,
                                          color: widget.isDisabled
                                              ? Colors.grey.shade500
                                              : Colors.blue.shade600,
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? Colors.grey.withOpacity(0.15)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            Iconsax.clock,
            color:
            widget.isDisabled ? Colors.grey.shade700 : Colors.blue.shade700,
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
    );
  }

  Widget _buildTimeButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: widget.isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
            widget.isDisabled ? Colors.grey.shade300 : Colors.blue.shade200,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: widget.isDisabled
                    ? Colors.grey.shade700
                    : Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Iconsax.clock,
              size: 12,
              color: widget.isDisabled
                  ? Colors.grey.shade600
                  : Colors.blue.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildBusinessHoursCard(
    BuildContext context,
    BusinessHours hours, {
      bool isDisabled = false,
    }) {
  return BusinessHoursCard(
    hours: hours,
    isDisabled: isDisabled,
  );
}