
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock employee data
  static const Map<String, dynamic> mockEmployee = {
    'id': 'EMP-15072025045',
    'authId': 'mock-auth-id',
    'nickname': 'OA',
    'firstName': 'Office',
    'lastName': 'Accountant',
    'email': 'oa@gmail.com',
    'primaryNumber': '0923423423',
    'companyName': 'NANO-STORES',
    'locationName': 'Bangkok',
    'branchName': 'Office',
    'positionName': 'Accountant',
    'status': 'active',
    'role': 'employee',
    'profileImage': 'https://via.placeholder.com/150',
    'has2FA': true,
    'joinDate': '2025-03-02T17:00:00.000Z',
    'maritalStatus': null,
    'dateOfBirth': null,
    'gender': 'Female',
    'salary': 50000,
    'updatedAt': '2025-09-04T02:36:54.898Z',
  };

  // Mock attendance data - start with empty list
  static List<Map<String, dynamic>> mockAttendanceData = [];

  // Mock leave requests data
  static List<Map<String, dynamic>> mockLeaveRequests = [
    {
      'id': 'LR-001',
      'employeeId': 'emp001',
      'leaveType': 'annual',
      'startDate': DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .split('T')[0],
      'endDate': DateTime.now()
          .add(const Duration(days: 9))
          .toIso8601String()
          .split('T')[0],
      'reason': 'Family vacation',
      'status': 'pending',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'updatedAt': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 'LR-002',
      'employeeId': 'emp001',
      'leaveType': 'sick',
      'startDate': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String()
          .split('T')[0],
      'endDate': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String()
          .split('T')[0],
      'reason': 'Flu',
      'status': 'approved',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 6))
          .toIso8601String(),
      'updatedAt': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
  ];

  // Authentication methods
  static Future<Map<String, dynamic>> loginWithCredentials(
    String email,
    String password,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'oa@gmail.com' && password == 'Admin123') {
      return {
        'success': true,
        'message': 'Login successful',
        'employee': mockEmployee,
      };
    } else {
      throw Exception('Invalid credentials');
    }
  }

  static Future<Map<String, dynamic>> checkEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email == 'oa@gmail.com') {
      return {
        'success': true,
        'message': 'Email found',
        'employee': mockEmployee,
      };
    } else {
      throw Exception('No employee found with this email address');
    }
  }

  static Future<Map<String, dynamic>> setPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    return {'success': true, 'message': 'Password set successfully'};
  }

  // Attendance methods
  static Future<Map<String, dynamic>> checkInOut(
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    // Check if there's already a record for today
    final existingRecordIndex = mockAttendanceData.indexWhere(
      (record) =>
          record['employeeId'] == data['employeeId'] && record['date'] == today,
    );

    if (data['type'] == 'checkin') {
      // Create new check-in record
      final timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final attendanceRecord = {
        'id': 'ATT-${now.millisecondsSinceEpoch}',
        'userId': data['employeeId'],
        'checkInAt': timeString,
        'checkOutAt': null,
        'location': data['location'] ?? 'Bangkok',
        'employeeId': data['employeeId'],
        'employeeName': data['employeeName'],
        'duration': null,
        'date': today,
        'time': timeString,
        'timestamp': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Add to mock data
      mockAttendanceData.add(attendanceRecord);

      return {
        'success': true,
        'message': 'Check In recorded successfully',
        'data': attendanceRecord,
      };
    } else {
      // Check out - update existing record
      print(
        '🔍 MockDataService: Looking for existing record for employeeId: ${data['employeeId']}, date: $today',
      );
      print(
        '🔍 MockDataService: Available records: ${mockAttendanceData.map((r) => '${r['employeeId']}-${r['date']}').toList()}',
      );

      if (existingRecordIndex != -1) {
        final existingRecord = mockAttendanceData[existingRecordIndex];
        print('🔍 MockDataService: Found existing record: $existingRecord');

        final timeString =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        existingRecord['checkOutAt'] = timeString;
        existingRecord['updatedAt'] = now.toIso8601String();

        // Calculate duration
        final checkInTimeString = existingRecord['checkInAt'] as String?;
        if (checkInTimeString != null) {
          final checkInTimeParts = checkInTimeString.split(':');
          final checkInTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(checkInTimeParts[0]),
            int.parse(checkInTimeParts[1]),
            checkInTimeParts.length > 2 ? int.parse(checkInTimeParts[2]) : 0,
          );
          final duration = now.difference(checkInTime);
          existingRecord['duration'] =
              '${duration.inHours}h ${duration.inMinutes % 60}m';
        }

        print('🔍 MockDataService: Updated record: $existingRecord');
        return {
          'success': true,
          'message': 'Check Out recorded successfully',
          'data': existingRecord,
        };
      } else {
        print('❌ MockDataService: No existing record found for check-out');
        throw Exception('No check-in record found for today');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayAttendance(
    String employeeId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayRecords = mockAttendanceData
        .where(
          (record) =>
              record['employeeId'] == employeeId && record['date'] == today,
        )
        .toList();

    // Convert to the format expected by Attendance.fromJson
    return todayRecords
        .map(
          (record) => {
            'id': record['id'],
            'userId': record['userId'],
            'checkInAt': record['checkInAt'],
            'checkOutAt': record['checkOutAt'],
            'location': record['location'],
            'employeeId': record['employeeId'],
            'employeeName': record['employeeName'],
            'duration': record['duration'],
          },
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getAttendanceHistory(
    String employeeId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return mockAttendanceData
        .where((record) => record['employeeId'] == employeeId)
        .toList();
  }

  // Leave management methods
  static Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();
    final leaveRequest = {
      'id': data['id'],
      'employeeId': data['employeeId'],
      'employeeName': data['employeeName'],
      'leaveType': data['leaveType'],
      'startDate': data['startDate'],
      'endDate': data['endDate'],
      'reason': data['reason'],
      'status': 'pending',
      'attachments': data['attachments'] ?? [],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    mockLeaveRequests.add(leaveRequest);

    return {
      'success': true,
      'message': 'Leave request created successfully',
      'data': leaveRequest,
    };
  }

  static Future<List<Map<String, dynamic>>> getLeaveRequests(
    String employeeId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return mockLeaveRequests
        .where((request) => request['employeeId'] == employeeId)
        .toList();
  }

  // File upload simulation
  static Future<Map<String, dynamic>> uploadFile(String filePath) async {
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'message': 'File uploaded successfully',
      'url':
          'https://mock-storage.com/files/${DateTime.now().millisecondsSinceEpoch}.pdf',
    };
  }

  // Clear all mock data (for testing)
  static void clearAllData() {
    mockAttendanceData.clear();
    mockLeaveRequests.clear();
  }
}
