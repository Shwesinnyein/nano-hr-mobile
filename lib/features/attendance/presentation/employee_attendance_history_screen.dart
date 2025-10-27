import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/language_provider.dart';
import 'package:intl/intl.dart';

class EmployeeAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const EmployeeAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<EmployeeAttendanceHistoryScreen> createState() =>
      _EmployeeAttendanceHistoryScreenState();
}

class _EmployeeAttendanceHistoryScreenState
    extends ConsumerState<EmployeeAttendanceHistoryScreen> {
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'month'; // 'date' or 'month' - default to month
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    // Load all attendance data on init
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ref.read(apiServiceProvider);
      final searchName = _searchController.text.trim();
      
      // Call API with search parameters
      Map<String, dynamic> response;
      
      if (_selectedPeriod == 'date') {
        final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
        response = await apiService.searchAttendanceByName(
          name: searchName, // Can be empty to get all
          date: dateString,
        );
      } else {
        // Month view
        response = await apiService.searchAttendanceByName(
          name: searchName, // Can be empty to get all
          year: _selectedDate.year,
          month: _selectedDate.month,
        );
      }

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        final summary = response['summary'] as Map<String, dynamic>?;
        
        setState(() {
          _attendanceData = data?.cast<Map<String, dynamic>>() ?? [];
          _summary = summary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _attendanceData = [];
          _summary = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _attendanceData = [];
        _summary = null;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>?> _showMonthYearPicker(BuildContext context) async {
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;

    return await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_t('เลือกเดือนและปี', 'Select Month & Year')),
              content: SizedBox(
                width: 350,
                height: 400,
                child: Column(
                  children: [
                    // Year Selection
                    Text(
                      _t('ปี', 'Year'),
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
                      _t('เดือน', 'Month'),
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
                          final monthNames = [
                            _t('ม.ค.', 'Jan'),
                            _t('ก.พ.', 'Feb'),
                            _t('มี.ค.', 'Mar'),
                            _t('เม.ย.', 'Apr'),
                            _t('พ.ค.', 'May'),
                            _t('มิ.ย.', 'Jun'),
                            _t('ก.ค.', 'Jul'),
                            _t('ส.ค.', 'Aug'),
                            _t('ก.ย.', 'Sep'),
                            _t('ต.ค.', 'Oct'),
                            _t('พ.ย.', 'Nov'),
                            _t('ธ.ค.', 'Dec'),
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
                  child: Text(_t('ยกเลิก', 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop({'year': selectedYear, 'month': selectedMonth}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kNanoGold,
                  ),
                  child: Text(
                    _t('ตกลง', 'OK'),
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

  String _t(String thaiText, String englishText) {
    final isThai = ref.watch(languageProvider);
    return isThai ? thaiText : englishText;
  }

  Widget _buildStat(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.kNanoGold, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.kNanoGold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.kBackground,
        appBar: AppBar(
          title: Text(
            _t('ประวัติการเข้างานของพนักงาน', 'Employee Attendance History'),
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.kNanoGold),
              onPressed: _loadAttendanceData,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.kOnBackground),
              onPressed: _loadAttendanceData,
            ),
          ],
        ),
        body: Column(
          children: [
            // Filters Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Summary Statistics
                  if (_summary != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.kNanoGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(Icons.people, _summary!['totalEmployees'].toString(), _t('พนักงาน', 'Employees')),
                          _buildStat(Icons.event_available, _summary!['totalRecords'].toString(), _t('บันทึก', 'Records')),
                          _buildStat(Icons.access_time_filled, _summary!['lateCount'].toString(), _t('สาย', 'Late'), color: Colors.red),
                          _buildStat(Icons.check_circle, _summary!['onTimeCount'].toString(), _t('ตรงเวลา', 'On Time'), color: Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Employee Search Input
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: _t('ค้นหาพนักงาน', 'Search Employee'),
                      hintText: _t('พิมพ์ชื่อพนักงาน', 'Type employee name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadAttendanceData();
                              },
                            )
                          : null,
                    ),
                    onFieldSubmitted: (_) => _loadAttendanceData(),
                  ),
                  const SizedBox(height: 16),

                  // Period Selection Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = 'date';
                            });
                            _loadAttendanceData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == 'date'
                                  ? AppTheme.kNanoGold
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _t('วันที่', 'Date'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedPeriod == 'date'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = 'month';
                            });
                            _loadAttendanceData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == 'month'
                                  ? AppTheme.kNanoGold
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _t('เดือน', 'Month'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedPeriod == 'month'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date/Month Selection
                  InkWell(
                    onTap: () async {
                      if (_selectedPeriod == 'date') {
                        // Date picker
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                          _loadAttendanceData();
                        }
                      } else {
                        // Month picker
                        final result = await _showMonthYearPicker(context);
                        if (result != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              result['year']!,
                              result['month']!,
                              1,
                            );
                          });
                          _loadAttendanceData();
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPeriod == 'date'
                                ? Icons.calendar_today
                                : Icons.calendar_month,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedPeriod == 'date'
                                ? _t('วันที่: ', 'Date: ') +
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate)
                                : _t('เดือน: ', 'Month: ') +
                                      DateFormat(
                                        'MMM yyyy',
                                      ).format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(child: _buildContent()),
          ],
        ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.kNanoGold),
            SizedBox(height: 16),
            Text('Loading attendance data...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        actionText: _t('ลองใหม่', 'Retry'),
        onAction: _loadAttendanceData,
      );
    }

    if (_attendanceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _t('ไม่มีข้อมูลการเข้างาน', 'No attendance data found'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _t('ลองค้นหาชื่อพนักงาน หรือเปลี่ยนวัน/เดือน', 'Try searching by employee name or change date/month'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
      color: AppTheme.kNanoGold,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _attendanceData.length,
        itemBuilder: (context, index) {
          final record = _attendanceData[index];
          return _buildAttendanceCard(record);
        },
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final employeeName = record['employeeName'] as String?;
    final checkInAt = record['checkInAt'] as String?;
    final checkOutAt = record['checkOutAt'] as String?;
    final status = record['status'] as String?;
    final location = record['location'] as String?;
    final date = record['date'] as String?;
    final lateMinutes = record['lateMinutes'] as int?;
    final branchName = record['branchName'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Name & Date Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (employeeName != null)
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kNanoGold,
                        ),
                      ),
                    if (date != null)
                      Text(
                        DateFormat('dd MMM yyyy').format(DateTime.parse(date)),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ),
          const SizedBox(height: 12),

          // Check In/Out Times
          Row(
            children: [
              if (checkInAt != null) ...[
                const Icon(Icons.login, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text(checkInAt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
              if (checkInAt != null && checkOutAt != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                ),
              if (checkOutAt != null) ...[
                const Icon(Icons.logout, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Text(checkOutAt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
              if (lateMinutes != null && lateMinutes > 0) ...[
                const Spacer(),
                Text('${_t('สาย', 'Late')} ${lateMinutes} ${_t('นาที', 'min')}', style: TextStyle(fontSize: 12, color: Colors.red[700])),
              ],
            ],
          ),

          // Branch
          if (branchName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(branchName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
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

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'late':
        return _t('สาย', 'Late');
      case 'on_time':
      case 'ontime':
        return _t('ตรงเวลา', 'On Time');
      case 'in_time':
        return _t('ในเวลา', 'In Time');
      case 'early':
        return _t('เช้า', 'Early');
      default:
        return _t('ไม่ทราบ', 'Unknown');
    }
  }
}
