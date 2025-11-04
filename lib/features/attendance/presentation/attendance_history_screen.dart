import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/widgets/animated_fade_in.dart';
import '../../../core/widgets/error_state_widget.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = false;
  String? _error;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        throw Exception('No employee ID found');
      }

      // Get attendance history for the selected month/year
      final response = await apiService.getAttendanceListWithFilter(
        employeeId: employeeId,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        if (data['success'] == true) {
          final attendanceData = data['data'] as List<dynamic>;
          setState(() {
            _attendanceHistory = attendanceData.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        } else {
          throw Exception(
            data['message'] ?? 'Failed to load attendance data',
          );
        }
      } else {
        // Handle "no records found" case
        final message = response['message'] ?? 'Failed to load attendance data';
        if (message.contains('No attendance records found') || 
            message.contains('No attendance records found for the specified period')) {
          // Show empty state instead of error
          setState(() {
            _attendanceHistory = [];
            _isLoading = false;
            _error = null; // Clear any previous errors
          });
        } else {
          throw Exception(message);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _t(WidgetRef ref, String thaiText, String englishText) {
    final isThai = ref.watch(languageProvider);
    return isThai ? thaiText : englishText;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    try {
      return timeString.substring(0, 5); // Show HH:MM format
    } catch (e) {
      return timeString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'late':
        return Colors.red;
      case 'on_time':
      case 'ontime':
        return Colors.green;
      case 'in_time':
        return Colors.orange;
      case 'early':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'late':
        return 'Late';
      case 'on_time':
      case 'ontime':
        return 'On Time';
      case 'in_time':
        return 'In Time';
      case 'early':
        return 'Early';
      default:
        return status;
    }
  }

  Widget _buildMonthYearSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: AppTheme.kNanoGold, size: 24),
          const SizedBox(width: 12),
          Text(
            '${_getMonthName(_selectedMonth)} $_selectedYear',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.kOnSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showMonthYearPicker(),
            icon: Icon(Icons.arrow_drop_down, color: AppTheme.kNanoGold),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final isThai = ref.watch(languageProvider);
    if (isThai) {
      const months = [
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
        'ธันวาคม',
      ];
      return months[month - 1];
    } else {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return months[month - 1];
    }
  }

  void _showMonthYearPicker() {
    int selectedYear = _selectedYear;
    int selectedMonth = _selectedMonth;
    final isThai = ref.watch(languageProvider);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isThai ? 'เลือกเดือนและปี' : 'Select Month & Year'),
              content: SizedBox(
                width: 350,
                height: 400,
                child: Column(
                  children: [
                    // Year Selection
                    Text(
                      isThai ? 'ปี' : 'Year',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                            ),
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          final year = DateTime.now().year - index;
                          final isSelected = year == selectedYear;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedYear = year;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.kNanoGold
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Month Selection
                    Text(
                      isThai ? 'เดือน' : 'Month',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                            ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final monthNames = isThai
                              ? [
                                  'ม.ค.',
                                  'ก.พ.',
                                  'มี.ค.',
                                  'เม.ย.',
                                  'พ.ค.',
                                  'มิ.ย.',
                                  'ก.ค.',
                                  'ส.ค.',
                                  'ก.ย.',
                                  'ต.ค.',
                                  'พ.ย.',
                                  'ธ.ค.',
                                ]
                              : [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec',
                                ];
                          final isSelected = month == selectedMonth;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMonth = month;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.kNanoGold
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  monthNames[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isThai ? 'ยกเลิก' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear = selectedYear;
                      _selectedMonth = selectedMonth;
                    });
                    Navigator.of(context).pop();
                    _loadAttendanceHistory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kNanoGold,
                  ),
                  child: Text(
                    isThai ? 'ตกลง' : 'OK',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final date = _formatDate(record['date'] ?? '');
    final checkIn = record['checkInAt']?.toString();
    final checkOut = record['checkOutAt']?.toString();
    final status = record['status']?.toString() ?? '';
    final location = record['checkInLocation']?.toString() ?? record['location']?.toString() ?? '';

    return AnimatedFadeIn(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Status Row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppTheme.kNanoGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kOnSurface,
                    ),
                  ),
                  const Spacer(),
                  if (status.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Check In Time
              if (checkIn != null) ...[
                Row(
                  children: [
                    Icon(Icons.login, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Check In:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(checkIn),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Check Out Time
              if (checkOut != null) ...[
                Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Check Out:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(checkOut),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Location
              if (location.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _t(ref, 'ไม่มีประวัติการเข้างาน', 'No attendance history'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              ref,
              'ไม่พบข้อมูลการเข้างานสำหรับ ${_getMonthName(_selectedMonth)} $_selectedYear',
              'No attendance records found for ${_getMonthName(_selectedMonth)} $_selectedYear',
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _t(
              ref,
              'ลองเลือกเดือนหรือปีอื่น',
              'Try selecting a different month or year',
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          _t(ref, 'ประวัติการเข้างาน', 'Attendance History'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.kOnBackground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.kOnBackground),
            onPressed: _loadAttendanceHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthYearSelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.kNanoGold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading attendance history...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? ErrorStateWidget(
                    message: _error!,
                    actionText: 'Retry',
                    onAction: _loadAttendanceHistory,
                  )
                : _attendanceHistory.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadAttendanceHistory,
                    color: AppTheme.kNanoGold,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _attendanceHistory.length,
                      itemBuilder: (context, index) {
                        return _buildAttendanceCard(_attendanceHistory[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
