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
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  Map<String, List<Map<String, dynamic>>> _employeeAttendanceData = {};
  bool _isLoading = true;
  String? _error;
  String _selectedEmployeeId = '';
  String _selectedEmployeeName = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'date'; // 'date' or 'month'
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees(String query) {
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        final name = employee['name'].toString().toLowerCase();
        final position = employee['position'].toString().toLowerCase();
        final department = employee['department'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            position.contains(searchQuery) ||
            department.contains(searchQuery);
      }).toList();
      _showSearchResults = query.isNotEmpty;
    });
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // For now, we'll use a mock employee list
      // In a real app, you would call an API to get all employees
      final mockEmployees = [
        {
          'id': 'EMP-02102025054',
          'name': 'TEST PROGRAMMER',
          'position': 'Programmer',
          'department': 'IT',
        },
        {
          'id': 'EMP-15072025045',
          'name': 'Office Accountant',
          'position': 'Accountant',
          'department': 'Finance',
        },
      ];

      setState(() {
        _employees = mockEmployees;
        _filteredEmployees = mockEmployees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployeeAttendance(String employeeId, DateTime date) async {
    try {
      final apiService = ref.read(apiServiceProvider);

      final dateString = DateFormat('yyyy-MM-dd').format(date);

      final response = await apiService.getShiftDataWithFilter(
        employeeId: employeeId,
        date: dateString,
      );

      if (response['success'] == true) {
        final attendanceData = response['attendanceData'] as List<dynamic>?;
        setState(() {
          _employeeAttendanceData[employeeId] =
              attendanceData?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (e) {
      print('Error loading attendance for $employeeId: $e');
    }
  }

  Future<void> _loadEmployeeAttendanceForMonth(
    String employeeId,
    int year,
    int month,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final List<Map<String, dynamic>> monthlyData = [];

      // Get all days in the month
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        try {
          final date = DateTime(year, month, day);
          final dateString = DateFormat('yyyy-MM-dd').format(date);

          final response = await apiService.getShiftDataWithFilter(
            employeeId: employeeId,
            date: dateString,
          );

          if (response['success'] == true) {
            final attendanceData = response['attendanceData'] as List<dynamic>?;
            if (attendanceData != null && attendanceData.isNotEmpty) {
              monthlyData.addAll(attendanceData.cast<Map<String, dynamic>>());
            }
          }
        } catch (e) {
          // Continue to next day if one fails
          continue;
        }
      }

      setState(() {
        _employeeAttendanceData[employeeId] = monthlyData;
      });
    } catch (e) {
      print('Error loading monthly attendance for $employeeId: $e');
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSearchResults = false;
        });
      },
      child: Scaffold(
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
        ),
        body: Column(
          children: [
            // Filters Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Employee Search Input
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: _t('ค้นหาพนักงาน', 'Search Employee'),
                      hintText: _t(
                        'พิมพ์ชื่อ, ตำแหน่ง หรือแผนก',
                        'Type name, position or department',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterEmployees('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterEmployees,
                    onTap: () {
                      setState(() {
                        _showSearchResults = true;
                      });
                    },
                  ),

                  // Search Results
                  if (_showSearchResults && _filteredEmployees.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = _filteredEmployees[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.kNanoGold.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                employee['name'][0],
                                style: const TextStyle(
                                  color: AppTheme.kNanoGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              employee['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${employee['position']} - ${employee['department']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedEmployeeId = employee['id'];
                                _selectedEmployeeName = employee['name'];
                                _searchController.text = employee['name'];
                                _showSearchResults = false;
                              });
                              _loadEmployeeAttendance(
                                employee['id'],
                                _selectedDate,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // Selected Employee Display
                  if (_selectedEmployeeId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.kNanoGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.kNanoGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.kNanoGold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedEmployeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.kNanoGold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.kNanoGold,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedEmployeeId = '';
                                _selectedEmployeeName = '';
                                _searchController.clear();
                                _employeeAttendanceData.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          if (_selectedEmployeeId.isNotEmpty) {
                            _loadEmployeeAttendance(_selectedEmployeeId, date);
                          }
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
                          if (_selectedEmployeeId.isNotEmpty) {
                            _loadEmployeeAttendanceForMonth(
                              _selectedEmployeeId,
                              result['year']!,
                              result['month']!,
                            );
                          }
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
            Text('Loading employees...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        actionText: _t('ลองใหม่', 'Retry'),
        onAction: _loadEmployees,
      );
    }

    if (_selectedEmployeeId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _t('กรุณาเลือกพนักงาน', 'Please select an employee'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final attendanceData = _employeeAttendanceData[_selectedEmployeeId] ?? [];
    final selectedEmployee = _employees.firstWhere(
      (emp) => emp['id'] == _selectedEmployeeId,
    );

    return Column(
      children: [
        // Employee Info Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedEmployee['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedEmployee['position']} - ${selectedEmployee['department']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Attendance Data
        Expanded(
          child: attendanceData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _t(
                          'ไม่มีข้อมูลการเข้างานในวันนี้',
                          'No attendance data for this date',
                        ),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: attendanceData.length,
                  itemBuilder: (context, index) {
                    final record = attendanceData[index];
                    return _buildAttendanceCard(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final checkInAt = record['checkInAt'] as String?;
    final checkOutAt = record['checkOutAt'] as String?;
    final status = record['status'] as String?;
    final location = record['location'] as String?;

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
          // Status Badge
          Row(
            children: [
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
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(DateTime.parse(record['timestamp'])),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Check In/Out Times
          if (checkInAt != null) ...[
            Row(
              children: [
                const Icon(Icons.login, color: AppTheme.kNanoGold, size: 20),
                const SizedBox(width: 8),
                Text(
                  _t('เข้างาน: ', 'Check In: ') + checkInAt,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          if (checkOutAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.logout, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  _t('ออกงาน: ', 'Check Out: ') + checkOutAt,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],

          if (location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t('สถานที่: ', 'Location: ') + location,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
