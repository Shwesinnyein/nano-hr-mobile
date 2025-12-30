import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../app/theme.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../core/providers/language_provider.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  Map<String, dynamic>? _calendarData;
  bool _isLoading = false;
  String? _selectedDateDetails;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get first and last day of current month
      final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      final fromDate =
          '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
      final toDate =
          '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

      final response = await apiService.getShiftCalendar(
        employeeId: employeeId,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success'] == true && response['data'] != null) {
            _calendarData = response['data'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading calendar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _calendarList {
    if (_calendarData == null || _calendarData!['calendar'] == null) {
      return [];
    }
    return List<Map<String, dynamic>>.from(_calendarData!['calendar']);
  }

  Map<String, dynamic>? _getDateData(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return _calendarList.firstWhere(
        (item) => item['date'] == dateStr,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }

  Color _getDateColor(DateTime date) {
    final dateData = _getDateData(date);
    final now = DateTime.now();
    final isFutureDate = date.isAfter(now) || 
        (date.year == now.year && date.month == now.month && date.day > now.day);
    
    // Future dates: normal gray color
    if (isFutureDate) {
      return Colors.grey.shade300;
    }

    if (dateData == null || dateData.isEmpty) {
      return Colors.grey.shade300;
    }

    final calendarStatus = dateData['calendarStatus']?.toString() ?? '';
    final isHoliday = dateData['isHoliday'] == true;
    final isLeave = dateData['isLeave'] == true;
    final attendanceStatus = dateData['attendanceStatus']?.toString() ?? '';
    final checkInAt = dateData['checkInAt']?.toString();
    final startTime = dateData['startTime']?.toString();

    // Leave: Purple/Lavender color
    if (isLeave) {
      return const Color(0xFFDEA3F7);
    }

    // Holiday: Blue color
    if (isHoliday) {
      return const Color(0xFF2A76D4);
    }

    // Check if there's attendance data to determine late/on time
    if (checkInAt != null && startTime != null && checkInAt.isNotEmpty && startTime.isNotEmpty) {
      try {
        // Parse check-in time (format: HH:mm:ss)
        final checkInParts = checkInAt.split(':');
        final checkInHour = int.parse(checkInParts[0]);
        final checkInMinute = int.parse(checkInParts[1]);
        
        // Parse start time (format: HH:mm)
        final startParts = startTime.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        
        // Calculate minutes difference
        final checkInMinutes = checkInHour * 60 + checkInMinute;
        final startMinutes = startHour * 60 + startMinute;
        final diffMinutes = checkInMinutes - startMinutes;
        
        // If checked in more than 5 minutes after start time, consider it late
        if (diffMinutes > 5) {
          // Late: Yellow color
          return const Color(0xFFF5F227);
        } else {
          // On time: Light green color
          return const Color(0xFF78F5A6);
        }
      } catch (e) {
        // If parsing fails, check calendar status
        if (calendarStatus == 'completed' || attendanceStatus == 'checked_out') {
          return const Color(0xFF78F5A6);
        }
      }
    }

    // If completed or checked out, show light green (on time)
    if (calendarStatus == 'completed' || attendanceStatus == 'checked_out') {
      return const Color(0xFF78F5A6);
    }

    // If checked in but not checked out yet
    if (attendanceStatus == 'checked_in') {
      return const Color(0xFF78F5A6);
    }

    // Default: normal gray color
    return Colors.grey.shade400;
  }

  void _showDateDetails(DateTime date) {
    final dateData = _getDateData(date);
    if (dateData == null || dateData.isEmpty) {
      return;
    }

    setState(() {
      _selectedDate = date;
      _selectedDateDetails = _formatDateDetails(dateData);
    });

    final isHoliday = dateData['isHoliday'] == true;
    final now = DateTime.now();
    final isFutureDate = date.isAfter(now) || 
        (date.year == now.year && date.month == now.month && date.day > now.day);
    
    // For future dates with no data, don't show modal
    if (isFutureDate && dateData['startTime'] == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateHeader(date),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kNanoGold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildDateDetailsContent(dateData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDetailsContent(Map<String, dynamic> dateData) {
    final startTime = dateData['startTime']?.toString();
    final endTime = dateData['endTime']?.toString();
    final shiftName = dateData['shiftName']?.toString();
    final location = dateData['location']?.toString();
    final checkInAt = dateData['checkInAt']?.toString();
    final checkOutAt = dateData['checkOutAt']?.toString();
    final attendanceStatus = dateData['attendanceStatus']?.toString() ?? '';
    final isLeave = dateData['isLeave'] == true;
    final isHoliday = dateData['isHoliday'] == true;
    final leave = dateData['leave'] as Map<String, dynamic>?;
    final calendarStatus = dateData['calendarStatus']?.toString() ?? '';
    
    // Get check-in and check-out locations if available
    final checkInLocation = dateData['checkInLocation']?.toString() ?? 
                           dateData['checkInAddress']?.toString();
    final checkOutLocation = dateData['checkOutLocation']?.toString() ?? 
                            dateData['checkOutAddress']?.toString();
    
    // Determine if it's a future date that hasn't been checked in
    final now = DateTime.now();
    final dateStr = dateData['date']?.toString() ?? '';
    bool isFutureDate = false;
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        isFutureDate = date.isAfter(now) || 
            (date.year == now.year && date.month == now.month && date.day > now.day);
      } catch (e) {
        isFutureDate = false;
      }
    }
    final hasCheckedIn = checkInAt != null && checkInAt.isNotEmpty;
    
    // Check if we have any location data
    final hasAnyLocation = (checkInLocation != null && checkInLocation.isNotEmpty) ||
        (checkOutLocation != null && checkOutLocation.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show Holiday message
        if (isHoliday) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Text(
                  ref.t('วันหยุด', 'Holiday'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Show Leave message (but don't show location)
        if (isLeave && leave != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.t('ลาพัก', 'On Leave'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leave['leaveTypeName']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Show working hours (if not holiday and has start/end time)
        if (!isHoliday && startTime != null && endTime != null) ...[
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.kNanoGold, size: 20),
              const SizedBox(width: 8),
              Text(
                '${ref.t('เวลาทำงาน', 'Working Hours')}: $startTime - $endTime',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Container(
          height: 1,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        // Show check-in with location and time combined
        if (checkInAt != null) ...[
          Row(
            children: [
              Icon(Icons.login, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ref.t('เข้างาน', 'Check In')}: $checkInAt',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (checkInLocation != null && checkInLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              checkInLocation,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Show check-out with location and time combined
        if (checkOutAt != null) ...[
          Row(
            children: [
              Icon(Icons.logout, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ref.t('ออกงาน', 'Check Out')}: $checkOutAt',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (checkOutLocation != null && checkOutLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              checkOutLocation,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ] else if (!isHoliday && checkInAt == null) ...[
          Text(
            ref.t('ยังไม่ได้สแกน', 'Not Scanned'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final isThai = ref.watch(languageProvider);
    if (isThai) {
      final day = date.day.toString().padLeft(2, '0');
      final monthsThai = [
        'มกราคม',
        'กุมภาพันธ์',
        'มีนาคม',
        'เมษายน',
        'พฤษภาคม',
        'มิถุนายน',
        'กรกฎาคม',
        'สิงหาคม',
        'กันยายน',
        'ตุลาคม',
        'พฤศจิกายน',
        'ธันวาคม'
      ];
      final month = monthsThai[date.month - 1];
      final year = (date.year + 543).toString();
      return '$day $month $year';
    }
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  String _formatDateDetails(Map<String, dynamic> dateData) {
    return dateData.toString();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadCalendarData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadCalendarData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.kNanoGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          ref.t('ดูการเข้างาน', 'View Attendance'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       setState(() {
        //         _currentMonth = DateTime.now();
        //       });
        //       _loadCalendarData();
        //     },
        //     child: Text(
        //       ref.t('ปฏิทิน', 'Calendar'),
        //       style: const TextStyle(color: Colors.white),
        //     ),
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar Header
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kNanoGold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),
                // Calendar Grid
                _buildCalendarGrid(),
                const Divider(height: 1),
                // Date List
                Expanded(
                  child: _buildDateList(),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDay.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDay.day;

    final isThai = ref.watch(languageProvider);
    final weekDays = isThai
        ? ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Week day headers
          Row(
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar dates
          ...List.generate(
            ((daysInMonth + firstDayOfWeek) / 7).ceil(),
            (weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = (weekIndex * 7) + dayIndex - firstDayOfWeek + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }
                  final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;
                  final dateData = _getDateData(date);
                  final hasShift = dateData != null &&
                      dateData['startTime'] != null &&
                      dateData['startTime'].toString().isNotEmpty;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _showDateDetails(date),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getDateColor(date),
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(color: AppTheme.kNanoGold, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? AppTheme.kNanoGold : Colors.black87,
                              ),
                            ),
                            if (hasShift)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateList() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    final dateList = List.generate(daysInMonth, (index) {
      return DateTime(_currentMonth.year, _currentMonth.month, index + 1);
    });

    if (dateList.isEmpty) {
      return Center(
        child: Text(ref.t('ไม่มีข้อมูล', 'No data available')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dateList.length,
      itemBuilder: (context, index) {
        final date = dateList[index];
        final dateData = _getDateData(date);
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        final dayOfWeek = DateFormat('EEEE').format(date);
        final isThai = ref.watch(languageProvider);
        final dayOfWeekThai = [
          'อาทิตย์',
          'จันทร์',
          'อังคาร',
          'พุธ',
          'พฤหัสบดี',
          'ศุกร์',
          'เสาร์'
        ];
        final dayName = isThai ? dayOfWeekThai[date.weekday % 7] : dayOfWeek;

        final startTime = dateData?['startTime']?.toString() ?? '';
        final endTime = dateData?['endTime']?.toString() ?? '';
        final attendanceStatus = dateData?['attendanceStatus']?.toString() ?? 'not_scanned';
        final checkInAt = dateData?['checkInAt']?.toString();
        final checkOutAt = dateData?['checkOutAt']?.toString();
        final isLeave = dateData?['isLeave'] == true;
        final isHoliday = dateData?['isHoliday'] == true;
        final now = DateTime.now();
        final isFutureDate = date.isAfter(now) || 
            (date.year == now.year && date.month == now.month && date.day > now.day);

        String statusText = ref.t('ยังไม่ได้สแกน', 'Not Scanned');
        Color statusColor = Colors.grey;

        if (isFutureDate) {
          statusText = ref.t('วันที่อนาคต', 'Future Date');
          statusColor = Colors.grey;
        } else if (isHoliday) {
          statusText = ref.t('วันหยุด', 'Holiday');
          statusColor = Colors.red;
        } else if (isLeave) {
          statusText = ref.t('ลาพัก', 'On Leave');
          statusColor = Colors.blue; // Leave: Blue color
        } else if (checkInAt != null && startTime.isNotEmpty && checkInAt.isNotEmpty) {
          // Determine if late or on time based on check-in time vs start time
          try {
            final checkInParts = checkInAt.split(':');
            final checkInHour = int.parse(checkInParts[0]);
            final checkInMinute = int.parse(checkInParts[1]);
            
            final startParts = startTime.split(':');
            final startHour = int.parse(startParts[0]);
            final startMinute = int.parse(startParts[1]);
            
            final checkInMinutes = checkInHour * 60 + checkInMinute;
            final startMinutes = startHour * 60 + startMinute;
            final diffMinutes = checkInMinutes - startMinutes;
            
            if (diffMinutes > 5) {
              // Late: Warning color (orange)
              statusText = ref.t('สาย', 'Late');
              statusColor = Colors.orange;
            } else {
              // On time: Green color
              statusText = ref.t('ตรงเวลา', 'On Time');
              statusColor = Colors.green;
            }
          } catch (e) {
            // If parsing fails, use default status
            if (attendanceStatus == 'checked_out') {
              statusText = ref.t('ออกงานแล้ว', 'Checked Out');
              statusColor = Colors.green;
            } else if (attendanceStatus == 'checked_in') {
              statusText = ref.t('เข้างานแล้ว', 'Checked In');
              statusColor = Colors.green;
            }
          }
        } else if (attendanceStatus == 'checked_out') {
          statusText = ref.t('ออกงานแล้ว', 'Checked Out');
          statusColor = Colors.green;
        } else if (attendanceStatus == 'checked_in') {
          statusText = ref.t('เข้างานแล้ว', 'Checked In');
          statusColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday
                ? BorderSide(color: AppTheme.kNanoGold, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _showDateDetails(date),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getDateColor(date),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.kNanoGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '| $dayName',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (startTime.isNotEmpty && endTime.isNotEmpty)
                          Text(
                            '$startTime - $endTime',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (checkInAt != null || checkOutAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (checkInAt != null)
                          Text(
                            'In: $checkInAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        if (checkOutAt != null)
                          Text(
                            'Out: $checkOutAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

