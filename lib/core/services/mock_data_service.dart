class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

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

  static List<Map<String, dynamic>> mockEmployeeList = [
    {
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
      'updatedAt': '2025-09-04T02:36:54.898Z',
    },
    {
      'id': 'EMP-24062025031',
      'authId': 'mock-auth-id-2',
      'nickname': 'Siri Ma',
      'firstName': 'Siri',
      'lastName': 'Ma',
      'email': 'siri.ma@nanostores.com',
      'primaryNumber': '0812345678',
      'companyName': 'NANO-STORES',
      'locationName': 'Bangkok',
      'branchName': 'Office',
      'positionName': 'HR Manager',
      'status': 'active',
      'role': 'hr',
      'profileImage': 'https://via.placeholder.com/150',
      'has2FA': true,
      'joinDate': '2024-06-20T17:00:00.000Z',
      'updatedAt': '2025-01-15T10:30:00.000Z',
    },
    {
      'id': 'EMP-12345678901',
      'authId': 'mock-auth-id-3',
      'nickname': 'John Doe',
      'firstName': 'John',
      'lastName': 'Doe',
      'email': 'john.doe@nanostores.com',
      'primaryNumber': '0823456789',
      'companyName': 'NANO-STORES',
      'locationName': 'Bangkok',
      'branchName': 'Office',
      'positionName': 'Software Developer',
      'status': 'active',
      'role': 'employee',
      'profileImage': 'https://via.placeholder.com/150',
      'has2FA': false,
      'joinDate': '2024-08-01T17:00:00.000Z',
      'updatedAt': '2025-01-10T14:20:00.000Z',
    },
    {
      'id': 'EMP-98765432109',
      'authId': 'mock-auth-id-4',
      'nickname': 'Jane Smith',
      'firstName': 'Jane',
      'lastName': 'Smith',
      'email': 'jane.smith@nanostores.com',
      'primaryNumber': '0834567890',
      'companyName': 'NANO-STORES',
      'locationName': 'Bangkok',
      'branchName': 'Office',
      'positionName': 'Marketing Manager',
      'status': 'active',
      'role': 'manager',
      'profileImage': 'https://via.placeholder.com/150',
      'has2FA': true,
      'joinDate': '2024-07-15T17:00:00.000Z',
      'updatedAt': '2025-01-12T09:15:00.000Z',
    },
    {
      'id': 'EMP-11111111111',
      'authId': 'mock-auth-id-5',
      'nickname': 'Alice Johnson',
      'firstName': 'Alice',
      'lastName': 'Johnson',
      'email': 'alice.johnson@nanostores.com',
      'primaryNumber': '0845678901',
      'companyName': 'NANO-STORES',
      'locationName': 'Bangkok',
      'branchName': 'Office',
      'positionName': 'Finance Manager',
      'status': 'active',
      'role': 'manager',
      'profileImage': 'https://via.placeholder.com/150',
      'has2FA': true,
      'joinDate': '2024-05-10T17:00:00.000Z',
      'updatedAt': '2025-01-08T11:45:00.000Z',
    },
    {
      'id': 'EMP-22222222222',
      'authId': 'mock-auth-id-6',
      'nickname': 'Bob Wilson',
      'firstName': 'Bob',
      'lastName': 'Wilson',
      'email': 'bob.wilson@nanostores.com',
      'primaryNumber': '0856789012',
      'companyName': 'NANO-STORES',
      'locationName': 'Bangkok',
      'branchName': 'Office',
      'positionName': 'Sales Executive',
      'status': 'active',
      'role': 'employee',
      'profileImage': 'https://via.placeholder.com/150',
      'has2FA': false,
      'joinDate': '2024-09-15T17:00:00.000Z',
      'updatedAt': '2025-01-05T16:30:00.000Z',
    },
    {
      'id': 'EMP-33333333333',
      'authId': 'mock-auth-id-7',
      'nickname': 'Carol Davis',
      'firstName': 'Carol',
      'lastName': 'Davis',
      'email': 'carol.davis@nanostores.com',
      'primaryNumber': '0867890123',
      'companyName': 'NANO-STORES',
      'locationName': 'Bangkok',
      'branchName': 'Office',
      'positionName': 'Customer Service',
      'status': 'active',
      'role': 'employee',
      'profileImage': 'https://via.placeholder.com/150',
      'has2FA': true,
      'joinDate': '2024-04-20T17:00:00.000Z',
      'updatedAt': '2025-01-03T09:20:00.000Z',
    },
  ];

  static List<Map<String, dynamic>> mockAttendanceData = [];

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

  static Future<Map<String, dynamic>> loginWithCredentials(
    String email,
    String password,
  ) async {
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

    final existingRecordIndex = mockAttendanceData.indexWhere(
      (record) =>
          record['employeeId'] == data['employeeId'] && record['date'] == today,
    );

    if (data['type'] == 'checkin') {
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

      mockAttendanceData.add(attendanceRecord);

      return {
        'success': true,
        'message': 'Check In recorded successfully',
        'data': attendanceRecord,
      };
    } else {
      if (existingRecordIndex != -1) {
        final existingRecord = mockAttendanceData[existingRecordIndex];

        final timeString =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        existingRecord['checkOutAt'] = timeString;
        existingRecord['updatedAt'] = now.toIso8601String();

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

        return {
          'success': true,
          'message': 'Check Out recorded successfully',
          'data': existingRecord,
        };
      } else {
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

  static Future<Map<String, dynamic>> uploadFile(String filePath) async {
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'message': 'File uploaded successfully',
      'url':
          'https://mock-storage.com/files/${DateTime.now().millisecondsSinceEpoch}.pdf',
    };
  }
  
  static void clearAllData() {
    mockAttendanceData.clear();
    mockLeaveRequests.clear();
  }
}
